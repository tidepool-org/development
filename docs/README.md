
# Introduction

This document describes how to install the Tidepool web service on an Amazon hosted Kubernetes platform.  

With suitable modification, one may install the service on another Kubernetes platform.  However, that is not contained in the scope of this document.

## TL;DR
These compressed instructions presume that you can figure out how to edit the `values.yaml` file. :)

  ```bash
  git clone git@github.com:tidepool-org/development.git
  export DEV_REPO=$(pwd)/development
  cd ${DEV_REPO}
  git checkout k8s
  export PATH=$PATH:${DEV_REPO}/bin

  cp $DEV_REPO/charts/configurator/values.yaml ..
  export VALUES_FILE=$(realpath ../values.yaml)
  $EDITOR ${VALUES_FILE}

  install_tools
  create_config_repo
  export_secrets
  create_s3_assets
  launch_cluster 
  export KUBECONFIG=$(realpath ./kubeconfig.yaml)
  ```

## Prerequisites

In order to sail through this installation, we presume the following:
* you are familiar with [TCP/IP networking concepts](https://en.wikipedia.org/wiki/Internet_protocol_suite);
* you are familiar with [DNS concepts](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/reviewing-dns-concepts), including aliases;
* you are comfortable with the [Bash shell](https://www.gnu.org/software/bash/);
* you are familiar with [Git](https://git-scm.com/);
* you are familiar with [AWS services](https://aws.amazon.com/) and how to use [S3](https://aws.amazon.com/s3/) and [IAM](https://aws.amazon.com/iam/);
* you are using a MacOS system to perform the installation and specifically [brew](https://brew.sh/);
* you are familiar with core [Kubernetes](https://kubernetes.io/) concepts; and,
* you are familiar with [Helm, the Kubernetes package manager](https://helm.sh/).

In addition, you should make yourself familiar with the base [Tidepool Helm Chart](https://github.com/tidepool-org/development/tree/k8s/charts/tidepool/0.1.6).
This is suitable for installing Tidepool on a local development environment.

## Ancillary Services

To run a publicly accessible, HIPAA compliant, scalable web service or, perhaps several, requires a number of ancillary services. You need:

* to publish DNS aliases;
* to acquire and publish TLS certificates (for web site authentication);
* to access cloud object storage;
* to access cloud hosted Mongo storage;
* to create and send signup emails (for user authentication);
* to track access (for HIPAA compliance);
* to monitor service performance metrics; and,
* to monitor cluster and node availability.

In addition, you may want:
* to notify internal users of cluster activity;
* to access third party provided diabetes data;
* to aggregate logs;
* to aggregate usage metrics; and,
* to integrate with mailing list providers. 

This document describes how to deploy Tidepool with all of these services and options.

This guide stands on the shoulders of giants, including excellent fee-based third party services and open-source software. 

### Fee-Based Service Providers

At Tidepool, we have chosen these fee-based services:

* [AWS](https://aws.amazon.com/)
  - object storage (S3)
  - Kubernetes management (EKS)
  - DNS services (Route53)
  - email services (SES)
  - secrets management
  - identity management (IAM)
  - compute (EC2)
  - cloud formation
* [Mailchimp](https://mailchimp.com/) - mailing lists
* [Slack](https://slack.com/) - notifications
* [Dexcom](https://developer.dexcom.com/) - diabetes user data
* [KissMetrics](https://www.kissmetricshq.com/) - usage metrics data
* [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) - Mongo database
* [Datadog](https://www.datadoghq.com/) - cluster and node availability monitoring
* [Sumologic](https://www.sumologic.com/lp/log-management/) - log aggregation
* [GitHub](https://github.com/) - version control

This document does not cover how to contract with service providers, nor does it detail the interfaces with these services. Rather, if your services are provided by these vendors, these instructions will walk you through how to set up one or more
Tidepool environments using these services.

### Open Source Kubernetes Services

In addition to the third-party hosted services, Tidepool utilizes a number of excellent open source packages that expose Kubernetes services:

* [Prometheus](https://prometheus.io/) - telemetry
* [Prometheus Operator](https://github.com/coreos/prometheus-operator) - Prometheus manager
* [Thanos](https://thanos.io/) (self-hosted) - service performance monitoring
* [Gloo](https://gloo.solo.io/) - API Gateway
* [Kubernetes External Secrets](https://github.com/godaddy/kubernetes-external-secrets) - secrets loader
* [Fluxcloud](https://github.com/justinbarrick/fluxcloud) - GitOps notifications
* [External-DNS](https://github.com/kubernetes-incubator/external-dns) - automated DNS updates
* [NoSQLClient](https://www.nosqlclient.com/) - Web based mongo data viewer
* [Certmanager](https://github.com/jetstack/cert-manager) - TLS certificate manager
* [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) - Cluster node autoscaler
* [Metrics Server](https://github.com/kubernetes-incubator/metrics-server) - cluster metrics server
* [Reloader](https://github.com/stakater/Reloader) - pod restarter on secret change

## GitOps

The next step in the evolution of DevOps with Kubernetes is, arguably, [GitOps](https://www.weave.works/technologies/gitops/).  

From WeaveWorks:

>GitOps is a way to do Kubernetes cluster management and application delivery.  It works by using Git as a single source of truth for declarative infrastructure and applications. With Git at the center of your delivery pipelines, developers can make pull requests to accelerate and simplify application deployments and operations tasks to Kubernetes.

![GitOps Flow](https://images.contentstack.io/v3/assets/blt300387d93dabf50e/blt15812c9fe056ba3b/5ce4448f32fd88a3767ee9a3/download "GitOps Flow")

We embrace the GitOps approach. We use the [Flux](https://flux-cd.readthedocs.io/en/latest/) operator to manage all the services on a cluster.  

Flux watches a Git repo for declarations of what should be running in your cluster and adjusts your cluster accordingly by adding or removing resources.  Flux eliminates the need to load resources manually (except bootstrapping the Flux service itself and a few secrets).

In this guide, we instruct you on how to create the files that you store into your `Git Config Repo`.  These files are called Kubernetes `manifests` or `resource files` or `custom resource descriptors` (CRDS).  In total, you will prepare:

* two Kubernetes manifests to describe the configuration of the services shared by all your Tidepool environments;
* three Kubernetes manifests to describe the configuration of each Tidepool environment;
* one manifest for each set of Kubernetes secrets (these may be checked into your Git repo if it is private) 

Together, these files describe the configuration of your Kubernetes cluster.  

If you need to make changes to the cluster, you change these files and store them in your Git config repo.  Flux will see the changes and make the changes.

# Installation Instructions

To get your Tidepool services up and running in a new Amazon EKS cluster, you must
* create a cluster;
* create a GitHub config repo with details on how to configure the services you run in your cluster; and,
* install the Flux GitOps operator to configure your cluster according to the contents of the repo.

Following are instructions on how to do just that!

## Create Secret Manifests

To connect with the third party service providers, you will need certain information.

The sensitive (secret) information will be stored in K8s secrets during operation of the cluster, and persisted outside the cluster.  The non-secret information can be checked into your configuration repo.  Below, we indicate exactly how to provide this information. 

For each secret, you will create a Kubernetes manifest file, named for the secret.  Each file will have the form:

  ```yaml
  apiVersion: v1
  data:
    ${SECRET_KEY_1}: ${SECRET_VALUE_1}
    ...
    ${SECRET_KEY_N}: ${SECRET_VALUE_N}
  kind: Secret
  metadata:
    name: ${SECRET_NAME}
    namespace: ${SECRET_NAMESPACE}
  type: Opaque
  ```
  
  where:

  - `${SECRET_KEY_K}` is name of the secret key
  - `${SECRET_VALUE_K}` is the value of the secret associated with key `${SECRET_KEY_K}`
  - `${SECRET_NAME}` is the name of the secret
  - `${SECRET_NAMESPACE}` is the Kubernetes namespace in which the secret is stored. 
     This will be the same as the Tidepool environment for environment specific secrets.  Otherwise it will be the same as the secret name.  

Name each secret file `${SECRET-NAMESPACE}-${SECRET}-secret.yaml`. 
  
Place all secrets in the directory `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/secrets`.  
  
This directory will NOT be uploaded to the config because of the presene of the `.gitignore` file in `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux` that contains the line `secrets`. This will instruct Git to ignore files and directories named `secrets`.

### Secrets for Shared Services 

Some services are shared by all Tidepool environments in your cluster.  We configure their secrets in a namespace specific to the service.

The `${SECRET_NAME}` is the same as the name of the service, but translated to lower case only.  So the `${SECRET_NAME}` for the Datadog service
is `datadog`.  

The `${SECRET_NAMESPACE}` is the same as the `S{SECRET_NAME}`. 

#### Datadog [Optional]

We use Datadog for cluster level monitoring.  You will need an [Datadog](https://docs.datadoghq.com/account_management/api-app-keys/#client-tokens) API key (`api-key`) and an application key (`app-key`). 

From Datadog:

>API keys are unique to your organization. An API key is required by the Datadog Agent to submit metrics and events to Datadog.

>Application keys, in conjunction with your org’s API key, give you full access to Datadog’s programmatic API. Application keys are associated with the user account that created them and must be named. The application key is used to log all requests made to the API.

You secret file must have the form:

  ```yaml
  apiVersion: v1
  data:
    api-key: ${api-key}
    app-key: ${app-key}
  kind: Secret
  metadata:
    name: datadog
    namespace: datadog
  type: Opaque
  ```

  where:

  - `${api-key}` is the API key
  - `${app-key}` is the application key

####  Sumologic [Optional]

We use [Sumologic](https://help.sumologic.com/APIs) to aggregate some logging information. You will need the collector URL (`collector-url`) value from Sumologic.  

  ```yaml
  apiVersion: v1
  data:
    collector-url: ${collector-url}
  kind: Secret
  metadata:
    name: sumologic
    namespace: sumologic
  type: Opaque
  ```
  
  where:

  - `${collector-url}` is the collector URL

#### Slack Channel Notifier [Optional]

In order to provide notifications of changes to your cluster, we provision an application called `fluxcloud` that listens to changes from the `flux` service and communicates those changes to a Slack channel.

To use this service, you must first create a Slack App.  When you create the app, you will be provided a webhook that `fluxcloud` can use to post messages to a Slack channel.

##### Create Slack App

Navigate to the [Slack api console](https://api.slack.com/apps?new_app=1) to and create a Slack application.  Name the Slack channel `#flux-${CLUSTER_NAME}`.
Retrieve the WebHook URL.  Assign it to an environment variable `SLACK_URL`, e.g.:

  ```bash
  $ export SLACK_URL="https://hooks.slack.com/services/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"
  ```

We use Slack for notifications of changes in your cluster.  You will need the webhook url (`url`) value from the Slack App that you create:

```yaml
apiVersion: v1
data:
  url: ${SLACK_URL}
kind: Secret
metadata:
  name: slack
  namespace: flux
type: Opaque
```

where:

- `${SLACK_URL}` is the webhook url that you got from the Slack App when you created it

Finally, set the environment variable `$FLUXCLOUD` to `fluxcloud`:

  ```bash
  $ export FLUXCLOUD=fluxcloud
  ```

We use this variable later to configure Flux to provide updates to the Fluxcloud application, when sends those updates to your Slack channel.

### Secrets For Each Tidepool Environment

Some services are configured separately for each Tidepool environment. 

#### Mongo

Your Tidepool environments persists user data in MongoDB. We recommend that you host your Mongo storage outside of Kubernetes.  To connect to it, you will need the components of the Mongo connection string. Place them components in a `Secret` in the namepsace of your `${ENVIRONMENT}`:

  ```yaml
  apiVersion: v1
  data:
    scheme: ${scheme}
    addresses: ${addresses}
    username: ${username}
    password: ${password}
    ssl: ${ssl}
    optParams: ${optParams}
  kind: Secret
  metadata:
    name: mongo
    namespace: ${ENVIRONMENT}
  type: Opaque
  ```

  where:

  - `${scheme}` is the Mongo scheme used, either `mongodb` or `mongodb-srv`
  - `${addresses}` is a comma-separated list of Mongo host[:port]
  - `${username}` is the Mongo username in the Mongo database used to authenticate the connection
  - `${password}` is the Mongo password associated with Mongo username used for authentication
  - `${ssl}` indicates whether to use SSL 
  - `${optParams}` are the additional URL parameters needed for the connection (e.g replica set info)

####  KissMetrics [Optional]

Tidepool collects data for user analytics using [Kissmetrics](http://support.kissmetrics.com/article/show/23938-api-specifications). We use the `v2` version of the Kissmetrics API.  This version requires that an API key be passed on each request.  

In addition, Tidepool allows logging of events that are not associated with a specific user.  This is indicated by passing a session token in the HTTP header of a request.

We publish metrics specificly for UCSF clinicians using a different Kissmetrics API key.

The list of users tracked is provided via a white list that you pass.

You store these secrets in the `kissmetrics` `Secret` in the namespace `${ENVIRONMENT}`:

  ```yaml
  apiVersion: v1
  data:
    KissmetricsAPIKey: ${KissmetricsAPIKey}
    KissmetricsToken: ${KissmetricsToken}
    UCSFKissmetricsAPIKey: ${UCSFKissmetricsAPIKey}
    UCSFWhitelist: ${UCSFWhitelist}
  kind: Secret
  metadata:
    name: kissmetrics
    namespace: ${ENVIRONMENT}
  type: Opaque
  ```

  where:

  - `${KissmetricsAPIKey}` is the API key from KissMetrics
  - `${KissmetricsToken}` is the session token that you will use in the HTTP header
  - `${UCSFKissmetricsAPIKey}` is the API key from KissMetrics for UCSF
  - `${UCSFWhitelist}` is the list of users tracked


#### Dexcom [Optional]

Many Tidepool users use Dexcom devices and already upload their data to Dexcom.  Internally, Tidepool has a service that polls Dexcom for new data and makes it available for visualization in the Tidepool Web service. 

From [Dexcom](https://developer.dexcom.com/authentication):

>The Dexcom API uses OAuth 2.0 to enable client applications to make requests on behalf of users. Users can authenticate themselves with Dexcom and do not enter their login information into the client application directly. Users also authorize a specific scope of data that may be transferred from Dexcom to the client application and can revoke the access at any time.

You store this data in the `dexcom-api` `Secret` within the `${ENVIRONMENT}` namespace:

  ```yaml
  apiVersion: v1
  data:
    ClientId: ${ClientId}
    ClientSecret: ${ClientSecret}
    StateSalt: ${StateSalt}
  kind: Secret
  metadata:
    name: dexcom-api
    namespace: ${ENVIRONMENT}
  type: Opaque
  ```

  where:

  - `${ClientId}` is the unique ID for the client application
  - `${ClientSecret}` is the secret for the client application
  - `${StateSalt}` is the state salt

#### Mailchimp [Optional]

We use Mailchimp for mailing list management.  You will need a [Mailchimp API key](https://mailchimp.com/help/about-api-keys/), a URL, and mailing list parameters.  Which technically the latter are not
sensitive information, for convenience we store them with our Secret information.

You provide the information in the `mailchimp` `Secret` within the `${ENVIRONMENT}` namespace: 

  ```yaml
  apiVersion: v1
  data:
    MailchimpApiKey: ${MailchimpApiKey}
    MailchimpURL: ${MailchimpURL}
    MailchimpPersonalLists: ${MailchimpPersonalLists}
    MailchimpClinicLists: ${MailchimpClinicLists}
  kind: Secret
  metadata:
    name: mailchimp
    namespace: ${ENVIRONMENT}
  type: Opaque
  ```

  where:
  
  -  `${MailchimpApiKey}` is the value of the Mailchimp API Key
  -  `${MailchimpURL}` is the URL to the Mailchimp service
  -  `${MailchimpPersonalLists}` is the mailing list info to individuals
  -  `${MailchimpClinicLists}` is the mailing list info for clinics 

## Export Values

The instructions rely on the availability of certain environment variables. Please export these.

1. Your Cluster Name

   This name must be unique across all of your Kubernetes clusters.
   ```bash
   $ export CLUSTER_NAME=my-cluster-name
   ```

1. Your AWS Region

   This is the [AWS region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions) in which you will deploy your Kubernetes cluster.

   ```bash
   $ export AWS_REGION=us-west-2
   ```

Additionally, if you are using GitHub as the Git server for your config repo, you may use a tools that we provide to perform operations on your GitHub repo.  We will need access to your GitHub credentials:
  
1. Place a [Git access token](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line) in `~/.secrets/github_access_token`.

## Clone Repos

We will use tools and data already stored in GitHub to help you install your cluster.

Please clone these repos.

1. Clone the Development repo

    We will use some simple tools available in the `bin` directory of the `git@github.com:tidepool-org/development.git`.  So, clone that repo and and place the `bin` directory into your path.

    ```bash
    $ git clone git@github.com:tidepool-org/development.git
    $ export DEV_REPO=$(pwd)/development
    $ cd ${DEV_REPO}
    $ git checkout k8s
    $ export PATH=$PATH:${DEV_REPO}/bin
    ```

    We will not modify this repo. We simply need a local copy of it to perform the installation.

1. Clone this Config repo.  

   We will start with this repo and modify it to be the configuration of your cluster. 

   When we are done making adjustments, push the changes to GitHub. By convention, we name the Git Config repo `cluster-${CLUSTER_NAME}`. 

    ```bash
    $ git clone git@github.com:tidepool-org/cluster-development.git
    $ export CONFIG_REPO=$(pwd)/cluster-development
    ```
    
1. Rename the cluster directory to match your chosen name and change to that directory:

    ```bash
    $ mv ${CONFIG_REPO}/clusters/development ${CONFIG_REPO}/clusters/${CLUSTER_NAME}
    $ cd ${CONFIG_REPO}/clusters/${CLUSTER_NAME}
    ```

## Install Dependencies

There are a number of client-side tools that you will need in the installation process.  

If you are on a Mac, you can use the `homebrew` tool to install all the packages and their dependencies.

For your convenience, we have created a `Brewfile` with the needed packages.  Install as follows:

   ```bash
   $ brew bundle --file=${DEV_REPO}/Brewfile
   ```
You may want to copy the Brewfile to the standard location in your home directory to expedite future updates:

   ```bash
   $ cp ${DEV_REPO}/Brewfile ~/.Brewfile
   ```
See the instructions for [brew bundle](https://github.com/Homebrew/homebrew-bundle).

This will install:
1. [awscli](https://aws.amazon.com/cli/) 
1. [helm](https://helm.sh/) 
1. [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) 
1. [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
1. [jq](https://stedolan.github.io/jq/)
1. [yq](https://github.com/mikefarah/yq)
1. [k9s](https://k9ss.io/)
1. [fluxctl](https://www.weave.works/blog/install-fluxctl-and-manage-your-deployments-easily)
1. [docker](https://gist.github.com/rstacruz/297fc799f094f55d062b982f7dac9e41)
1. [python3](https://docs.python.org/3/)

Install some python3 packages:

   ```bash
   $ pip3 install boto3 --user
   ```

You may also want to install some supplemental packages.  However,
they are not required for the installation of the K8s cluster and Tidepool services.

   ```bash
   $ brew bundle --file=${DEV_REPO}/Brewfile-supplemental
   ```

## Persist Your Secrets

Most of your Kubernetes services must be provided secrets, including API Keys for external services, encryption keys for data, etc.

In an operational Kubernetes cluster, secrets are stored in a persistent store called `etcd`.  You install secrets in `etcd` using the
Kubernetes `Secret` resource.  

But where do you store your secrets *before* your cluster is operational?  And, if you need to take down your cluster and create a new one,
where do you persist your secrets.  

We store secrets in Amazon Secrets Manager.  We provide a service called `external-secrets` that loads your secrets
securely and creates Kubernetes Secrets resources in `etcd`.  If the secrets are changed, the service will eventually see the change and 
update the Kubernetes secret.

AWS Secrets Manager is a key-value store. By convention, our AWS Secrets Manager `keys` have the form `${CLUSTER_NAME}/${ENVIRONMENT}/${SECRET_NAME}`.
The values in our AWS Secrets are json objects, where each property is a `${SECRET_NAME}` and each value is a secret value. 

You provide the mapping between secrets stored in AWS Secrets Manager and secrets stored in Kubernetes with a Kubernetes Custom Resource called `ExternalSecret` that has the form:

  ```yaml
  apiVersion: kubernetes-client.io/v1
  kind: ExternalSecret
  metadata:
    name: ${SECRET_NAME}
    namespace: ${ENVIRONMENT}
  secretDescriptor:
    backendType: secretsManager
    data:
    - key: ${CLUSTER_NAME}/${ENVIRONMENT}/${SECRET_NAME}
      name: ${SECRET_KEY_1}
      property: ${SECRET_KEY_1}
    ...
    - key: ${CLUSTER_NAME}/${ENVIRONMENT}/${SECRET_NAME}
      name: ${SECRET_KEY_N}
      property: ${SECRET_KEY_N}
  ```

### Uploading Secrets To AWS Secrets Manager

To support your use of `ExternalSecrets`, we provide a helper function called `external_secret` that:

1. loads secrets to AWS Secrets Manager and 
2. generates `ExternalSecret` manifests, following naming conventions suggested in the above example.  

Above you created your `Secret` manifests. We provide a helper function called `external_secrets` do
help you upload them to AWS Secrets Manager using the aforementioned naming conventions: 

  ```bash
  $ external_secrets ${FILENAME} ${OPERATION} ${CLUSTER_NAME} ${ENCODING}
  ```

  where:

  - `${FILENAME}` is a sequence of YAML `Secret` manifests separated by `---`
  - `${OPERATION}` is the operation to perform on the external secret, either  `create`, `update` or `delete`
  - `${CLUSTER_NAME}` is the name of the cluster
  - `${ENCODING}` indicates whether the values in the `Secret` manifests are base64 `encoded` or in `plaintext`

Now, upload all the secrets that you created above:

  ```bash
  $ for file in ${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/secrets/*
    do
      external_secrets $file create ${CLUSTER_NAME} plaintext
    done
  ```
If you later need to update the secret, provide the `update` operation instead of the `create` operation to `external_secrets`.

#### Confirm Secrets Are Persisted

You may confirm that the secrets were created by listing the secrets in the AWS Secrets Manager:

   ```bash
   $ aws secretsmanager list-secrets
   ```

You may view a secret stored in AWS Secrets Manager using the helper `get_external_secret`:

  ```bash
  $ get_external_secret ${SECRET} ${NAMESPACE} ${CLUSTER_NAME}
  ```

  where
  - `${SECRET}` is the name of the secret
  - `${NAMESPACE}` is either a) for shared services, the name of the shared service or b) for per environment services, the name of the ${ENVIRONMENT}
  - `${CLUSTER_NAME}` is the name of the cluster

## Create Your Amazon EKS Cluster

To create an Amazon EKS cluster, you will need an AWS account and proper authority (IAM policy) to allow you to do so.

### Prepare Cluster Configuration File

We use the `eksctl` cli tool to create EKS clusters. This tool has an option to provide a single cluster configuration file
to configure your cluster.  We use that approach.  In the file `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/config.yaml` we have a description of the desired cluster. Here is an example:
  
  ```yaml
  apiVersion: eksctl.io/v1alpha5
  kind: ClusterConfig
  
  metadata:
    name: development
    region: us-west-2
    version: "1.13"
  
  vpc:
    cidr: "10.49.0.0/16"
  
  nodeGroups:
    - name: ng-1
      instanceType: m5.large
      desiredCapacity: 3
      minSize: 1
      maxSize: 5
      labels:
        kiam-server: "false"
      tags:
        k8s.io/cluster-autoscaler/enabled: "true"
        k8s.io/cluster-autoscaler/development: "true"
    - name: ng-kiam
      instanceType: t3.medium
      desiredCapacity: 1
      labels:
        kiam-server: "true"
      taints:
        kiam-server: "false:NoExecute"
  ```

Edit this file before creating a cluster.

  ```bash
  $ ${EDITOR} ${CONFIG_REPO}/clusters/${CLUSTER_NAME}/config.yaml
  ```

#### Cluster Name

At minimum, you must change:
1. the value of the field `metadata.name` to be the value of `${CLUSTER_NAME}` and 
1. the tag `k8s.io/cluster-autoscaler/development` to `k8s.io/cluster-autoscaler/${CLUSTER_NAME}`.

The former indicates to the `eksctl` how to name cluster resources in CloudFormation.

The latter indicates to the cluster auto-scaler which nodes to consider when scaling this cluster.  See details below.

#### CIDR

Your cluster will exist in an Amazon VPC.  The Amazon Container Networking Interface will assign IP addresses from a CIDR range that you provide.  Generally, the range does not matter, as long as it is a legal range for local addresses and it is large enough (/16) to carve our three subnets.

However, you may want to route traffic from your VPC directly to another VPC.  You would find
yourself in this situation if you intend to host your MongoDB in another VPC.  In order to route to another VPC, the addresses ranges of the VPCs must not overlap.  When you create your K8s cluster, you have the option of providing a CIDR range for the VPC.  

If you plan to host your MongoDB in Mongo AtlasDB, then you may find that the CIDR chosen by default by AtlasDB is in the CIDR `192.68.0.0/16`.  Therefore, you will want to avoid selecting a CIDR in that range.

At the time of this writing, Tidepool hosts its own Mongo servers in 4 different VPCs. Those VPCs have the following CIDRs:

| Env | CIDR         |
|-----|--------------|
| prd | 10.16.0.0/16 |
| stg | 10.32.0.0/16 |
| dev | 10.48.0.0/16 |
| int | 10.64.0.0/16 |

If you connect to one of these environments for you MongoDB, you must avoid conflicting with it.  

#### Create Cluster
After you have modified the `config.yaml` file, you are ready to create your K8s cluster.

  ```bash
  $ create_cluster ${CONFIG_FILE:-config.yaml} ${KUBECONFIG:-kubeconfig.yaml}
  ```
  > FIXME: We need to document the required IAM Policy to be able to run `create_cluster`.
  > FIXME: We may need some instructions (could be in a separate document), about what to do when `create_cluster` fails. I had to go and manually delete my CF Stack to try again. I got the policy instructions from https://github.com/weaveworks/eksctl/issues/204

You will see immediately see output similar to:

  ```
  [ℹ]  using region us-west-2
  [ℹ]  setting availability zones to [us-west-2b us-west-2c us-west-2d]
  [ℹ]  subnets for us-west-2b - public:10.49.0.0/19 private:10.49.96.0/19
  [ℹ]  subnets for us-west-2c - public:10.49.32.0/19 private:10.49.128.0/19
  [ℹ]  subnets for us-west-2d - public:10.49.64.0/19 private:10.49.160.0/19
  [ℹ]  nodegroup "ng-1" will use "ami-089d3b6350c1769a6" [AmazonLinux2/1.13]
  [ℹ]  using SSH public key "/Users/derrickburns/.saws-tidepool-derrickburns.pub" as "eksctl-development-nodegroup-ng-1-5a:13:38:5e:a3:a6:20:54:78:52:90:65:02:da:38"
  [ℹ]  nodegroup "ng-kiam" will use "ami-089d3b6350c1769a6" [AmazonLinux2/1.13]
  [ℹ]  using SSH public key "/Users/derrickburns/.saws-tidepool-derrickburns.pub" as "eksctl-development-nodegroup-ng-kiam-5a:13:38:5e:a3:a6:20:54:78:52:90:65:02:9a:38"
  [ℹ]  creating EKS cluster "development" in "us-west-2" region
  [ℹ]  2 nodegroups (ng-1, ng-kiam) were included
  [ℹ]  will create a CloudFormation stack for cluster itself and 2 nodegrostack(s)
  [ℹ]  if you encounter any issues, check CloudFormation console or try 'ekscutils describe-stacks --region=us-west-2 --name=development'
  [ℹ]  2 sequential tasks: { create cluster control plane "development",parallel sub-tasks: { create nodegroup "ng-1", create nodegro"ng-kiam" } }
  [ℹ]  building cluster stack "eksctl-development-cluster"
  [ℹ]  deploying stack "eksctl-development-cluster"
  ```

  Then, there will be a 5-10 `FIXME: (seconds|minutes)` waiting period for AWS to spin up the EKS cluster:

  ```
  [ℹ]  building nodegroup stack "eksctl-development-nodegroup-ng-1"
  [ℹ]  building nodegroup stack "eksctl-development-nodegroup-ng-kiam"
  [ℹ]  --nodes-min=3 was set automatically for nodegroup ng-1
  [ℹ]  --nodes-max=3 was set automatically for nodegroup ng-1
  [ℹ]  deploying stack "eksctl-development-nodegroup-ng-1"
  [ℹ]  deploying stack "eksctl-development-nodegroup-ng-kiam"
  ```

  Finally,

  ```
  [✔]  all EKS cluster resource for "development" had been created
  [✔]  saved kubeconfig as "kubeconfig.yaml"
  [ℹ]  adding role "arn:aws:iam::${AWS_ACCOUNT}:role/eksctl-development-nodegroup-ng-1-NodeInstanceRole-1BSR58IZJYPTN" to auth ConfigMap
  [ℹ]  nodegroup "ng-1" has 0 node(s)
  [ℹ]  waiting for at least 3 node(s) to become ready in "ng-1"
  [ℹ]  nodegroup "ng-1" has 3 node(s)
  [ℹ]  node "ip-10-49-21-209.us-west-2.compute.internal" is ready
  [ℹ]  node "ip-10-49-48-225.us-west-2.compute.internal" is ready
  [ℹ]  node "ip-10-49-85-86.us-west-2.compute.internal" is ready
  [ℹ]  adding role "arn:aws:iam::${AWS_ACCOUNT}:role/eksctl-development-nodegroup-ng-k-NodeInstanceRole-1X6ALBSVX3O5T" to auth ConfigMap
  [ℹ]  nodegroup "ng-kiam" has 0 node(s)
  [ℹ]  waiting for at least 1 node(s) to become ready in "ng-kiam"
  [ℹ]  nodegroup "ng-kiam" has 1 node(s)
  [ℹ]  node "ip-10-49-7-216.us-west-2.compute.internal" is ready
  [ℹ]  kubectl command should work with "kubeconfig.yaml", try 'kubectl      --kubeconfig=kubeconfig.yaml get nodes'
  [✔]  EKS cluster "development" in "us-west-2" region is ready
  ```

#### Export KUBECONFIG

This will create a `kubeconfig.yaml` file. Set the `KUBECONFIG` environment value to the absolute path of that file:

  ```bash
  $ export KUBECONFIG=$(realpath ./kubeconfig.yaml)
  ```

Verify that you can communicate with the cluster by running:

  ```bash
  $ kubectl get all --all-namespaces
  ```
If you get an error, confirm that the value of `$KUBECONFIG` is correct.

#### AWS CloudFormation

Under the covers, `eksctl` uses Amazon CloudFormation to create resources in AWS.   Observe the mention of the stacks created:
   ```
   eksctl-${CLUSTER_NAME}-cluster
   eksctl-${CLUSTER_NAME}-nodegroup-ng-1
   eksctl-${CLUSTER_NAME}-nodegroup-ng-kiam
   ```
We reference these AWS CloudFormation resources later when we create additional IAM roles and policies.

### Create Kubernetes Users

When you create your cluster with `eksctl`, it will be fully manageable by IAM identity, the identity that created it.  This will be the role returned from:

  ```bash
  $ aws sts get-caller-identity
  ```

You may want to provide other members of your operations staff with Kubernetes identities and  `system:master` privileges.

Amazon EKS provides an integration between their identity management system (IAM) and the Kubernetes native identity system.  This allows one to associate a specific IAM user or role with a specific Kubernetes user.   This correspondence is communicated to Kubernetes via a ConfigMap called `aws-auth` in the `kube-system` namespace, along with the Kubernetes privileges for each user.

For your convenience, we provide a helper function  `authorize_users` to provide Kubernetes `system:master` privileges to your operations staff.  Simply run this tool with a list of IAM users and the helper will update the ConfigMap accordingly:

  ```bash
  $ authorize_users "${USERS}" ${CONFIG_FILE:-config.yaml}
  ```

  where 
       
  - `${USERS}` is a whitespace-separated list of the AWS IAM users whom you would like to provide Kubernetes `system:master` access to the cluster (in addition to the AWS user that creates the cluster).  By default, this value will be replaced with the CLI IAM identities of the Tidepool Operations staff.

  - `${CONFIG_FILE}` is the path to the config file

  This helper uses the environment variable `${AWS_ACCOUNT}` if it is defined.  In this way you can allow users from any AWS account access 
  to access your cluster with full privileges if you desire.

  If the environment variable is not set, then the helper will identify your AWS account number from the Kubernetes cluster.

  You will see output similar to:

  ```
  [ℹ]  adding role "arn:aws:iam::${AWS_ACCOUNT}:user/lennartgoedhart-cli" to auth ConfigMap
  [ℹ]  adding role "arn:aws:iam::${AWS_ACCOUNT}:user/benderr-cli" to auth ConfigMap
  [ℹ]  adding role "arn:aws:iam::${AWS_ACCOUNT}:user/derrick-cli" to auth ConfigMap
  [ℹ]  adding role "arn:aws:iam::${AWS_ACCOUNT}:user/mikeallgeier-cli" to auth ConfigMap
  ```

At the completion, verify the list of users:

  ```bash
  $ kubectl describe -n kube-system configmap aws-auth
  ```

  You should see something like:

  ```
  Name:         aws-auth
  Namespace:    kube-system
  Labels:       <none>
  Annotations:  <none>
  
  Data
  ====
  mapRoles:
  ----
  - groups:
    - system:bootstrappers
    - system:nodes
    rolearn: arn:aws:iam::${AWS_ACCOUNT}:roleksctl-development-nodegroup-ng-1-NodeInstanceRole-17TEEDTV6M1CZ
    username: system:node:{{EC2PrivateDNSName}}
  - groups:
    - system:bootstrappers
    - system:nodes
    rolearn: arn:aws:iam::${AWS_ACCOUNT}:roleksctl-development-nodegroup-ng-k-NodeInstanceRole-1H4ND0VVJHXBN
    username: system:node:{{EC2PrivateDNSName}}
  - groups:
    - system:masters
    rolearn: arn:aws:iam::${AWS_ACCOUNT}:user/lennartgoedhart-cli
    username: lennartgoedhart-cli
  - groups:
    - system:masters
    rolearn: arn:aws:iam::${AWS_ACCOUNT}:user/benderr-cli
    username: benderr-cli
  - groups:
    - system:masters
    rolearn: arn:aws:iam::${AWS_ACCOUNT}:user/derrick-cli
    username: derrick-cli
  - groups:
    - system:masters
    rolearn: arn:aws:iam::${AWS_ACCOUNT}:user/mikeallgeier-cli
    username: mikeallgeier-cli
  
  Events:  <none>
  ```

### Deploy Tiller, the Helm server.

The helm package manager allows you to install software to your cluster.  Helm version 2.X consists of a client side CLI and a server side service. You must install the server component, called Tiller.

Use the helper function `install_tiller`:

  ```bash
  $ install_tiller
  ```

You should see output similar to:

   ```
   serviceaccount/tiller created
   clusterrolebinding.rbac.authorization.k8s.io/tiller-cluster-rule created 
   
   $HELM_HOME has been configured at /Users/derrickburns/.helm.
   
   Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.
   
   Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.

   To prevent this, run `helm init` with the --tiller-tls-verify flag. For more information on securing your installation see: https://docs.helm.sh/ using_helm/#securing-your-helm-installation
   ```

## Configure Shared Services

We use a number of open source Kubernetes services.  These services must be properly configured. In some cases, this configuration includes certain secrets that you must provide. In other cases, this configuration consists of values that you provide in a Kubernetes manifest file by way of Helm configuration values.

### Prepare Flux Manifests

In your cluster, you will run a number of Kubernetes services.  Some are services that are shared by all of your Tidepool environments.  Others are configured specifically for each Tidepool environment.

We install these services via the `flux` GitOps operator.  `flux` runs in your cluster, constantly monitoring your Git Config repo for  changes (including addition, deletion, or modification)  of Kubernetes manifest files. When `flux` discovers a change, it attempts to modify the cluster configuration to match the new state.

Instead of invoking `helm` via the CLI, you provide a `HelmRelease` resource in your Config repo.  This is a resource specific to `flux`.  It directs `flux` to run helm with values provided in the manifest itself.  

There are two files that contain the configuration of these shared services:
`${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/shared-start-helmrelease.yaml` and `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/shared-helmrelease.yaml`.   

Here is an example `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/shared-helmrelease.yaml`:

  ```yaml
  apiVersion: flux.weave.works/v1beta1
  kind: HelmRelease
  metadata:
    name: shared
    namespace: default
    annotations:
      flux.weave.works/automated: "false"
  spec:
    releaseName: shared
    chart:
      git: git@github.com:tidepool-org/development
      path: charts/shared/0.1.0
      ref: k8s
    values:
      global:
        clusterName: development
        hostnames: 
        - qa1.development.tidepool.org
        - dev-api.tidepool.org
        - dev-app.tidepool.org
        - dev-uploads.tidepool.org
        - qa2.development.tidepool.org
        - stg-api.tidepool.org
        - stg-app.tidepool.org
        - stg-uploads.tidepool.org
      gloo:
        crds:
          create: false
  ```

Observe that this is a Kubernetes [Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/).  Specifically, this is resource of kind `HelmRelease` provided as part of the `flux.weave.works/v1beta1` API.  

The file `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/shared-start-helmrelease.yaml` describes resources that are required to be installed before the resources in `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/shared-helmrelease.yaml`.  Despite the dependency, you need not manually install one before the other.  The `flux` operator will retry the installation of each `helmrelease` continually until it succeeds.

We do not use `flux` to update the images for these services automatically. Hence you see the value `false` in the declaration:
  ```yaml
  metadata:
    annotations:
      flux.weave.works/automated: "false"
  ```

#### Identify the Cluster 

You must identify your cluster name in both `HelmRelease` manifests.  Edit these files to replace `${CLUSTER_NAME}` with the name of your cluster.

   ```yaml
   spec:
     values:
       global:
         clusterName: ${CLUSTER_NAME}
   ```

#### Identify the DNS Hostnames to Advertise

In order for traffic to be directed to your Kubernetes cluster, a DNS alias must be registered and advertised by the DNS service.  This is done on your behalf by a service called `external-dns` that is installed as one of the `shared` services.  You need only configure the service by providing a list of DNS names to serve.  The `external-dns` service will create DNS aliases to the AWS load balancer that is created by the Gloo API Gateway:

   ```yaml
   spec:
     values:
       global:
         hostnames:
         - name1
         - name2
         ....
   ```

If you are not ready to redirect the DNS entries of those names, you may update the file later and check it into GitHub. This is trigger a restart of the `external-dns` service with the new names.

Note, the automatic update of DNS aliases will only succeed if no *other* entity has created DNS aliases for this entities in Route53.
If there is a conflicting entity, you must delete first.

#### Install Cert-Manager CRDs

To use the `cert-manager`, we must manually install the CRDs before we install the `cert-manager`:

   ```bash
   $ kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
   ```

You should see output similar to:

   ```
   customresourcedefinition.apiextensions.k8s.io/certificates.certmanager.k8s.io created
   customresourcedefinition.apiextensions.k8s.io/challenges.certmanager.k8s.io created
   customresourcedefinition.apiextensions.k8s.io/clusterissuers.certmanager.k8s.io    created
   customresourcedefinition.apiextensions.k8s.io/issuers.certmanager.k8s.io created
   customresourcedefinition.apiextensions.k8s.io/orders.certmanager.k8s.io created
   ```

### Create IAM Roles for Your Shared Services

Several of the services need to access or modify Amazon resources.  To do this, your services must have IAM roles with policies that authorize such actions. 

An IAM role is associated with each node in your Kubernetes cluster. By default, a Kubernetes service gets the authority of the node on which it runs.  Moreover, any Kubernetes service can run on any node.  Therefore, in order to authorize a service to access your AWS resources, every node must have the union of all privileges needed. However, this violates the principle of least privilege.
       
Instead of relying on the default mechanism, we use the `kiam` service to associate IAM roles with specific services. With `kiam`, you simply annotate each pod with an IAM role that it needs, and you annotate the namespace to permit the assumption of those roles. 

The `kiam` service itself needs permission to assume roles on behalf of your specific services.

To make that process simple, we provide an Amazon CloudFormation template that creates all the IAM roles.  We name those roles following a convention
that ensures that the roles created match the names used for those roles in the Helm templates.

Create a CF stack named `eksctl-${CLUSTER_NAME}-roles` as follows.

For your convenience, we provide a helper function to create the IAM roles.

  ```bash
  $ cluster_roles ${CLUSTER_NAME} ${AWS_REGION:-us-west-2}
  ```

You should see output similar to:
  ```json
  {
     "StackId": "arn:aws:cloudformation:us-west-2:${AWS_ACCOUNT}:stack/eksctl-${CLUSTER_NAME}-roles/39c22a40-af63-11e9-b075-025219eb189a"
  }
  ```

## Configure Your Tidepool Environments

Above we configured the services shared by all Tidepool environments.  Now, you must configure each specific Tidepool Environment.

To configure each Tidepool environment, you must provide:
  * a single `HelmRelease` file that describes the parameters for the Tidepool Helm Chart;
  * a namespace file to create the K8s namespace for the environment.

All of these resources must exist in the namespace of the environment, ${ENVIRONMENT}`.

In addition, you must create IAM roles that provide policies that allow access:
  * the S3 buckets used and
  * the Amazon SMS mail service.
 
### Tidepool HelmRelease Manifest

To configure each Tidepool environment, you must provide a single `HelmRelease`.

By convention, we call this file  `tidepool-helmrelease.yaml` and we store it a directory called ${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/environments/${ENVIRONMENT}.

However, if you have followed the standard `flux` installation, any location under the `flux` directory will suffice.
  
There are two parts of the `HelmRelease` that you need to understand in detail: `metadata` and `values`:

#### Metadata

The `metadata` section identifies the resource using the standard `name` and `namespace`.  Additionally, the
`metadata` section also has `annotations`, which instruct `flux` whether and how to update the `${CONFIG_REPO}` when it 
sees new images on Docker Hub. Please read the [flux documentation](https://flux-cd.readthedocs.io/en/latest/using/annotations-tutorial.html#driving-flux) on the meaning of these annotations. In this example, we instruct flux to update the Docker image tags inside the same `HelmRelease` file when we tag starts with the word `develop` for all images except `blip`.

  ```yaml
  metadata:
    name: tidepool
    namespace: ${ENVIRONMENT}
    annotations:
      flux.weave.works/automated: "true"
      flux.weave.works/tag.auth: glob:develop-*
      flux.weave.works/tag.blip: glob:release-1.23.0*
      flux.weave.works/tag.blob: glob:develop-*
      flux.weave.works/tag.data: glob:develop-*
      flux.weave.works/tag.export: glob:develop-*
      flux.weave.works/tag.gatekeeper: glob:develop-*
      flux.weave.works/tag.highwater: glob:develop-*
      flux.weave.works/tag.hydrophone: glob:develop-*
      flux.weave.works/tag.image: glob:develop-*
      flux.weave.works/tag.jellyfish: glob:mongo-*
      flux.weave.works/tag.messageapi: glob:develop-*
      flux.weave.works/tag.migrations: glob:develop-*
      flux.weave.works/tag.notification: glob:develop-*
      flux.weave.works/tag.seagull: glob:develop-*
      flux.weave.works/tag.shoreline: glob:develop-*
      flux.weave.works/tag.task: glob:develop-*
      flux.weave.works/tag.tidewhisperer: glob:develop-*
      flux.weave.works/tag.tools: glob:develop-*
      flux.weave.works/tag.user: glob:develop-*
  ```

#### Values 

The `values` section contains descriptions of:

  * the hosts / DNS aliases
  * the mongo connnection parameters
  * the source of your secrets

You must customize the `values` section for your particular needs.

##### S3 Storage

Each Tidepool environment needs a place to persist non-Mongo data.  We store this data in [Amazon S3](https://aws.amazon.com/s3/).  


You will use S3 for object storage instead of local file storage that is configured by default in the Tidepool helm chart. You must override the
default local file storage as follows in your `HelmRelease` manifest:

  ```yaml
  spec:
    values:
      global:
        store:
          type: s3
  ```

You may override the name of the S3 bucket used as described below.

##### Read-Write Buckets

By default, your data is stored in a bucket labelled `tidepool-${ENVIRONMENT}-data`.   You may change that name by providing values
for these fields in the HelmRelease for the environment. Here we show the default values:

  ```yaml
  spec:
    values:
      blob:
        bucket: tidepool-${ENVIRONMENT}-data
      image:
        bucket: tidepool-${ENVIRONMENT}-data
      jellyfish:
        bucket: tidepool-${ENVIRONMENT}-data
  ```

You may override the bucket names to store your private data in another place.

##### Read-only Buckets

In addition, the hydrophone services reads email templates for user signup purposes.  By default, that data is in a public read-only bucket named:
  ```yaml
  spec:
    values:
      hydrophone:
        bucket: tidepool-${ENVIRONMENT}-asset`
  ```

You may copy [this example](https://s3.console.aws.amazon.com/s3/buckets/tidepool-int-asset/?region=us-west-2&tab=overview) using the Amazon CLI:

  ```bash
  aws s3 mb s3://tidepool-${ENVIRONMENT}-asset
  aws s3 cp s3://tidepool-dev-asset s3://tidepool-${ENVIRONMENT}-asset
  ```

Alternatively, you may override the bucket name to retrieve your email templates from another place.

#### Configure the Cluster Name

You must provide the name of your cluster.  When Flux installs your Tidepool environment using the `HelmRelease` manifest for that environment, it has
not access to K8s resources outside the namespace of the environment.  In other words, your Tidepool services do not directly refer to the shared services or any other Kubernetes objects outside of theie namespace.  Consequently, we must provide in the `HelmRelease` the cluster name and AWS region.  By default, the AWS region is `us-west-2`:

  ```yaml
  spec:
    values:
      global:
        clusterName: ${CLUSTER_NAME}
        awsRegion: ${AWS_REGION}
  ```

#### Configure Mongo

Your Mongo data must be served by a Mongo server. You must provide the Mongo connection information to your Tidepool environment.  You may
do this directly via a Kubernetes `Secret` as described above, or, for test purposes, you may provide that data via your `HelmRelease` file. 

##### Production Configuration

For production, you should store your Mongo data in a replicated store that is configured for durability.  The embedded configuration does not meet those requirements.

You will need to provide the [Mongo connection string](https://docs.mongodb.com/manual/reference/connection-string/).  This is a standard way of identifying a Mongo service.  

Above, you created a `Secret` with the Mongo connection information. In addition, you must provide the secret name.  This indicates that the connection information is stored in the secret of the given name. By convention, the name of that secret is `mongo`.

  ```yaml
  spec:
    values:
      global:
        mongo:
          secretName: "mongo"
  ```

Finally, if you do not host Mongo in the same VPC, but you use a Mongo server in another Amazon VPC, you may establish a peering relationship between your VPC and the Mongo VPC in order to enable network communcation without leaving the Amazon private network. See the appendix for details.
      
##### Test Configuration

For *testing*, you may install an embedded Mongo database using:
  ```yaml
  spec:
    values:
      mongodb:
        enabled: true
      global:
        mongo:
          scheme: mongodb
          hosts: localhost
          ssl: "true"
  ```
This will create a Mongo secret with the given Mongo connnection information and use that secret to connect to a local, embedded Mongo database. 

#### Enable Nosqlclient

You may install the [nosqlclient](https://www.nosqlclient.com/) as a replacement to the MongoDB shell. To do so, enable the installation flag:
  ```yaml
  spec:
    values:
      nosqlclient:
        enabled: "true"
  ```

With this enabled and deployed, you will be able connect to the `nosqlclient` by forwarding a port to port `3000` of the `nosqlcient` service in
the namespace of your environment, `${ENVIRONMENT}`  This client will be pre-configured to address your Mongo database.

#### Configure DNS Aliases

You must configure your environment to support HTTP and/or HTTPS access.  By default, you are provided http access on port 8080:

   ```yaml
   spec:
     values:
       global:
         hosts:
            default:
              protocol: http                          # the protocol to use for signup emails
              host: localhost                         # a valid DNS name[:port] for the service
            http:
              enabled: true
              port: "8080"                            # HTTP port (must be quoted)
              dnsNames:                               # list of DNS names to server 
              - localhost              
            https:
              enabled: false
   ```

You may configure https access and generate TLS secrets by providing the `domains` for the hosts and a name in 
which to store the TLS certificate.  Here is an example that turns off HTTP access and enables HTTPS access only, using
5 DNS aliases, for two domains, and with automatic generation of a TLS certificate:
   ```yaml
   spec:
     values:
       global:
         hosts:
            default:
              protocol: https
              host: qa1.development.tidepool.org
            http:
              enabled: false
            https:
              enabled: true
              port: "8443"
              commonName: qa1.development.tidepool.org
              secretName: qa1-tls-secret
              dnsNames:
              - qa1.development.tidepool.org
              - dev.tidepool.org
              - dev-app.tidepool.org
              - dev-api.tidepool.org
              - dev-uploads.tidepool.org
   ```

#### Configure Secrets Access

The section above discussed how to select a secrets source.  Make that selection in your `HelmRelease` file:
  ```bash
  ${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/environments/${ENVIRONMENT}
  ```

#### Turn off Embedded Mongo

You will not use the embedded Mongo database that is installed with the Tidepool helm chart. You may disable its installation.
  ```yaml
  spec:
    values:
      mongodb:
        enabled: false
  ```
Alternatively, you may install it and use it for the `mongo` utilities that are installed with it.

#### Turn off Embedded Gloo

You will not use the embedded Gloo API Gateway that is installed with the Tidepool helm chart. So, you will need to disable its installation:
  ```yaml
  spec:
    values:
      gloo:
        enabled: false
  ```

#### Horizontal Pod Autoscalers

By default, a horizontal pod autoscaler is created for each Tidepool deployment. This allows Kubernetes to automatically scale the number
of pods for the deployment based on CPU usage.

You may disable all of these by setting:
  ```yaml
  spec:
    values:
      global:
        hpa:
          enabled: false
  ```

### Create IAM Roles for Each Environment

Your Tidepool environment needs to access certain S3 buckets and Secrets stored in the AWS Secrets Manager. 

Above, we created IAM roles for the shared services.  Now, we must create IAM roles for each Tidpool environment.

For you convenience, you may configure those IAM roles with the following helper function:
    
  ```bash
  $ env_roles ${ENVIRONMENT} ${CLUSTER_NAME} ${BUCKET_NAME:-tidepool-${ENVIRONMENT}-data} ${REGION:-us-west-2}
  ```

This will create two IAM roles specific to the Tidepool environment using CloudFormation.

You should see output similar to:

  ```json
  {
    "StackId": "arn:aws:cloudformation:us-west-2:${AWS_ACCOUNT}:stack/eksctl-${CLUSTER_NAME}-qa1-roles/cef84130-af63-11e9-bf8f-060a94aeeab6"
  }
  ```

This helper uses Amazon CloudFormation to create the roles with read/write policies for the default S3 buckets mentioned above.

The helper function ignores any specialization of the bucket names that you provide.  If you change the default bucket names, you will need to modify the cloud formation stack or template that the helper create or uses.

### Set the Namespace 

Each separate Tidepool environment must live in its own namespace. If you have not already done so, you may ensure that all your Kubernetes manifests
have the namespace of the ${ENVIRONMENT} using a simple helper function.

  ```bash
  $ change_namespace ${ENVIRONMENT}
  ```

## Create Intra-cluster Secrets

Above you created and persisted secrets for external services.  There are also secrets needed for intra-cluster communication. 

For you convenience, we provide a means of creating random secret values for such intra-cluster communication.  You then need to
persist these values to AWS Secrets Manager as you did the external service secrets.

Each Tidepool environment is parameterized with a number of values.  You have already provided some of these values in the `HelmRelease` file.  You provide others as Kubernetes Secrets.

There are two types of secrets that are needed to run your services: intra-cluster secrets and externally shared secrets.

You may create random infra-cluster secrets and upload them to the AWS Secrets Manager using the
`external_secrets` helper:

  ```bash
  $ external_secret <(helm template --namespace=${ENVIRONMENT} ${DEV_REPO}/charts/intra-secrets/0.1.6) create ${CLUSTER_NAME} encoded
  ```

For example, you may retrieve the Mongo connection data as follows:

  ```bash
  $ get_external_secret mongo qa1 development
  ```

Example output:

  ```yaml
  apiVersion: v1
  kind: Secret
  type: Opaque
  data:
      addresses: cluster0-shard-00-01-hu2cn.mongodb.net:27017,cluster0-shard-00-00-hu2cn.mongodb.net:27017,cluster0-shard-00-02-hu2cn.mongodb.net:27017
      optParams: replicaSet=Cluster0-shard-0&authSource=admin&w=majority
      password: ...
      scheme: mongodb
      ssl: 'true'
      username: derrickburns
  metadata:
    name: mongo
    namespace: qa1
  ```

## Install Services

Congratulations, you are almost there.  You simply need to commit the Config repo, and enable GitOps.

### Publish Your Config Repo 

You are now ready to publish your config repo to a public Git repo such as GitHub. 

If you have chosen to store your secrets outside of your repo, then you may make your config repo public.

1. Your Git Server and Repo

   Now publish a repo of the configuration of your cluster in a publiclly assessible Git server such as GitHub: 

  ```bash
  $ git commit -am "Initial configuration"
  $ git remote add origin git@github.com:${GITHIB_ACCOUNT}/${CONFIG_REPO_NAME}.git
  $ git push
   ``` 
 
  where 
  - `${GITHIB_ACCOUNT}` is your GitHub account name.  For Tidepool.org this is `tidepool-org`.
  - `${CONFIG_REPO_NAME}` is the name of your config repo.  We follow the convention `$CONFIG_REPO_NAME=cluster-${CLUSTER_NAME}`.

You must name the remote `origin` as in the example above.  We use that name later when we identify your public repo from your local Git config.

Now that you have written your configuration files and published them to GitHub, you may deploy the services to your cluster using GitOps via the Flux tool.

### Enable GitOps

We need to configure and install the GitOps controller.

#### Install Flux

The `HelmRelease` manifests that you edited above are inputs to the Flux controller. Flux installs the services named in those manifests.  We must install [flux](https://github.com/fluxcd/flux), in order for it to do so.

For your convenience, we provide a helper function which you may execute from within the $CONFIG_REPO.  Note
that the config repo *must* have a remote associated with it named `origin`.  This is the repo that Flux will monitor.

If you have chosen to install the slack helper, then provide the argument `$FLUXCLOUD=fluxcloud` otherwise set `$FLUXCLOUD=`:

   ```bash
   $ cd $CONFIG_REPO
   $ install_flux "$FLUXCLOUD"
   ```
   
#### Install List of Helm Repositories

Flux can install software from Git repos or Helm repos.  For the latter, you must provide the access credentials. None of the repositories that we use require authentication.  If they did, then we would need to modify this repo to access secrets.  For now, we simply compose a secrets file from plaintext using the helm chart in `${DEV_REPO}/charts/flux-repositories`.
 
  ```bash
  $ helm install --name flux-repositories --namespace flux ${DEV_REPO}/charts/flux-repositories
  ```

#### Retrieve the flux public key.

[Flux](https://flux-cd.readthedocs.io/en/latest/install/standalone-setup.html#add-an-ssh-deploy-key-to-the-repository) can update your config repo whenerer new images are published to your Docker image repot (e.g. DockerHub).  To do this, your Git server (e.g. GitHub) must be configured to allow flux permission to make changes.  You do this on GitHub by providing a [deploy key](https://developer.github.com/v3/guides/managing-deploy-keys/), which is the public key of your flux server.

If you have provided your GitHub Access token as instructed above, then you may use the helper function to install the flux public key to your Git config repo so that Flux may read and write to the repo:
 
  ```bash
  $ push_deploy_key
  ```

You should see output similar to:
      
   ```
   cluster-development
   HTTP/1.1 201 Created
   Date: Fri, 26 Jul 2019 07:12:56 GMT
   Content-Type: application/json; charset=utf-8
   Content-Length: 686
   Server: GitHub.com
   Status: 201 Created
   X-RateLimit-Limit: 5000
   X-RateLimit-Remaining: 4999
   X-RateLimit-Reset: 1564128776
   Cache-Control: private, max-age=60, s-maxage=60
   Vary: Accept, Authorization, Cookie, X-GitHub-OTP
   ETag: "e67e797431099e2fff922a3692c27108"
   X-OAuth-Scopes: admin:public_key, repo
   X-Accepted-OAuth-Scopes:
   Location: https://api.github.com/repos/tidepool-org/cluster-development/keys/36570161
   X-GitHub-Media-Type: github.v3; format=json
   Access-Control-Expose-Headers: ETag, Link, Location, Retry-After, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes,   X-Poll-Interval, X-GitHub-Media-Type
   Access-Control-Allow-Origin: *
   Strict-Transport-Security: max-age=31536000; includeSubdomains; preload
   X-Frame-Options: deny
   X-Content-Type-Options: nosniff
   X-XSS-Protection: 1; mode=block
   Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
   Content-Security-Policy: default-src 'none'
   Vary: Accept-Encoding
   X-GitHub-Request-Id: DFDA:2FFA:A5ADC:D0492:5D3AA7F8
   ```

   ```json
   {
     "id": 36570161,
     "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsOW54woRtFFv+xrtQKfSjWENsjy58tEJO/34aMD7PP3PY7FLIsGMfeKQvYGO3NMis5P0K0cbbzLpAJElC8CtCLj1o1WyE9A2u3DC+cu59/  xquwtibc9orfAVvXxahUc3BhdH6eZqn8yOrhPRpWZR7l55ucpP+5LGoq00C9803FEV3DC9XNcZoTVKOp4C0A3uKdiK0XJ4Q8ra85F2Yh/tcd8FUDapoWzFJDk1CpJi0IJ2d18cOswsFhih8GyVZt3lCpxHm/Zyo+4Y91d+N46D  +rgmnW4dzrjgRExWmwW0MdlFppebOIH+Dfsi4mwIOvdaUjYddtW0A8dc88xnb3QQP",
     "url": "https://api.github.com/repos/tidepool-org/cluster-development/keys/36570161",
     "title": "weave flux key for derrick@development.us-west-2.eksctl.io Fri Jul 26 00:12:56 PDT 2019",
     "verified": true,
     "created_at": "2019-07-26T07:12:56Z",
     "read_only": false
   }
   ```
     
Otherwise, manually you may run retrieve the public key by running:

   ```bash
   $ fluxctl identity
   ```

Then, go to your GitHub repo and add the deploy key.  In the comment, place the name of the cluster.
 
## Confirm Proper Installation

Now that you have done all the work, let's confirm that everything is running properly.

To do this, we use the `k9s` tool to inspect the various manifests and services in your Kubernetes cluster.

  ```bash
  $ k9s
  ```

### Confirm that all namespaces exist

List the namespaces with the `:ns<Enter>` command. Inspect the list. You should see a list like this, where instead of `qa1` and `qa2` you see the Tidepool environments that you created:

  ```                     
  autoscaler                 
  cert-manager               
  datadog                   
  default                  
  external-dns-system        
  external-secrets           
  flux                 
  gloo-system                
  kube-public                
  kube-system                
  metrics-server             
  monitoring                 
  qa1                       
  qa2                        
  reloader                   
  sumologic                     
  ```

### Inspect the pods in the `flux` namespace.

Move the cursor to the `flux` namespace and type `po:<Enter>`.

You should see something similar to:

   ```
   flux-54b8477478-8sh6k                1/1   Running   ... 
   flux-helm-operator-77586cb994-r46hm  1/1   Running   ...
   flux-memcached-676b496574-68bpj      1/1   Running   ...   
   fluxcloud-7d48476d98-hksr6           1/1   Running   ...                    │
   ```
   
### Inspect the logs of the `flux-helm-operator`

You should see entries like:

  ```
  ts=2019-07-26T17:40:50.775818801Z caller=operator.go:309 component=operator info="enqueuing release" resource=metrics-server:helmrelease/metrics-s
  ts=2019-07-26T17:39:08.340312499Z caller=release.go:183 component=release info="processing release autoscaler (as 85b18b9e-af7a-11e9-9c49-022146cdd9ae)" action=CREATE options="{DryRun:true ReuseName:false}" timeout=300s
  ```

### Inspect the Mongo Database

If you have enabled the `nosqlclient` service in your Tidepool environment, you may inspect the database configured for that environment:
  ```bash
  $ kubectl port-forward -n ${ENVIRONMENT} svc/nosqlclient 3000
  ```

If successful, you will see:
  ```
  Forwarding from 127.0.0.1:3000 -> 3000
  Forwarding from [::1]:3000 -> 3000
  ```

Now, follow these steps to open up a Mongo shell that is pre-configured for your Mongo database.

  1. Open your browser to `localhost:3000`
  
       ```bash
       open -a /Applications/Google\ Chrome.app/ http://localhost:3000`
       ```

  1. Click the `Connect` button in the upper left corner.
  
  1. Select the `Default (preconfigured)` connection.
  
  1. Click `Connect` in the lower right corner.

  1. Click `Tools` in the left pane.

  1. Select `Shell` in the sub-pane.

## Post-Installation Configuration

After you have installed your cluster, you may want to create a Demo clinic account.  After you create that account, you may place
the clinic demo user id in a Kubernetes `ConfigMap`.  Create a file of the following form and check it into your config repo under
the directory `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/environments/${ENVIRONMENT}`:

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: shoreline
    namespace: ${ENVIRONMENT}
  data:
    ClinicDemoUserId: ${ClinicDemoUserId}
  ```

  where

  - ${ClinicDemoUserId} is the clinic demo id, e.g. `e79b15328a`

# Destroying a Cluster

To destroy a cluster without disturbing the persistent data, we provide two helper functions:

   ```bash
   $ stop_services ${ENVIRONMENTS}
   $ delete_cluster ${CLUSTER_NAME} "${ENVIRONMENTS}" "${NODE_GROUPS:-ng-1 ng-kiam}"
   ```

   The first helper function uses the helm cli to stop the K8s services in the cluster that may control AWS resources.

   The second helper function uses the AWS cli to destroy the cloudformation stacks.

# Troubleshooting

1. `k9s` does not start

    Is `KUBECONFIG` set to the location of your `.kubeconfig` file?  Is your kube context set to the cluster?

1.  Most of my services persist in the `CreatingContainer` state.

    Kubernetes cannot create the container until your secrets are ready. Confirm that your secrets exist in the same namespace as your Kubernetes environment.

1.  Shoreline keep restarting.

    Shoreline depends on Mongo.  If Mongo is unaccessible, then 
    shoreline will crash.  Confirm that your Mongo credentials are correct and that Mongo is reachable from your VPC.  

  
# Appendix

## How To Create a Peering Relationship

A [peering relationship](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html) is an authorization for separately managed VPCs to communicate with each other. Peering relationships are symmetric. Both sides must grant approval for the relationship.  

From [AWS online documentation](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html):
>To establish a VPC peering connection, you do the following:

>The owner of the requester VPC sends a request to the owner of the accepter VPC to create the VPC peering connection. The accepter VPC can be owned by you, or another AWS account, and cannot have a CIDR block that overlaps with the requester VPC's CIDR block.

>The owner of the accepter VPC accepts the VPC peering connection request to activate the VPC peering connection.

>To enable the flow of traffic between the VPCs using private IP addresses, the owner of each VPC in the VPC peering connection must manually add a route to one or more of their VPC route tables that points to the IP address range of the other VPC (the peer VPC).

>If required, update the security group rules that are associated with your instance to ensure that traffic to and from the peer VPC is not restricted. If both VPCs are in the same region, you can reference a security group from the peer VPC as a source or destination for ingress or egress rules in your security group rules.

>By default, if instances on either side of a VPC peering connection address each other using a public DNS hostname, the hostname resolves to the instance's public IP address. To change this behavior, enable DNS hostname resolution for your VPC connection. After enabling DNS hostname resolution, if instances on either side of the VPC peering connection address each other using a public DNS hostname, the hostname resolves to the private IP address of the instance.
    
### Peering with AtlasDB

If you use MongoDB Atlas to host your Mongo data, you will need to go to the Atlas Web Console and create the peering connection. To do this, you will need 
1. your AWS Account number, 
1. your VPC ID, 
1. your CIDR block, and
1. your AWS region.

After you create the peering connection request from MongoDB Atlas, you go the the AWS Web Console to accept the connection.

After approval of the peering connection, you must create routing rules from your EC2 instances in the `eksctl-${CLUSTER_NAME}-nodegroup-ng-1` nodegroup *to* the CIDR block used by entities that you peer with.  Your instances in the public subnet.  So, you must add a route in the public route table `eksctl-${CLUSTER_NAME}-cluster/PublicRouteTable`.

### Using the AWS Web Interface

You may request a peering relationships in the [AWS console](https://us-west-2.console.aws.amazon.com/vpc/home?region=us-west-2#PeeringConnections:sort=vpcPeeringConnectionId).  The `Requestor` is named `eksctl-${CLUSTER_NAME}-cluster/VPC`.  The `Acceptor` is the name of the VPC that you want to connect to.  
    
To complete a peering relationship, the `Acceptor` must accept your request. If you control the accounts of the `Acceptor`, you may accept the peering relationship.

To accept a peering request, select the peering connection that is in the `Pending Acceptance` state.  That is your request.  Then accept the connection using the menu.

Now, [navigate to the route tables](https://us-west-2.console.aws.amazon.com/vpc/home?region=us-west-2#RouteTables:sort=routeTableId) and  select `eksctl-${CLUSTER_NAME}-cluster/PublicRouteTable`. Click on `Routes` then `Edit Routes`. Now enter the CIDR of the target VPC (e.g. `192.168.248.0/21`) and the name of the target peering connection (e.g. `pcx-07a996cd36be9d3d8`). Click `Save Routes`.

## How To Generate Cluster-wide Shared TLS Certificates

If you intend to provide HTTPS access to services in your cluster, then you will need to create or provide TLS certificates for your domains. 
For your convenience, you may use the provided `cert-manager` to create TLS certificates and to renew them as needed. 

You may provide certificates in the `default` namespace that are available to all Tidepool environments by creating cert-manager `Certificate` manifests with a `ClusterIssuer` and adding those manifests to your Config repo.

Alternatively, you may create certificates *along with your individual Tidepool environments* by providing the request information as part of the 
description of the Tidepool environment (in the `HelmRelease` file).  This (easier) option is covered in the section "Configure Your Tidepool Environments".

### Prepare Certificate Requests for the default Namespace

To provide shared certificates for the entire cluster, prepare certificate requests and place them in the `certs` directory.
You may provide certificates in the `default` namespace that are available to all Tidepool environments by creating cert-manager [Certificate manifests](https://docs.cert-manager.io/en/latest/tasks/issuing-certificates/index.html) with a `ClusterIssuer`.

The example below requests a *fake* wildcard certificate for the `tidepool.org` domain using the `letsencrypt` staging server. Simply provide a request such as
this one in your `flux` directory (or any sub-directory).

After you have installed these manifests, look at the log files. If you see that a fake certificate was created, then you may assume that you correctly specified the parameters and that all communication with `letsencrypt` is working.  At this point, switch to the `letsencrypt` production server to get permanent certificates.  See the [documentation](https://docs.cert-manager.io/en/latest/).

  ```yaml
  apiVersion: certmanager.k8s.io/v1alpha1
  kind: Certificate
  metadata:
    name: tidepool-cert
    namespace: default
  spec:
    secretName: tidepool-tls
    issuerRef:
      name: letsencrypt-staging
      kind: ClusterIssuer
    commonName: '*.tidepool.org'
    dnsNames:
    - '*.tidepool.org'
    acme:
      config:
      - dns01:
          provider: route53
        domains:
        - '*.tidepool.org'
  ```

## How To Configure Additional Nodegroups

If you configure nodegroups other than those defined in the provided `config.yaml` file, then you will need to allow that node to assume the role of the
kiam server. You may *skip* this step if you have configured your cluster with exactly two node groups as shown in the example.
	
In order to allow the [kiam](https://github.com/uswitch/kiam) role to be assumed, you must add the node instance roles of each nodegroup as a Trusted Role.  

For your convenience, we provide a helper function:

  ```bash
  $ set_kiam_trust {CLUSTER_NAME} ${CONFIG_FILE:-config.yaml}
  ```

## How To Store Secrets in Your PRIVATE Git Repo

Instead of storing secrets in the AWS Secrets Manager using the `external-secrets` service to retrieve them, you may 
provide the secrets in any way that you please, as long as they become Kubernetes `Secret` resources with the proper names.

### Using a Private Git Repo

One simply alternative is to store the secrets (after `base64` encoding the values) in a *private* Git config repo.  Simply commit your `Secret` manifests to your Git config repo. This means that you need to edit the `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/.gitconfig` file to eliminate the `secrets` line.

You may mix and match the source of your secrets.  

You may select the *source* of the secrets by setting a `source` value.  Any value other than `awsSecretsManager` is interpreted to mean that
secrets of that category will be provided by you via your config repo or some other means.

#### Secrets for Shared Services

To configure all secrets for intra-cluster communication to come from Git, set the value below in the `HelmRelease` for your `${ENVIRONMENT}`.
That is the file `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/shared/shared-helmrelease.yaml`:

   ```yaml
   spec:
     values:
       global:
         secrets:
           source: gitops
   ```

#### Secrets for Internal Services Specific to Each Tidepool Environment

To configure all secrets for intra-cluster communication to come from Git, set the value below in the `HelmRelease` for your `${ENVIRONMENT}`.
That is the file `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/environments/${ENVIRONMENT}/tidepool-helmrelease.yaml`:

   ```yaml
   spec:
     values:
       global:
         secrets:
           internal:
             source: gitops
   ```

#### Secrets for External Services Specific to Each Tidepool Environment

To configure all secrets for external services used by your Tidepool environment, set the value below in the `HelmRelease` for your `${ENVIRONMENT}`.
That is the file `${CONFIG_REPO}/clusters/${CLUSTER_NAME}/flux/environments/${ENVIRONMENT}/tidepool-helmrelease.yaml`:

   ```yaml
   spec:
     values:
       global:
         secrets:
           external:
             source: gitops
   ```
