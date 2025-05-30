# twiist

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key                       | Type | Default | Description                                     |
|---------------------------|------|---------|-------------------------------------------------|
| configmap.enabled         | bool | `false` | whether to generate a configmap                 |
| configmap.redirectURL     | string | `""` | OAuth2 redirect URL                             |
| configmap.tokenURL        | string | `""` | OAuth2 token URL                                |
| configmap.authorizeURL    | string | `""` | OAuth2 authorization URL                        |
| configmap.jwksURL         | string | `""` | jwks URL                                        |
| configmap.scopes          | string | `""` | OAuth2 scopes                                   |
| secret.enabled            | bool | `false` | whether to create a secret                      |
| secret.data_.clientId     | string | `""` | plaintext OAuth2 client id                      |
| secret.data_.clientSecret | string | `""` | plaintext OAuth2 client secret                  |
| secret.data_.stateSalt    | string | `""` | plaintext OAuth2 state salt                     |
----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.3.0](https://github.com/norwoodj/helm-docs/releases/v1.3.0)
