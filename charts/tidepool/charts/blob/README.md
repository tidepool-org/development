# blob

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| deployment.env.store.file.directory | string | `"_data/blobs"` | directory to use when storing blobs on file storage |
| deployment.env.store.file.prefix | string | `"blobs"` |  |
| deployment.env.store.s3.bucket | string | `"data"` | S3 bucket where blob data is written |
| deployment.env.store.s3.prefix | string | `"blobs"` |  |
| deployment.env.store.type | string | `"file"` | if `s3`, store blob data in Amazon S3. If `file` store blob data in local files. |
| deployment.image | string | `"tidepool/platform-blob:master-latest"` | default Docker image |
| deployment.replicas | int | `1` |  |
| hpa.enabled | bool | `false` | whether to create a horizontal pod autoscalers for all pods of given deployment |
| hpa.maxReplicas | string | `nil` | maximum number of replicas that HPA will maintain |
| hpa.minReplicas | int | `1` | minimum number of replicas that HPA will maintain |
| mongo.secretName | string | `"mongo"` |  |
| nodeSelector | object | `{}` |  |
| pdb.enabled | bool | `false` |  |
| pdb.minAvailable | string | `"50%"` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| resources | object | `{}` |  |
| secret.data_.ServiceAuth | string | `""` | plaintext service authorization secret |
| secret.enabled | bool | `false` | whether to create blob secret |
| securityContext | object | `{}` |  |
| serviceAccount.create | bool | `false` |  |
| tolerations | list | `[]` |  |
