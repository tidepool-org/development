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
| enabled | bool | `true` |  |
| global.gateway.proxy.name | string | `"gateway-proxy"` |  |
| global.gateway.proxy.port | int | `80` |  |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| virtualServices.http.dnsNames[0] | string | `"localhost"` |  |
| virtualServices.http.enabled | bool | `true` |  |
| virtualServices.http.extauth.enabled | bool | `false` |  |
| virtualServices.http.jwt.enabled | bool | `false` |  |
| virtualServices.http.labels | object | `{}` |  |
| virtualServices.http.name | string | `"http"` |  |
| virtualServices.http.options | object | `{}` |  |
| virtualServices.http.redirect | bool | `false` |  |
| virtualServices.httpInternal.extauth.enabled | bool | `false` |  |
| virtualServices.httpInternal.jwt.enabled | bool | `false` |  |
| virtualServices.httpInternal.labels | object | `{}` |  |
| virtualServices.httpInternal.name | string | `"http-internal"` |  |
| virtualServices.httpInternal.options | object | `{}` |  |
| virtualServices.https.dnsNames | list | `[]` |  |
| virtualServices.https.enabled | bool | `false` |  |
| virtualServices.https.extauth.enabled | bool | `false` |  |
| virtualServices.https.hsts | bool | `false` |  |
| virtualServices.https.jwt.enabled | bool | `false` |  |
| virtualServices.https.labels | object | `{}` |  |
| virtualServices.https.name | string | `"https"` |  |
| virtualServices.https.options | object | `{}` |  |
