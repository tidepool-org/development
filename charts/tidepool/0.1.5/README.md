# Tidepool

Tidepool is an open source, Kubernetes-native web-service that stores and visualizes diabetes data.

## TL;DR;

```console
$ helm install --dry-run --debug .
```

## Introduction

This chart bootstraps an Tidepool Environment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.13+

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release .
```

The command deploys Tidepool on the Kubernetes cluster in the default configuration.
The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-release` environment:

```console
$ helm delete --purge my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the Ambassador chart and their default values.

| Parameter                          | Description                                                                     | Default                           |
| ---------------------------------- | ------------------------------------------------------------------------------- | --------------------------------- |
| `global.store.type`                | If `s3`, store blob/image data in Amazon S3. If `file` store blob/image data in local files.               | `file`                            |
| `global.secrets.external.source`   | If `awsSecretsManager`, retrieve secrets shared with third parties from Amazon Secrets Manager. If `local`, you must provide these secrets as Kubernetes Secrets | `local`                            |
| `global.secrets.internal.source`   | If `awsSecretsManager`, retrieve internally used secrets from Amazon Secrets Manager. If `helm`, these internal secrets will be generated when the Helm chart is installed. If `local`, you must provide these secrets as Kubernetes Secrets | `helm`                            |
| `global.linkerd`                | If `enabled` then use the `linkerd` service mesh | `disabled`                       |
| `global.ports.blip`               | Blip service container port                   | `3000`      |
| `global.ports.export`             | Export service container port                 | `9300`      |
| `global.ports.gatekeeper`         | Gatekeeper service container port             | `9123`      |
| `global.ports.highwater`          | Highwater service container port              | `9191`      |
| `global.ports.jellyfish`          | Jellyfish service container port              | `9122`      |
| `global.ports.messageapi`         | Message-Api service container port            | `9119`      |
| `global.ports.auth`               | Auth service container port                   | `9222`      |
| `global.ports.blob`               | Blob service container port                   | `9225`      |
| `global.ports.data`               | Data service container port                   | `9220`      |
| `global.ports.image`              | Image service container port                  | `9226`      |
| `global.ports.notification`       | Notification service container port           | `9223`      |
| `global.ports.task`               | Task service container port                   | `9224`      |
| `global.ports.user`               | User service container port                   | `9221`      |
| `global.ports.seagull`            | Seagull service container port                | `9120`      |
| `global.ports.shoreline`          | Shoreline service container port              | `9107`      |
| `global.ports.tidewhisperer`      | Tide whisperer service container port         | `9127`      |
| `global.ports.seagull`            | Seagull service container port                | `9120`      |
| `global.aws.region`               | AWS region to deploy in                       | `us-west-2` |
| `global.environment`              | Node environment (passed as NODE_ENV)         | `production`|
| `global.fullnameOverride`         |                   | ``                           |
| `global.nameOverride`             | If non-empty, Helm chart name to use          | ``          |
| `global.namespace.create`         | If true, create namespace                     | `false`     |
| `global.mongo.hosts`              | Comma-separated list of Mongo hosts           | `mongodb`   |
| `global.mongo.port`               | Mongo service port                            | `27017`     |
| `global.mongo.username`           | If non-empty, Mongo username                  | ``          |
| `global.mongo.ssl`                | If true, use SSL on Mongo connection          | `false`     |
| `global.mongo.optParams`          | Additional Mongo connection params            | ``          |
| `global.provider.dexcom.token.url` | The URL to retrieve an Dexcom Oauth2 token   | `https://api.dexcom.com/v1/oauth2/token` |
| `global.provider.dexcom.authorize.url` | The URL to authorization from Dexcom     | `https://api.dexcom.com/v1/oauth2/login?prompt=login` |
| `global.provider.dexcom.client.url` | The Dexcom client API URL                   | `https://api.dexcom.com` |
| `global.hosts.default.protocol`   | If `http` use `http` for email verification link. If `https` use 	`https` for email verification links.          | `http`     |
| `global.hosts.default.host`   | Host to use in email verification link.          | `localhost`  |
| `global.hosts.http.{name}`   | Display name to use for http host                 | `localhost`  |
| `global.hosts.http.{name}.name`   | Http host[:port] to listen to                       | `localhost`  |
| `global.hosts.https.{name}`   | Display name to use for https host {name}        | ``  |
| `global.hosts.https.{name}.name`   | Https host[:port] to listen to host {name}         | ``  |
| `global.hosts.https.{name}.tlssecret.name`   | TLS secret name for host {name}   | ``  |
| `global.hosts.https.{name}.tlssecret.namespace` | TLS secret namespace for host {name} | ``  |
| `global.gateway.proxy.name`   | Name of the API gateway proxy                  | `gateway-proxy`  |
| `global.gateway.proxy.namespace`   | Namespace of the API gateway proxy        | `gloo-system`  |
| `global.resources.limits.cpu`   | CPU Limit                                    | `200m`  |
| `global.resources.limits.memory`  | Memory Limit                               | `128Mi`  |
| `global.resources.requests.cpu`   | CPU Limit                                  | `50m`  |
| `global.resources.requests.memory`   | Memory Limit                            | `32Mi`  |
| `global.securityContext`   | Set Security Context for pods                     | `200m`  |
| `export.enabled`   | Enable export service if true                             | `true`  |
| `jellyfish.enabled`   | Enable jellyfish service if true                       | `true`  
| `export.enabled`   | Enable export service if true                             | `true`  |
| `migrations.enabled`   | Enable migrations service if true                     | `true`  |
| `tools.enabled`   | Enable tools service if true                               | `true`  |
| `hydrophone.fromAddress`   | Email address to use for replies to sigups        | `Tidepool <noreply@tidepool.org>`  |
| `hydrophone.bucket` | S3 bucket where email templates are stored               | `tidepool-{env}` |
| `messageapi.window` |                                                          | `21` |
| `blob.directory` | Directory to use when storing blobs on file storage         | `_data/blobs` | 
| `blob.prefix`  | File prefix to use when storing blobs on file storage         | `blobs` | 
| `image.directory` | Directory to use when storing images on file storage       | `_data/image` | 
| `image.prefix` | File prefix to use when storing images on file storage        | `images` | 
| `gloo.enabled` | Whether to include an API Gateway with this installation      | `true` |
| `mongodb.enabled` | Whether to include an mongodb with this installation      | `true` |
| `mongodb.{name}`  | See [mongodb values](https://github.com/helm/charts/tree/master/stable/mongodb) | `` |
| `gloo.gatewayProxies.gateway-proxy.service.type` | The Service type to expose. If `LoadBalancer`, then a LoadBalancer will be allocated. | `ServiceIP` |
| `gloo.gatewayProxies.gateway-proxy.service.httpPort` | The http port to listen to.| `80` |
| `gloo.gatewayProxies.gateway-proxy.service.httpsPort` | The https port to listen to.| `` |
| `gloo.{name}`  | See [gloo values](https://github.com/solo-io/gloo/tree/master/install/helm/gloo) | `` |


### Specifying Values

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm upgrade --install --wait my-release \
    --set global.resources.limit.cpu=400m \
    .
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm upgrade --install --wait my-release -f values.yaml .
```
