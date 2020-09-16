# hydrophone

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| deployment.env.fromAddress | string | `"Tidepool <noreply@tidepool.org>"` |  |
| deployment.env.store.s3.bucket | string | `"asset"` |  |
| deployment.image | string | `"tidepool/hydrophone:master-latest"` | Docker image |
| deployment.replicas | int | `1` |  |
| hpa.enabled | bool | `false` | whether to create a horizontal pod autoscalers for all pods of given deployment |
| hpa.maxReplicas | string | `nil` | maximum number of replicas that HPA will maintain |
| hpa.minReplicas | int | `1` | minimum number of replicas that HPA will maintain |
| livenessProbe.enabled | bool | `false` |  |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| livenessProbe.path | string | `"/live"` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| mongo.secretName | string | `"mongo"` |  |
| nodeSelector | object | `{}` |  |
| pdb.enabled | bool | `false` |  |
| pdb.minAvailable | string | `"50%"` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| readinessProbe.enabled | bool | `true` |  |
| readinessProbe.initialDelaySeconds | int | `30` |  |
| readinessProbe.path | string | `"/status"` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| serviceAccount.create | bool | `false` |  |
| tolerations | list | `[]` |  |
