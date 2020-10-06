# marketo

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| configmap.data_.ClinicRole | string | `"clinic"` |  |
| configmap.data_.PatientRole | string | `"user"` |  |
| configmap.data_.Timeout | string | `"15000000"` |  |
| nodeSelector | object | `{}` |  |
| secret.data_.ID | string | `""` |  |
| secret.data_.Secret | string | `""` |  |
| secret.data_.URL | string | `""` |  |
| secret.enabled | bool | `false` |  |
| tolerations | list | `[]` |  |
