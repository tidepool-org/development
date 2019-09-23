# tpctl
`tpctl` is used to create AWS EKS clusters that run the Tidepool services
in a HIPAA compliant way.

## Prerequisites
You need Docker to run `tpctl`. 
We package `tpctl` in a Docker container to ensure that it can be run in any environment.  Please install Docker on your local machine.

You need a GitHub account and the ability to create/write to a GitHub repository.

You also need an AWS account with an identity that has the right:
* to create a Kubernetes cluster in EKS, 
* to create secrets in the AWS Secrets Manager; and,
* to create stacks in AWS CloudFormation.

## Installation
You may pull down the latest version Docker image of `tpctl`
from Docker Hub with tag `tidepool/tpctl:latest`.

```bash
docker pull tidepool/tpctl
```

Execute the following to create a file called `tpctl` and to make it executable:

```bash
cat <<! >tpctl
#!/bin/bash
docker run -it \
-e REMOTE_REPO=${REMOTE_REPO} \
-e GITHUB_TOKEN=${GITHUB_TOKEN} \
-v ~/.ssh:/root/.ssh:ro  \
-v ~/.aws:/root/.aws \
-v ~/.kube:/root/.kube \
-v ~/.helm:/root/.helm \
-v ~/.gitconfig:/root/.gitconfig \
tidepool/tpctl /root/tpctl $*
!
chmod +x tpctl
```

Alternatively, you may build your own local Docker image from the source by cloning theTidepool `development` repo and running the `build.sh` script:
```bash
git clone git@github.com:tidepool-org/development
cd development/cmd
./build.sh
```

Thereafter, you may use the `tpctl` script provided.

## Execution Environment

Most of the operations of `tpctl` either use or manipulate a GitHub repository.  You may use `tpctl` to configure an existing GitHub repository.  To do so, provide the name of the repository:

```bash
export REMOTE_REPO=git@github.org:tidepool-org/cluster-test1 
```

Alternatively, if you have not already created a GitHub repository you may create one using `tpctl`:
```bash
tpctl repo
```

## Authentication

`tpctl` interacts with several external services on your behalf.  `tpctl` must authenticate itself.

To do so, `tpctl` must access your credentials stored on your local machine.  This explains the need for the numerous directories that are mounted into the Docker container.  We explain these in detail below. If the assumptions we make are incorrect for your environment, please amend the file accordingly.

### GitHub 
In order to update your Git configuration repo with the tags of new versions of Docker images that you use, you must provide a [GitHub personal access token](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line) that provides
write access to the GitHub configuration repository:

```bash
export GITHUB_TOKEN=....
```

### AWS
In order to create and query AWS resources, you must provide access to your AWS credentials. We assume that you store those
credentials in the standard place, 
```
~/.aws/credentials
```

`tpctl` mounts `~/.aws` inside the Docker container to access the credentials.

### Kubernetes
In order to access your Kubernetes cluster, you must provide access to the file that stores your Kubernetes configurations.  We assume that you store that file in:
```
~/.kube/config
```

`tpctl` mounts `~/.kube` inside the Docker container to access that file.

### Helm
In order to provide you access to the Kubernetes cluster via the `helm` client, you must provide access to the directory that stores your `helm` client credentials.  That directory is typically stored at: 
```
~/.helm
```
 `tpctl` populates that directory with a TLS certificate and keys that are needed to communicate with the `helm` installer.

### Git
In order to make Git commits, `tpctl` needs your Git username and email. This is typically stored in:
```
~/.gitconfig
```    
`tpctl` mounts that file.

### SSH
In order to clone private repos in your organization, `tpctl` needs access to your GitHub public key.  This is typically stored in:
```
~/.ssh/id_rsa
```

## Basic Usage

To create a EKS cluster running the Tidepool services with GitOps
and a service mesh that provides HIPAA compliance, you perform
a series of steps:

* Create an GitHub Configuration Repository

  This creates an empty GitHub repository for storing the desired state of your EKS
  cluster.

  ```bash
  tpctl repo
  ```

* Create an Configuration File

  This creates a file in your GitHub configuration repo called `values.yaml` that contains
  all the data needed to construct the other Kubernetes configuration files.

  ```bash
  tpctl values
  ```

  In this file, you find parameters that you may change to customize the installation.  

  By default, the cluster name is derived from the GitHub repository name.  You may override it.

  In addition, the default `values.yaml` file defines a single Tidepool environment named `qa2`. You must modify this environment or add others.

  Importantly, be sure to set the DNS names for your Tidepool services. 
  Assuming that you have the authority to do so, TLS certificates are automatically generated for the names that your provide and DNS aliases to the DNS names you provide are also created.

* Generate the Configuration

  From the  `values.yaml` file  `tpctl`  can generate all the Kubernetes manifest files, the AWS IAM roles and  policies, and the `eksctl` `ClusterConfig` file that is used to build a cluster.  You do this with:

  ```bash
  tpctl config
  ```

* Create an AWS EKS Cluster

  Once you have generated the manifest files, you may create your EKS cluster.

  ```bash
  tpctl cluster
  ```

* Install a Service Mesh

  A service mesh encrypt inter-service traffic to ensure that personal health information (PHI) is protected in transit from exposure to unauthorized parties. 

  You may install a service mesh as follows.

  ```bash
  tpctl mesh
  ```

  This must be done *before* the next step.

* Install the Flux GitOps Controller

  The Flux GitOps controller keeps your Kubernetes cluster up to date with the contents of the GitHub configuration repo.  It also keeps your GitHub configuration repo up to date with the latest versions of Docker images of your services that are published in Docker Hub.
  
  To install the GitOps operator:
  

  ```bash
  tpctl flux
  ```

  In addition, this command installs the `tiller`
  server (the counterpart to the `Helm` client) and creates and installs TLS certificates that the Helm client needs to communicate with `tiller` server.

## Advanced Usage
In addition to the basic commands above, you may:

* edit any of file in the configuration repo
  
  You may access the GitHub configuration repo using standard Git commands.  In addition, `tpctl` makes it convenient to clone the repo into a directory for you to make changes. 

  With this command, `tpctl` opens a shell with a clone of th repo in the current directory.  You may makes changes to that clone as you see fit.  When you exit the shell, `tpctl` will commit those changes (with your permission) and push them to GitHub.

  ```bash
  tpctl edit_repo
  ```
 
* regenerate client certs for Helm to access Tiller

  If you are managing multiple Kubernetes clusters with a TLS-enabled `tiller`, you must switch between TLS certificates.  You may use this command to change to or regenerate the TLS certificates in you `~/.helm` directory:

  ```bash
  tpctl regenerate_cert 
  ```

* edit your values.yaml file

  If you need to modify the configuration parameters in the `values.yaml` file, you may do so with standard Git commands to operate on your Git repo.  `tpctl` makes it even easier by checking out the Git repo on your behalf and opening the `vi` editor:

  ```bash
  tpctl edit_values
  ```

* copy S3 assets to new bucket

  If you are launching a new cluster, you must provide S3 assets for email verification.  You may copy the standard assets by using this command:

  ```bash
  tpctl copy_assets
  ```

* migrate secrets from legacy GitHub repo to AWS secrets manager
  
  If you are migrating from one of the Tidepool legacy environments, you may migrate the secrets that are used in one of those environments to AWS Secrets Manager and modify your configuration repo to access those secrets:

  ```bash
  tpctl migrate_secrets
  ```

* generate random secrets and persist into AWS secrets manager

  If you are creating a new environment, you can generate a new set of secrets and persist those secrets in AWS Secrets Manager and modify your configuration repot to access those secrets:

  ```bash
  tpctl randomize_secrets
  ```

* read STDIN for plaintext K8s secrets

  If you have secrets to persist and use in your cluster, such as 
  those provided by a third party vendor, you may upload those secrets to AWS Secrets Manager and update your config repo to access those secrets by providing those secrets (as *plaintext* Kubernetes secrets) via the standard input to `tpctl`:

  ```bash
  tpctl upsert_plaintext_secrets
  ```

* add system:master USERS to K8s cluster

  If you have additional `system:master` users to add to your cluster, you may add them to your `values.yaml` file and run this command to install them in your cluster:

  ```bash
  tpctl install_users
  ```

* copy deploy key from Flux to GitHub config repo

  If you delete and reinstall Flux manually, it will create a new public key that you must provide to your GitHub repo in order to authenticate 
  Flux and authorize it to modify the repo.  You do that with:

  ```bash
  tpctl deploy_key
  ``` 

* initiate deletion of the AWS EKS cluster

  If you wish to delete a AWS EKS cluster that you created with `tpctl`, you may do so with:

  ```bash
  tpctl delete_cluster
  ```

  Note that this only starts the process.  The command returns *before* the process has completed.

* await completion of deletion of the AWS EKS cluster

  To await the completion of the deletion of an AWS EKS cluster, you may do this:

  ```bash
  tpctl await_deletion
  ```

* copy the KUBECONFIG into the local $KUBECONFIG file

  If you need to regenerate your local ~/.kube/config, you add the credentials of your cluster with:

  ```bash
  tpctl merge_kubeconfig
  ```

* open the Gloo dashboard

  We use the Gloo API Gateway.  If you would like to see the gateways, virtual services, and/or routes that are installed, you may use this command to open up a web page to the Gloo dashboard:

  ```bash
  tpctl gloo_dashboard
  ```

* open the service mesh dashboard

  If you have installed a service mesh, you may view a dashboard to monitor traffic in a web page:
  ```bash
  tpctl linkerd_dashboard
  ```

* create managed policies
  ```bash
  tpctl managed_policies
  ```

* show recent git diff

  If you would like to see the most recent changes to your config repo, you may use standard Git tools, or you may simply run:
  ```bash
  tpctl diff
  ```

## The values.yaml File

Your primary configuration file, `values.yaml`, contains all the information needed to create your Kubernetes cluster and its services.  Here is an annotated example:


### GitHub Config
This section establishes where the GitHub repo is located.  
```yaml
github:
  git: git@github.com:tidepool-org/cluster-test1
  https: https://github.com/tidepool-org/cluster-test1
```

### Logging Config
This section provides the default log level for the services that run in the
cluster.

```yaml
logLevel: debug                               # the default log level for all services
```

### Cluster Administration Configuration
This section provides an email address for the administrator of the cluster.
```yaml
email: derrick@tidepool.org                   # cluster admin email address
```

### AWS Configuration
This section provides the AWS account number and the IAM users who are to 
be granted `system:master` privileges on the cluster:

```yaml
aws:
  accountNumber: 118346523422                # AWS account number
  iamUsers:                                  # AWS IAM users who will be grants system:master privileges to the cluster
  - derrickburns-cli
  - lennartgoedhard-cli
  - benderr-cli
  - jamesraby-cli
  - haroldbernard-cli
```

### Kubectl Access Configuration
This secion provides the default location of the Kubernetes cluster configuration file.

```yaml
kubeconfig: "$HOME/.kube/config"             # place to put KUBECONFIG
```
### Cluster Provisioning Configuration
This sections provides a description of the AWS cluster itself, including its
name, region, size, networking config, and IAM policies.
```yaml

cluster:
  metadata:
    name: test1                              # name of the cluster
    region: us-west-2                        # AWS region to host the cluster
  cloudWatch:                                # AWS cloudwatch configuration
    clusterLogging:                          
      enableTypes:                           # Types of log messages to persist to CloudWatch
      - authenticator
      - api
      - controllerManager
      - scheduler
  vpc:                                       # Amazon VPC configuration
    cidr: "10.47.0.0/16"                     # CIDR of AWS VPC
  nodeGroups: 
  - instanceType: "m5.large"                 # AWS instance type for workers 
    desiredCapacity: 4                       # initial capacity of auto scaling group of workers
    minSize: 1                               # minimum size of auto scaling group of workers
    maxSize: 10                              # maximum size of auto scaling group of workers
    name: ng
    iam:                                     # AWS IAM policies to attach to the nodes in the cluster
      attachPolicyARNs:
      - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
      - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
      - arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess
      withAddonPolicies:
        autoScaler: true
        certManager: true
        externalDNS: true
```

### Optional Service Configuration

There are a number of services that can be installed by `tpctl` to run in your
Kubernetes cluster.   This section allows you to select the services
that you want to enable:
```yaml

pkgs:
  amazon-cloudwatch:                         # AWS CloudWatch logging
    enabled: true
  external-dns:                              # External DNS maintains DNS aliases to Amazon ELBs
    enabled: true
  gloo:                                      # Gloo provides the API Gateway 
    enabled: true
  gloo-crds:                                 # Gloo CRDs define the Custom Resource Definitions
    enabled: true
  prometheus-operator:                       # Prometheus Operator creates Prometheus instances
    enabled: true
  certmanager:                               # Certmanager issues TLS certificates
    enabled: true
  cluster-autoscaler:                        # Cluster autoscaler scales the nodes in the cluster as needed
    enabled: true
  external-secrets:                          # External secrets loads persisted secrets from AWS Secrets Manager
    enabled: true
  reloader:                                  # Reloader restarts services on secrets/configmap changes
    enabled: true
  datadog:                                   # Datadog send telemetry to the hosted Datadog service
    enabled: false
  flux:                                      # Flux provides GitOps
    enabled: true
  fluxcloud:                                 # Fluxcloud sends GitOps notifications to Slack
    enabled: false
    username: "derrickburns"                 
    secret: slack                            # Name of secret in which Slack webhook URL is provided
    #channel: foo                            # Slack channel on which to post notifications
  metrics-server:                            # Metrics server collects Node level metrics and sends to Prometheus
    enabled: true
  sumologic:                                 # Sumologic collects metrics and logs and sents to the hosted service
    enabled: false
  thanos:                                    # Thanos aggregates telemetry from all Tidepool clusters
    enabled: true
    bucket: tidepool-thanos                  # Writable S3 bucket in which to aggregate multi-cluster telemetry data
    secret: thanos-objstore-config           # Name of Kubernetes secret in which Thanos config is stored.
```

### Tidepool Environment Configuration
The last section allows you to configure the Tidepool environments that you run in your cluster.


```yaml
environments:
  qa2:
    mongodb:
      enabled: true                          # Whether to use an embedded mongodb 
    tidepool:
      source: stg                            # Where to get initial secrets from
      enabled: true
      hpa:                                   # Whether to implement horizontal pod scalers for each service
        enabled: true
      nosqlclient:                           # Whether to deploy a nosqlclient to query Mongo data
        enabled: true
      mongodb:                  
        enabled: true
      gitops:                                
        branch: develop                      # Which branch to use for automatic image updates
      buckets: {}                            # Which S3 buckets to store/retrieve data to/from
        #data: tidepool-test-qa2-data        # Name of the writable S3 bucket to store document data to
        #asset: tidepool-test-qa2-asset      # Name of the readable S3 bucker form which to get email assets
      certificate:
        secret: tls                          # Name of the K8s secret to store the TLS certificate for the hosts served
        issuer: letsencrypt-staging          # Name of the Certificate Issuer to use
      gateway:
        default:                             # Default protocol to use for communication for email verification
          protocol: http                
        http:
          enabled: true                      # Whether to offer HTTP access
          dnsNames:                          # DNS Names of the HTTP hosts to serve
          - localhost                       
        https:
          enabled: false                     # Whether to offer HTTPS access
          dnsNames:                          # DNS Names of the HTTPS hosts to serve
          - qa2.tidepool.org
```
