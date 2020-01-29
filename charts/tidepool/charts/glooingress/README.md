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

## Gloo Virtual Services
This subchart creates your Gloo Virtual Services.  You may enable http and/or https access.  You may also redirect http to https.  In all cases, you must provide the domain names to route. 

## Deploying Gloo Control Plane in the Same Namespace
You may use the subchart to deploy the Gloo control plane within the same namespace as the Tidepool environment.
This configuration is desirable for testing where there are no other clients of the Gloo API gateway.

In this case, set the `gloo.enabled` flag to true.

The default configuration of Gloo will create two Gloo Gateway resources, one for HTTP traffic and one for HTTPS traffic.  The Gloo Virtual Services created by the chart will be associated with those Gateways.

## Deploying Gloo Control Plane in a Separate Namespace
If you deploy the Gloo control plane to a separate namesspace, you will need to associate the Gloo Virtual Services created by the chart with your Gloo Gateway resources. 

There are two ways to do so.  First, you may select all Virtual Services that match certain labels and appear in certain namespaces.  Second, you may name the virtual services explicitly.  For the former, you may provide labels.  For the latter, you may provie the names of the virtual services. 

If you are using http redirection or not using http access, then a special "internal" Virtual Service must be created that will accept http traffic that originates from Tidepool microservices. You may name that virtual service or provide labels for it.

Refer to the Gloo documentation on how to do associate Gloo Virtual Services with Gloo Gateways.

### TLS Termination

You may use the Gloo virtual services to terminate HTTPS traffic. Simply store the TLS certificate and provide the name of the secret (which must be in the same namespace).

## Configuration Parameters

The following tables lists the configurable parameters of the chart and their default values.


| Parameter                                            | Description                                                                               | Default                             |  
|------------------------------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------|
| `discovery.namespace`                    | namespace where the gloo upstreams are stored                                             |  release namespace                  |
| `enabled`                                | whether to enable the Gloo integrations                                                   | `true`                              |
| `global.gateway.proxy.port`                     | port of the gateway proxy                                                                 | `80`                                |
| `global.gateway.proxy.name`                     | name of the proxy to use for this gateway                                                 | `gateway-proxy`                     |
| `globa.gateway.proxy.namespace`                | namespace of the proxy to use for this gateway                                            | release namespace                   |
| `gloo.enabled`                           | whether to install the Gloo control plane                                                 | `false`                             |
| `gloo.crds.create`                       | whether to install the Gloo crds                                                          | `true`                              |
| `routeTable.name`                        | name to use for the Gloo RouteTable                                                       | release namespace                   |
| `virtualServices.http.enabled`           | whether to enable http ingress                                                            | `true`                              |  
| `virtualServices.http.name`              | name of the Gloo http virtual service                                                     | `http`                              |  
| `virtualServices.http.labels`            | labels to apply to http virtual service                                                   | {}                                  |  
| `virtualServices.http.port`              | port to listen on                                                                         | 80                                  |  
| `virtualServices.http.redirect`          | whether to redirect http to https                                                         | `false`                             |  
| `virtualServices.httpInternal.name`      | name of the Gloo http internal virtual service                                            | `http-internal`                     |  
| `virtualServices.httpInternal.labels`    | labels to apply to http internal virtual service                                          | { }                                 |  
| `virtualServices.https.certificateSecretName` | name of secret holding TLS certificate                                               | `https-certificate`                 |  
| `virtualServices.https.dnsNames`         | list of Subject Alternative Names to use                                                  | `[]`                                |  
| `virtualServices.https.enabled`          | whether to enable https ingress                                                           | `false`                             |  
| `virtualServices.https.hsts`             | whether to enable strict transport security                                               | `false`                             |  
| `virtualServices.https.labels`           | labels to apply to https virtual service                                                  | { }                                 |  
| `virtualServices.https.name`             | name of the Gloo http virtual service                                                     | `http`                              |  
| `virtualServices.https.port`             | port to listen on                                                                         | 443                                 |  
| `gloo.enabled`                           | whether to install Gloo helm chart                                                        | `false`                             |  
