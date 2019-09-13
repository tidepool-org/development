
# Introduction

This document describes how to install the Tidepool web service on an Amazon hosted Kubernetes platform.  

With suitable modification, one may install the service on another Kubernetes platform.  However, that is not contained in the scope of this document.

## TL;DR 

To create a new cluster, you will first need to select a REMOTE_REPO name and acquire a GITHUB_TOKEN
per [these directions] (https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line.)

  ```bash
  git clone git@github.com:tidepool-org/development.git
  export DEV_REPO=$(pwd)/development
  cd ${DEV_REPO}
  git checkout k8s
  export PATH=$PATH:${DEV_REPO}/bin

  export REMOTE_REPO=....
  hub create tidepool-org/${REMOTE_REPO}

  # see https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line
  export GITHUB_TOKEN=....

  install_tools         # installs all tools needed
  make_values 		# creates values.yaml file in $REMOTE_REPO
  make_config		# populates $REMOTE_REPO with configuration
  make_assets		# makes S3 bucket for readonly assets
  make_cluster		# create EKS cluster, kubeconfig file
  make_random_secrets	# loads random secrets into K8s cluster
  make_flux		# installs flux and TLS-secured tiller into cluster, installs deploy key into $REMOTE_REPO
  make_cert		# creates a TLS certificate for local helm use, installs in ${HELM_HOME:-~/.helm}
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

In addition, you should make yourself familiar with the base [Tidepool Helm Chart](https://github.com/tidepool-org/development/tree/k8s/charts/tidepool/0.1.7).
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
  
1. A GitHub Access Token

   We will need to make adjustments to your GitHub config repo. To do this, we will need a [Git access token](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line) with repo read/write permissions. Provide that token in an environment variable: 

   ```bash
   $ export GITHUB_TOKEN=...
   ```

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

For your convenience, we have helper file that installs dependencies:

   ```bash
   $ install_tools
   ```
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
1. [hub](https://hub.github.com/)

It will also install some required python packages.

You may also want to install some supplemental packages.  However,
they are not required for the installation of the K8s cluster and Tidepool services.

   ```bash
   $ brew bundle --file=${DEV_REPO}/Brewfile-supplemental
   ```

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
    token: ${token}
  kind: Secret
  metadata:
    name: datadog
    namespace: datadog
  type: Opaque
  ```

  where:

  - `${api-key}` is the API key
  - `${app-key}` is the application key
  - `${token}` is a shared random token for intra-service comms

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

Finally, set the environment variable `$FLUXCLOUD` to `true`:

  ```bash
  $ export FLUXCLOUD=true
  ```

We use this variable later to configure Flux to provide updates to the Fluxcloud application, when sends those updates to your Slack channel.

### Secrets For Each Tidepool Environment

Some services are configured separately for each Tidepool environment. 

#### Mongo

Your Tidepool environments persists user data in MongoDB. We recommend that you host your Mongo storage outside of Kubernetes.  To connect to it, you will need the components of the Mongo connection string. Place them components in a `Secret` in the namepsace of your `${ENVIRONMENT}`:

  ```yaml
  apiVersion: v1
  data:
    Scheme: ${scheme}
    Addresses: ${addresses}
    Username: ${username}
    Password: ${password}
    Tls: ${tls}
    OptParams: ${optParams}
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
  - `${tls}` indicates whether to use SSL 
  - `${optParams}` are the additional URL parameters needed for the connection (e.g replica set info)

####  KissMetrics [Optional]

Tidepool collects data for user analytics using [Kissmetrics](http://support.kissmetrics.com/article/show/23938-api-specifications). We use the `v2` version of the Kissmetrics API.  This version requires that an API key be passed on each request.  

In addition, Tidepool allows logging of events that are not associated with a specific user.  This is indicated by passing a session token in the HTTP header of a request.

We publish metrics specificly for UCSF clinicians using a different Kissmetrics API key.

The list of users tracked is provided via a white list that you pass.

You store these secrets in the `kissmetrics` `Secret` in the namespace `${ENVIRONMENT}`:

  ```yaml
  apiVersion: v1

    APIKey: ${APIKey}
    Token: ${Token}
    UCSFAPIKey: ${UCSFAPIKey}
    UCSFWhitelist: ${UCSFWhitelist}
  kind: Secret
  metadata:
    name: kissmetrics
    namespace: ${ENVIRONMENT}
  type: Opaque
  ```

  where:

  - `${APIKey}` is the API key from KissMetrics
  - `${Token}` is the session token that you will use in the HTTP header
  - `${UCSFAPIKey}` is the API key from KissMetrics for UCSF
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
    ApiKey: ${ApiKey}
    URL: ${URL}
    PersonalLists: ${PersonalLists}
    ClinicLists: ${ClinicLists}
  kind: Secret
  metadata:
    name: mailchimp
    namespace: ${ENVIRONMENT}
  type: Opaque
  ```

  where:
  
  -  `${ApiKey}` is the value of the Mailchimp API Key
  -  `${URL}` is the URL to the Mailchimp service
  -  `${PersonalLists}` is the mailing list info to individuals
  -  `${ClinicLists}` is the mailing list info for clinics 

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


![secret creation flow](https://docs.google.com/drawings/d/e/2PACX-1vRNAMa_N0IQZr51u5cbCoC91pd7bYpkDZE-altY9i9A5Iew6HYOq4aEKzfstGmqtmwDVJymNuBJ1iZE/pub?w=960&amp;h=720 "Secrets Creation Flow")

Above you created your `Secret` manifests. We provide a helper function called `external_secrets` to
help you upload them to AWS Secrets Manager using the aforementioned naming conventions: 

  ```bash
  $ external_secrets ${FILENAME} ${OPERATION} ${CLUSTER_NAME} ${ENCODING} >external-secret.yaml
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

Finally, save the generated `external-secret.yaml` file in your Git config repo.

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

## Create Your Configuration 

```bash
  $ make_values
  [i] creating initial values file for repo git@github.com:tidepool-org/cluster-test1
  Cloning into 'tidepool-quickstart'...
  remote: Enumerating objects: 300, done.
  remote: Counting objects: 100% (300/300), done.
  remote: Compressing objects: 100% (225/225), done.
  remote: Total 300 (delta 137), reused 221 (delta 69), pack-reused 0
  Receiving objects: 100% (300/300), 85.16 KiB | 2.94 MiB/s, done.
  Resolving deltas: 100% (137/137), done.
  Cloning into 'cluster-test1'...
  remote: Enumerating objects: 1003, done.
  remote: Total 1003 (delta 0), reused 0 (delta 0), pack-reused 1003
  Receiving objects: 100% (1003/1003), 244.05 KiB | 96.00 KiB/s, done.
  Resolving deltas: 100% (541/541), done.
  WARNING: will overwrite prior contents of values.yaml?
  Are you sure? y[i] creating values.yaml?
  On branch master
  Your branch is up to date with 'origin/master'.
  
  nothing to commit, working tree clean
  Everything up-to-date
  [i] done
```

Your initial  values.yaml looks like this:
```yaml
logLevel: debug                               # the default log level for all services
email: derrick@tidepool.org                   # cluster admin email address

aws:
  accountNumber: 118346523422
  iamUsers:
  - derrickburns-cli
  - lennartgoedhard-cli
  - benderr-cli
  - jamesraby-cli
  - haroldbernard-cli

kubeconfig: "~/.kube/config"                 # place to put KUBECONFIG

cluster:
  metadata:
    name: test1
    region: us-west-2
  vpc:
    cidr: "10.47.0.0/16"                      # CIDR of AWS VPC
  nodeGroups:
  - instanceType: "m4.large"                  # AWS instance type for workers
    desiredCapacity: 4                        # initial capacity of auto scaling group of workers
    minSize: 1                                # minimum size of auto scaling group of workers
    maxSize: 10                               # maximum size of auto scaling group of workers
    name: ng
    iam:
      withAddonPolicies:
        autoScaler: true
        certManager: true
        externalDNS: true

pkgs:
  amazon-cloudwatch:
    enabled: true
  external-dns:
    enabled: true
  gloo:
    enabled: true
  gloo-crds:
    enabled: true
  prometheus-operator:
    enabled: true
  certmanager:
    enabled: true
  cluster-autoscaler:
    enabled: true
  external-secrets:
    enabled: true
  reloader:
    enabled: true
  datadog:
    enabled: false
  flux:
    enabled: true
  fluxcloud:
    enabled: false
  metrics-server:
    enabled: true
  sumologic:
    enabled: false

environments:
  qa2:
    hpa:
      enabled: true
    nosqlclient:
      enabled: true
    mongodb:
      enabled: true
    gitops:
      branch: develop
    buckets: {}
      #data: tidepool-test-qa2-data
      #asset: tidepool-test-qa2-asset
    gateway:
      default:
        protocol: http
      http:
        enabled: true
        dnsNames:
        - localhost
      https:
        enabled: false
        dnsNames: []
```

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

## Create Your Amazon EKS Cluster

To create an Amazon EKS cluster, you will need an AWS account and proper authority (IAM policy) to allow you to do so.

### A Look at the Cluster Config File

We use the `eksctl` cli tool to create EKS clusters. This tool has an option to provide a single cluster configuration file
to configure your cluster.  We use that approach. Our `make_config` helper generates a `config.yaml` file that looks like this:
  
  ```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: test1
  region: us-west-2
  version: "1.14"
nodeGroups:
- desiredCapacity: 4
  iam:
    withAddonPolicies:
      autoScaler: true
      certManager: true
      externalDNS: true
  instanceType: m4.large
  maxSize: 10
  minSize: 1
  name: ng
  tags:
    k8s.io/cluster-autoscaler/enabled: "true"
    k8s.io/cluster-autoscaler/test1: "true"
vpc:
  cidr: 10.47.0.0/16
iam:
  withOIDC: true
  serviceAccounts:
  - attachPolicy:
      Statement:
      - Action:
        - autoscaling:DescribeAutoScalingGroups
        - autoscaling:DescribeAutoScalingInstances
        - autoscaling:DescribeLaunchConfigurations
        - autoscaling:DescribeTags
        - autoscaling:SetDesiredCapacity
        - autoscaling:TerminateInstanceInAutoScalingGroup
        Effect: Allow
        Resource: '*'
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: cluster-ops
      name: cluster-autoscaler
      namespace: kube-system
  - attachPolicy:
      Statement:
      - Action:
        - route53:ChangeResourceRecordSets
        Effect: Allow
        Resource: arn:aws:route53:::hostedzone/*
      - Action:
        - route53:GetChange
        - route53:ListHostedZones
        - route53:ListResourceRecordSets
        - route53:ListHostedZonesByName
        Effect: Allow
        Resource: '*'
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: certificate-management
      name: certmanager
      namespace: certmanager
  - attachPolicy:
      Statement:
      - Action:
        - logs:CreateLogGroup
        - logs:CreateLogStream
        - logs:PutLogEvents
        - logs:DescribeLogStreams
        Effect: Allow
        Resource: arn:aws:logs:*:*:*
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: cloudwatch-logging
      name: cloudwatch
      namespace: amazon-cloudwatch
  - attachPolicy:
      Statement:
      - Action:
        - route53:ChangeResourceRecordSets
        Effect: Allow
        Resource: arn:aws:route53:::hostedzone/*
      - Action:
        - route53:GetChange
        - route53:ListHostedZones
        - route53:ListResourceRecordSets
        - route53:ListHostedZonesByName
        Effect: Allow
        Resource: '*'
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: DNS-alias-creation
      name: external-dns
      namespace: external-dns
  - attachPolicy:
      Statement:
      - Action: secretsmanager:GetSecretValue
        Effect: Allow
        Resource: arn:aws:secretsmanager:us-west-2:118346523422:secret:test1/*
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: secrets-management
      name: external-secrets
      namespace: external-secrets
  - attachPolicy:
      Statement:
      - Action: s3:ListBucket
        Effect: Allow
       Resource: arn:aws:s3:::tidepool-test1-qa2-data/*
      - Action:
        - s3:GetObject
        - s3:PutObject
        - s3:DeleteObject
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-data/*
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: blob-service
      name: blob
      namespace: qa2
  - attachPolicy:
      Statement:
      - Action: s3:ListBucket
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-data/*
      - Action:
        - s3:GetObject
        - s3:PutObject
        - s3:DeleteObject
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-data/*
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: image-service
      name: image
      namespace: qa2
  - attachPolicy:
      Statement:
      - Action: s3:ListBucket
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-data/*
      - Action:
        - s3:GetObject
        - s3:PutObject
        - s3:DeleteObject
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-data/*
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: jellyfish-service
      name: jellyfish
      namespace: qa2
  - attachPolicy:
      Statement:
      - Action: s3:ListBucket
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-asset/*
      - Action:
        - s3:GetObject
        Effect: Allow
        Resource: arn:aws:s3:::tidepool-test1-qa2-asset/*
      - Action: ses:*
        Effect: Allow
        Resource: '*'
      Version: "2012-10-17"
    metadata:
      labels:
        aws-usage: hydrophone-service
      name: hydrophone
      namespace: qa2

  ```

## Create Cluster

  ```bash
  $ make_cluster 
  ```
  > FIXME: We need to document the required IAM Policy to be able to run `make_cluster`.
  > FIXME: We may need some instructions (could be in a separate document), about what to do when `make_cluster` fails. I had to go and manually delete my CF Stack to try again. I got the policy instructions from https://github.com/weaveworks/eksctl/issues/204

You will see see output similar to:

  ```
Cloning into 'cluster-test1'...
remote: Enumerating objects: 1003, done.
remote: Total 1003 (delta 0), reused 0 (delta 0), pack-reused 1003
Receiving objects: 100% (1003/1003), 244.05 KiB | 2.60 MiB/s, done.
Resolving deltas: 100% (541/541), done.
creating cluster test1
[ℹ]  using region us-west-2
[ℹ]  setting availability zones to [us-west-2c us-west-2d us-west-2b]
[ℹ]  subnets for us-west-2c - public:10.47.0.0/19 private:10.47.96.0/19
[ℹ]  subnets for us-west-2d - public:10.47.32.0/19 private:10.47.128.0/19
[ℹ]  subnets for us-west-2b - public:10.47.64.0/19 private:10.47.160.0/19
[ℹ]  nodegroup "ng" will use "ami-076c743acc3ec4159" [AmazonLinux2/1.14]
[ℹ]  using Kubernetes version 1.14
[ℹ]  creating EKS cluster "test1" in "us-west-2" region
[ℹ]  1 nodegroup (ng) was included (based on the include/exclude rules)
[ℹ]  will create a CloudFormation stack for cluster itself and 1 nodegroup stack(s)
[ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-west-2 --name=test1'
[ℹ]  CloudWatch logging will not be enabled for cluster "test1" in "us-west-2"
[ℹ]  you can enable it with 'eksctl utils update-cluster-logging --region=us-west-2 --name=test1'
[ℹ]  3 sequential tasks: { create cluster control plane "test1", create nodegroup "ng", 2 sequential sub-tasks: { associate IAM OIDC provider, 9 parallel sub-tasks: { 2 sequential sub-tasks: { create IAM role for serviceaccount "kube-system/cluster-autoscaler", create serviceaccount "kube-system/cluster-autoscaler" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "certmanager/certmanager", create serviceaccount "certmanager/certmanager" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "amazon-cloudwatch/cloudwatch", create serviceaccount "amazon-cloudwatch/cloudwatch" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "external-dns/external-dns", create serviceaccount "external-dns/external-dns" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "external-secrets/external-secrets", create serviceaccount "external-secrets/external-secrets" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "qa2/blob", create serviceaccount "qa2/blob" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "qa2/image", create serviceaccount "qa2/image" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "qa2/jellyfish", create serviceaccount "qa2/jellyfish" }, 2 sequential sub-tasks: { create IAM role for serviceaccount "qa2/hydrophone", create serviceaccount "qa2/hydrophone" } } } }
[ℹ]  building cluster stack "eksctl-test1-cluster"
[ℹ]  deploying stack "eksctl-test1-cluster"
[ℹ]  building nodegroup stack "eksctl-test1-nodegroup-ng"
[ℹ]  deploying stack "eksctl-test1-nodegroup-ng"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-certmanager-certmanager"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-qa2-blob"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-qa2-hydrophone"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-external-secrets-external-secrets"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-amazon-cloudwatch-cloudwatch"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-qa2-image"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-qa2-jellyfish"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-kube-system-cluster-autoscaler"
[ℹ]  building iamserviceaccount stack "eksctl-test1-addon-iamserviceaccount-external-dns-external-dns"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-qa2-hydrophone"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-certmanager-certmanager"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-qa2-jellyfish"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-qa2-image"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-external-dns-external-dns"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-amazon-cloudwatch-cloudwatch"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-qa2-blob"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-external-secrets-external-secrets"
[ℹ]  deploying stack "eksctl-test1-addon-iamserviceaccount-kube-system-cluster-autoscaler"
[ℹ]  created namespace "amazon-cloudwatch"
[ℹ]  created serviceaccount "amazon-cloudwatch/cloudwatch"
[ℹ]  created namespace "external-secrets"
[ℹ]  created serviceaccount "external-secrets/external-secrets"
[ℹ]  created namespace "qa2"
[ℹ]  created serviceaccount "qa2/blob"
[ℹ]  created serviceaccount "kube-system/cluster-autoscaler"
[ℹ]  created namespace "certmanager"
[ℹ]  created serviceaccount "certmanager/certmanager"
[ℹ]  created serviceaccount "qa2/jellyfish"
[ℹ]  created serviceaccount "qa2/image"
[ℹ]  created serviceaccount "qa2/hydrophone"
[ℹ]  created namespace "external-dns"
[ℹ]  created serviceaccount "external-dns/external-dns"
[✔]  all EKS cluster resource for "test1" had been created
[✔]  saved kubeconfig as "/private/var/folders/m1/9nxmym25533_5khp4gsv89fc0000gn/T/tmp.jmAqKFfu/cluster-test1/kubeconfig.yaml"
[ℹ]  adding role "arn:aws:iam::118346523422:role/eksctl-test1-nodegroup-ng-NodeInstanceRole-YF0MFBO66OAQ" to auth ConfigMap
[ℹ]  nodegroup "ng" has 0 node(s)
[ℹ]  waiting for at least 1 node(s) to become ready in "ng"
[ℹ]  nodegroup "ng" has 4 node(s)
[ℹ]  node "ip-10-47-0-70.us-west-2.compute.internal" is ready
[ℹ]  node "ip-10-47-5-129.us-west-2.compute.internal" is not ready
[ℹ]  node "ip-10-47-72-154.us-west-2.compute.internal" is not ready
[ℹ]  node "ip-10-47-83-190.us-west-2.compute.internal" is not ready
[ℹ]  kubectl command should work with "/private/var/folders/m1/9nxmym25533_5khp4gsv89fc0000gn/T/tmp.jmAqKFfu/cluster-test1/kubeconfig.yaml", try 'kubectl --kubeconfig=/private/var/folders/m1/9nxmym25533_5khp4gsv89fc0000gn/T/tmp.jmAqKFfu/cluster-test1/kubeconfig.yaml get nodes'
[✔]  EKS cluster "test1" in "us-west-2" region is ready
  ```


## Create Random Secrets

```bash
  $ make_random_secrets
  Cloning into 'tidepool-quickstart'...
  remote: Enumerating objects: 303, done.
  remote: Counting objects: 100% (303/303), done.
  remote: Compressing objects: 100% (227/227), done.
  remote: Total 303 (delta 138), reused 224 (delta 70), pack-reused 0
  Receiving objects: 100% (303/303), 85.55 KiB | 695.00 KiB/s, done.
  Resolving deltas: 100% (138/138), done.
  Cloning into 'development'...
  remote: Enumerating objects: 35, done.
  remote: Counting objects: 100% (35/35), done.
  remote: Compressing objects: 100% (29/29), done.
  remote: Total 13045 (delta 12), reused 14 (delta 6), pack-reused 13010
  Receiving objects: 100% (13045/13045), 12.87 MiB | 11.97 MiB/s, done.
  Resolving deltas: 100% (9905/9905), done.
  Branch 'k8s' set up to track remote branch 'k8s' from 'origin'.
  Switched to a new branch 'k8s'
  Cloning into 'cluster-test1'...
  remote: Enumerating objects: 29, done.
  remote: Counting objects: 100% (29/29), done.
  remote: Compressing objects: 100% (21/21), done.
  remote: Total 1031 (delta 14), reused 22 (delta 8), pack-reused 1002
  Receiving objects: 100% (1031/1031), 252.47 KiB | 1.09 MiB/s, done.
  Resolving deltas: 100% (555/555), done.
  [i] creating random secrets for cluster test1 in repo git@github.com:tidepool-org/cluster-test1
  [i] creating secret fluxcloud-secret.yaml
  secret/slack configured
  [i] creating secret datadog-secret.yaml
  secret/datadog configured
  [i] creating secret sumologic-secret.yaml
  secret/sumologic configured
  [i] creating secret qa2/dexcom-secret.yaml
  secret/dexcom configured
  [i] creating secret qa2/auth-secret.yaml
  secret/auth configured
  [i] creating secret qa2/notification-secret.yaml
  secret/notification configured
  [i] creating secret qa2/server-secret.yaml
  secret/server configured
  [i] creating secret qa2/user-secret.yaml
  secret/user configured
  [i] creating secret qa2/image-secret.yaml
  secret/image configured
  [i] creating secret qa2/mailchimp-secret.yaml
  secret/mailchimp configured
  [i] creating secret qa2/shoreline-secret.yaml
  secret/shoreline configured
  [i] creating secret qa2/task-secret.yaml
  secret/task configured
  [i] creating secret qa2/kissmetrics-secret.yaml
  secret/kissmetrics configured
  [i] creating secret qa2/mongo-secret.yaml
  secret/mongo configured
  [i] creating secret qa2/carelink-secret.yaml
  secret/jellyfish configured
  [i] creating secret qa2/export-secret.yaml
  secret/export configured
  [i] creating secret qa2/data-secret.yaml
  secret/data configured
  [i] creating secret qa2/userdata-secret.yaml
  secret/userdata configured
  [i] creating secret qa2/blob-secret.yaml
  secret/blob configured
  [i] done
```
#### Kubeconfig

This will create merge in a new K8s kubeconfig into the file named in your values.yaml file under the key `kubeconfig`.

Verify that you can communicate with the cluster by running:

  ```bash
  $ kubectl get all --all-namespaces
  ```
If you get an error, confirm that the value of `$KUBECONFIG` is set to the same values as in your `values.yaml` file.

#### AWS CloudFormation 

Under the covers, `eksctl` uses Amazon CloudFormation to create resources in AWS.   Observe the mention of the stacks created:
   ```
   eksctl-${CLUSTER_NAME}-cluster
   eksctl-${CLUSTER_NAME}-nodegroup-ng
   ...
   ```
We reference these AWS CloudFormation resources later when we create additional IAM roles and policies.

### IAM Master Users

Amazon EKS provides an integration between their identity management system (IAM) and the Kubernetes native identity system.  This allows one to associate a specific IAM user or role with a specific Kubernetes user.   You provide the name of the master users in the value `aws.iamUsers` of your `values.yaml` file.

This correspondence is communicated to Kubernetes via a ConfigMap called `aws-auth` in the `kube-system` namespace, along with the Kubernetes privileges for each user.

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

### A Look at Flux Manifests

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
        cluster:
          name: development
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
         cluster:
           name: ${CLUSTER_NAME}
   ```

#### Identify the DNS Hostnames to Advertise

In order for traffic to be directed to your Kubernetes cluster, a DNS alias must be registered and advertised by the DNS service.  This is done on your behalf by a service called `external-dns` that is installed as one of the `shared` services.  You need only configure the service by providing a list of DNS names to serve.  The `external-dns` service will create DNS aliases to the AWS load balancer that is created by the Gloo API Gateway:

   ```yaml
   spec:
     values:
       global:
         cluster:
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
 
### A Look at the Tidepool HelmRelease Manifest

To configure each Tidepool environment, you must provide a single `HelmRelease`.

By convention, we call this file  `tidepool-helmrelease.yaml` and we store it a directory called ${CONFIG_REPO}/environments/${ENVIRONMENT}.
  
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
        environment:
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
        deployment:
          env: 
            bucket: tidepool-${ENVIRONMENT}-data
      image:
        deployment:
          env: 
            bucket: tidepool-${ENVIRONMENT}-data
      jellyfish:
        deployment:
          env: 
            bucket: tidepool-${ENVIRONMENT}-data
  ```

You may override the bucket names to store your private data in another place.

##### Read-only Buckets

In addition, the hydrophone services reads email templates for user signup purposes.  By default, that data is in a public read-only bucket named:
  ```yaml
  spec:
    values:
      hydrophone:
        deployment:
          env:    
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
        cluster:
          name: ${CLUSTER_NAME}
          region: ${AWS_REGION}
  ```

#### Configure Mongo

Your Mongo data must be served by a Mongo server. You must provide the Mongo connection information to your Tidepool environment.  You may
do this directly via a Kubernetes `Secret` as described above, or, for test purposes, you may provide that data via your `HelmRelease` file. 

##### Production Configuration

For production, you should store your Mongo data in a replicated store that is configured for durability.  The embedded configuration does not meet those requirements.

You will need to provide the [Mongo connection string](https://docs.mongodb.com/manual/reference/connection-string/).  This is a standard way of identifying a Mongo service.  

Finally, if you do not host Mongo in the same VPC, but you use a Mongo server in another Amazon VPC, you may establish a peering relationship between your VPC and the Mongo VPC in order to enable network communcation without leaving the Amazon private network. See the appendix for details.
      
##### Test Configuration

For *testing*, you may install an embedded Mongo database using:
  ```yaml
  spec:
    values:
      mongodb:
        enabled: true
      mongo:
        secrets:
          Scheme: mongodb
          Hosts: localhost
          Tls: "true"
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
        environment:
          hosts:
             default:
               protocol: http                          # the protocol to use for signup emails
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
5 DNS aliases, for two domains, and with automatic generation of a TLS certificate. The first name listed of the
default protocol is used as the `common name` and the default host for email verifications.
  ```yaml
  spec:
    values:
      global:
        environment:
          hosts:
             default:
               protocol: https
             http:
               enabled: false
             https:
               enabled: true
               port: "8443"
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
        environment:
          hpa:
            create: false
  ```

### Create IAM Roles for Each Environment

Your Tidepool environment needs to access certain S3 buckets and Secrets stored in the AWS Secrets Manager. 

Above, we created IAM roles for the shared services.  Now, we must create IAM roles for each Tidpool environment.

For you convenience, you may configure those IAM roles with the following helper function:
    
  ```bash
  $ ENVIRONMENTS=... env_roles
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
  $ ENVIRONMENT=... change_namespace 
  ```



## Install Flux

You must install the Flux GitOps operator and the (Helm) Tiller server with `make_flux`.  

#### Tiller

Flux communicatew with Tiller to install helm charts using TLS.  The Certificate Authority for this communication is generated on the fly. We store the CA credentials in AWS Secrets Manager so you can use a Helm client locally.  We create a TLS certificate for your
Helm client and place it in your `${HELM_HOME:~/.helm}`.    

### GitHub

[Flux](https://flux-cd.readthedocs.io/en/latest/install/standalone-setup.html#add-an-ssh-deploy-key-to-the-repository) can update your config repo whenerer new images are published to your Docker image repot (e.g. DockerHub).  To do this, your Git server (e.g. GitHub) must be configured to allow flux permission to make changes.  You do this on GitHub by providing a [deploy key](https://developer.github.com/v3/guides/managing-deploy-keys/), which is the public key of your flux server. Export a value called `GITHUB_TOKEN` with permission [to write to the repo].

### Example

   ```bash
     $ make_flux
     Cloning into 'tidepool-quickstart'...
     remote: Enumerating objects: 303, done.
     remote: Counting objects: 100% (303/303), done.
     remote: Compressing objects: 100% (227/227), done.
     remote: Total 303 (delta 138), reused 224 (delta 70), pack-reused 0
     Receiving objects: 100% (303/303), 85.55 KiB | 2.95 MiB/s, done.
     Resolving deltas: 100% (138/138), done.
     Cloning into 'cluster-test1'...
     remote: Enumerating objects: 1003, done.
     remote: Total 1003 (delta 0), reused 0 (delta 0), pack-reused 1003
     Receiving objects: 100% (1003/1003), 244.05 KiB | 1.74 MiB/s, done.
     Resolving deltas: 100% (541/541), done.
     NAME    VERSION STATUS  CREATED                 VPC                     SUBNETS                                                                                                                                                      SECURITYGROUPS
     test1   1.14    ACTIVE  2019-09-13T01:54:44Z    vpc-0e7ecff91e6db74e4   subnet-01ea9f26a8346827e,subnet-033bf2fdaf6b14e17,subnet-048c287b8348c5070,subnet-0546210ba442e5d03,     subnet-07db5f084b935aadd,subnet-0be0e45d834f18c4a   sg-0574016742342f753
     [i] installing flux in cluster test1
     [ℹ]  Generating public key infrastructure for the Helm Operator and Tiller
     [ℹ]    this may take up to a minute, please be patient
     [!]  Public key infrastructure files were written into directory "/var/folders/m1/9nxmym25533_5khp4gsv89fc0000gn/T/eksctl-helm-pki924701860"
     [!]  please move the files into a safe place or delete them
     [ℹ]  Generating manifests
     [ℹ]  Cloning git@github.com:tidepool-org/cluster-test1.git
     Cloning into '/var/folders/m1/9nxmym25533_5khp4gsv89fc0000gn/T/eksctl-install-flux-clone-487086515'...
     remote: Enumerating objects: 1003, done.
     remote: Total 1003 (delta 0), reused 0 (delta 0), pack-reused 1003
     Receiving objects: 100% (1003/1003), 244.05 KiB | 2.28 MiB/s, done.
     Resolving deltas: 100% (541/541), done.
     Already on 'master'
     Your branch is up to date with 'origin/master'.
     [ℹ]  Writing Flux manifests
     [ℹ]  created "Namespace/flux"
     [ℹ]  Applying Helm TLS Secret(s)
     [ℹ]  created "flux:Secret/tiller-secret"
     [ℹ]  created "flux:Secret/flux-helm-tls-cert"
     [!]  Note: certificate secrets aren't added to the Git repository for security reasons
     [ℹ]  Applying manifests
     [ℹ]  created "flux:Secret/flux-git-deploy"
     [ℹ]  created "flux:Deployment.apps/memcached"
     [ℹ]  created "flux:Service/memcached"
     [ℹ]  created "flux:ServiceAccount/flux"
     [ℹ]  created "ClusterRole.rbac.authorization.k8s.io/flux"
     [ℹ]  created "ClusterRoleBinding.rbac.authorization.k8s.io/flux"
     [ℹ]  created "flux:Deployment.apps/flux-helm-operator"
     [ℹ]  created "flux:ConfigMap/flux-helm-tls-ca-config"
     [ℹ]  created "flux:ServiceAccount/flux-helm-operator"
     [ℹ]  created "ClusterRole.rbac.authorization.k8s.io/flux-helm-operator"
     [ℹ]  created "ClusterRoleBinding.rbac.authorization.k8s.io/flux-helm-operator"
     [ℹ]  created "CustomResourceDefinition.apiextensions.k8s.io/helmreleases.helm.fluxcd.io"
     [ℹ]  created "flux:Deployment.extensions/tiller-deploy"
     [ℹ]  created "flux:Service/tiller-deploy"
     [ℹ]  created "flux:ServiceAccount/tiller"
     [ℹ]  created "ClusterRoleBinding.rbac.authorization.k8s.io/tiller"
     [ℹ]  created "flux:ServiceAccount/helm"
     [ℹ]  created "flux:Role.rbac.authorization.k8s.io/tiller-user"
     [ℹ]  created "kube-system:RoleBinding.rbac.authorization.k8s.io/tiller-user-binding"
     [ℹ]  created "flux:Deployment.apps/flux"
     [ℹ]  Waiting for Helm Operator to start
     [ℹ]  Helm Operator started successfully
     [ℹ]  see https://docs.fluxcd.io/projects/helm-operator for details on how to use the Helm Operator
     [ℹ]  Waiting for Flux to start
     [ℹ]  Flux started successfully
     [ℹ]  see https://docs.fluxcd.io/projects/flux for details on how to use Flux
     [ℹ]  Committing and pushing manifests to git@github.com:tidepool-org/cluster-test1.git
     [master f87037d] Add Initial Flux configuration
      3 files changed, 302 insertions(+), 38 deletions(-)
      create mode 100644 flux/flux-deployment.yaml
      create mode 100644 flux/helm-operator-deployment.yaml
      rewrite flux/tiller-ca-cert-configmap.yaml (87%)
     Enumerating objects: 7, done.
     Counting objects: 100% (7/7), done.
     Delta compression using up to 12 threads
     Compressing objects: 100% (4/4), done.
     Writing objects: 100% (4/4), 1.76 KiB | 1.76 MiB/s, done.
     Total 4 (delta 2), reused 0 (delta 0)
     remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
     To github.com:tidepool-org/cluster-test1.git
        3b3a8ff..f87037d  master -> master
     [ℹ]  Flux will only operate properly once it has write-access to the Git repository
     [ℹ]  please configure git@github.com:tidepool-org/cluster-test1.git so that the following Flux SSH public key has write access to it
     ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLsTE7W1LUMYQ0uWh9yxfbye2weREb6w4zlljFAKipSoapj0i+elOnRxV36lS21HyDY4JdPfjG9PuRnO/Em0o43zRB/yH8fawLCJky7KRE6b/     lPovyJ4xsLxDNwAJUxubNFn1qvsXe4BzprkjNn9MPiRN4GvwDTLviCO27YhecPQcmSwYARBF+Ul+/TLccY6OeGO7QP6mygJE     +9uhSlsjnN7WWMjlmgKyl3DvfMeM34o4f3nkN2puDueASpVAK2FxSHOuHFaCp3pztjzek1AaioZjY2pPt3FUG9AGPFqq67V4c7nE0ZmPk/dbQzvwB+wC8vp3/NtS+Y050u2k7Oj/N
     remote: Enumerating objects: 4, done.
     remote: Counting objects: 100% (4/4), done.
     remote: Compressing objects: 100% (2/2), done.
     remote: Total 4 (delta 2), reused 4 (delta 2), pack-reused 0
     Unpacking objects: 100% (4/4), done.
     From github.com:tidepool-org/cluster-test1
        3b3a8ff..f87037d  master     -> origin/master
     Updating 3b3a8ff..f87037d
     Fast-forward
      flux/flux-deployment.yaml          | 157 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      flux/helm-operator-deployment.yaml | 107 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      flux/tiller-ca-cert-configmap.yaml |  52 +++++++++++++++++++--------------------
      3 files changed, 290 insertions(+), 26 deletions(-)
      create mode 100644 flux/flux-deployment.yaml
      create mode 100644 flux/helm-operator-deployment.yaml
     Current branch master is up to date.
     [i] saving ca pem and key to AWS secrets manager
     {
         "ARN": "arn:aws:secretsmanager:us-west-2:118346523422:secret:test1/flux/ca.pem-YtjhkS",
         "Name": "test1/flux/ca.pem",
         "LastChangedDate": 1568335679.261,
         "LastAccessedDate": 1568332800.0,
         "VersionIdsToStages": {
             "bf829637-9e34-4074-9860-c37ca11aeded": [
                 "AWSPREVIOUS"
             ],
             "c531506f-65ef-46db-aa86-0d7965275ded": [
                 "AWSCURRENT"
             ]
         }
     }
     {
         "ARN": "arn:aws:secretsmanager:us-west-2:118346523422:secret:test1/flux/ca.pem-YtjhkS",
         "Name": "test1/flux/ca.pem",
         "VersionId": "290ad64f-4838-458a-adf7-0408a07cd417"
     }
     {
         "ARN": "arn:aws:secretsmanager:us-west-2:118346523422:secret:test1/flux/ca-key.pem-2eHODg",
         "Name": "test1/flux/ca-key.pem",
         "VersionId": "01b402e8-63ab-4bd2-ac34-afc6280a6ea1"
     }
     [i] installing helm client cert for cluster test1
     [i] retrieving ca.pem from AWS secrets manager
     [i] retrieving ca-key.pem from AWS secrets manager
     [i] creating cert in /Users/derrickburns/.helm/clusters/test1
     2019/09/12 19:30:54 [INFO] generate received request
     2019/09/12 19:30:54 [INFO] received CSR
     2019/09/12 19:30:54 [INFO] generating key: rsa-4096
     2019/09/12 19:30:55 [INFO] encoded CSR
     2019/09/12 19:30:55 [INFO] signed certificate with serial number 587458340608176870727716153014044100274825898618
     [i] done
     [i] authorizing access to git@github.com:tidepool-org/cluster-test1
     HTTP/1.1 201 Created
     Date: Fri, 13 Sep 2019 02:47:14 GMT
     Content-Type: application/json; charset=utf-8
     Content-Length: 632
     Server: GitHub.com
     Status: 201 Created
     X-RateLimit-Limit: 5000
     X-RateLimit-Remaining: 4999
     X-RateLimit-Reset: 1568346434
     Cache-Control: private, max-age=60, s-maxage=60
     Vary: Accept, Authorization, Cookie, X-GitHub-OTP
     ETag: "5c603737d49a08d0b44452ccbcc03fe5"
     X-OAuth-Scopes: admin:public_key, repo
     X-Accepted-OAuth-Scopes:
     Location: https://api.github.com/repos/tidepool-org/cluster-test1/keys/37593956
     X-GitHub-Media-Type: github.v3; format=json
     Access-Control-Expose-Headers: ETag, Link, Location, Retry-After, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes,      X-Poll-Interval, X-GitHub-Media-Type
     Access-Control-Allow-Origin: *
     Strict-Transport-Security: max-age=31536000; includeSubdomains; preload
     X-Frame-Options: deny
     X-Content-Type-Options: nosniff
     X-XSS-Protection: 1; mode=block
     Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
     Content-Security-Policy: default-src 'none'
     Vary: Accept-Encoding
     X-GitHub-Request-Id: D88A:563A:33B1FA:3DA64E:5D7B0332
     
     {
       "id": 37593956,
       "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLsTE7W1LUMYQ0uWh9yxfbye2weREb6w4zlljFAKipSoapj0i+elOnRxV36lS21HyDY4JdPfjG9PuRnO/Em0o43zRB/yH8fawLCJky7KRE6b/     lPovyJ4xsLxDNwAJUxubNFn1qvsXe4BzprkjNn9MPiRN4GvwDTLviCO27YhecPQcmSwYARBF+Ul+/TLccY6OeGO7QP6mygJE     +9uhSlsjnN7WWMjlmgKyl3DvfMeM34o4f3nkN2puDueASpVAK2FxSHOuHFaCp3pztjzek1AaioZjY2pPt3FUG9AGPFqq67V4c7nE0ZmPk/dbQzvwB+wC8vp3/NtS+Y050u2k7Oj/N",
       "url": "https://api.github.com/repos/tidepool-org/cluster-test1/keys/37593956",
       "title": "flux key for test1 created by make_flux",
       "verified": true,
       "created_at": "2019-09-13T02:47:14Z",
       "read_only": false
     }
     Already up to date.
     Current branch master is up to date.
     [i] updating flux and flux-helm-operator manifests
     [i] commiting repo
     [master b3e3490] Added tidepool environments
      2 files changed, 264 deletions(-)
      delete mode 100644 flux/flux-deployment.yaml
      delete mode 100644 flux/helm-operator-deployment.yaml
     Enumerating objects: 5, done.
     Counting objects: 100% (5/5), done.
     Delta compression using up to 12 threads
     Compressing objects: 100% (3/3), done.
     Writing objects: 100% (3/3), 309 bytes | 309.00 KiB/s, done.
     Total 3 (delta 2), reused 0 (delta 0)
     remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
     To github.com:tidepool-org/cluster-test1
        ddc0e1d..b3e3490  master -> master
     [i] done
   ```

 
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
  external-dns        
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
  $ set_kiam_trust ${CLUSTER_NAME} 
  ```

## How To Store Secrets in Your PRIVATE Git Repo

Instead of storing secrets in the AWS Secrets Manager using the `external-secrets` service to retrieve them, you may 
provide the secrets in any way that you please, as long as they become Kubernetes `Secret` resources with the proper names.

### Using a Private Git Repo

One simply alternative is to store the secrets (after `base64` encoding the values) in a *private* Git config repo.  Simply commit your `Secret` manifests to your Git config repo. 


