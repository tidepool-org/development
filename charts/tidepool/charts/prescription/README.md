# prescription

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| deployment.env.store.s3.bucket | string | `"asset"` |  |
| deployment.image | string | `"tidepool/platform-prescription:master-latest"` |  |
| deployment.podAnnotations | object | `{}` |  |
| deployment.replicas | int | `1` |  |
| hpa.enabled | bool | `false` | whether to create a horizontal pod autoscalers for all pods of given deployment |
| hpa.maxReplicas | string | `nil` | maximum number of replicas that HPA will maintain |
| hpa.minReplicas | int | `1` | minimum number of replicas that HPA will maintain |
| mongo.secretName | string | `"mongo"` |  |
| nodeSelector | object | `{}` |  |
| pdb.enabled | bool | `false` |  |
| pdb.minAvailable | string | `"50%"` |  |
| resources | object | `{}` |  |
| secret.data_.ServiceAuth | string | `""` |  |
| secret.enabled | bool | `false` |  |
| securityContext | object | `{}` |  |
| tolerations | list | `[]` |  |
