Input:

```
 Gateway
   []VirtualServices
      VirtualHost
        []Domain
        cors
        []Route
      SslConfig <- if used with TLS
        SecretRef (tls)
        []SniDomains
   bindAddress
   bindPort
   ssl : bool <- selects virtual services 
```

Output:

```
Proxy
  []Listeners
    bindAddress
    bindPort
    HttpListener
      []VirtualHost
```
### Local development or integration testing
For local development or integration testing (single domain, multi-port, without SSL) we need
a load balancer service that listens on separate ports for each virtual host: api, app, and uploads.
This load balancer sends traffic to a gateway proxy in the same namespace using the given selector.

```
  kind: Service
  type: LoadBalancer
  metadata:
     name: localhost-external
     namespace: gloo-system
  selector:
     gloo: gateway-proxy
  ports:
    -name: api
     protocol: tcp
     port: ${api-port}
     targetPort: ${api-port}
    -name: app
     protocol: tcp
     port: ${app-port}
     targetPort: ${app-port}
    -name: uploads
     protocol: tcp
     port: ${uploads-port}
     targetPort: ${uploads-port}
  annotations;
     Hostnames: - empty -
```
The Gateway resource creates routes to the gateway proxy service in the same namespace.
Since we can associate only a single port to a Gateway resource, we need three separate
Gateways resources. Each Gateway resource points to a single virtual service that
routes to the appropriate backend (api, app, or uploads). 

```
——
   kind: Gateway #(for external api traffic)
   bindAddress: “::”
   bindPort:  ${api-port}
   ssl : false
   metadata:
     namespace: gloo-system
     name: ${ns}-api-external
   virtualServices:
      - namespace: ${ns}
        name: ${ns}-api-localhost-external
——
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-api-localhost-external
      virtualHost
        domains:
          - localhost
        routes:
          ${api-routes}
——
   kind: Gateway #(for external app traffic)
   bindAddress: “::”
   bindPort:  ${app-port}
   ssl : false
   metadata:
     namespace: gloo-system
     name: ${ns}-app-external
   virtualServices:
      - namespace: ${ns}
        name: ${ns}-app-localhost-external
——
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-app-localhost-external
      virtualHost
        domains:
          - localhost
        routes:
          ${app-routes}
——
   kind: Gateway #(for external uploads traffic)
   bindAddress: “::”
   bindPort: ${uploads-port}
   ssl : false
   metadata:
     namespace: gloo-system
     name: ${ns}-uploads-external
   virtualServices:
      - namespace: ${ns}
        name: ${ns}-uploads-localhost-external
——
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-uploads-localhost-external
      virtualHost
        domains:
          - localhost
        routes:
          ${uploads-routes}
```
A single port is needed to route internal traffic.  Consequently, none of the other gateways can be
reused.  Therefore, we need a new, Gateway resource.  We configure it to listen to port 80, where we will
forward traffic via ExternalName services.
```
   kind: Gateway #(for internal traffic)
   metadata:
     namespace: ${ns}
     name: ${ns}-internal
   bindAddress: “::”
   bindPort: 80
   ssl: false 
   virtualServices:
     - namespace: ${ns}
       name: ${ns}-api-internal
     - namespace: ${ns}
       name: ${ns}-app-internal
     - namespace: ${ns}
       name: ${ns}-uploads-internal
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: {ns}-api-internal
      virtualHost
        domains:
          - ${ns}-api-internal
        routes:
          ${api-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: {ns}-app-internal
      virtualHost
        domains:
          - ${ns}-app-internal
        routes:
          ${app-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: {ns}-uploads-internal
      virtualHost
        domains:
          - ${ns}-uploads-internal
        routes:
          ${uploads-routes}

```
### For deployment using separate external host names using with https 
For deployment using separate external host names using with https (multi-domain, single port, with SSL), we need
a load balancer that listens on port 443 for traffic to the various host names.  It forward trafic to a proxy in
the same namespace, `gloo-system`, listening on port 443.

```
  kind: Service
  type: LoadBalancer
  metadata:
     name: external
     namespace: gloo-system
  selector:
     gloo: gateway-proxy
  ports:
   - protocol: tcp
     port: 443
     targetPort: 443
  annotations;
     hostnames: “${prefix}api.tidepool.org, ${prefix}api.tidepool.org, ${prefix}api.tidepool.org”
```
The gateway configures a proxy in the same namespace.
The gateway identifies three virtual services, one for each backend.
The virtual services configure the proxy associated with the gateway to supports CORS and to terminate
SSL traffic, using a hostname whose prefix is based on the namespace.  If the namespace is "production",
then the prefix is empty.  Otherwise, the prefix is the namespace followed by a hyphen.
```
   kind: Gateway #(for external traffic)
   metadata:
     namespace: gloo-system
     name: external-ssl

   bindAddress: “::”
   bindPort: 443
   ssl: true 
   virtualServices:
     - namespace: ${ns}
       name: ${ns}-api-external-ssl
     - namespace: ${ns}
       name: ${ns}-app-external-ssl
     - namespace: ${ns}
       name: ${ns}-uploads-external-ssl
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-api-external-ssl
      virtualHost
        domains:
          - ${prefix}api.tidepool.org
        cors
        routes:
          ${api-routes}
      sslConfig:
        SecretRef (tls)
          *.tidepool.org
—-
      kind: VirtualService
      metadata: 
        namespace: ${ns}
        name: ${ns}-app-external-ssl
      virtualHost
        domains:
          - ${prefix}app.tidepool.org
        cors
        routes:
          ${app-routes}
      sslConfig:
        SecretRef (tls)
          *.tidepool.org
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-uploads-external-ssl
      virtualHost
        domains:
          - ${prefix}uploads.tidepool.org
        cors
        routes:
          ${uploads-routes}
      sslConfig:
        SecretRef (tls)
          *.tidepool.org
```
For internal traffic, a separate gateway is needed because the internal traffic does not use SSL. 
This gateway is placed in a separate namespace.

```
   kind: Gateway #(for internal traffic)
   metadata:
     namespace: ${ns}
     name: ${ns}-internal
   bindAddress: “::”
   bindPort: 80
   ssl: false 
   virtualServices:
     - namespace: ${ns}
       name: ${ns}-api-internal
     - namespace: {ns}
       name: ${ns}-app-internal
     - namespace: {ns}
       name: ${ns}-uploads-internal
—— 
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-api-internal
      virtualHost:
        domains:
          - ${ns}-api-internal
        routes:
          ${api-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-app-internal
      virtualHost:
        domains:
          - ${ns}-app-internal
        routes:
          ${app-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-uploads-internal
      virtualHost:
        domains:
          - ${ns}-uploads-internal
        routes:
          ${uploads-routes}

```
For deployment with http (multi-domain, single port, without SSL), we need:
```
  kind: Service
  type: LoadBalancer
  metadata:
     name: external
     namespace: gloo-system
  selector:
     app: gateway-proxy
  ports:
   - protocol: tcp
     port: 80
     targetPort: 80
  annotations;
     hostnames: “${prefix}api.tidepool.org, ${prefix}api.tidepool.org, ${prefix}api.tidepool.org”
—
   kind: Gateway #(for external traffic)
   metadata:
     namespace: gloo-system
     name: external
   bindAddress: “::”
   bindPort: 80
   ssl: false 
   virtualServices:
     - namespace: ${ns}
       name: ${ns}-api-external
     - namespace: ${ns}
       name: ${ns}-app-external
     - namespace: ${ns}
       name: ${ns}-uploads-external
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-api-external
      virtualHost
        domains:
          - ${prefix}api.tidepool.org
        routes:
          ${api-routes}
—-
      kind: VirtualService
      metadata: 
        namespace: ${ns}
        name: ${ns}-app-external
      virtualHost
        domains:
          - ${prefix}app.tidepool.org
        routes:
          ${app-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-app-external
      virtualHost
        domains:
          - ${prefix}uploads.tidepool.org
        routes:
          ${uploads-routes}
——

   kind: Gateway #(for internal traffic)
   metadata:
     namespace: ${ns}
     name: ${ns}-internal
   bindAddress: “::”
   bindPort: 80
   ssl: false 
   virtualServices:
     - namespace: ${ns}
       name: ${ns}-api-internal
     - namespace: {ns}
       name: ${ns}-app-internal
     - namespace: {ns}
       name: ${ns}-uploads-internal
—— 
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-api-internal
      virtualHost:
        domains:
          - ${ns}-api-internal
        routes:
          ${api-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-app-internal
      virtualHost:
        domains:
          - ${ns}-app-internal
        routes:
          ${app-routes}
—-
      kind: VirtualService
      metadata:
        namespace: ${ns}
        name: ${ns}-uploads-internal
      virtualHost:
        domains:
          - ${ns}-uploads-internal
        routes:
          ${uploads-routes}
```
