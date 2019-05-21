## Routing to Tidepool Environments

A Tidepool `environment` is composed of three virtual services:
- app - the web service
- uploader - the legacy uploader
- api - the backend

We can run multiple versions of a Tidepool environment within a single Kubernetes cluster. To do so, we associate each version with its own 
Kubernetes `namespace`. The name of the environment is the name of the namespace.


### External Addressing
To address a particular environment, we associate with each namespace a distinct set of DNS names. The DNS names are composed by concatenating the name of the environment with the name of the virtual service (separated by a hyphen) with the tidepool.org domain, e.g. `qa1-app.tidepool.org`.

Multiple environments within a single Kuebernetes cluster are served by a single Amazon load balancer.  Consequently, all the DNS names are aliases to DNS name of the load balancer.  Note that the DNS name of the load balancer *cannot* be used to address the services.  The aliases
are needed so that the API gateway running within the Kubernetes cluster can disambiguate which environment is being addressed.  

Moreover, the Tidepool services are only accessible over https.  The certificate that authenticates the services has a wildcard name, `*.tidepool.org`.  So even if there were only a single environment served in the Kubernetes cluster, one still must address it with a hostname that matches the DNS wildcard name `*.tidepool.org`.  The DNS name of the load balancer does not satisfy this condition.

### Internal Addressing

Once traffic hits the load balancer, it is directed based on the host name to one of the environments.  If the request hits a service that
must communicate with a peer service, then the API gateway can be used to route to the peer service.  To do so, the API gateway needs a way
of identifying which peer service to route to.  Again, we can use host-based routing.  

However, instead of routing to an externally visible DNS name, e.g. `qa1-api.tidepool.org`, we route to an name that is only known within the
Kubernetes cluster, e.g. `qa1-api.gateway-proxy.svc.cluster.local`. In this way, different environments from within the Kubernetes cluster an be addressed without the need to use or even establish an external DNS entry. This is necessary for testing, where external DNS names may not be constructed. 

### Peer to Peer Communication

Services within Kubernetes, excluding the external gateway, use `http` for communication, with an optional `mTLS` overlay provided by a service mesh.  In this design, the services need not be provisioned with certificates. The service mesh overlay provides secure communication
with rotating certificated provided by the mesh.  This `zero trust` design provides secure communication, satisfying one of the requirements
for HIPAA complaince. 
