# Setting up a plural cluster

This documentation describes how to set up a new cluster with the domain
`dev.at.onplural.sh` and deploy Kubeflow at <https://kubeflow.dev.at.onplural.sh>.

You find the general plural docs [here](https://docs.plural.sh).

To successfully set up a cluster using plural, follow the instructions below and
make sure that the following requirements are met before your start.

- You are a plural admin user and can edit the AlexanderThamm account on
  <https://app.plural.sh>
- You have AdminAccess to one of our AWS accounts.

In case you need more rights, please contact <juergen.stary@alexanderthamm.com>

The following instructions assume you execute them on a unix based system. Take
the below toc as an overview of what needs to be done in order to set up a
cluster.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Installing required software](#installing-required-software)
- [Configure the AWS cli](#configure-the-aws-cli)
  - [`aws sso login`](#aws-sso-login)
  - [Copy and paste session tokens](#copy-and-paste-session-tokens)
- [Set up a service account](#set-up-a-service-account)
  - [create the service account](#create-the-service-account)
- [Set up the installation repository](#set-up-the-installation-repository)
- [Set up the cluster](#set-up-the-cluster)
  - [Install bootstrap](#install-bootstrap)
    - [install bootstrap aws-k8s](#install-bootstrap-aws-k8s)
    - [Install bootstrap aws-efs](#install-bootstrap-aws-efs)
  - [Install console](#install-console)
  - [Build the workspace and deploy](#build-the-workspace-and-deploy)
- [Share repo with everybody](#share-repo-with-everybody)
- [Install Kubricks](#install-kubricks)
- [Install Kubeflow](#install-kubeflow)
- [Install SparkOperator](#install-sparkoperator)
- [Install SparkHistoryServer](#install-sparkhistoryserver)
- [Install Kyverno](#install-kyverno)
- [Install Kyverno AT policies](#install-kyverno-at-policies)
- [Install CronJob for Zombie Spark Pod cleanup](#install-cronjob-for-zombie-spark-pod-cleanup)
- [Add additional software](#add-additional-software)
- [Optimize for cost efficiency](#optimize-for-cost-efficiency)
- [Share the installation repo](#share-the-installation-repo)
- [Destroy and redeploy](#destroy-and-redeploy)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installing required software

The software you need to install before being able to use plural and setup a
cluster is located [here](https://docs.plural.sh/getting-started).

Basically you need

- [aws cli (v2!)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- the Plural CLI
- [helm](https://helm.sh/docs/intro/install/)
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

With respect to the plural cli, we recommend an alternative approach to the one
from the official docs. This recommended way is to clone the [plural-cli repository](https://github.com/pluralsh/plural-cli),
build the cli using the [makefile](https://github.com/pluralsh/plural-cli/blob/master/Makefile)
and the `make build-cli` command and regularly pull the latest changes and build
the latest version.

```sh
# clone plural-cli repo and cd into it
git clone git@github.com:pluralsh/plural-cli.git
cd plural-cli

# build the cli
make build-cli

# move plural.o to your local go bin or any other dir on your PATH
cp plural.o /usr/local/go/bin/plural

# check installation
plural version
```

## Configure the AWS cli

In order to provide plural access to the aws account, you need to be
authenticated as an admin user in your current cli session. This can be achieved
using

- `aws sso login --profile <AWS-PROFILE>` or
- copy pasting session tokens from the aws [single sign on portal](https://alexanderthamm.awsapps.com/start#/).

**Attention** - You need to have admin access to in order to be able to set up
the cluster!

### `aws sso login`

In order to use sso login via the command line, you have to create a profile in
your `~/.aws/config` which sets the account id and role you want to assume. The
below config is configured to provide admin access to the kf4 account.

```ini
[profile kf4-admin]
sso_start_url = https://alexanderthamm.awsapps.com/start
sso_region = eu-central-1
sso_account_id = 975691912542
sso_role_name = AdministratorAccess
region = eu-central-1
output = json
```

Having set up the `~/.aws/config` like this, you should be able to login.

```sh
aws sso login --profile kf4-admin
```

The command will take you to a web page asking you to confirm the login attempt.

### Copy and paste session tokens

The [single sign on portal](https://alexanderthamm.awsapps.com/start#/) lists
all the accounts you have access to and all the role you can assume. For each
role, you can have programmatic access or command line access.

![single-sign-on](/img/plural/aws-single-sign-on.png)

Click on 'Command line or programmatic access' and copy the session tokens from
the popup.

![copy-session-token](/img/plural/aws-copy-session-tokens.png)

## Set up a service account

All our clusters should be set up using a service account. This allows us to
collaboratively work on the cluster. If a cluster is set up with a personal
account, only this person is able to deploy the cluster. A service account can
be impersonated by multiple colleagues.

### create the service account

The service account can be set up via the [plural web ui](https://app.plural.sh/accounts/edit/service-accounts).
Name and email can be arbitrary values. The email has to be unique but does not have to exist.

It is recommended to use to target domain as the name and as prefix for the
email. This makes it easy to link service accounts to deployments.

The service account needs to be authorized to perform actions on the plural
account. This can be achieved by adding the service account to the [user group](https://app.plural.sh/accounts/edit/groups)
**general**. New service accounts should be added to that group automatically.
However, it is always good to double check that.

In order to allow other users to impersonate the service account, you need to
add those accounts in the user binding field. This can also be done afterwards.
You might just want to add your own user right now.

![create service account](/img/plural/create-service-account.png)
## Set up the installation repository

On our [GitHub](https://github.com/KubeSoup), create a new repository for the
deployment. Name it after the domain you want to deploy to, replacing `.` with
`-`. Add a Readme, so you already have a branch and a first commit.

![create service account](/img/plural/create-installation-repo.png)

Switch back to your CLI, clone the new repo and run plural init using the
service account. **Also make sure your active shell is logged into the correct aws account!**

```sh
# check your current aws account
aws sts get-caller-identity  # result should show target account

# clone the new repo and cd into
git clone git@github.com:KubeSoup/dev-at-onplural-sh.git
cd dev-at-onplural-sh

# login and impersonate the service account
plural login --service-account dev.at.onplural.sh@alexanderthamm.com

# run plural init
plural init
```

Instead of `plural login --service-account` and `plural init`, you can directly
run plural init as the service account.

```sh
# run plural init as the service account
plural init --service-account dev.at.onplural.sh@alexanderthamm.com
```

Fill in the prompts as follows:

```sh
# ? It looks like you've already logged in as dev.at.onplural.sh@alexanderthamm.com, use this profile? (y/N)
y  # N if this is not already the service account you want to use

# ? Select one of the following providers:  [Use arrows to move, type to filter]
aws

# ? Enter the name of your cluster:
dev-at-onplural-sh  # should equal the repository name

# ? What region will you deploy to?
eu-central-1

# Give us a unique, memorable string to use for bucket naming, eg an abbreviation for your company:
at

# Do you want to use plural's dns provider: [Yn]
Y

# What do you want to use as your subdomain, must be a subdomain under onplural.sh:
dev.at.onplural.sh
```

You have now initialized the installation repo! Checkout the generated
`workspace.yaml` to see that it contains the values you just entered.

```yaml
apiVersion: plural.sh/v1alpha1
kind: ProjectManifest
metadata:
  name: dev-at-onplural-sh
spec:
  cluster: dev-at-onplural-sh
  bucket: at-tf-state
  project: "975691912542"  # your aws account number
  provider: aws
  region: eu-central-1
  owner:
    email: dev.at.onplural.sh@alexanderthamm.com
  network:
    subdomain: dev.at.onplural.sh
    pluraldns: true
  bucketPrefix: at
  context: {}
```

Next, you will install the first applications and deploy the cluster.

## Set up the cluster

The first to applications we want to install are

- bootstrap, which sets up the cluster and
- console, which provides a web ui for administrating the cluster.

For installing and deploying applications, we will use the following commands:

```sh
# install application
plural bundle install <app-name> <bundle-name>

# build the workspace
plural build
plural build --only <application name>

# deploy to the cluster
plural deploy
```

Installing application bundles will make changes to the file `context.yaml`. For
some application bundles, you have to enter configuration in an interactive way.
This config is also reflected by `context.yaml`

### Install bootstrap

To check which bundles need to be installed, we run

```sh
plural bundle list bootstrap
```

The output tells us that the application **bootstrap** provides two bundles

```sh
+---------+--------------------------------+----------+
|  NAME   |          DESCRIPTION           | PROVIDER |
+---------+--------------------------------+----------+
| aws-efs | Creates and configures an      | AWS      |
|         | EFS instance for use with      |          |
|         | kubernetes                     |          |
| aws-k8s | Creates an eks cluster and     | AWS      |
|         | installs the bootstrap chart   |          |
+---------+--------------------------------+----------+
```

make sure to be logged in as the service account

```sh
plural login --service-account dev.at.onplural.sh@alexanderthamm.com
```

#### install bootstrap aws-k8s

```sh
# install the bootstrap aws-k8s bundle
plural bundle install bootstrap aws-k8s
```

Answer the prompts as follows:

```sh
# >> Arbitary name for the virtual private cloud to place your cluster in, eg "plural"
# ? Enter the value
dev-at-onplural-sh  # should equal cluster name for consistency
```

#### Install bootstrap aws-efs

```sh
# install the bootstrap aws-efs bundle
plural bundle install bootstrap aws-efs
```

### Install console

To check which bundles need to be installed, run

```sh
plural bundle list console
```

The output shows that the application **console** provides a single bundle

```sh
+-------------+--------------------------------+----------+
|    NAME     |          DESCRIPTION           | PROVIDER |
+-------------+--------------------------------+----------+
| console-aws | Deploys console on an EKS      | AWS      |
|             | cluster                        |          |
+-------------+--------------------------------+----------+
```

To install it, run

```sh
# install the bootstrap console-aws bundle
plural bundle install console console-aws
```

Answer the prompts as follows:

```sh
# >> Arbitary name for s3 bucket to store wal archives in, eg plural-wal-archives
# ? Enter a globally unique bucket name, will be formatted as at-dev-at-onplural-sh-<your-input>
#   (at-dev-at-onplural-sh-postgres-wal)
postgres-wal

# >> Fully Qualified Domain Name for the console dashboard, eg console.topleveldomain.com
#    if topleveldomain.com is the hostname you inputed above.
# ? Enter a domain, which must be beneath dev.at.onplural.sh
console.dev.at.onplural.sh

# >> git username for console to use in git operations, eg your github username
# ? Enter the value
KubeChef  # this is our bot user for automation

# >> email for git operations by console
# ? Enter the value
kubesoup.bot@alexanderthamm.com  # this is the group email for the bot user

# >> email for the initial admin user
# ? Enter the value
dev.at.onplural.sh@alexanderthamm.com  # service account mail

# >> name for the initial admin user
# ? Enter the value
dev.at.onplural.sh  # service account name

# >> path to the private key to use for git authentication
# ? select a file: [tab for suggestions] (~/.ssh/id_rsa)
~/.ssh/id_rsa_KubeChef  # get the file from KeePassXC

# >> path to the public key to use for git authentication
# ? select a file: [tab for suggestions] (~/.ssh/id_rsa.pub)
~/.ssh/id_rsa_KubeChef.pub  # get the file from KeePassXC

# >> passphrase to use for encrypted private keys (leave empty if not applicable)
# ? Enter the value
  # empty for KubeChef

# ? Enable plural OIDC
Y
```

### Build the workspace and deploy

After executing all of the instructions above, the context yaml should look like
this:

```yaml
apiVersion: plural.sh/v1alpha1
kind: Context
spec:
  bundles:
  - repository: bootstrap
    name: aws-k8s
  - repository: bootstrap
    name: aws-efs
  - repository: console
    name: console-aws
  configuration:
    bootstrap:
      vpc_name: dev-at-onplural-sh
    console:
      admin_email: dev.at.onplural.sh@alexanderthamm.com
      admin_name: dev.at.onplural.sh
      console_dns: console.dev.at.onplural.sh
      git_email: kubesoup.bot@alexanderthamm.com
      git_user: KubeChef
      passphrase: ""
      private_key: |
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnN****
        -----END OPENSSH PRIVATE KEY-----
      public_key: |
        ssh-rsa AAAA****
      repo_url: git@github.com:KubeSoup/dev-at-onplural-sh.git
    ingress-nginx: {}
    monitoring: {}
    postgres:
      wal_bucket: at-dev-at-onplural-sh-postgres-wal
```

Before being able to deploy the cluster and the installed applications, you need
to build your workspace first. This downloads all installed artifacts and
corresponding helm charts and terraform modules.

```sh
plural build
```

Once your workspace is build, you will find new directories and files in your
workspace. Each directory corresponds to a new application that will be deployed
and comes with subdirectories for crds, helm charts and terraform modules.

Deploy the cluster and the installed applications using:

```sh
plural deploy
```

Or, if you are building a cluster from scratch but the service account you are
using did already install applications before. Impersonate the [service account](https://app.plural.sh/accounts/edit/service-accounts)
and check the if the [list of installed repositories](https://app.plural.sh/me/edit/installations)
contains anything else than bootstrap, postgres or console.

```sh
# first build workspace
plural build --only bootstrap
plural build --only postgres      # dependency of console
plural build --only ingress-nginx # dependency of console
plural build --only monitoring    # dependency of console
plural build --only console

# then deploy
plural deploy
```

After the successfull deploy, you can do some checks to see if everything works
as expected.

- Login to the aws management console and check the [EKS section](https://eu-central-1.console.aws.amazon.com/eks/home?region=eu-central-1#/clusters)
- Navigate to the web UI of the console (e.g. <https://console.dev.at.onplural.sh>).
  Make sure to impersonate the correct service account before.
- Connect to your cluster using [Lens](https://k8slens.dev). Make sure to have
  configured the correct aws account in your cli and run:

    ```sh
    aws eks --profile kf4-admin update-kubeconfig --name dev-at-onplural-sh
    ```

Last, commit the files in the installation repo and push them to the remote:

```sh
# add changes
git add .

# commit
git commit -m "initial setup of dev cluster"

# push
git push
```

## Share repo with everybody

In order to let other teammates decrypt the repository, let's share it with everyone. If you need more info, look into the [plural doc](https://docs.plural.sh/advanced-topics/security/secret-management#share-a-repo). 

Requirement: Every user needs to have a key [here](https://app.plural.sh/profile/keys). If no key exists there, the user needs to create it by himself/herself:
```
plural login #Use your user
plural crypto setup-keys --name xyz #The name does not matter
```

The plublishing behaviour is weird but might get fixed in a future plural cli version - every user needs to be added step by step and as the last user:
```
plural crypto share --email david.vanderspek@partner.alexanderthamm.com
plural crypto share --email david.vanderspek@partner.alexanderthamm.com --email tim.krause@alexanderthamm.com
plural crypto share --email david.vanderspek@partner.alexanderthamm.com --email tim.krause@alexanderthamm.com --email hans.rauer@alexanderthamm.com
plural crypto share --email david.vanderspek@partner.alexanderthamm.com --email tim.krause@alexanderthamm.com --email hans.rauer@alexanderthamm.com --email nico.becker@alexanderthamm.com
plural crypto share --email david.vanderspek@partner.alexanderthamm.com --email tim.krause@alexanderthamm.com --email hans.rauer@alexanderthamm.com --email nico.becker@alexanderthamm.com --email salil.mishra@alexanderthamm.com

cat .plural-crypt/identities.yml
#You should see all users now
```

Push the changes into the Github repo! Done.

## Install Kubricks

**Optional** - only deploy it if you really need it.

Deploying kubricks as a plural artifact is fairly simple. Be sure the `bootstrap` artifact has been deployed beforehand:
```
plural bundle list kubricks
plural bundle install kubricks kubricks-aws
plural build 
#plural build --only kubricks is not enough!

plural deploy
```

## Install Kubeflow

Make sure you have set up your aws cli for the account the target cluster is
running on. Also confirm that you are logged in as the plural service account
that is the owner of the cluster (e.g. `dev.at.onplural.sh`).

List the components that are part of the kubeflow bundle:

```sh
plural bundle list kubeflow
```

The output shows:

```sh
+--------------+--------------------------------+----------+
|     NAME     |          DESCRIPTION           | PROVIDER |
+--------------+--------------------------------+----------+
| kubeflow-aws | Installs Kubeflow on an EKS    | AWS      |
|              | cluster                        |          |
+--------------+--------------------------------+----------+
```

install `kubeflow-aws`.

```sh
kubeflow bundle install kubeflow kubeflow-aws
```

Answer the prompts as follows:

```sh
# >> bucket to store mysql backups in
# ? Enter a globally unique bucket name, will be formatted as at-dev-at-onplural-sh-<your-input> (at-dev-at-onplural-sh-mysql-backups)
mysql-backups

# >> FQDN to use for your accessing the mysql orchestrator
# ? Enter a domain, which must be beneath dev.at.onplural.sh
mysql.dev.at.onplural.sh

# >> the dns name to access the redis master (optional)
# ? Enter a domain, which must be beneath dev.at.onplural.sh
redis-master.dev.at.onplural.sh

# >> the dns name to access your redis replicas (optional)
# ? Enter a domain, which must be beneath dev.at.onplural.sh
redis-replicas.dev.at.onplural.sh

# >> Arbitrary bucket name to store the traces in, eg plural-tempo-traces
# ? Enter a globally unique bucket name, will be formatted as at-dev-at-onplural-sh-<your-input> (at-dev-at-onplural-sh-grafana-tempo)
grafana-tempo

# >> FQDN to use for the Kiali installation
# ? Enter a domain, which must be beneath dev.at.onplural.sh
kiali.dev.at.onplural.sh

# >> bucket to store the pipeline artifacts and logs in
# ? Enter a globally unique bucket name, will be formatted as at-dev-at-onplural-sh-<your-input> (at-dev-at-onplural-sh-kubeflow-pipelines)
kubeflow-pipelines

# >> FQDN to use for your Kubeflow installation
# ? Enter a domain, which must be beneath dev.at.onplural.sh
kubeflow.dev.at.onplural.sh

# ? Enable plural OIDC
Y
```

Since we use interactive SparkSessions in Jupyter notebooks, we need to use our forked "notebook-controller" image to get the correct ports injected into the svc:

```sh
vi kubeflow/helm/kubeflow/values.yaml
#notebooks: {}
notebooks:
  controller:
    image:
      repository: public.ecr.aws/atcommons/kubeflow/notebook-controller
      tag: 1.5.0.spark
```

In order to configure the culling feature properly (bringing idled notebooks automatically into suspend mode to save costs) add the following config as well:
```
notebooks:
  controller:
    culling:
      checkPeriod: "5"
      enabled: "true"
      idleTime: "360"
```

Run any of the below commands to build your workspace.

```sh
plural build
plural build --only kubeflow
```

Deploy Kubeflow.

```sh
plural deploy
```

Commit your changes.

```sh
git add .
git commit -m "install kubeflow"
git push
```

You can add users to your kubeflow installation via the web ui. Select Kubeflow
from the [list of installed applications](https://app.plural.sh/explore/installed).
Click on **configure** and **OpenID Connect** and add users to the user binding.

## Install SparkOperator

Since the SparkApplications provided by the SparkOperator are used for long running Spark jobs, we need to provide it on all environments.

Get the structure into your git repo:

```sh
plural bundle install spark spark-aws
```

Add a new ClusterRole for adding SparkApplications to the ServiceAccount `default-editor` so that normal kubeflow users have correct permissions:

```sh
cat <<'EOF' >> spark/helm/spark/templates/clusterrole-kubeflow-spark-edit.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    rbac.authorization.kubeflow.org/aggregate-to-kubeflow-edit: "true"
  name: kubeflow-spark-edit
rules:
- apiGroups:
  - sparkoperator.k8s.io
  resources:
  - sparkapplications
  - sparkapplications/status
  - scheduledsparkapplications
  - scheduledsparkapplications/status
  verbs:
  - '*'
EOF
```

Deploy it:

```sh
plural build --only spark
plural deploy
```

## Install SparkHistoryServer

This SparkHistoryServer is required on the clusters if Spark is used/shiped as it improves the user experience. It enables the users to spin up a SparkHistoryServer for them as a self-serve services. 

This section installs the SparkHistoryServer controller with one command (it is not a plural artifact but a manual deployment via Makefile and kustomize in the end):

```
git clone https://github.com/KubeSoup/spark-history-server-controller.git
cd spark-history-server-controller
git pull

make deploy IMG=public.ecr.aws/atcommons/sparkhistoryservercontroller:0.1.1
```

You can verify that the operator is up and running by:
```
kubectl get pods -n spark-history-server-controller-system
```

### Troubleshooting

If you get the following error:
```
/home/atxps/Git/KubeSoup/spark-history-server-controller/bin/controller-gen rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash -s -- 3.8.7 /home/atxps/Git/KubeSoup/spark-history-server-controller/bin
/home/atxps/Git/KubeSoup/spark-history-server-controller/bin/kustomize exists. Remove it first.
make: *** [Makefile:123: /home/atxps/Git/KubeSoup/spark-history-server-controller/bin/kustomize] Error 1
```
just fix it by running: `rm bin/kustomize`




## Install Kyverno

Kyverno needs to be deployed on all our clusters. It is a sort of Mutating
Webhook Admission Controller that listens on CRs. We use it for manipulating
(e.g. injecting annotations or additional ports) K8s resources which are owned
by a Kubernetes Operator we do not want to fork.

It can be simply done with the following commands:

```sh
plural bundle install kyverno kyverno-aws
#>> Deploy Kyverno policies: N
plural build --only kyverno
plural deploy

#After one minute the kyverno pod should run:
kubectl get pods -n kyverno
```

## Install Kyverno AT policies

After kyverno is up and running we can deploy needed ClusterPolicy's. It is required to be applied on all clusters. The following mentioned .yaml files are like fire and forget (work on all our clusters and need no adjustments).

Just do:

```sh
git clone https://github.com/KubeSoup/k8s-scratchpad
cd k8s-scratchpad

kubectl apply -f kyverno-at-policies/Namespace.yaml
```

## Install CronJob for Zombie Spark Pod cleanup

We need to setup a K8s CronJob to cleanup Zombie Spark pods.

Just do:

```bash
git clone https://github.com/KubeSoup/k8s-scratchpad
cd k8s-scratchpad

helm install zombie-pod ./zombie-pod --namespace zombie-pod -
-create-namespace

# to uninstall
# helm uninstall zombie-pod --namespace zombie-pod
```

## Add additional software

You can now go on and install other apps offered by plural using the commands
`plural bundle install`, `plural build` and `plural deploy`.

**Attention** - Make sure to impersonate the correct service account. And
**always push** your changes after you deployed or destroyed applications. Also
**always pull** the latest changes from the remote before you start working.

## Optimize for cost efficiency

Check out the chapter about [cost efficiency](/aws-accounts/cost-efficiency.md)
to understand how you can change your deployment to separate different kinds of
workloads and schedule them on the best suited node groups.

## Share the installation repo

The installation repo is encrypted because it stores sensitive information. If
others want to collaborate on the installation repo, the encryption key needs to
be shared with them. This key can be found in your plural directory `~/.plural/key`.
The easiest way to share this key within the team is to create an entry for it
in our [KeePassXC database](https://github.com/KubeSoup/secrets) and attach the
file to it. Anybody who wants to decrypt the repo, needs to place this key file
at the correct location `~/.plural/key`.

**Attention** - if you already have a key there, make sure to create a back up
of it. Otherwhise you might lose access to other installation repos.

Once the correct key is in place, clone the repository and decrypt it as
follows.

```sh
git clone git@github.com:KubeSoup/dev-at-onplural-sh.git
cd dev-at-onplural-sh

plural crypto init
plural crypto unlock
```

You should now be able to read all files in the directory. Also, you can install
and deploy applications.

## Destroy and redeploy

**Attention** - This section describes how terminating and redeploying the
cluster **should** work. At the moment, this procedure leads to errors when
redeploying. For now, we decided to leave the dev cluster up and running.

If you don't need a cluster to be running all time, costs can be saved by
tearing it down and redeploying it, when it is needed again.

For teardown, make sure you have checked out the latest version of the
respective installation repo. Also, check if you have the correct AWS account
configured and make sure to login as the service account that originally
deployed the cluster.

```sh
aws sts get-caller-identity
```

The result should show the account where the cluster you want to tear down is
currently deployed (e.g. dev.at.onplural.sh).

```sh
plural login --service-account dev.at.onplural.sh@alexanderthamm.com
```

Once you are set, destroy your cluster using:

```sh
plural destroy
```

Commit your changes.

```sh
git add .
git commit -m "shut down cluster"
git push
```

This command takes a while but eventually the infrastructure is taken down. Once
you need to spin up the cluster again, check out the latest commit on the repo
and redeploy the workspace.

```sh
# build
plural build

# deploy
plural deploy
```

Commit your changes.

```sh
git add .
git commit -m "spin up cluster"
git push
```

If you want to permanently destroy the cluster, please also clean up any
related artifacts:

- the plural service account,
- the installation repository,
- the entries in the KeePass, which belong **exclusively** to the specific
  deployment and
- the aws account usage documentation.
