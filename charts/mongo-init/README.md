# mongo-init

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)

A Helm chart to initialize a Mongo database

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Derrick Burns | derrick@tidepool.org |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| mongo.host | string | `"mongo"` |  |
| mongo.image | string | `"mongo:3.2"` |  |
| mongo.persistent | bool | `true` |  |
| mongo.port | string | `"27017"` |  |
| mongo.seed | bool | `false` |  |
| mongo.tls | string | `"false"` |  |
| mongo.volume | string | `"mongo2"` |  |
