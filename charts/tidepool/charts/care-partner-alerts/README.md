# care-partner-alerts

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configmap.data_.APNSBundleID | string | `"org.tidepool.carepartner"` |  |
| configmap.data_.APNSKeyID | string | `"QA3495JW4S"` |  |
| configmap.data_.APNSTeamID | string | `"75U4X84TEG"` |  |
| configmap.enabled | bool | `true` |  |
| secret.data_.APNSSigningKey | string | `""` |  |
| secret.enabled | bool | `false` |  |

