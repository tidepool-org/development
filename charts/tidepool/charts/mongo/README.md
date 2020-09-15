# mongo

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| nodeSelector | object | `{}` |  |
| secret.data_.Addresses | string | `""` |  |
| secret.data_.Database | string | `""` |  |
| secret.data_.OptParams | string | `""` |  |
| secret.data_.Password | string | `""` |  |
| secret.data_.Scheme | string | `""` |  |
| secret.data_.Tls | string | `""` |  |
| secret.data_.Username | string | `""` |  |
| secret.enabled | bool | `false` |  |
| tolerations | list | `[]` |  |
