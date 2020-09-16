# dexcom

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| configmap.enabled | bool | `true` |  |
| configmap.redirectURL | string | `""` |  |
| nodeSelector | object | `{}` |  |
| secret.data_.ClientId | string | `""` | plaintext Dexcom Oauth2 client id |
| secret.data_.ClientSecret | string | `""` | plaintext Dexcom Oauth2 client secret |
| secret.data_.StateSalt | string | `""` | plaintext Dexcom Oauth2 state salt |
| secret.enabled | bool | `false` | whether to create dexcom secret |
| tolerations | list | `[]` |  |
