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

This chart bootstraps an Tidepool Environment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release .
```

The command deploys Tidepool on the Kubernetes cluster in the default configuration.
The [configuration](#configuration) section lists the parameters that can be configured during installation.

The default configuration  includes an embedded Mongo database and a Gloo API Gateway.  You may access

```console
```

```console
open -a /Applications/Google\ Chrome.app/ http://localhost:8080
```

## Uninstalling the Chart

To uninstall/delete the `my-release` environment:

```console
$ helm delete --purge my-release
```
The command removes all the Kubernetes components associated with the chart and deletes the release *except* CRDs.

To remove the gloo CRDS, you may do this manually:
```
kubectl delete crd virtualservices.gateway.solo.io
kubectl delete crd gateways.gateway.solo.io
kubectl delete crd proxies.gloo.solo.io
kubectl delete crd settings.gloo.solo.io
kubectl delete crd upstreams.gloo.solo.io
kubectl delete crd upstreamgroups.gloo.solo.io
```

Alternatively, you may leave the CRDs.  However on the next install of this chart, you will get an error that one of the Gloo CRDs exists.
To avoid attempts to reinstall the Gloo CRDs, set the parameter `gloo.crds.create` to `false` on install:
```
helm install --name my-release --set gloo.crds.create=false .
```

## Configuration

The following tables lists the configurable parameters of the Ambassador chart and their default values.


| Parameter             | Description   | Default   |
|-----------------------|--------------|-------------------------------------------------------|
| `auth.deployment.image` | auth Docker image | `` |
| `blip.deployment.image` | blip Docker image | `` |
| `blob.deployment.env.store.s3.bucket`                                      | S3 bucket where blob data is written | `data`                                      |
| `blob.deployment.env.store.file.directory`                                         | Directory to use when storing blobs on file storage                                          | `_data/blobs`                                         |
| `blob.deployment.env.store.file.prefix`                                            | File prefix to use when storing blobs on file storage                                        | `blobs`                                               |
| `blob.deployment.env.store.type`                                      | If `s3`, store blob data in Amazon S3. If `file` store blob data in local files. | `file`                                                |
| `blob.deployment.image` | blob Docker image | `` |
| `blob.secret.enabled`                                         | whether to create blob secret | ``                                         |
| `blob.secret.data_.ServiceAuth`                                         | plaintext service authorization secret | ``                                         |
| `carelink.enabled`                                       | Enable carelink                                                                              | `false`                                               |
| `carelink.secret.enabled`                                       | whether to create carelink secret| `false`                                               |
| `carelink.secret.data_.CareLinkSalt`                                       | plaintext Carelink salt | `false`                                               |
| `data.deployment.image` | data Docker image | `` |
| `data.secret.data_.ServiceAuth`                                         | Service authorization secret | ``                                         |
| `dexcom.secret.enabled`                                         | whether to create dexcom secret| `false`                                               |
| `dexcom.secret.data_.ClientId`                                  | plaintext Oauth2 client id | ``                                               |
| `dexcom.secret.data_.ClientSecret`                                         | plaintext Oauth2 client secret | `false`                                               |
| `dexcom.secret.data_.StateSalt`                                         | plaintext Oauth2 state salt | `false`                                               |
| `gatekeeper.deployment.image` | gatekeeper Docker image | `` |
| `gatekeeper.nodeEnvironment`                     | Node environment (passed as NODE_ENV)                                                        | `production`                                          |
| `global.fullnameOverride`                                |                                                                                              | ``                                                    |
| `global.gateway.default.host`                          | Host to use for email verification                                                      | `localhost`   |
| `global.gateway.default.protocol`                          | Protocol to use for email verification.                                                      | `http`                                                    |
| `global.gateway.default.domain`                          | Domain to use for cookies
| `global.logLevel`                              | Default log level | `info`                                        |
| `global.nameOverride`                                    | If non-empty, Helm chart name to use                                                         | ``                                                    |
| `global.ports.auth`                                      | Auth service container port                                                                  | `9222`                                                |
| `global.ports.blip`                                      | Blip service container port                                                                  | `3000`                                                |
| `global.ports.blob`                                      | Blob service container port                                                                  | `9225`                                                |
| `global.ports.data`                                      | Data service container port                                                                  | `9220`                                                |
| `global.ports.export`                                    | Export service container port                                                                | `9300`                                                |
| `global.ports.gatekeeper`                                | Gatekeeper service container port                                                            | `9123`                                                |
| `global.ports.highwater`                                 | Highwater service container port                                                             | `9191`                                                |
| `global.ports.image`                                     | Image service container port                                                                 | `9226`                                                |
| `global.ports.jellyfish`                                 | Jellyfish service container port                                                             | `9122`                                                |
| `global.ports.messageapi`                                | Message-Api service container port                                                           | `9119`                                                |
| `global.ports.notification`                              | Notification service container port                                                          | `9223`                                                |
| `global.ports.seagull`                                   | Seagull service container port                                                               | `9120`                                                |
| `global.ports.seagull`                                   | Seagull service container port                                                               | `9120`                                                |
| `global.ports.shoreline`                                 | Shoreline service container port                                                             | `9107`                                                |
| `global.ports.task`                                      | Task service container port                                                                  | `9224`                                                |
| `global.ports.tidewhisperer`                             | Tide whisperer service container port                                                        | `9127`                                                |
| `global.ports.user`                                      | User service container port                                                                  | `9221`
| `global.region`                                  | AWS region to deploy in                                                                      | `us-west-2`                                           |
| `global.secret.enabled`                                  | whether to generate all secret files | `false`                                           |
| `gloo.enabled`                                           | Whether to launch Gloo control and plane
| `gloo.generate.virtualServices`                          | Whether to include an Gloo virtual services resources in installation
| `gloo.generate.gateways`                          | Whether to include a Gloo vGateway resources
| `gloo.generate.loadBalancer`                          | Whether to include a load balancer
| `gloo.gatewayProxies.gatewayProxy.service.httpPort`  | HTTP port to listen to | `8080`                                                  |
| `gloo.gatewayProxies.gatewayProxy.service.httpsPort`  | HTTPS port to listen to | `8433`                                                  |
| `gloo.gatewayProxies.gatewayProxy.service.type`  | Type on service | `ClusterIP`                                                  |
| `highwater.deployment.image` | highwater Docker image | `` |
| `highwater.nodeEnvironment`                     | Node environment (passed as NODE_ENV)                                                        | `production`                                          |
| `hydrophone.deployment.env.fromAddress`                                 | Email address to use for replies to sigups                                                   | `Tidepool <noreply@tidepool.org>`                     |
| `hydrophone.deployment.env.store.s3.bucket`                                      | S3 bucket where email templates are stored                                                   | `asset`                                      |
| `hydrophone.deployment.image` | hydrophone Docker image | `` |
| `image.deployment.env.store.s3.bucket`                                      | S3 bucket where image data is written | `data`                                      |
| `image.deployment.env.store.file.directory`                                        | Directory to use when storing images on file storage                                         | `_data/image`                                         |
| `image.deployment.env.store.file.prefix`                                           | File prefix to use when storing images on file storage                                       | `images`                                              |
| `image.deployment.env.store.type`                                      | If `s3`, store image data in Amazon S3. If `file` store image data in local files. | `file`                                                |
| `image.deployment.image` | image Docker image | `` |
| `image.secret.enabled`                                         | whether to create image secret| ``                                         |
| `image.secret.data_.ServiceAuth`                                         | plaintext service authorization secret | ``                                         |
| `ingress.deployment.name`                              | Name of the API gateway proxy                                                                | `internal-gateway-proxy`                                    |
| `ingress.deployment.namespace`                         | Namespace of the API gateway proxy                                                           | `gloo-system`                                         |
| `ingress.gateway.http.dnsNames`                             | List of host to listen to                                                                    | `localhost`                                           |
| `ingress.gateway.https.dnsNames`                            | List of Subject Alternative Names to use                                                     | `[]`                                                  |
| `ingress.service.annotations`                             |  The service annotations | `{}`                                           |
| `ingress.service.http.enabled`                             |  Whether to provide HTTP access | `true`                                           |
| `ingress.service.https.enabled`                             |  Whether to provide HTTPS access | `false`                                           |
| `jellyfish.deployment.env.store.s3.bucket`                                      | S3 bucket where jellyfish data is written | `data`                                      |
| `jellyfish.deployment.env.store.type`                                      | If `s3`, store jellyfish data in Amazon S3. If `file` store jellyfishdata in local files. | `file`                                                |
| `jellyfish.deployment.image` | jellyfish Docker image | `` |
| `jellyfish.enabled`                                      | Enable jellyfish service if true                                                             | `true`                                                |
| `jellyfish.nodeEnvironment`                     | Node environment (passed as NODE_ENV)                                                        | `production`                                          |
| `kissmetrics.secret.enabled` | whether to use create kissmetrics secret | `false` |
| `kissmetrics.secret.data_.APIKey` | plaintext Kissmetrics API Key | `` |
| `kissmetrics.secret.data_.Token` | plaintext Kissmetrics Token | `` |
| `kissmetrics.secret.data_.UCSFAPIKey` | plaintext UCSF Kissmetrics Token | `` |
| `kissmetrics.secret.data_.UCSFWhitelist` | plaintext UCSF metrics whitelist | `` |
| `linkerd.generate.serviceProfiles` | whether to generate Linkerd ServiceProfiles | `false` |
| `mailchimp.secret.enabled` | whether to create Mailchimp secret | `false` |
| `mailchimp.secret.data_.ApiKey` | plaintext Mailchimp API key | `` |
| `mailchimp.secret.data_.ClinicLists` | plaintext clinic mailing lists| `` |
| `mailchimp.secret.data_.PersonalLists` | plaintext personal mailing lists| `` |
| `mailchimp.secret.data_.URL` | plaintext Mailchimp URL | `` |
| `messageapi.deployment.env.window`                                      |                                                                                              | `21`                                                  |
| `messageapi.deployment.image` | message-api Docker image | `` |
| `messageapi.nodeEnvironment`                     | Node environment (passed as NODE_ENV)                                                        | `production`                                          |
| `migrations.deployment.image` | migrations Docker image | `` |
| `migrations.enabled`                                     | Enable migrations service if true                                                            | `true`                                                |
| `mongo.secret.enabled`                                        | Whether to create mongo secret | `false`                                             |
| `mongo.secret.data_.OptParams`                                        | plaintext additional Mongo connection params                                                           | ``                                                    |
| `mongo.secret.data_.Password`                                         | plaintext Mongo password                                                                 | `` ||                                                  |
| `mongo.secret.data_.Scheme`                                        | plaintext Mongo DB scheme, either `mongodb` or `mongodb+srv`                                              | `mongodb`                                             |
| `mongo.secret.data_.Addresses`                                        | plaintext comma-separated list of Mongo `host[:port]` addresses                                              | `mongodb`                                             |
| `mongo.secret.data_.Tls`                                              | plaintext, If true, use SSL on Mongo connection                                                         | `false`                                               |
| `mongo.secret.data_.Username`                                         | plaintext, If non-empty, Mongo username                                                                 | ``                                                    |
| `mongodb.enabled`                                 | Whether to include an mongodb with this installation                                         | `true`                                                |
| `nosqlclient.enabled`                                    | Enable nosqlclient                                                                           | `false`                                               |
| `notification.deployment.image` | notification Docker image | `` |
| `notification.secret.enabled`                                         | wheter to create notification secret | ``                                         |
| `notification.secret.data_.ServiceAuth`                                         | plaintext service authorization secret | ``                                         |
| `seagull.deployment.image` | seagull Docker image | `` |
| `seagull.nodeEnvironment`                     | Node environment (passed as NODE_ENV)                                                        | `production`                                          |
| `server.secret.enabled` | whether to create secret |  `` |
| `server.secret.data_.ServiceAuth` | service authorization, if empty, random value is generated |  `` |
| `shoreline.deployment.image` | shoreline Docker image | `` |
| `shoreline.secret.data_.ServiceAuth`                                         | Service authorization secret | ``                                         |
| `task.deployment.image` | task Docker image | `` |
| `task.secret.data_.ServiceAuth` | task authorization, if empty, random value is generated |  `` |
| `tidepool.namespace.create`                                | If true, create namespace                                                                    | `false`                                               |
| `tidewhisperer.deployment.image` | tidewhisperer Docker image | `` |
| `tools.deployment.image` | tools Docker image | `` |
| `tools.enabled`                                          | Enable tools service if true                                                                 | `true`                                                |
| `user.deployment.image` | user Docker image | `` |
| `user.secret.enabled` | whether to generate user secret |  `` |
| `user.secret.data_.ServiceAuth` | user authorization, if empty, random value is generated |  `` |
| `userdata.secret.enabled` | whethe to create userdata secret | `` |
| `userdata.secret.data_.GroupIdEncryptionKey` | plaintext group id encryption key| `` |
| `userdata.secret.data_.UserIdSalt` | plaintext user id salt | `` |
| `userdata.secret.data_.UserPasswordSalt` | plaintext user password salt | `` |
| `{name}.hpa.enabled`                                      | If true, create a horizontal pod autoscalers for all pods of given deployment                                    | 'false'                                               |
| `{name}.hpa.data.maxReplicas`                                      | Maximum number of replicase that HPA will maintain | 'false'                                               |
| `{name}.hpa.data.minReplicas`                                      | Minimum number of replicase that HPA will maintain | 'false'                                               |
| `{name}.hpa.data.targetCPUUtilizationPercentage`                     | Target CPU utilization percentage for HPA to maintain| 'false'                                               |
| `{name}.resources.limits.cpu`                            | CPU Limit                                                                                    | `200m`                                                |
| `{name}.resources.limits.memory`                         | Memory Limit                                                                                 | `128Mi`                                               |
| `{name}.resources.requests.cpu`                          | CPU Limit                                                                                    | `50m`                                                 |
| `{name}.resources.requests.memory`                       | Memory Limit                                                                                 | `32Mi`                                                |
| `{name}.securityContext`                                 | Set Security Context for pods of given name                                                                | `200m`                                                |



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
By default, this helm chart will install a version of mongodb in the Kubernetes cluster.  You may disable this by setting `mongodb.enabled` to `false`.

To use an existing Mongo server, simply provide the Mongo connection parameters are above.

N.B If you are running Mongo on your local laptop and typically access it using host `localhost`, you cannot simply use the host name `localhost` because that name is overloaded to mean something different in the Kubernetes cluster. Instead, you must provide an alias that resolves to your `localhost`.  Do this by creating the alias in your `/etc/hosts` file.  Then, you may use that alias to identify your Mongo server.

### Multiple Instantiations

The Tidepool web service may be installed under multiple namespaces within the same cluster (using different host names).  However, the Gloo API Gateway may only be installed once.  You must disable the installation of Gloo for subsequent installations by setting the value `gloo.enabled` to `false`.

### Secrets

To use external services such as DexcomAPI, Mailchimp, and KissMetrics, you must provide certain secrets.

