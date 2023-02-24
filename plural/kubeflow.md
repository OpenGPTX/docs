# Kubeflow with plural

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [customization](#customization)
  - [Add new instance types](#add-new-instance-types)
    - [Update the Kubeflow terraform module](#update-the-kubeflow-terraform-module)
    - [Update the UI config for the notebooks webapp](#update-the-ui-config-for-the-notebooks-webapp)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## customization

There are specific cases in which we would like to customize the installation
of kubeflow.

- different types of nodes or a higher maximum capacity
- launch configuration of notebooks

### Add new instance types

In order to be able to provision instance types other than the default ones,
those types need to be added explicitly. The available instance types are
configured via [managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
which are created by terraform. In addition it might me necessary to customize
the configuration options provided by the notebooks ui. If you apply special
taints or labels to your node groups, users should be able to configure
tolerations or affinities so their notebooks can be scheduled on the new types.

The following example assumes that new instance types should be added to the
cluster running on at.onplural.sh. The relevant installation repo can be found
in [gitlab](https://gitlab.alexanderthamm.com/kaas/at.onplural.sh).

#### Update the Kubeflow terraform module

To add new instance types, modifications need to be made in
`kubeflow/terraform/main.tf` in the plural installation repo. This file has a
reserved section for customization. It is enclosed by two comments:

```terraform
  ### BEGIN MANUAL SECTION <<aws>>

  ...

  ### END MANUAL SECTION <<aws>>
```

New instance types should be stored in the variable `single_az_node_groups`,
which is a nested dictionary. The keys are arbitrary names that describe the
instance type, e.g. `gpu_medium_on_demand`. The value is a dictionary with
configuration for the new node group. Have a look at the
[node group defaults](https://github.com/pluralsh/plural-artifacts/blob/0a96f6e8927cbde01e7f2aa8b1dddf401caa02e0/kubeflow/terraform/aws/variables.tf#L30)
and the [preinstalled node groups](https://github.com/pluralsh/plural-artifacts/blob/0a96f6e8927cbde01e7f2aa8b1dddf401caa02e0/kubeflow/terraform/aws/variables.tf#L48)
to see a valid node group configuration.

The following example shows how to setup a node group for p3.8xlarge gpus.

```terraform
  single_az_node_groups = {
    gpu_medium_on_demand = {
      name = "gpu-medium-on-demand"
      capacity_type = "ON_DEMAND"                                # use "SPOT" for spot instances
      min_capacity = 0
      max_capacity = 2
      desired_capacity = 0                                       # should usually be 0! especially for GPUs
      ami_type = "AL2_x86_64_GPU"                                # can be omitted if this is a CPU only instance type
      instance_types = ["p3.8xlarge"]                            # ec2 instance types with comparable resources
      k8s_labels = {
        "plural.sh/capacityType" = "ON_DEMAND"                   # use "SPOT" for spot instances
        "plural.sh/performanceType" = "SUSTAINED"
        "plural.sh/scalingGroup" = "gpu-medium-on-demand"        # has to be the same as the name!
        "k8s.amazonaws.com/accelerator" = "nvidia-tesla-v100"    # todo research labels for other gpus
      }
      k8s_taints = [
        {
          key = "nvidia.com/gpu"                                 # required for nvidia gpus
          value = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
  some_other_node_group = {
      ...
  }
```

After having modified the nodegroups, they are deployed following these steps:

1. on your machine, go to the kubeflow terraform module of the installation
   repository and run `terraform init` and `terraform plan`.

   ```sh
   cd kubeflow/terraform/

   terraform init
   terraform plan
   ```

   Check if the output of terraform plan corresponds to your changes to the
   instance types.

2. If everything looks fine, go ahead and deploy your changes to the cluster

   ```sh
   plural deploy
   ```

3. Check if the new node groups and autoscaling groups are created. E.g. using
   the AWS console.

4. If everything looks good, commit your changes and push it to the upstream.

   ```sh
   git add kubeflow/deploy.hcl
   git add kubeflow/terraform/main.tf
   git commit -m "[added|modified] node group [node group name]"
   git push
   ```

#### Update the UI config for the notebooks webapp

the notebooks ui config (aka `spawner_ui`) can be customized by providing
configuration in `kubeflow/helm/kubeflow/values.yaml`. This file gathers
configuration for the different components of kubeflow. To change the notebooks
ui, the config below the keyword `notebooks` needs to be adapted.

To learn about possible options for configuration, checkout the
[default values](https://github.com/pluralsh/plural-artifacts/blob/main/kubeflow/helm/notebooks/values.yaml)
of the kubeflow notebooks Chart. Within `kubeflow/helm/kubeflow/values.yaml`
you have to use the same configuration paths as defined in the default values.
Otherwhise your customization cannot be merged in.

**Attention:** Be careful with adding configuration! the config paths are not
merged. Instead, your custom configuration will overwrite the default values.
So if you want to keep the default, you have to explicitly add it again!

The following example adds an affinity config for the `gpu-medium-on-demand`
node group added above and the node group `gpu-medium-spot`.

```yaml
notebooks:
  webApp:
    config:
      affinityConfig:
        options:
          - configKey: GPU-Medium
            displayName: GPU Medium
            affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: plural.sh/scalingGroup
                          operator: In
                          values:
                            - gpu-medium-on-demand
              podAntiAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  - labelSelector:
                      matchExpressions:
                        - key: notebook-name
                          operator: Exists
                    namespaces: []
                    topologyKey: kubernetes.io/hostname
          - configKey: GPU-Medium-Spot
            displayName: GPU Medium Spot
            affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: plural.sh/scalingGroup
                          operator: In
                          values:
                            - gpu-medium-spot
              podAntiAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  - labelSelector:
                      matchExpressions:
                        - key: notebook-name
                          operator: Exists
                    namespaces: []
                    topologyKey: kubernetes.io/hostname
```
The following example adds a toleration config called `Big Notebooks` to let the users to use bigger notebook instance types.
```yaml
notebooks:
  webApp:
    config:
      tolerationGroup:
        options:
        - displayName: Spot Pool
          groupKey: spot
          tolerations:
          - effect: NoSchedule
            key: plural.sh/capacityType
            operator: Equal
            value: SPOT
        - displayName: GPU Pool
          groupKey: gpu
          tolerations:
          - effect: NoSchedule
            key: nvidia.com/gpu
            operator: Exists
        - displayName: GPU Spot Pool
          groupKey: spot-gpu
          tolerations:
          - effect: NoSchedule
            key: nvidia.com/gpu
            operator: Exists
          - effect: NoSchedule
            key: plural.sh/capacityType
            operator: Equal
            value: SPOT
        - displayName: Big Notebooks
          groupKey: bignotebooks
          tolerations:
          - effect: NoSchedule
            key: kubesoup.com/tier2
            operator: Equal
            value: notebook-dedicated
```

After having modified `values.yaml`, changes are deployed following these steps:

1. Deploy using the plural cli.

   ```sh
   plural deploy
   ```

2. Once this has finished, go to the notebooks webapp and try to launch a new
   notebook. You should see the effect of your changes in the UI. Check the
   affinities and tolerations dropdowns or other locations that should reflect
   the modifications.

   See, if your notebook launches on the instance type you expect.

3. If everything looks good, commit your changes and push it to the upstream.

   ```sh
   git add kubeflow/deploy.hcl
   git add kubeflow/helm/kubeflow/values.yaml
   git commit -m "[added|modified] [affinites|tolerations] to spawner ui"
   git push
   ```
