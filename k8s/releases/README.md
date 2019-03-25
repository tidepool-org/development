This directory stores the configuration for two separate instances of the Tidepool backend, `qa1` and `qa2`.

##### Mongo Storage
They have separate instances of Mongo.  

##### Kubernetes Namespaces
They live in separate Kubernetes namespaces. 

##### API Gateway - Shared
They share a single API Gateway that performs host-based routing to separate the traffic. 

##### GitOps
They share a single branch `qa` of the `dev-ops` repo for GitOps.  Changes are reflected in different files: `tidepool-qa1.yaml` and `tidepool-qa2.yaml`.

##### Weave Configuration
`qa1` will NOT auto update using Weave flux.  `qa2` will.
