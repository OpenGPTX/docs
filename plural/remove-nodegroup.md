# Removing node groups

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Step 1 - Check for other node groups](#step-1---check-for-other-node-groups)
- [Step 2 - Add `NO_SCHEDULE` taint](#step-2---add-no_schedule-taint)
- [Step 3 - Drain and delete nodes](#step-3---drain-and-delete-nodes)
- [Step 4 - Remove node group](#step-4---remove-node-group)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

The following steps have been established as current best practice for removing
node groups from a cluster. As an explanatory example, we want to change the
instance types of the node groups in the bootstrap module.

At the beginning, the node groups for the bootstrap module are defined as follows:

```terraform
single_az_node_groups = {
  small_burst_on_demand = {
    name = "small-burst-on-demand"
    capacity_type = "ON_DEMAND"
    min_capacity = 3
    desired_capacity = 3
    instance_types = ["t3.large", "t3a.large"]
    k8s_labels = {
      "plural.sh/capacityType" = "ON_DEMAND"
      "plural.sh/performanceType" = "BURST"
      "plural.sh/scalingGroup" = "small-burst-on-demand"
    }
  }
}
```

Note that `small_burst_on_demand` is the only node group.

## Step 1 - Check for other node groups

Check if the pods which are running on the node group to be removed can be
scheduled on nodes of a __different__ node group. If this is not the case,
removing the node group might bring down the system.

If there is no alternative node group, add one to terraform. Most likely in the
[bootstrap](https://github.com/KubeSoup/dev-at-onplural-sh/blob/main/bootstrap/terraform/main.tf)
or [kubeflow](https://github.com/KubeSoup/dev-at-onplural-sh/blob/main/kubeflow/terraform/main.tf)
module. You can either directly deploy this node group now using `plural build && plural deploy --commit "<message>"`
or you deploy together with the changes in step 2.

In the above example, there is only one node group. So we have to setup a new
one first. We add the new node group `medium_burst_on_demand`.

```terraform
medium_burst_on_demand = {
  name = "medium-burst-on-demand"
  capacity_type = "ON_DEMAND"
  min_capacity = 3
  desired_capacity = 3
  instance_types = ["t3.xlarge", "t3a.xlarge"]
  k8s_labels = {
    "plural.sh/capacityType" = "ON_DEMAND"
    "plural.sh/performanceType" = "BURST"
    "plural.sh/scalingGroup" = "medium-burst-on-demand"
  }
}
```

## Step 2 - Add `NO_SCHEDULE` taint

Give the node group to be removed a taint which prevents scheduling of new pods
on nodes of this node group. This can be achieved by adding the below snippet to
the node group definition in terraform and running `plural build && plural deploy --commit "<message>"`
afterwards.

```terraform
k8s_taints = [{
  key = "kubesoup.com/nodegroup-lifecycle"
  value = "toBeRemoved"
  effect = "NO_SCHEDULE"
}]
```

In our example, we add the taint to the node group `small_burst_on_demand`. The
terraform code for the node groups now looks as follows. We added a new node
group and we added the `NO_SCHEDULE` taint to the old one.

```terraform
single_az_node_groups = {
  small_burst_on_demand = {
    name = "small-burst-on-demand"
    capacity_type = "ON_DEMAND"
    min_capacity = 3
    desired_capacity = 3
    instance_types = ["t3.large", "t3a.large"]
    k8s_labels = {
      "plural.sh/capacityType" = "ON_DEMAND"
      "plural.sh/performanceType" = "BURST"
      "plural.sh/scalingGroup" = "small-burst-on-demand"
    }
    k8s_taints = [{
      key = "kubesoup.com/nodegroup-lifecycle"
        value = "toBeRemoved"
        effect = "NO_SCHEDULE"
    }]
  }
  medium_burst_on_demand = {
    name = "medium-burst-on-demand"
    capacity_type = "ON_DEMAND"
    min_capacity = 3
    desired_capacity = 3
    instance_types = ["t3.xlarge", "t3a.xlarge"]
    k8s_labels = {
      "plural.sh/capacityType" = "ON_DEMAND"
      "plural.sh/performanceType" = "BURST"
      "plural.sh/scalingGroup" = "medium-burst-on-demand"
    }
  }
}
```

A more rigid approach would be to add a taint with effect "NO_EXECUTE". This
would cause an immediate rescheduling of all the pods running on instances of
the respective node group.

## Step 3 - Drain and delete nodes

Once the node group is tainted, you can start manually draining and deleting the
nodes. The auto scaler should not bring up new instances of the tainted nodegroup

```sh
kubectl drain <node to be deleted>
```

## Step 4 - Remove node group

Once you have deleted all the nodes, you can safely remove the node group
entirely from terraform. Afterwards, run `plural buld && plural deploy --commit "<message>"`
again.

In our example, the final terraform looks as follows

```terrraform
single_az_node_groups = {
  medium_burst_on_demand = {
    name = "medium-burst-on-demand"
    capacity_type = "ON_DEMAND"
    min_capacity = 3
    desired_capacity = 3
    instance_types = ["t3.xlarge", "t3a.xlarge"]
    k8s_labels = {
      "plural.sh/capacityType" = "ON_DEMAND"
      "plural.sh/performanceType" = "BURST"
      "plural.sh/scalingGroup" = "medium-burst-on-demand"
    }
  }
}
```
