# glooingress

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.3.2](https://img.shields.io/badge/AppVersion-1.3.2-informational?style=flat-square)

A Helm chart to use Gloo for Tidepool ingress

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Derrick Burns | derrick@tidepool.org |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| discovery | object | `{}` |  |
| enabled | bool | `true` | whether to enable the Gloo API Gateway integration |
| extauth.enabled | bool | `false` |  |
| global.gateway.proxy | object | `{"name":"gateway-proxy","port":80}` | name of the Gloo gateway proxy that will host the virtual service |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| virtualServices.http.dnsNames[0] | string | `"localhost"` |  |
| virtualServices.http.enabled | bool | `true` | whether to accept HTTP requests  |
| virtualServices.http.labels | object | `{}` |  |
| virtualServices.http.name | string | `"http"` | DNS names served with HTTP  |
| virtualServices.http.options | object | `{}` |  |
| virtualServices.http.redirect | bool | `false` | whether to redirect HTTP requests to HTTPS |
| virtualServices.httpInternal.labels | object | `{}` |  |
| virtualServices.httpInternal.name | string | `"http-internal"` |  |
| virtualServices.httpInternal.options | object | `{}` |  |
| virtualServices.https | object | `{"dnsNames":[],"enabled":false,"hsts":false,"labels":{},"name":"https","options":{}}` | DNS names served with HTTPS |
