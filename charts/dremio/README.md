# dremio

![Version: 0.7.0](https://img.shields.io/badge/Version-0.7.0-informational?style=flat-square)

**Homepage:** <https://www.dremio.com/>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| coordinator.client.port | int | `31010` |  |
| coordinator.count | int | `0` |  |
| coordinator.cpu | int | `15` |  |
| coordinator.memory | int | `122880` |  |
| coordinator.volumeSize | string | `"100Gi"` |  |
| coordinator.web.port | int | `9047` |  |
| distStorage.aws.accessKey | string | `"Your_AWS_Access_Key"` |  |
| distStorage.aws.bucketName | string | `"Your_AWS_bucket_name"` |  |
| distStorage.aws.path | string | `"/"` |  |
| distStorage.aws.secret | string | `"Your_AWS_Secret"` |  |
| distStorage.azure.applicationId | string | `"Your_Azure_Application_Id"` |  |
| distStorage.azure.datalakeStoreName | string | `"Your_Azure_DataLake_Storage_name"` |  |
| distStorage.azure.oauth2EndPoint | string | `"Azure_OAuth2_Endpoint"` |  |
| distStorage.azure.path | string | `"/"` |  |
| distStorage.azure.secret | string | `"Your_Azure_Secret"` |  |
| distStorage.azureStorage.accessKey | string | `"Access_key_for_the_storage_account"` |  |
| distStorage.azureStorage.accountName | string | `"Azure_storage_v2_account_name"` |  |
| distStorage.azureStorage.filesystem | string | `"Filesystem_in_storage_account"` |  |
| distStorage.azureStorage.path | string | `"/"` |  |
| distStorage.type | string | `"local"` |  |
| executor.cloudCache.enabled | bool | `true` |  |
| executor.cloudCache.quota.cache_pct | int | `100` |  |
| executor.cloudCache.quota.db_pct | int | `70` |  |
| executor.cloudCache.quota.fs_pct | int | `70` |  |
| executor.count | int | `3` |  |
| executor.cpu | int | `15` |  |
| executor.memory | int | `122880` |  |
| executor.volumeSize | string | `"100Gi"` |  |
| image | string | `"dremio/dremio-oss"` |  |
| imageTag | string | `"latest"` |  |
| serviceAccount.name | string | `"dremio"` |  |
| serviceType | string | `"LoadBalancer"` |  |
| tls.client.enabled | bool | `false` |  |
| tls.client.secret | string | `"dremio-tls-secret-client"` |  |
| tls.ui.enabled | bool | `false` |  |
| tls.ui.secret | string | `"dremio-tls-secret-ui"` |  |
| zookeeper.count | int | `3` |  |
| zookeeper.cpu | float | `0.5` |  |
| zookeeper.memory | int | `1024` |  |
| zookeeper.name | string | `"zk-hs"` |  |
| zookeeper.volumeSize | string | `"10Gi"` |  |
