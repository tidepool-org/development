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
| secret.data_.ClientId | string | `""` |  |
| secret.data_.ClientSecret | string | `""` |  |
| secret.data_.StateSalt | string | `""` |  |
| secret.enabled | bool | `false` |  |
| tolerations | list | `[]` |  |
