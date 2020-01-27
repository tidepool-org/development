# Overview
This subchart provides support for using Gloo API Gateway by Solo.io for Ingress and routing.

Gloo offer supports for host and HTTP method based routing decisions, as well as timeouts and retries, features needed
at present by the Tidepool service.

## Configuration
Ingress is simple in theory, but complicated in practice.  To deal with the complexity, this helm chart offers
a number of parameters that may be changed in order to support various use cases. 

Key questions are:
1. Does your ingress support http only, http and https, or http redirect to https?
1. Do you run the Gloo control plane in the same namespace as the Tidepool services?

Answers to these design questions will dictate how you configure this helm chart.

## Deploying Gloo Control Plane in the Same Namespace
You may use the subchart to deploy the Gloo control plane within the same namespace as the Tidepool environment.
This configuration is desirable for testing where there are no other clients of the Gloo API gateway.

In this case, set the `gloo.enabled` flag to true.

## Deploying Gloo Control Plane in a Separate Namespace
You may use this subchart to create Gloo Virtual Services that are consumed by a Gloo Gateway of your choosing.
These are enabled by default and provided labels.  You may use these labels to associate the Virtual Services with your Gateway.

### Gloo Gateways
Your Gloo Gateway resources must be created in the same namespace as your Gloo Gateway Proxies (data plane). Hence, if you want 
to isolate your traffic in a proxy in the same namespace as the Tidepool environment, you will want to create a Gateway resource in
the same namespaces.  

#### Gateway in Same Namespace
You may use this subchart to create a Gloo Gateway in the same namespace. 

To do this, set `internalGatewayProxy.enabled` to `true`.  This will create an http-only ingress.

#### Gateway in Different Namespace
If you are sharing a Gloo Gateway, you may not, you may not want to install Gloo in the same namespace as Tidepool.  This configuration makes
sense if there are multiple Tidepool environments sharing a single Gloo Gateway, or the Gloo Gateway is also used by other non-Tidepool services.

In this case, you may use the `virtualServiceNamespace` field and/or the `virtualServiceSelectors` field of the Gateway resource to associate
the virtual services with your external Gateway.

## Gloo Virtual Services
This subchart creates your Gloo Virtual Services.  You may enable http and/or https access.  You may also redirect http to https.
In all cases, you must provide the domain names to route. 

### HTTP Redirect

### TLS Termination

## Configuration

The following tables lists the configurable parameters of the chart and their default values.


| Parameter                                            | Description                                                                               | Default                             |  
|------------------------------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------|
| `discovery.namespace`                    | namespace where the gloo upstreams are stored                                             |  release namespace                  |
| `gateway.proxy.name`                     | name of the proxy to use for this gateway                                                 | `gateway-proxy`                     |
| `gateway.proxy.namespace`                | namespace of the proxy to use for this gateway                                            | release namespace                   |
| `gloo.enabled`                           | whether to install the Gloo control plane                                                 | `false`                             |
| `gloo.crds.create`                       | whether to install the Gloo crds                                                          | `true`                              |
| `routeTable.name`                        | name to use for the Gloo RouteTable                                                       | release namespace                   |
| `virtualServices.http.enabled`           | whether to enable http ingress                                                            | `true`                              |  
| `virtualServices.http.labels`            | labels to apply to http virtual service                                                   | {}                                  |  
| `virtualServices.http.port`              | port to listen on                                                                         | 80                                  |  
| `virtualServices.http.redirect`          | whether to redirect http to https                                                         | `false`                             |  
| `virtualServices.https.certificateSecretName` | name of secret holding TLS certificate                                               | `https-certificate`                 |  
| `virtualServices.https.dnsNames`         | list of Subject Alternative Names to use                                                  | `[]`                                |  
| `virtualServices.https.enabled`          | whether to enable https ingress                                                           | `false`                             |  
| `virtualServices.https.hsts`             | whether to enable strict transport security                                               | `false`                             |  
| `virtualServices.https.labels`           | labels to apply to https virtual service                                                  | { }                                 |  
| `virtualServices.https.port`             | port to listen on                                                                         | 443                                 |  
| `gloo.enabled`                           | whether to install Gloo helm chart                                                        | `false`                             |  
