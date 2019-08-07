# Overview

This document describes the major components and service providers that we rely on run Tidepool services in Kubernetes, and seeks to answer some of the common questions that arise during operation.  

Importantly, this document does *not* address the problem of initiating service with a cloud service vendor, such as setting up user accounts and permissions, auditing, or reporting.  These administrative services are necessary, but out of scope for this document.  Much of what is written here is independent of cloud vendor. 

Nevertheless, we do rely on our cloud vendor to provide ancillary services that are orthogonal to and managed outside of Kubernetes, such as auditing. Please refer to these documents for information on auditing:

* [AWS S3 Logging](https://github.com/tidepool-org/ops/tree/develop/aws#setup-aws-s3-logging)
* [AWS CloudTrail](https://github.com/tidepool-org/ops/tree/develop/aws#setup-aws-cloudtrail)
* [AWS ELB Access Logging](https://github.com/tidepool-org/ops/tree/develop/aws#setup-aws-elb-access-logging)
* [AWS Config](https://github.com/tidepool-org/ops/tree/develop/aws#setup-aws-config)

## Tidepool Helm Chart

We use the [helm](https://helm.sh/) tool to parameterize the configuration of a Tidepool service.  Our [Helm chart](https://github.com/tidepool-org/development/tree/k8s/charts/tidepool/0.1.5) can be used both for production and for local development.

The [development repo](https://github.com/tidepool-org/development/blob/k8s/k8s/README.md) contains other resources to help you set up your own local development environment.

## Service Providers 

We outsource as much as we can so that we can focus on diabetes software.  This section describes the third party providers of services that we leverage to provide Tidepool services.

### Compute, Storage, Email, and DNS

Our cloud vendor for compute, storage, and email is Amazon AWS. 

We host our Kubernetes clusters on Amazon.  Specifically, we use the Amazon managed Kubernetes service called [EKS](https://aws.amazon.com/eks/).  EKS manages the Kubernetes control plane components.  We manage the worker nodes. 

We store object data in Amazon S3. 

We send email for account activation using Amazon SES.

Alternatives to these offerings are readily available.  Consequently, there is minimal vendor lock-in as a result of using these services.

### Mongo Database 

We host our Mongo database on [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).  

This is a 2019 change from self-hosting Mongo databases on bare virtual machines.  We chose to migrate to a hosted environment to shift the burden of database backup and VM maintenance to a vendor that specializes in that service. This decision is reversible, however our dependency on MongoDB itself is strong.  Migrating to another database (such as Elasticsearch, Postgres, etc.) would be a major undertaking.

### User Metrics

We send usage data to [KissMetrics](https://www.kissmetricshq.com/) through a single microservice called `highwater`.

### Mailing Lists

We manage our email lists with [MailChimp](https://mailchimp.com/) through a single microservice called `shoreline`.

### Diabetes Data Integration

For customers that provide their data to Dexcom through Dexcom devices, we provide the option to link that data to Tidepool via the [Dexcom API](https://developer.dexcom.com/) through a single microservice called `task`.

### Telemetry

We publish cluster and node level metrics to [Datadog](https://www.datadoghq.com/).  This allows us to inspect the state of our Kubernetes cluster from outside the cluster.

## Third-party Components

We use a number of well-documented open source components to manage our infrastructure. Please refer to the documentation of these components for details on how to use them.

### Cluster Creation with eksctl

We use the WeaveWorks [eksctl](https://eksctl.io/) tool to create and manage EKS clusters.  As of July 2019, this tool is under active development and is recognized as the best tool to create Kubernetes clusters on Amazon EKS.

### GitOps with Flux

We embrace the GitOps approach to configuration management: storing declarative infrastructure configuration as code in Git and using Git to drive all infrastructure updates.

We use [Flux](https://github.com/fluxcd/flux) to implement GitOps.  Specifically, Flux monitors a Git repo such as this one for changes and realizes those changes in the cluster that Flux is running in.  

Moreover, Flux monitors our Docker image repo (DockerHub) for changes and automatically updates this GitHub config repo with new image tags as images are published.

In July 2019, Flux was [adopted into the CNCF sandbox](https://github.com/fluxcd/flux/wiki/MoveToFluxCD).

### API Gateway with Gloo

We use [Gloo](https://gloo.solo.io/) as the API Gateway. Gloo routes incoming traffic from a AWS load balancer to the appropriate service, identified by a combination of the target host (HTTP2 :authority), path, and HTTP method.

Because we can distinguish services by host, a single load balancer can accept traffic for multiple hosts. Moreover, Gloo supports SNI so we can provide a distinct TLS certificate per host, as needed.

### CPU Elasticity

Our architecture is compute elastic, meaning that as we observe changes in demand for much CPU resources, our infrastructure automatically adjusts our CPU resource allocation to accommodate the changes.  No human intervention is required.

Specifically, we use the Kubernetes cluster autoscaler and horizontal pod autoscalers to scale our CPU needs automatically.

#### Cluster/Node Autoscaling

The Kubernetes [cluster autoscaler](https://github.com/kubernetes/autoscaler) increases  compute capacity on demand.  After the autoscaler notices that there are a number of pods that are ready to be scheduled (called the `pending` state), it waits a small period to avoid oscillation.  Then, it allocates a new EC2 node in a node group with capacity (i.e. a node group that is part of an autoscaling group that is not at the maximum number of allowed nodes).  Similarly, if there are under-utilized nodes, the cluster autoscaler will scale down the number of nodes.

#### Pod Autoscaling

We use [Horizontal pod autoscalers](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) (one per service) to scale CPU as needed per service.

HPAs allocate an additional pod to a service that is using a substantial amount of its CPU limit. Similarly, if there are pods that are inactive, the HPA will scale down the number of pods.

### IAM Roles Assignment with kiam

Since we host our infrastructure on AWS, we leverage the [AWS Identity and Access Management](https://aws.amazon.com/iam/) (IAM) system to provide and limit access to AWS resources.

Several of the services need to access or modify Amazon resources.  To do this,your services must have IAM roles with policies that authorize such actions.  An IAM role is associated with the EC2 node that your service runs on.  One could create a policy that is the union of all policies needed for all services and associate that union with every node.  However, this violates the principle of least privilege.

We do not pass AWS credentials on disk or via environment variables. We use the metadata service available on all AWS EC2 nodes to authorize access.

We further limit what individual Kubernetes services can do by attaching specific IAM roles to Kubernetes services following the least privilege principle using [kiam](https://github.com/uswitch/kiam). This makes it impossible for a properly configured service to make improper access to AWS resources.  

When the `kiam` service starts, it has the power and privileges of the `NodeInstanceRole`.  However, because there may be multiple node groups, each with its own node instance role, we create a single IAM role for the cluster that may assume other more narrowly privileged roles.

### TLS Certificates Creation/Renewal with certmanager

We offer HTTPS access with valid TLS certificates for all Tidepool domains and subdomains.  Prior to the introduction of Kubernetes, these certificates were acquired, installed, and renewed manually.

We now use the [certmanager](https://github.com/jetstack/cert-manager) service to create, save, and renew TLS certificates.  This obviates the need to generate TLS certificates manually, and enables us to shorten the lifetime of the certificates, thereby decreasing one vector of attack.

### DNS Alias Publication with external-dns

Our public web services are advertised on DNS and fronted with AWS load balancers.  Prior to the introduction of Kubernetes, we created the association between the DNS aliases to AWS load balancers manually. 

With the introduction of Kubernetes, we use  the [external-dns](https://github.com/kubernetes-incubator/external-dns) service to publish DNS entries for domains that we own. This obviates the need to use AWS Route53 directly to manipulate DNS Aliases.  This also means that upon restart of any AWS load-balancer, the DNS entries will be automatically updated.

### Slack Notifications with fluxcloud

At any time we can inspect this Git repo to see the desired state of the Kubernetes cluster that it is associated with.  In addition, we provide access to a change log via notifications to a Slack channel.

We use [fluxcloud](https://github.com/justinbarrick/fluxcloud) to monitor changes to the cluster and to report them via Slack.

### Telemetry with Prometheus

We gather and publish service level metrics using [Prometheus](https://prometheus.io/).  We use sidecars to the Prometheus instances provided by the [Prometheus operator](https://github.com/coreos/prometheus-operator) to make the metrics available for aggregation by [Thanos](https://github.com/improbable-eng/thanos) in a separate cluster.

### Secrets Management with kubernetes-external-secrets and AWS Secrets Manager

We store our secrets using the [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).  
We use the [kubernetes-external-secrets](https://godaddy.github.io/2019/04/16/kubernetes-external-secrets/) service to load these secrets into Kubernetes Secrets objects at runtime and to update the Kubernetes cache of secrets upon change to the data stored in Amazon.

### Reloader

When secrets are updated, Kubernetes services that depend on these secrets must be notified in some way to use the new secrets.  

We use the [reloader](https://github.com/stakater/Reloader) to restart (stateless) services that are dependent on such secrets (and configmaps).   

