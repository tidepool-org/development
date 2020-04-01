# Tidepool

This directory contains a helm chart for Tidepool, an open source, Kubernetes-native web-service that stores and visualizes diabetes data.

## TL;DR;

```console
$ helm install --dry-run --debug .
```

## Features

This helm chart for Tidepool features:

* horizontal pod scaling
* multiple DNS aliases to same backend
* HTTP and/or HTTPS access
* server SNI (different certificates as needed per domain)
* internal secret generation (on first installation)
* local deployment with
  * optional embedded MongoDB
  * optional embedded API Gateway
* simultaneous, multiple deployments (in different namespaces)
* ability to forgo installing certain non-essential services (tools, migration, jellyfish)
  * including mongodb and mongdb+srv schemes, usernames, passwords, and additional URL parameters
  * allows use of AtlasDB or Amazon DocumentDB
  * allows use of local (out of cluster) MongoDB
* automatic generation of TLS certificate requests (using certmanager)

## Prerequisites

- Kubernetes 1.13+

## Quickstart

This chart bootstraps an Tidepool Environment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager version 3.

To install the chart with the release name `my-release`:

```console
$ helm install my-release .
```

The command deploys Tidepool on the Kubernetes cluster in the default configuration.
The [configuration](#configuration) section lists the parameters that can be configured during installation.

The default configuration includes an embedded Mongo database and a Gloo API Gateway.

```console
open -a /Applications/Google\ Chrome.app/ http://localhost:8080
```

## Uninstalling the Chart

To uninstall/delete the `my-release` environment:

```console
$ helm delete my-release
```

## Configuration

The following tables lists the configurable parameters of the Ambassador chart and their default values.


| Parameter                                            | Description                                                                               | Default                             |  
|------------------------------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------|
| `auth.deployment.image`                              | auth Docker image                                                                         | ``                                  |  
| `blip.deployment.image`                              | blip Docker image                                                                         | ``                                  |  
| `blob.deployment.env.store.s3.bucket`                | S3 bucket where blob data is written                                                      | `data`                              |  
| `blob.deployment.env.store.file.directory`           | directory to use when storing blobs on file storage                                       | `_data/blobs`                       |  
| `blob.deployment.env.store.file.prefix`              | file prefix to use when storing blobs on file storage                                     | `blobs`                             |  
| `blob.deployment.env.store.type`                     | if `s3`, store blob data in Amazon S3. If `file` store blob data in local files.          | `file`                              |  
| `blob.deployment.image`                              | blob Docker image                                                                         | ``                                  |  
| `blob.secret.enabled`                                | whether to create blob secret                                                             | ``                                  |  
| `blob.secret.data_.ServiceAuth`                      | plaintext service authorization secret                                                    | ``                                  |  
| `carelink.enabled`                                   | enable carelink                                                                           | `false`                             |  
| `carelink.secret.enabled`                            | whether to create carelink secret                                                         | `false`                             |  
| `carelink.secret.data_.CareLinkSalt`                 | plaintext Carelink salt                                                                   | `false`                             |  
| `data.deployment.image`                              | data Docker image                                                                         | ``                                  |  
| `data.secret.data_.ServiceAuth`                      | service authorization secret                                                              | ``                                  |  
| `dexcom.secret.enabled`                              | whether to create dexcom secret                                                           | `false`                             |  
| `dexcom.secret.data_.ClientId`                       | plaintext Dexcom Oauth2 client id                                                         | ``                                  |  
| `dexcom.secret.data_.ClientSecret`                   | plaintext Dexcom Oauth2 client secret                                                     | `false`                             |  
| `dexcom.secret.data_.StateSalt`                      | plaintext Dexcom Oauth2 state salt                                                        | `false`                             |  
| `gatekeeper.deployment.image`                        | gatekeeper Docker image                                                                   | ``                                  |  
| `gatekeeper.nodeEnvironment`                         | node environment (passed as NODE_ENV)                                                     | `production`                        |  
| `glooingress.enabled`                                | whether to use Gloo API Gateway for ingress                                               | `true`
| `global.fullnameOverride`                            |                                                                                           | ``                                  |  
| `global.gateway.default.host`                        | host to use for email verification                                                        | `localhost`                         |  
| `global.gateway.default.protocol`                    | protocol to use for email verification.                                                   | `http`                              |  
| `global.gateway.default.domain`                      | domain to use for cookies                                                                 | ''                                  |  
| `global.logLevel`                                    | default log level                                                                         | `info`                              |  
| `global.nameOverride`                                | if non-empty, Helm chart name to use                                                      | ``                                  |  
| `global.ports.auth`                                  | auth service container port                                                               | `9222`                              |  
| `global.ports.blip`                                  | blip service container port                                                               | `3000`                              |  
| `global.ports.blob`                                  | blob service container port                                                               | `9225`                              |  
| `global.ports.data`                                  | data service container port                                                               | `9220`                              |  
| `global.ports.export`                                | export service container port                                                             | `9300`                              |  
| `global.ports.gatekeeper`                            | gatekeeper service container port                                                         | `9123`                              |  
| `global.ports.highwater`                             | highwater service container port                                                          | `9191`                              |  
| `global.ports.image`                                 | image service container port                                                              | `9226`                              |  
| `global.ports.jellyfish`                             | jellyfish service container port                                                          | `9122`                              |  
| `global.ports.messageapi`                            | message-Api service container port                                                        | `9119`                              |  
| `global.ports.notification`                          | notification service container port                                                       | `9223`                              |  
| `global.ports.seagull`                               | seagull service container port                                                            | `9120`                              |  
| `global.ports.shoreline`                             | shoreline service container port                                                          | `9107`                              |  
| `global.ports.task`                                  | task service container port                                                               | `9224`                              |  
| `global.ports.tidewhisperer`                         | tide whisperer service container port                                                     | `9127`                              |  
| `global.ports.user`                                  | user service container port                                                               | `9221`                              |  
| `global.region`                                      | AWS region to deploy in                                                                   | `us-west-2`                         |  
| `global.secret.enabled`                              | whether to generate all secret files                                                      | `false`                             |  
| `hydrophone.deployment.image`                        | hydrophone Docker image                                                                   | ``                                  |  
| `image.deployment.env.store.s3.bucket`               | S3 bucket where image data is written                                                     | `data`                              |  
| `image.deployment.env.store.file.directory`          | directory to use when storing images on file storage                                      | `_data/image`                       |  
| `image.deployment.env.store.file.prefix`             | file prefix to use when storing images on file storage                                    | `images`                            |  
| `image.deployment.env.store.type`                    | if `s3`, store image data in Amazon S3. If `file` store image data in local files.        | `file`                              |  
| `image.deployment.image`                             | image Docker image                                                                        | ``                                  |  
| `image.secret.enabled`                               | whether to create image secret                                                            | ``                                  |  
| `image.secret.data_.ServiceAuth`                     | plaintext service authorization secret                                                    | ``                                  |  
| `jellyfish.deployment.env.store.s3.bucket`           | S3 bucket where jellyfish data is written                                                 | `data`                              |  
| `jellyfish.deployment.env.store.type`                | if `s3`, store jellyfish data in Amazon S3. If `file` store jellyfishdata in local files. | `file`                              |  
| `jellyfish.deployment.image`                         | jellyfish Docker image                                                                    | ``                                  |  
| `jellyfish.enabled`                                  | whether toenable jellyfish service                                                        | `true`                              |  
| `jellyfish.nodeEnvironment`                          | node environment (passed as NODE_ENV)                                                     | `production`                        |  
| `kissmetrics.secret.enabled`                         | Whether to use create kissmetrics secret                                                  | `false`                             |  
| `kissmetrics.secret.data_.APIKey`                    | plaintext Kissmetrics API Key                                                             | ``                                  |  
| `kissmetrics.secret.data_.Token`                     | plaintext Kissmetrics Token                                                               | ``                                  |  
| `kissmetrics.secret.data_.UCSFAPIKey`                | plaintext UCSF Kissmetrics Token                                                          | ``                                  |  
| `kissmetrics.secret.data_.UCSFWhitelist`             | plaintext UCSF metrics whitelist                                                          | ``                                  |  
| `linkerdsupport.enabled`                             | whether to include linkerdsupport subchart with Linkerd service profiles                  | `false`                             |  
| `messageapi.deployment.env.window`                   |                                                                                           | `21`                                |  
| `messageapi.deployment.image`                        | message-api Docker image                                                                  | ``                                  |  
| `messageapi.nodeEnvironment`                         | node environment (passed as NODE_ENV)                                                     | `production`                        |  
| `migrations.deployment.image`                        | migrations Docker image                                                                   | ``                                  |  
| `migrations.enabled`                                 | enable migrations service if true                                                         | `true`                              |  
| `mongo.secret.enabled`                               | whether to create mongo secret                                                            | `false`                             |  
| `mongo.secret.data_.OptParams`                       | plaintext additional Mongo connection params                                              | ``                                  |  
| `mongo.secret.data_.Password`                        | plaintext Mongo password                                                                  | ``                                  |  
| `mongo.secret.data_.Scheme`                          | plaintext Mongo DB scheme, either `mongodb` or `mongodb+srv`                              | `mongodb`                           |  
| `mongo.secret.data_.Addresses`                       | plaintext comma-separated list of Mongo `host[:port]` addresses                           | `mongodb`                           |  
| `mongo.secret.data_.Tls`                             | plaintext, If true, use SSL on Mongo connection                                           | `false`                             |  
| `mongo.secret.data_.Username`                        | plaintext, If non-empty, Mongo username                                                   | ``                                  |  
| `mongodb.enabled`                                    | whether to include an mongodb with this installation                                      | `false`                             |  
| `notification.deployment.image`                      | notification Docker image                                                                 | ``                                  |  
| `notification.secret.enabled`                        | wheter to create notification secret                                                      | ``                                  |  
| `notification.secret.data_.ServiceAuth`              | plaintext service authorization secret                                                    | ``                                  |  
| `seagull.deployment.image`                           | seagull Docker image                                                                      | ``                                  |  
| `seagull.nodeEnvironment`                            | node environment                                                                          | `production`                        |  
| `server.secret.enabled`                              | whether to create secret                                                                  | ``                                  |  
| `server.secret.data_.ServiceAuth`                    | service authorization, if empty, random value is generated                                | ``                                  |  
| `shoreline.deployment.image`                         | shoreline Docker image                                                                    | ``                                  |  
| `shoreline.secret.data_.ServiceAuth`                 | service authorization secret                                                              | ``                                  |  
| `task.deployment.image`                              | task Docker image                                                                         | ``                                  |  
| `task.secret.data_.ServiceAuth`                      | task authorization, if empty, random value is generated                                   | ``                                  |  
| `tidepool.namespace.create`                          | whether to create namespace                                                               | `false`                             |  
| `tidewhisperer.deployment.image`                     | tidewhisperer Docker image                                                                | ``                                  |  
| `tools.deployment.image`                             | tools Docker image                                                                        | ``                                  |  
| `tools.enabled`                                      | whether to Enable tools service                                                           | `true`                              |  
| `user.deployment.image`                              | user Docker image                                                                         | ``                                  |  
| `user.secret.enabled`                                | whether to generate user secret                                                           | ``                                  |  
| `user.secret.data_.ServiceAuth`                      | user authorization, if empty, random value is generated                                   | ``                                  |  
| `userdata.secret.enabled`                            | whethe to create userdata secret                                                          | ``                                  |  
| `userdata.secret.data_.GroupIdEncryptionKey`         | plaintext group id encryption key                                                         | ``                                  |  
| `userdata.secret.data_.UserIdSalt`                   | plaintext user id salt                                                                    | ``                                  |  
| `userdata.secret.data_.UserPasswordSalt`             | plaintext user password salt                                                              | ``                                  |  
| `{name}.hpa.enabled`                                 | whether to create a horizontal pod autoscalers for all pods of given deployment           | 'false'                             |  
| `{name}.hpa.data.maxReplicas`                        | maximum number of replicase that HPA will maintain                                        | 'false'                             |  
| `{name}.hpa.data.minReplicas`                        | minimum number of replicase that HPA will maintain                                        | 'false'                             |  
| `{name}.hpa.data.targetCPUUtilizationPercentage`     | target CPU utilization percentage for HPA to maintain                                     | 'false'                             |  
| `{name}.mongo.secretName`                            | name of mongo database secret to use                                                      | 'mongo'                             |  
| `{name}.resources.limits.cpu`                        | cpu limit                                                                                 | `200m`                              |  
| `{name}.resources.limits.memory`                     | memory limit                                                                              | `128Mi`                             |  
| `{name}.resources.requests.cpu`                      | cpu limit                                                                                 | `50m`                               |  
| `{name}.resources.requests.memory`                   | memory limit                                                                              | `32Mi`                              |  
| `{name}.securityContext`                             | security context for pods of given name                                                   | `200m`                              |  


### Specifying Values

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm upgrade --install --wait my-release .
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm upgrade --install --wait my-release -f values.yaml .
```

### Using a Pre-existing Mongo Instance
To use an existing Mongo server, simply provide the Mongo connection parameters in the mongo secret.

N.B If you are running Mongo on your local laptop and typically access it using host `localhost`, you cannot simply use the host name `localhost` because that name is overloaded to mean something different in the Kubernetes cluster. Instead, you must provide an alias that resolves to your `localhost`.  Do this by creating the alias in your `/etc/hosts` file.  Then, you may use that alias to identify your Mongo server.

### Multiple Instantiations

The Tidepool web service may be installed under multiple namespaces within the same cluster (using different host names).  However, the Gloo API Gateway may only be installed once.  You must disable the installation of Gloo for subsequent installations by setting the value `gloo.enabled` to `false`.

### Secrets

To use external services such as DexcomAPI, Mailchimp, and KissMetrics, you must provide certain secrets.

