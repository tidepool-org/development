# mongo

![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square)

A Helm chart for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Derrick Burns | derrick@tidepool.org |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| mongodb.image | string | `"mongo:4.0"` |  |
| mongodb.persistent | bool | `true` |  |
| mongodb.port | string | `"27017"` |  |
| mongodb.seed | bool | `false` |  |
| mongodb.volume | string | `"mongo2"` |  |
