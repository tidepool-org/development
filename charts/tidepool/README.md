# tidepool

![Version: 0.7.51](https://img.shields.io/badge/Version-0.7.51-informational?style=flat-square)

A Helm chart for Tidepool

**Homepage:** <https://github.com/tidepool-org/development/charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Derrick Burns | derrick@tidepool.org | https://github.com/derrickburns |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.fullnameOverride | string | `""` |  |
| global.gateway.default.apiHost | string | `""` | host to use for API calls |
| global.gateway.default.appHost | string | `""` | host to use for front end calls |
| global.gateway.default.domain | string | `""` | domain to use for cookies |
| global.gateway.default.host | string | `"localhost"` |  |
| global.gateway.default.protocol | string | `"http"` |  |
| global.gateway.proxy.name | string | `"gateway-proxy"` |  |
| global.gateway.proxy.namespace | string | `"gloo-system"` |  |
| global.glooingress.enabled | bool | `true` | whether to use Gloo API Gateway for ingress |
| global.glooingress.jwt.enabled | bool | `false` |  |
| global.linkerdsupport.enabled | bool | `true` |  |
| global.logLevel | string | `"info"` | the default log level for all services |
| global.maxTimeout | string | `"120s"` | maximum timeout for any web request |
| global.nameOverride | string | `""` | if non-empty, Helm chart name to use |
| global.ports.auth | int | `9222` | auth service internal port |
| global.ports.blip | int | `3000` | blip service internal port |
| global.ports.blob | int | `9225` | blob service internal port |
| global.ports.data | int | `9220` | data service internal port |
| global.ports.devices_grpc | int | `9228` | devices service grpc internal port |
| global.ports.devices_http | int | `9229` | devices service http internal port |
| global.ports.export | int | `9300` | export service internal port |
| global.ports.gatekeeper | int | `9123` | gatekeeper service internal port |
| global.ports.highwater | int | `9191` | highwater service internal port |
| global.ports.hydrophone | int | `9157` | hydrophone service internal port |
| global.ports.image | int | `9226` | image service internal port |
| global.ports.jellyfish | int | `9122` | jellyfish service internal port |
| global.ports.messageapi | int | `9119` | messageapi service internal port |
| global.ports.notification | int | `9223` | notification service internal port |
| global.ports.prescription | int | `9227` | prescription service internal port |
| global.ports.seagull | int | `9120` | seagull service internal port |
| global.ports.shoreline | int | `9107` | shoreline service internal port |
| global.ports.summary | int | `9230` | summary service internal port |
| global.ports.task | int | `9224` | task service internal port |
| global.ports.tidewhisperer | int | `9127` | tidewhisperer service internal port |
| global.ports.user | int | `9221` | user service internal port |
| global.region | string | `"us-west-2"` | aws region that services run in |
| global.secret.enabled | bool | `false` |  |
| global.secret.generated | bool | `false` |  |
| global.secret.templated | bool | `false` |  |
| tidepool.namespace.annotations | object | `{}` |  |
| tidepool.namespace.create | bool | `true` |  |
| tidepool.tests.enabled | bool | `false` |  |
| tidepool.tests.job | string | `"none"` |  |
