# jellyfish

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| configmap.enabled | bool | `false` |  |
| deployment.env.store.s3.bucket | string | `"data"` |  |
| deployment.env.type | string | `"file"` |  |
| deployment.image | string | `"tidepool/jellyfish:master-latest"` |  |
| deployment.replicas | int | `1` |  |
| enabled | bool | `true` |  |
| hpa.enabled | bool | `false` |  |
| hpa.minReplicas | int | `1` |  |
| mongo.secretName | string | `"mongo"` |  |
| nodeEnvironment | string | `"production"` |  |
| nodeSelector | object | `{}` |  |
| pdb.enabled | bool | `false` |  |
| pdb.minAvailable | string | `"50%"` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| serviceAccount.create | bool | `false` |  |
| store.database | string | `"data"` |  |
| store.prefix | string | `""` |  |
| tolerations | list | `[]` |  |
