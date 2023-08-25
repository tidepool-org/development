# Welcome!

Welome to [Tidepool](https://tidepool.org) at GitHub!

This GitHub repository is your launching pad to running and developing the Tidepool software on your very own computer. You can use it to run your own local installation of Tidepool, take a quick peek at the Tidepool code, and even help us at Tidepool design and develop the next new and amazing feature!

Please note that this repository is only intended to run a simplified version of the Tidepool stack on a local machine. We do not recommend using this to provision remote, production-grade instances, nor can we support those who choose to do so.

Of course, if you haven't already done so, you should check out [Tidepool](https://tidepool.org) and [Tidepool Web](https://app.tidepool.org). It's a snap to create an account, upload your or your loved one's diabetes device data, and visualize it all in one place. We've already done the hard work of setting up the servers, software, databases, backups, and more, so you don't have to. Check it out!

## Quick Links

- [Initial Setup](#initial-setup)
  - [Install Docker](#install-docker)
  - [Install Kubernetes Client](#install-kubernetes-client)
  - [Install Helm](#install-helm)
  - [Install Tilt](#install-tilt)
  - [Install Tilt "cattle patrol" (ctlptl)](#install-ctlptl)
  - [Install Gloo Gateway CLI (glooctl)](#install-glooctl)
  - [Install Netcat](#install-netcat)
  - [Install and Configure MongoDB](#install-and-configure-mongodb)
  - [Clone This Repository](#clone-this-repository)
  - [Add Tidepool Helper Script (recommended)](#add-tidepool-helper-script-recommended)
  - [Environment Setup (recommended)](#environment-setup-recommended)
- [Quick Start](#quick-start)
  - [With The Tidepool Helper Script (recommended)](#with-the-tidepool-helper-script-recommended)
  - [Without The Tidepool Helper Script](#without-the-tidepool-helper-script)
  - [Monitor Kubernetes State With K9s (Optional)](#monitor-kubernetes-state-with-k9s-optional)
- [Using Tidepool](#using-tidepool)
  - [Identity And Access Management](#identity-and-access-management)
  - [Creating An Account](#creating-an-account)
  - [Verifying An Account Email](#verifying-an-account-email)
  - [Uploading Data](#uploading-data)
  - [Data Retention](#data-retention)
- [Advanced Customization](#advanced-customization)
  - [Tilt Config Overrides](#tilt-config-overrides)
  - [Alternate MongoDB Host](#alternate-mongodb-host)
  - [Dexcom API integration](#dexcom-api-integration)
  - [Running Alternate Remote Images](#running-alternate-remote-images)
- [Developing Tidepool Services](#developing-tidepool-services)
  - [Image Source Respositories](#image-source-repositories)
  - [Building Local Images](#building-local-images)
  - [Custom Docker Build Parameters](#custom-docker-build-parameters)
  - [Linking And Un-Linking Tidepool Web NPM Packages](#linking-and-un-linking-tidepool-web-npm-packages)
  - [Working With Yarn For NodeJS Services](#working-with-yarn-for-nodejs-services)
- [Misc](#misc)
  - [Tracing Internal Services](#tracing-internal-services)
  - [Troubleshooting](#troubleshooting)
  - [Known Issues](#known-issues)

# Initial Setup

It's easy to get up and running quickly as long as you know a bit about your computer and your way around a terminal window.

**WINDOWS USERS:**

Currently, our local development environment only works natively in MacOS and Linux environments. To run within Windows, we recommend you set up and run within a Linux VM via a virtualization tool such as VirtualBox or VMWare. We hope to natively support Windows in an upcoming iteration.

_Very_ determined Windows users may be able to get it working in it's current form with [GitBash](https://git-for-windows.github.io/), [Cygwin](https://www.cygwin.com/) or the new [Bash integration in Windows 10](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide).

If you do get this working on Windows before we get to it, please consider contributing back to the community with a pull request.

## Install Docker

The Tidepool stack relies on [Docker](https://www.docker.com) to run all of the code on your computer.

Follow the appropriate link for your platform (Mac OSx or Linux recommended) at https://docs.docker.com/install/#supported-platforms and follow the directions to install and run Docker on your computer. The minimum supported version is `20.10.17`

**IMPORTANT:** This stack is VERY resource intensive.  You will need a fairly robust computer to run it efficiently, and will need to provide Docker with at least 60 GB of disk space and 4 GB of RAM. The default 2 GB RAM for Docker on MacOS won't cut it, and will need to be increased via the preferences panel. We recommend 8 GB or higher if you have 12 GB or more available.

## Install Kubernetes Client

The Kubernetes command-line tool, [kubectl](https://kubernetes.io/docs/user-guide/kubectl/), allows you to run commands against Kubernetes clusters.

It's important to install a version that's at minimum up-to-date with the version of the Kubernetes server we're running locally (currently `1.21.12`). Please follow the [kubectl installation instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for your operating system.

For reference, the following should work:

```bash
# MacOS
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.21.12/bin/darwin/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Linux
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.21.12/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

After installation, you can ensure that your client version meets the minimum requirements by running:

```bash
kubectl version
```

## Install Helm

The Tidepool services (and supporting services such as the [MongoDB](https://www.mongodb.com/) database and the [Gloo Gateway](https://gloo.solo.io/) for routing requests) are defined by [Helm](https://helm.sh/) templates, which the `helm` tool uses to convert into manifests that can be applied to the our local [Kubernetes](https://kubernetes.io/) (K8s) cluster.

**IMPORTANT NOTE:** We currently run against version `v3.9.1` of Helm, so be sure to install the correct version when following the [Helm Installation Instructions](https://helm.sh/docs/intro/install/#from-the-binary-releases).

```bash
# MacOS
curl -fsSL https://get.helm.sh/helm-v3.9.1-darwin-amd64.tar.gz | tar -xzv darwin-amd64 && sudo mv darwin-amd64/helm /usr/local/bin/helm

# Linux
curl -fsSL https://get.helm.sh/helm-v3.9.1-linux-amd64.tar.gz | tar -xzv linux-amd64 && sudo mv linux-amd64/helm /usr/local/bin/helm
```

After installing Helm, you can verify the correct version by typing `helm version` in your terminal.

## Install Tilt

Managing a K8s cluster can be very challenging, and even more so when using one for local development. [Tilt](https://tilt.dev/) is a CLI tool used to simplify and streamline management of local development services within a Kubernetes cluster.

By using our Tilt setup, developers can very easily run a live-reloading instance of any of our frontend or backend services without needing to directly use or understand Helm or Kubernetes. All that's needed is uncommenting a couple of lines in a `Tiltconfig.yaml` file, and updating the local paths to where the developer has checked out the respective git repo, if different than the default defined in the config.

**IMPORTANT NOTE:** We currently run against version `v0.33.5` of Tilt, so be sure to install the correct version when following the [Tilt Installation Instructions](https://docs.tilt.dev/install.html#alternative-installation).

```bash
# MacOS
curl -fsSL https://github.com/windmilleng/tilt/releases/download/v0.33.5/tilt.0.33.5.mac.x86_64.tar.gz | tar -xzv tilt && sudo mv tilt /usr/local/bin/tilt

# Linux
curl -fsSL https://github.com/windmilleng/tilt/releases/download/v0.33.5/tilt.0.33.5.linux.x86_64.tar.gz | tar -xzv tilt && sudo mv tilt /usr/local/bin/tilt
```

After installing Tilt, you can verify the correct version by typing `tilt version` in your terminal.

## Install ctlptl

We provision the kubernetes backend using a Tilt-provided tool called ctlptl. This sets up a Kubernetes-in-Docker (kind) server that integrates well with Tilt. Please follow the [ctlptl Installation Instructions](https://github.com/tilt-dev/ctlptl).

Once installed, you can provision the kubernetes stack with `ctlptl`, using the `Kindconfig.yaml` configuration provided at the root of this repo.

```
ctlptl apply -f Kindconfig.yaml
```

This config will provision and start up the Kubernetes server, and a private docker registry that Tilt will deploy development builds to as you work locally on the Tidepool services.

## Install glooctl

We provision the Gloo gateway, which is responsible for service routing, using glooctl. Please follow the [glooctl Installation Instructions](https://docs.solo.io/gloo-edge/latest/installation/preparation/#glooctl).

Once installed, you can provision the kubernetes stack with `glooctl`, using the `Glooconfig.yaml` configuration provided at the root of this repo.

```
glooctl install gateway -n default --values Glooconfig.yaml
```

This config will provision the Gloo gateway in the `default` namespace. This only needs to be provisioned once.

## Install Netcat

Netcat should be installed by default on an recent versions of MacOS. If it is not, you can install it via homebrew.

On Linux, you will need to use the appropriate package manager to install it.

```bash
# CentOS/RHEL
yum install nc

# Fedora 22+ and RHEL 8
dnf install nc

# Debian/Ubuntu
sudo apt-get install netcat-openbsd # or netcat-traditional
```

After installing Netcat, you can verify it's working by typing `nc -h` in your terminal.

## Install and configure MongoDB

In order to run the local Tidepool services, you will need to provide a running MongoDB replica set.

We recommend installing a local instance of MongoDB Community Edition with a single member for this purpose, though you should be fine with providing an already-running remote instance as well if you have one available by providing the appropriate address and auth details in the `Tiltconfig.yaml` referenced below.

For local installation of MongoDB, please follow [these installation instructions](https://www.mongodb.com/docs/manual/administration/install-community/) for your platform.

The stack has been tested with version `6.x`, which is the latest version available at the time of writing. The minimum supported version is `5.0`.

After installing MongoDB locally, you will need to set up your `mongo.conf` to allow local connections, and configure it as a replica set (it will be a standalone instance by default).

If, for instance, you installed via homebrew on Mac, the default file location will be `/usr/local/etc/mongod.conf`. This is the configuration we recommend for local use. Note, however, that this is very permissive, and allows all incoming connections, so you may want to

```bash
systemLog:
  destination: file
  path: /usr/local/var/log/mongodb/mongo.log # Update this path as desired
  logAppend: true
storage:
  dbPath: /usr/local/var/mongodb # Update this path as desired
  journal:
    enabled: true
net:
  bindIp: ::,0.0.0.0 # Restrict as required if your machine is publicly accessible
replication:
  replSetName: rs0
```

After setting up the config, you may need to restart your MongoDB service in order for the changes to take effect.

At this point, you'll now need to initiate the replica set (`rs0`) that you defined in the `mongod.conf`.  To do so, enter your mongo shell, and run:

```js
// Initiate the replica set
rs.initiate()

// Confirm that it's set up
rs.conf()

// Should output something like:
/*
{
  _id: 'rs0',
  version: 1,
  term: 3,
  protocolVersion: Long("1"),
  writeConcernMajorityJournalDefault: true,
  members: [
    {
      _id: 0,
      priority: 1,
      votes: 1
      ...
    }
  ],
  settings: {
    ...
  }
}
*/

// Exit the shell
quit()
```

At this point, your MongoDB service is ready.

**Note for Linux users:** If you are running this stack on a Linux machine, then you will likely need to use the Docker host IP of `172.17.0.1` to point to the MongoDB. For example, in `local/Tiltconfig.yaml`:

```yaml
mongo:
  secret:
    data_:
      Addresses: "172.17.0.1"
    # ...
```

For more information about setting up overrides to the Tilt config, see [Tilt Config Overrides](#tilt-config-overrides)

## Clone This Repository

At a minimum you'll need to clone this very GitHub repository to your computer. Execute the following command in a terminal window, but be sure to replace the `<local-directory>` with the destination directory where you want the respository to be copied.

```bash
git clone https://github.com/tidepool-org/development.git <local-directory>
```

For example, if you want the code to be cloned into the `~/Tidepool/development` directory on your computer, then run the following command in the terminal window.

```bash
git clone https://github.com/tidepool-org/development.git ~/Tidepool/development
```

For more information about `git`, please see [Git](https://git-scm.com/) and [Try Git](https://try.github.io/).

## Add Tidepool Helper Script (recommended)

Though not strictly necessary, we recommend that you manage your local Tidepool stack via the `tidepool` helper script provided by this repo at `/bin/tidepool`.

Most of this documentation will assume you've chosen to install the helper script, but we do have some Quick Start instructions for [managing the stack without the helper script](#without-the-tidepool-helper-script) for those who prefer to manage all the components directly.


* `TIDEPOOL_DOCKER_SERVER_SECRET`
* `TIDEPOOL_DOCKER_SERVICE_PROVIDER_DEXCOM_STATE_SALT`
* `TIDEPOOL_DOCKER_GATEKEEPER_SECRET`
* `TIDEPOOL_DOCKER_HIGHWATER_SALT`
* `TIDEPOOL_DOCKER_JELLYFISH_SALT`
* `TIDEPOOL_DOCKER_PLATFORM_AUTH_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_BLOB_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_DATA_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_TASK_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_USER_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_SEAGULL_SALT`
* `TIDEPOOL_DOCKER_SHORELINE_API_SECRET`
* `TIDEPOOL_DOCKER_SHORELINE_LONG_TERM_KEY`
* `TIDEPOOL_DOCKER_SHORELINE_SALT`
* `TIDEPOOL_DOCKER_SHORELINE_VERIFICATION_SECRET` - should always start with "`+`"

```bash
# Show the help text (run from the root of this repo)
bin/tidepool help
```

It's recommended, however, to add the `bin` directory to your $PATH (e.g. in `~/.bashrc`) so that you can run the script from anywhere as `tidepool`.

```bash
export PATH=$PATH:/path/to/this/repo/bin
```

You can now easily manage your stack and services from anywhere.

```bash
# Show the help text (run from anywhere :) )
tidepool help
```

**NOTE:** `tidepool help` will describe and outline the use of all of the available commands.

## Environment Setup (recommended)

There are 2 environment variables that we recommend you export before starting up the Tidepool stack for the first time.

It's recommended that you export them in a persistent way, such as within your local `~/.bash_profile` (or whatever equivalent you use)

`KUBECONFIG` - This is the path used by Tilt to issue commands to your Kubernetes cluster.

```bash
export KUBECONFIG="$HOME/.kube/config"
```

`MONGODB_SHELL` - This is the path used run the MongoDB shell on your local machine. By default, if unset, the `tidepool` script will use the path resolved by running `which mongosh`.

If you would like to override this, for instance, if the command you run to open the MongoDB shell is `/usr/local/bin/mongo`, then just set the value of the environment variable like so:

```bash
export MONGODB_SHELL="/usr/local/bin/mongo"
```

[[back to top]](#welcome)

# Quick Start

Once you've completed the [Initial Setup](#initial-setup), getting the Tidepool services (including supporting services such as the database and gateway services) up and running in a local Kubernetes cluster is trivial.

## With The Tidepool Helper Script (recommended)

### Start the kubernetes server and store the Kubernetes server config locally

One-time initial startup:

```bash
tidepool server-init
```

This will save the Kubernetes server config to the path defined in your `$KUBECONFIG` environment variable. This is only required for the initial server provisioning.

For subsequent server starts, run:

```bash
tidepool server-start
```

### Start the tidepool services

```bash
tidepool start
```

This will start the Tidepool services in the kubernetes cluster via Tilt. You will see a terminal UI open that will allow you to view the both the build status, build logs and container logs for all of the Tidepool services.

### Stop the tidepool services

You can stop the Tidepool services either by exiting the Tilt UI with `ctrl-c`, or with the following terminal command:

```bash
tidepool stop
```

### Stop the kubernetes server

```bash
tidepool server-stop
```

## Without The Tidepool Helper Script

**NOTE:** All commands must be run from the root of this repo.

### Initial provisioning of the kubernetes server and registry

```bash
ctlptl apply -f 'Kindconfig.yaml'
```
This will save the Kubernetes server config to the path defined in your `$KUBECONFIG` environment variable. This is only required for the initial server provisioning.

For subsequent server starts, run:

```bash
docker start tidepool-kind-control-plane
docker start ctlptl-registry
```

### Start the tidepool services

```bash
# Start the tidepool services with Tilt,
# with trap to shut down properly upon exit
trap 'SHUTTING_DOWN=1 tilt down' EXIT; tilt up -dv --port=0 --legacy
```

### Stop the tidepool services

You can stop the Tidepool services either by exiting the Tilt UI with `ctrl-c`, or with the following terminal command:

```bash
export SHUTTING_DOWN=1; tilt down
```

### Stop the kubernetes server and registry

```bash
docker stop tidepool-kind-control-plane
docker stop ctlptl-registry
```

## Monitor Kubernetes State With K9s (Optional)

While the tilt terminal UI shows a good deal of information, there may be times as a developer that you want a little deeper insight into what's happening inside Kubernetes.

[K9s](https://k9ss.io/) is a CLI tool that provides a terminal UI to interact with your Kubernetes clusters.  It allows you to view in realtime the status of your Kubernetes pods and services, including CPU and memory usage metrics, without needing to learn the intricacies of `kubectl`, the powerful-but-complex Kubernetes CLI tool.

After [Installing the k9s CLI](https://github.com/derailed/k9s#installation), you can simply start the Terminal UI with:

```bash
k9s
```

[[back to top]](#welcome)

# Using Tidepool

## Identity And Access Management

Tidepool uses Keycloak as its main identity and access management solution. Legacy mongo user accounts are migrated from mongo to Keycloak as users sign in (so their credentials can be migrated as well).

Keycloak admin console is available at [http://localhost:32000/](http://localhost:32000/). To login as an administrtor you can use the default credentials:
```
username: admin
password: admin
```

The administrator credentials can be tweaked by setting KEYCLOAK_USER and KEYCLOAK_PASSWORD environment variables in the keycloak chart.

## Creating An Account

Once your local Tidepool is running, open your Chrome browser and browse to [http://localhost:31500/](http://localhost:31500). You should see the Tidepool login page running from your local computer, assuming everything worked as expected. Go ahead and signup for a new account. Remember, all accounts and data created via this local Tidepool are _ONLY_ stored on your computer. _No_ data is stored on any of the Tidepool servers.

## Verifying An Account Email

Since your local Tidepool does not have a configured email server, no emails will be sent at all. This includes the verification email sent during account creation. To get around this when running locally, you need to verify the email account manually.

Accounts created in Keycloak can be verified using the Keycloak admin console which is available at [http://localhost:8081/](http://localhost:8081/).

> Once viewing the Keycloak admin site, be sure to select the correct realm (probably "dev") via the drop-down in the upper left, under the Keycloak logo.

Legacy accounts in mongo can be verified in the database directly by setting the `authenticated` field to true for the user you've created, which can be found at `db.user.users`.

This can be done by connecting to the mongo client within the mongo container (out of scope for this document), or, more conveniently, with the `tidepool` helper script:

```bash
tidepool verify-account-email [user-email-address]
```

## Uploading Data

To upload diabetes device data to your local Tidepool, first make sure the [Tidepool Uploader](https://tidepool.org/products/tidepool-uploader) is installed on your computer. Follow the directions at [https://tidepool.org/products/tidepool-uploader](https://tidepool.org/products/tidepool-uploader).

After installing and launching the Tidepool Uploader, _but before logging in_, right-click on the "Log In" button. From the popup menu displayed, first select "Change server" and then select "localhost". This directs the Tidepool Uploader to upload data to the running local Tidepool rather than our production servers. Then, login to the Tidepool Uploader using the account just created.

NOTE: If you wish to upload to our official, production Tidepool later, you'll have to repeat these instructions, but select the "Production" server instead. Please do not use any server other than "localhost" or "Production", unless explicitly instructed to do so by Tidepool staff.

## Data Retention

Remember, this is all running on your computer only. This means that all accounts you create and all data you upload to your local Tidepool are _ONLY_ stored in a Mongo database located in the local directory on your computer.

Fortunately, at [Tidepool Web](https://app.tidepool.org), we worry about that for you and make sure all of your data is secure and backed up regularly.

[[back to top]](#welcome)

# Advanced Customization

## Tilt Config Overrides

Custom Tilt configuration and overrides of the Tidepool, MongoDB, and Gateway services is done through a `local/Tiltconfig.yaml` file.

While updates can be made directly to the root `Tiltconfig.yaml` file,making your changes to a local overrides file ensures that your changes are ignored by version control.

It also means less work for you when pulling in upstream updates to the root config file.

```bash
# Create an empty Tiltconfig.yaml file in your local directory
touch local/Tiltconfig.yaml
```

Both the root `Tiltconfig.yaml` and the overrides file is read by the `Tiltfile` (and `Tiltfile.mongodb` and `Tiltfile.proxy`) at the root of this repo, and any changes defined for the helm charts will be passed through to helm to override settings in the helm chart `values.yaml`.

In addition to the helm chart overrides, there are some extra configuration parameters to instruct Tilt on how to build local images for any of the Tidepool services.

See [Building Local Images](#building-local-images) for more details

## Dexcom API integration

The Dexcom API integration will not work out of the box as it requires a private developer id and secret known only to Dexcom and Tidepool. If you wish to enable this functionality, please see [https://developer.dexcom.com/](https://developer.dexcom.com/).

Once you receive a developer id and secret from Dexcom, you add them to your `local/Tiltconfig.yaml` file as follows:

```yaml
dexcom:
  secret:
    enabled: true
    data_:
      ClientId: "<dexcom-generated-client-id>"
      ClientSecret: "<dexcom-generated-client-secret>"
      StateSalt: "<some-text>"
```

NOTES:
 - ensure that in the dexcom developer setup the redirect URI is set correctly, for example if running locally `http://localhost:31500/v1/oauth/dexcom/redirect`

 - you will need to restart the tidepool services for the config changes to take effect

## Running Alternate Remote Images

By default, Tilt will pull and provision the images specified in the `values.yaml` file for the tidepool helm charts from the [Docker Hub](https://hub.docker.com/).

To pull and deploy a different image from the Docker Hub, simply uncomment and update the `deployment.image` value for the given service in your `local/Tiltconfig.yaml` file with any valid `image:tag` combination (See [Tilt Config Overrides](#tilt-config-overrides) if you haven't set up your local overrides file).

For instance, to have Tilt provision the latest remote image for `shoreline`:


```yaml
### Change this:
shoreline:
  # deployment:
  #   image: tidepool-k8s-shoreline
  # hostPath: '~/go/src/github.com/tidepool-org/shoreline'
  # ...

### To this:
shoreline:
  deployment:
    image: tidepool/shoreline:latest
  # hostPath: '~/go/src/github.com/tidepool-org/shoreline'
  # ...
```

**IMPORTANT:** You must leave the `hostPath` value for the service commented out if you want to deploy a remote image

[[back to top]](#welcome)

# Developing Tidepool Services

If you wish to build and run one or more Docker images locally using the latest-and-greatest source code, then you'll need to do a few more things.

## Image Source Repositories

First, you'll need to clone the GitHub repository you are interested in to your computer.


### Using development images

The `blip` service image uses a multistage Dockerfile to allow the option of building development environment images or minimal production-ready images from the same file.

By default, the production-ready image is pulled.

If you need to develop this repo, you need to ensure that you are pulling and running the image with the `develop` tag to be able to run yarn commands and unit tests, package linking, and other development tasks.

```bash
  blip:
    image: tidepool/blip
  # ...
```

becomes

```bash
  blip:
    image: tidepool/blip:develop
  # ...
```

### Mounting Local Volumes

| Repository Name                                                  | Docker Container Name (`<docker-container-name>`) | Description                     | Language                       | Git Clone URL (`<git-clone-url>`)                  | Default Clone Directory (`<default-clone-directory>`)     |
| ---------------------------------------------------------------- | ------------------------------------------------- | ------------------------------- | ------------------------------ | -------------------------------------------------- | --------------------------------------------------------- |
| [blip](https://github.com/tidepool-org/blip)                     | blip                                              | Web (ie. http://localhost:31500) | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/blip.git           | ../blip                                                      |
| [gatekeeper](https://github.com/tidepool-org/gatekeeper)         | gatekeeper                                        | Permissions                     | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/gatekeeper.git     | ../gatekeeper                                                |
| [highwater](https://github.com/tidepool-org/highwater)           | highwater                                         | Metrics                         | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/highwater.git      | ../highwater                                                 |
| [hydrophone](https://github.com/tidepool-org/hydrophone)         | hydrophone                                        | Email, Invitations              | [Golang](https://golang.org/)  | https://github.com/tidepool-org/hydrophone.git     | ~/go/src/github.com/tidepool-org/hydrophone               |
| [jellyfish](https://github.com/tidepool-org/jellyfish)           | jellyfish                                         | Data Ingestion [LEGACY]         | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/jellyfish.git      | ../jellyfish                                                 |
| [message-api](https://github.com/tidepool-org/message-api)       | message-api                                       | Notes                           | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/message-api.git    | ../message-api                                               |
| [platform](https://github.com/tidepool-org/platform)             | (see below)                                       | (see below)                     | [Golang](https://golang.org/)  | https://github.com/tidepool-org/platform.git       | ~/go/src/github.com/tidepool-org/platform                 |
| [seagull](https://github.com/tidepool-org/seagull)               | seagull                                           | Metadata                        | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/seagull.git        | ../seagull                                                   |
| [shoreline](https://github.com/tidepool-org/shoreline)           | shoreline                                         | Authentication                  | [Golang](https://golang.org/)  | https://github.com/tidepool-org/shoreline.git      | ~/go/src/github.com/tidepool-org/shoreline                |
| [tide-whisperer](https://github.com/tidepool-org/tide-whisperer) | tide-whisperer                                    | Download                        | [Golang](https://golang.org/)  | https://github.com/tidepool-org/tide-whisperer.git | ~/go/src/github.com/tidepool-org/tide-whisperer           |

Please note that the `platform` repository actually contains source code for multiple Docker services, specifically:

| Docker Container Name | Description                      |
| --------------------- | -------------------------------- |
| auth                  | Authentication                   |
| blob                  | Blob Storage                     |
| data                  | Data Ingestion (next generation) |
| migrations            | Database Migrations              |
| task                  | Background Jobs                  |
| tools                 | Tools, Utilities                 |
| user                  | Users                            |

NOTE: The Golang repositories include the extra-long directory hierarchy to ensure a unique, valid GOPATH. Read more about [Golang](https://golang.org/) and [GOPATH](https://golang.org/doc/code.html) for details.

```bash
  blip:
    image: tidepool/blip:develop
    depends_on:
      - hakken
    # build:
    #   context: ${TIDEPOOL_DOCKER_BLIP_DIR}
    #   target: 'develop'
    volumes:
      - ${TIDEPOOL_DOCKER_BLIP_DIR}:/app:cached
      - /app/node_modules
      - /app/dist
      # - ${TIDEPOOL_DOCKER_PLATFORM_CLIENT_DIR}:/tidepool-platform-client:cached
      # - /tidepool-platform-client/node_modules
      # - ${TIDEPOOL_DOCKER_TIDELINE_DIR}:/tideline:cached
      # - /tideline/node_modules
      # - ${TIDEPOOL_DOCKER_VIZ_DIR}:/@tidepool/viz:cached
      # - viz-dist:/@tidepool/viz/dist:ro

```bash
git clone <git-clone-url> <default-clone-directory>
```

For example, if you wanted to clone the `shoreline` repository:

```bash
git clone https://github.com/tidepool-org/shoreline.git ~/Tidepool/development/shoreline/src/github.com/tidepool-org/shoreline
```

### Alternate Source Repository Directory

You can alternatively clone the source repository to any directory on your computer. To do so, clone the repository to the directory of your choosing and update the value of `hostPath` in your local Tilt config for that service.

For example, if you wanted the `tide-whisperer` source code to be cloned into the `~/development/tide-whisperer` directory, then execute the command:

```bash
git clone https://github.com/tidepool-org/tide-whisperer.git ~/development/tide-whisperer
```

Then, update the `local/Tiltconfig.yaml` file as follows:

```yaml
tidewhisperer:
  hostPath: "~/development/tide-whisperer"
  # ...
```

**NOTE:** Ensure that any cloned Golang repositories end up in a valid GOPATH directory hierarchy.

## Building Local Images

To build and run a Docker image from the source code you just cloned, you simply need to uncomment the `deployment.image` and `hostPath` values for the given service in your `local/Tiltconfig.yaml` file (See [Tilt Config Overrides](#tilt-config-overrides) if you haven't set this up).

For instance, to have Tilt build a local image for `shoreline`:

```yaml
### Copy this service definition from the root Tiltconfig.yaml:
shoreline:
  # deployment:
  #   image: tidepool-k8s-shoreline
  # hostPath: "~/go/src/github.com/tidepool-org/shoreline"
  # ...

### Paste it into your local/Tiltconfig.yaml file and make your updates:
shoreline:
  deployment:
    image: tidepool-k8s-shoreline
  hostPath: "~/go/src/github.com/tidepool-org/shoreline"
  # ...
```

### Automatic Service Rebuilding And Reloading

All service containers built locally with Tilt will automatically rebuild/reload whenever file changes are detected.

Most changes will leave the container itself deployed and simply restart the main container process (the Dockerfile `ENTRYPOINT` and/or `CMD`).

Changes to the `Dockerfile` for any Tilt-built image will trigger a new image build and a new service container will be deployed once it's ready.

Any changes to the Tilt config that warrant a new image build will also trigger a new image build and service container deployment.

### Custom Service Rebuild Command

While automatic rebuilds are currently set up for all Tidepool services, it is possible to specify a custom rebuild command that will run


## Custom Docker Build Parameters

### Set Build Target Environment Variable

All of the Tidepool services uses a multi-target `Dockerfile` to build the Docker images. This means there is a `development` target, which includes all of the necessary development tools, and a `production` target, which contains only the final binaries. The default, if no target is specified, is `development`

To set a different build tarket, update the `buildTarget` value for the service config in your `local/Tiltconfig.yaml` file.

For example, if you wanted to build the production `blip` service image:

```yaml
blip:
  deployment:
    image: tidepool-k8s-blip
  hostPath: ../blip
  buildTarget: production # <- Add this
  # ...
```

### Use Custom Dockerfile

By default, Tilt will build using the `Dockerfile` at the root of the specified `hostPath` for a given service.

To use a different Dockerfile, set or update the `dockerFile` value for the service config in your `local/Tiltconfig.yaml` file.

For example, if you created a custom `Dockerfile.myBlip` file at the root of the `blip` repo, update the `blip` service config as follows:

```yaml
blip:
  deployment:
    image: tidepool-k8s-blip
  hostPath: ../blip
  dockerFile: Dockerfile.myBlip # Add custom dockerfile here
  buildTarget: myBuildTarget # Set to false if not a multistage Dockerfile
  # ...
```

## Linking And Un-Linking Tidepool Web NPM Packages

Making changes to our primary web application, Tidepool Web, which goes by the service name `blip`, is exactly the same process as all of the other services as long as all the changes required can be made within the `blip` repository.

If a feature requires changes to any of our supporting NPM packages (listed below), they need to be mounted into the `blip` service container and linked via NPM

First, you'll need to clone the GitHub repository you are interested in to your computer.

Here is a list of the Tidepool npm packages you may need to make changes to:

| Package Name             | Service Name    | Description                                                     | Git Clone URL (`<git-clone-url>`)               | Default Clone Directory (`<default-clone-directory>`)|
| ---                      | ---             | ---                                                             | ---                                             | ---                                                  |
| @tidepool/viz            | viz             | Component Visualization and Data Pre-Processing                 | https://github.com/tidepool-org/viz             | ../viz                                               |
| tideline                 | tideline        | Legacy Component Visualization and Data Pre-Processing          | https://github.com/tidepool-org/tideline        | ../tideline                                          |
| tidepool-platform-client | platform-client | Client-side library to interact with the Tidepool  backend APIs | https://github.com/tidepool-org/platform-client | ../platform-client                                   |

Choose one of the above repositories and clone locally using the following command. Replace `<git-clone-url>` with the appropriate Git Clone URL from the above table. Replace `<default-clone-directory>` with the appropriate Default Clone Directory from the above table.

```bash
git clone <git-clone-url> <default-clone-directory>
```

For example, if you wanted to clone the `viz` service repository:

```bash
git clone https://github.com/tidepool-org/viz.git ../viz
```

### Linking A Package With Tilt Config

Next, you need to set the linked package's `enabled` value to `true` in your `local/Tiltconfig.yaml` file.

You will also need to ensure that the `blip.deployment.image` and `blip.hostPath` values are uncommented

```yaml
blip:
  deployment:
    image: tidepool-k8s-blip # Uncommented
  hostPath: ../blip # Uncommented and path matches the cloned blip repo location
  containerPath: "/app"
  apiHost: "http://localhost:31500"
  webpackDevTool: cheap-module-eval-source-map
  webpackPublicPath: "http://localhost:31500"
  linkedPackages:
    - name: tideline
      packageName: tideline
      hostPath: ../tideline
      enabled: false

    - name: tidepool-platform-client
      packageName: tidepool-platform-client
      hostPath: ../platform-client
      enabled: false

    - name: viz
      packageName: "@tidepool/viz"
      hostPath: ../viz # Path matches where the cloned viz repo location
      enabled: true # Set from false to true
```

When you save this, if the services are already running, or you start the services with `tidepool start`, Tilt will automatically build and deploy a new `blip` container image with the `viz` repo package mounted at `/app/packageMounts/@tidepool/viz`, and will have already installed the `viz` npm dependancies and `npm link`-ed the package to `blip`

### Un-Linking A Package With Tilt Config

If you set `enabled` for the `viz` package back to `false` in your `local/Tiltconfig.yaml` file, Tilt will automatically build and deploy a new `blip` container image without the package link.

```yaml
blip:
  deployment:
    image: tidepool-k8s-blip
  hostPath: ../blip
  containerPath: "/app"
  apiHost: "http://localhost:31500"
  webpackDevTool: cheap-module-eval-source-map
  webpackPublicPath: "http://localhost:31500"
  linkedPackages:
    # ...
    - name: viz
      packageName: "@tidepool/viz"
      hostPath: ../viz
      enabled: false # Set from true back to false
  # ...
```
### Troubleshooting Webpack Dev Server issues in blip or viz with Docker For Mac

From time to time, the Webpack Dev Server started by the `blip` or `viz` npm `start` scripts will stop detecting file changes, which will stop the live recompiling.  It is unclear why this occurs, but the following steps seem to fix it:

Examples for `blip`.  Simply replace with `viz` as needed.

```bash
# First, try a simple restart of the service
docker-compose restart blip

# This will often do it.  If not, try bringing down the full stack and restarting
docker-compose down
docker-compose up

# If this doesn't work, try restarting Docker For Mac and bring up the stack as per ussual.
# On very rare occasions, there is a corrupted volume mount.
# To fix this, remove the container and it's volumes, and restart the service
docker-compose rm -fsv blip
docker-compose up blip
```

# Tidepool Helper Script

Included in the `bin` directory of this repo is a bash script named `tidepool_docker`.

## Working With Yarn For NodeJS Services

Running your development environment in Docker is great for a number of reasons, but it does complicate package management when working with Node.js projects.

The main issue is that you can't manage your node packages in the container using your local installation of `npm` or `yarn` (which we use) because the `node_modules` folder does not get volume-mounted into the containers.

This is for performance reasons, but also because we want the packages to be compiled for and running in the same environment/operating system (`linux` in our case).

This results in us having to issue our `yarn` commands from **_within_** the containers, instead of from our native operating system.

The `tidepool` helper script (see [Add Tidepool Helper Script](#add-tidepool-helper-script-recommended)) allows us to shell into a container and run commands.

```bash
# Shell into the container from your local terminal
tidepool exec blip sh

# You will now be 'inside' the container in the /app directory
yarn install
# The node_modules folder will now be updated with the latest packages, and the yarn.lock file updated

# Now we exit the container and return to our local terminal shell
exit
```

This is overkill when just doing a simple command (streamlined alternative outlined below), but it's very hand when you need to perform multiple operations or simply poke around the container's file system.


| Command                       | Description                                                              |
|-------------------------------|--------------------------------------------------------------------------|
| `up [service]`                | Start the Kubernetes server and Tidepool services, in that order         |
| `down`                        | Stop the Tidepool services and Kubernetes server, in that order          |
| `destroy`                     | Shut down and completely remove the local Kubernetes server and services |
| `start`                       | Provision and start the Tidepool services via Tilt                       |
| `stop`                        | Stop and remove the Tidepool services via Tilt                           |
| `restart [service]`           | Restart the specified service                                            |
| `logs [service]`              | tail logs for the entire tidepool stack or the specified service         |
| `exec service [...cmds]`      | run arbitrary shell commands in the currently running service container  |
| `yarn node_service [...cmds]` | shortcut to run yarn commands against the specified Node.js service      |
| `help`                        | show more detailed usage text than what's listed here                    |

```bash
# Examples (from your local terminal)

# Perform an install
tidepool yarn blip # Could specify install, but it's implied as the default command

# Run an npm script, such as a test-watch
tidepool yarn blip test-watch

# Run the linked @tidepool/viz storybook
tidepool yarn @tidepool/viz stories

# IMPORTANT STEP: in a separate tab, expose the storybook port
# in the blip service so you can access the storybook UI from your browser
tidepool port-forward blip 8083
```

### Persisting Yarn Lockfile Updates

**IMPORTANT:** If you were to add a new NPM package directly (or otherwise update the `yarn.lock` or `package.json`) within the container using the above `tidepool yarn` helper, it would work within that container, but these changes would **_NOT_** propogate back to your host filesystem.

To persist updates to your `yarn.lock` (or `package-lock.json` in some repos) and `package.json` files, you should run the `yarn` or `npm` commands locally.

This will allow your changes to be tracked properly in version control, and Tilt is configured to recognize when a `yarn.lock` or `package-lock.json` file changes and will automatically run `yarn install` for you in the service container (so you don't have to do it in 2 places).


| Service                                                           | Standard Port(s)       |
| ----------------------------------------------------------------- | ---------------------- |
| [blip](https://github.com/tidepool-org/blip)                      |                 31500                   |
| [export](https://github.com/tidepool-org/export)                  | 9300                   |
| [gatekeeper](https://github.com/tidepool-org/gatekeeper)          | 9123                   |
| [hakken](https://github.com/tidepool-org/hakken)                  | 8000                   |
| [highwater](https://github.com/tidepool-org/highwater)            | 9191                   |
| [hydrophone](https://github.com/tidepool-org/hydrophone)          | 9157                   |
| [jellyfish](https://github.com/tidepool-org/jellyfish)            | 9122                   |
| [message-api](https://github.com/tidepool-org/message-api)        | 9119                   |
| [platform-auth](https://github.com/tidepool-org/platform)         | 9222                   |
| [platform-blob](https://github.com/tidepool-org/platform)         | 9225                   |
| [platform-data](https://github.com/tidepool-org/platform)         | 9220                   |
| [platform-migrations](https://github.com/tidepool-org/platform)   | N/A (see below)        |
| [platform-task](https://github.com/tidepool-org/platform)         | 9224                   |
| [platform-tools](https://github.com/tidepool-org/platform)        | N/A (see below)        |
| [platform-user](https://github.com/tidepool-org/platform)         | 9221                   |
| [seagull](https://github.com/tidepool-org/seagull)                | 9120                   |
| [shoreline](https://github.com/tidepool-org/shoreline)            | 9107                   |
| [styx](https://github.com/tidepool-org/styx)                      | 8009, 8010 (see below) |
| [tide-whisperer](https://github.com/tidepool-org/tide-whisperer)  | 9127                   |

[[back to top]](#welcome)

# Misc

## Tracing Internal Services

Sometimes, you'll want to capture some or all of the network traffic that flows into and between the various Tidepool services.

Unfortunately, due the version of the Gloo gateway (which handles internal networking between the Tidepool services) that we are currently using, we don't yet have an easy way to do this.

The good news is that we anticipate upgrading the Gloo version in the near future, and will support [Envoy's tracing capabilities](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing.html), as outlined in the [Gloo Tracing Documentation](https://gloo.solo.io/advanced_configuration/tracing/).

Stay Tuned :)

## Troubleshooting

| Issue                                                           | Things to try                                                                                                                                                                                                                                                                                                                           |
| ---                                                             | ---                                                                                                                                                                                                                                                                                                                                     |
| kubectl errors when provisioning services                       | Make sure you've set the `KUBECONFIG` environment variable. See [Environment Setup (recommended)](#environment-setup-recommended) and [Retrieve and store the Kubernetes server config](#retrieve-and-store-the-kubernetes-server-config)                                                                                               |
| kubectl errors when starting k9s                                | Make sure you've set the `KUBECONFIG` environment variable. See [Environment Setup (recommended)](#environment-setup-recommended) and [Retrieve and store the Kubernetes server config](#retrieve-and-store-the-kubernetes-server-config)                                                                                               |
| Tidepool Web ('blip') not loading                               | Check the service logs, either in the Tilt UI or with `tidepool logs blip` to make sure it's finished compiling successfully.  If it has compiled, see [Tidepool Web becomes inaccessible](#tidepool-web-becomes-inaccessible)                                                                                                          |
| `tidepool start` hangs at "Preparing gateway services..."       | NOTE: It's normal for this to take a few minutes the first time you run this. Otherwise, check to see if gloo gateway pods are still provisioning in [k9s](#monitor-kubernetes-state-with-k9s-optional), and if so, wait, else cancel the `tidepool start` process and re-run it                                                        |
| `tidepool start` has numerous "Bad Address: shoreline" errors   | NOTE: It's normal for this to happen while services wait for shoreline to be provisioned.  This can go on for a quite a while during the first time running the stack, due to the extra time it takes to download all the service images. Give it a few minutes, and as long as shoreline comes up eventually, it should resolve itself |
| Services are crashed and k9s shows them in an **evicted** state | The docker environment running the k8s server node has run out of disk space, likely due to old image build layers. Run `tidepool server-prune`. Afterwards, within a few minutes, services should begin re-deploying again automatically                                                                                               |

## Known Issues

### Tilt UI errors on service(s), but shows `Running` status

As long as your Tidepool services are working properly for you, you can likely ignore these errors.

When a container is started, there may be initial errors while it waits for other services to be ready. Kubernetes should get everything up and running eventually, but the Tilt UI will not remove the error messages that occured on the initial attempts.

This is where it's nice to run [k9s](#monitor-kubernetes-state-with-k9s-optional) alongside Tilt, as it reports the current service states accurately.

**NOTE:** You can highlight any service in the Tilt UI and hit `2` to see the build logs for the service, and `3` to view the runtime logs, which can be helpful in assessing the current state.  The log pane in the UI is quite small by default, but hitting `x` will cycle through the various sizes available, up to full-height.

### Tilt K8s event reporting can be unreliable

When Tilt is provisioning services, it polls the K8s server events to get the current state of a service, such as when a pod is pending, initializing, running, crashed, etc.

Usually, this works just fine, but every now and then it stops sycning the K8s events properly. This seems to occur most often on the first time starting the services where everything takes longer, and perhaps Tilt is timing out.

If your services are running properly, you can simply ignore the state reporting in Tilt. Otherwise, simply restarting the Tilt process (`ctrl-c` and then `tidepool start` again) should fix it.

### Tidepool Web becomes inaccessible

Currently, there is a known issue where at times the gateway proxy service that handles incoming requests loses track of the local blip service.

This will present itself usually with the web app getting stuck in a loading state in the browser, or possibly resolving with an error message like: `‘No healthy upstream on blip (http://localhost:31500)`

The solution first solution to try is to restart the gloo `gateway` services, which should restore access in a few moments:

```bash
tidepool restart-gateway
```

If this doesn't work, simply stop the running `tidepool start` process, and re-run it. This will terminate and re-provision the entire stack, and should fix the issue. This second approach is often needed after the initial provisioning of the stack, likely due to some timeouts stemming from the extra time it takes for all the images to be downloaded the first time.

[[back to top]](#welcome)
