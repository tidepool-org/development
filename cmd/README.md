# tpctl
`tpctl` is used to create AWS EKS clusters that run the Tidepool services
in a HIPAA compliant way.

## Why user Docker
We package `tpctl` in a Docker container to ensure that it can be run in any environment.

## Prerequisites
To run `tpctl`, you will need: 
* a local Docker daemon;
* a GitHub account and an ability to create or write to a GitHub repo; and,
* an AWS account with an identity that has the right to create a Kubernetes cluster in EKS 
cluster, secrets in the AWS Secrets Manager, and stacks in AWS CloudFormation.

## Installation
`tpctl` is distributed as a Docker image.  You may pull down the latest version
from Docker Hub with tag `tidepool/tpctl:latest`.

```bash
docker pull tidepool/tpctl
```

Or, you may clone the
Tidepool `development` repo and build the Docker image from the Dockerfile:
```bash
git clone git@github.com:tidepool-org/development
cd development/cmd
./build.sh
```

## Execution Environment

You may use `tpctl` to configure an existing GitHub repository.  To do so, 
provide the name of the repository:

```bash
export REMOTE_REPO=git@github.org:tidepool-org/cluster-test1 
```

Or, if you have not already created a GitHub repository you may create one:
```bash
tpctl repo
```

In addition, you will need to provide a GitHub personal access token that provides
write access to the config repo:

```bash
export GITHUB_TOKEN=....
```
This token will be provided to a service that runs in your cluster to keep
its services up-to-date.

These two environment variables are passed to the process running in
the Docker container.

In addition to that, you will need to provide access to your GitHub public key,
to your AWS credentials, to your GitHub name and email address, and
to your Kubernetes `kubeconfig.yaml` file.  This is done by mounting
host files and directories into your Docker image.  If you look at the
`tpctl` script, you will see what directories it mounts:

```bash
docker run -it \
-e REMOTE_REPO=${REMOTE_REPO} \
-e GITHUB_TOKEN=${GITHUB_TOKEN} \
-v ~/.ssh:/root/.ssh:ro  \
-v ~/.aws:/root/.aws \
-v ~/.kube:/root/.kube \
-v ~/.helm:/root/.helm \
-v ~/.gitconfig:/root/.gitconfig 
tpctl /root/tpctl $*
```

This presumes that your `.ssh` public key is stored at `~/.ssh/id_rsa`, that your 
aws credentials are stored as `~/.aws/credentials`, that your
GitHub global credentials are stored at `~/.gitconfig`,  that your
kubeconfig file is stores at `~/.kube/config.yaml`, and that your `Helm` identity
is stored in `~/.helm`. 

If any of these are incorrect, please amend the file accordingly.


## Basic Usage

To create a EKS cluster running the Tidepool services with GitOps
and a Service Mesh that provides HIPAA compliance, you will perform
a series of steps:

* Create an GitHub Configuration Repository

  This will create an empty GitHub repository for storing the desired state of your EKS
  cluster.

  ```bash
  tpctl repo
  ```

* Create an Configuration File

  This will create a file in your GitHub configuration repo called `values.yaml` that contains
  all the data needed to construct the other Kubernetes configuration files.

  ```bash
  tpctl values
  ```

  In this file, you will find parameters that you may change to customize the installation.

  By default, the cluster name is derived from the GitHub repository name.  You may override it.

* Generate the Configuration

  From the  `values.yaml` file you can generate all the Kubernetes manifest files, the AWS IAM roles and 
  policies, and the `eksctl` `ClusterConfig` file that is used to build a cluster.

  ```bash
  tpctl config
  ```

* Create an AWS EKS Cluster

  Once you have generated the manifest files, you may create your EKS cluster.

  ```bash
  tpctl cluster
  ```

* Install a Service Mesh

  A service mesh will encrypt inter-service traffic to ensure that Personal Health Information (PHI) is protected in transit from exposure.

  ```bash
  tpctl mesh
  ```

* Install the Flux GitOps Controller

  The Flux GitOps controller  watches for changes in the GitHub configuration repo and reflects 
  those changes in your AWS Kubernetes cluster. 
  
  In addition, the command will install the `tiller`
  service and will create and install TLS certificates.

  ```bash
  tpctl flux
  ```

## Advanced Usage
In addition to the basic commands above, you may:


* open shell with config repo in current directory.  Exit shell to commit changes.
  ```bash
  tpctl edit_repo
  ```
 
* regenerate client certs for Helm to access Tiller
  ```bash
  tpctl regenerate_cert 
  ```

* open editor to edit values.yaml file
  ```bash
  tpctl edit_values
  ```

* copy S3 assets to new bucket
  ```bash
  tpctl copy_assets
  ```

* migrate secrets from legacy GitHub repo to AWS secrets manager
  ```bash
  tpctl migrate_secrets
  ```

* generate random secrets and persist into AWS secrets manager
  ```bash
  tpctl randomize_secrets
  ```

* read STDIN for plaintext K8s secrets
  ```bash
  tpctl upsert_plaintext_secrets
  ```

* add system:master USERS to K8s cluster
  ```bash
  tpctl install_users
  ```

* copy deploy key from Flux to GitHub config repo
  ```bash
  tpctl deploy_key
  ``` 

* initiate deletion of the AWS EKS cluster
  ```bash
  tpctl delete_cluster
  ```

* await completion of deletion of gthe AWS EKS cluster
  ```bash
  tpctl await_deletion
  ```

* copy the KUBECONFIG into the local $KUBECONFIG file
  ```bash
  tpctl merge_kubeconfig
  ```

* open the Gloo dashboard
  ```bash
  tpctl gloo_dashboard
  ```

* open the Linkerd dashboard
  ```bash
  tpctl linkerd_dashboard
  ```

* create managed policies
  ```bash
  tpctl managed_policies
  ```

* show recent git diff
  ```bash
  tpctl diff
  ```