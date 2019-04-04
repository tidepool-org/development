This directory stores the configuration for several separate instances of the Tidepool services.  Each instance is defined in a subdirectory of the `namespaced` directory.

### GitOps
To make changes to a Tidepool instance, simply change the manifests in the subdirectory of the `namespaced` directory.  N.B. The directory
structure is *immaterial* to how the resources are utilized in Kubernetes.  To associate a manifest with a particular Tidepool instance, you *must*
set the namespace in the manifest.  This is how Kubernetes knows which Tidepool instance you intend to affect. 

### Mongo Storage
Each Tidepool instance has a separate instances of Mongo.  The storage is backed by a Kubernetes Persisent Volume.  Should the Mongo instance be restarted, the volume will continue to exist.

### Kubernetes Namespaces
Each Tidepool instance lives in separate Kubernetes namespace. 

### API Gateway - Shared
Each Tidepool instance share a single API Gateway that performs host-based routing to separate the traffic. 

### Weave - Shared
Each Tidepool instance requires the [Weave Flux](https://medium.com/@m.k.joerg/gitops-weave-flux-in-detail-77ce36945646) service to be running in the cluster.

### Usage and Configuration Notes

#### QA
QA1 is used by Derrick for testing new services.  
#### QA2
#### QA3
#### QA4

