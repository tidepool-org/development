## Routing to Tidepool Environments

We can run multiple versions of a Tidepool environment within a
single Kubernetes cluster. To do so, we associate each version with
its own Kubernetes `namespace`. The name of the environment is the
name of the namespace.


### External Addressing

To address a particular environment, we
associate with each namespace a distinct DNS name. The DNS
name is composed by concatenating the name of the environment
with the with the domain, e.g. `qa1.tidepool.org`.

Multiple environments within a single Kubernetes cluster are served
by a single Amazon load balancer.  Consequently, all the DNS names
are aliased to DNS name of the load balancer.  Note that the DNS
name of the load balancer *cannot* be used to address the services
if:
1. https access is utilized or 
1. multple environments are served in the same cluster.
In the `https` case, the hostname is needed to determine which TLS
certificate to use.
In the `multiple environment` case, the hostname is needed to determine
which instance to route traffic to.

To serve `https`, one must provide a TLS certificate as a Kubernetes secret.

### Internal Addressing

Once traffic hits the load balancer, it is directed based on the
hostname to one of the environments.  If the request hits a service
that must communicate with a peer service, then the API gateway can
be used to route to the peer service.  To do so, the API gateway
needs a way of identifying which peer service to route to.  We
use host-based routing, where the hostname is an internal name with the 
name prefixed with the name of the environment, e.g.
`qa1.gateway-proxy.svc.cluster.local`. In this way, different
environments from within the Kubernetes cluster an be addressed
without the need to use or even establish an external DNS entry.

### Peer to Peer Communication

Services within Kubernetes, excluding the external gateway, use
`http` for communication, with an optional `mTLS` overlay provided
by a service mesh.  In this design, the services need not be
provisioned with certificates. The service mesh overlay provides
secure communication by rotating certificates provided by the
mesh.  This `zero trust` design provides secure communication,
satisfying one of the requirements for HIPAA complaince.

### Adding Routes

To add a route to a service, modify the "tidepool.org/config"
annotation of the service manifest.  We use the notation of [Ambassador
Mappings](https://www.getambassador.io/reference/mappings/), except
that the annotation key is `tidepool.org/config` and the `apiVersion`
is `tidepool/v1alpha`.
```

Note the use of Helm templating to get values for host, namespace,
and port.  Use of these templates is required in order that the
mappings may be properly parameterized.

#### Using Gloo

To generate an API gateway using Gloo, run the
`gloo_gateway` tool to generate an API gateway using Gloo. This
tool will produce two helm templated files `gloo-http.yaml` and
`gloo-https.yaml` that define the API Gateway.  Include these in
the definition of the helm template for the Tidepool services in
directory `charts/tidepool/$VERSION/templates/`.

#### Using Istio [Tool is untested]

To generate an API gateway using Istio, run the
`istio_gateway` tool to generate an API gateway using Istio. This
tool will produce two helm templated files `istio-http.yaml` and
`istio-https.yaml` that define the API Gateway.  Include these in
the definition of the helm template for the Tidepool services in
directory `charts/tidepool/$VERSION/templates/`.

