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

