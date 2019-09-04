# Welcome!

Welome to [Tidepool](https://tidepool.org) at GitHub!

This GitHub repository is your launching pad to running and developing the Tidepool software on your very own computer. You can use it to run your own installation of Tidepool, take a quick peek at the Tidepool code, and even help us at Tidepool design and develop the next new and amazing feature!

Of course, if you haven't already done so, you should check out [Tidepool](https://tidepool.org) and [Tidepool Web](https://app.tidepool.org). It's a snap to create an account, upload your or your loved one's diabetes device data, and visualize it all in one place. We've already done the hard work of setting up the servers, software, databases, backups, and more, so you don't have to. Check it out!

## Quick Links

- [Initial Setup](#initial-setup)
  - [Install Docker](#install-docker)
  - [Install Docker Compose](#install-docker-compose)
  - [Install Helm](#install-helm)
  - [Install Tilt](#install-tilt)
  - [Clone This Repository](#clone-this-repository)
  - [Add Tidepool Helper Script (recommended)](#add-tidepool-helper-script-recommended)
  - [Environment Setup (recommended)](#environment-setup-recommended)
- [Quick Start](#quick-start)
  - [With the tidepool helper script (recommended)](#with-the-tidepool-helper-script-recommended)
  - [Without the tidepool helper script](#without-the-tidepool-helper-script)
  - [Monitor Kubernetes state with k9s (Optional)](#monitor-kubernetes-state-with-k9s-optional)
- [Using Tidepool](#using-tidepool)
  - [Creating An Account](#creating-an-account)
  - [Verifying An Account Email](#verifying-an-account-email)
  - [Uploading Data](#uploading-data)
  - [Data Retention](#data-retention)
- [Advanced Customization](#advanced-customization)
  - [Tilt Config Overrides](#tilt-config-overrides)
  - [Alternate Mongo Host](#alternate-mongo-host)
  - [Dexcom API integration](#dexcom-api-integration)
  - [Running Alternate Remote Images](#running-alternate-remote-images)
- [Developing Tidepool Services](#developing-tidepool-services)
  - [Image Source Respositories](#image-source-repositories)
  - [Building Local Images](#building-local-images)
  - [Custom Docker Build Parameters](#custom-docker-build-parameters)
- [Troubleshooting](#troubleshooting)
- [Known Issues](#known-issues)

- DEPRECATED?
  - [Tracing](#tracing)

# Initial Setup

It's easy to get up and running quickly as long as you know a bit about your computer and your way around a terminal window.

**WINDOWS USERS:**

Currently, our local development environment only works natively in MacOS and Linux environments. To run within Windows, we recommend you set up and run within a Linux VM via a virtualization tool such as VirtualBox or VMWare. We hope to natively support Windows in an upcoming iteration.

_Very_ determined Windows users may be able to get it working in it's current form with [GitBash](https://git-for-windows.github.io/), [Cygwin](https://www.cygwin.com/) or the new [Bash integration in Windows 10](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide).

If you do get this working on Windows before we get to it, please consider contributing back to the community with a pull request.

## Install Docker

The Tidepool stack relies on [Docker](https://www.docker.com) and [Docker Compose](https://docs.docker.com/compose) to run all of the code on your computer.

Follow the appropriate link for your platform (Mac OSx or Linux recommended) at https://docs.docker.com/install/#supported-platforms and follow the directions to install and run Docker on your computer.

## Install Docker Compose

We use [Docker Compose](https://docs.docker.com/compose/) to run a local Kubernetes cluster within Docker. There are a number of _Kubernetes-in-Docker_ solutions available, but the one we've settled on as offering the best all-around fit for local development is [bsycorp/kind](https://github.com/bsycorp/kind/).

If you installed Docker Desktop, the `docker-compose` tool will have been automatically installed with it.  If you installed Docker on Linux, you'll need to download the binary by following the [Docker Compose Installation Instructions](https://docs.docker.com/compose/install/#install-compose)

## Install Helm

The Tidepool services (and supporting services such as the [MongoDB](https://www.mongodb.com/) database and the [Gloo Gateway](https://gloo.solo.io/) for routing requests) are defined by [Helm](https://helm.sh/) templates, which the `helm` tool uses to convert into manifests that can be applied to the our local [Kubernetes](https://kubernetes.io/) (K8s) cluster.

Please install the `helm` CLI tool via the [Helm Installation Instructions](https://helm.sh/docs/using_helm/#installing-helm).

## Install Tilt

Managing a K8s cluster can be very challenging, and even more so when using one for local development. [Tilt](https://tilt.dev/) is a CLI tool used to simplify and streamline management of local development services within a Kubernetes cluster.

By using our Tilt setup, developers can very easily run a live-reloading instance of any of our frontend or backend services without needing to directly use or understand Helm or Kubernetes. All that's needed is uncommenting a couple of lines in a `Tiltconfig.yaml` file, and updating the local paths to where the developer has checked out the respective git repo, if different than the default defined in the config.

**IMPORTANT NOTE:** We currently run against version `v0.9.7` of Tilt, so be sure to install the correct version when following the [Tilt Installation Instructions](https://docs.tilt.dev/install.html#alternative-installation).

```bash
# MacOS
curl -fsSL https://github.com/windmilleng/tilt/releases/download/v0.9.7/tilt.0.9.7.mac.x86_64.tar.gz | tar -xzv tilt && sudo mv tilt /usr/local/bin/tilt

# Linux
curl -fsSL https://github.com/windmilleng/tilt/releases/download/v0.9.7/tilt.0.9.7.linux.x86_64.tar.gz | tar -xzv tilt && sudo mv tilt /usr/local/bin/tilt
```

After installing Tilt, you can verify the correct version by typing `tilt version` in your terminal.

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

You can run the script from the root directory of this repo from your terminal with:

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

## Environment Setup (recommended)

There are 2 environment variables that we recommend you export before starting up the Tidepool stack for the first time.

It's recommended that you export them in a persistent way, such as within your local `~/.bash_profile` (or whatever equivalent you use)

`KUBECONFIG` - This is the path used by Tilt to issue commands to your Kubernetes cluster.

```bash
export KUBECONFIG="$HOME/.kube/config"
```

`TIDEPOOL_DOCKER_MONGO_VOLUME` - This is the path used to persist your local MongoDB data. You don't need to set this, but if you don't, you'll be restarting from a blank slate each time you start up your dev environment.

For example, if you want to store the Mongo data in the `~/MyMongoData` directory, then just set the value of the environment variable like so:

```bash
export TIDEPOOL_DOCKER_MONGO_VOLUME="~/MyMongoData"
```

[[back to top]](#quick-links)

# Quick Start

Once you've completed the [Initial Setup](#initial-setup), getting the Tidepool services (including supporting services such as the database and gateway services) up and running in a local Kubernetes cluster is trivial.

## With the tidepool helper script (recommended)

### Start the kubernetes server

```bash
tidepool server-start
```

### Retrieve and store the Kubernetes server config

```bash
tidepool server-set-config
```

This will save the Kubernetes server config to ~/.kube/config. This is only required after the initial server start provisioning.

### Start the tidepool services

```bash
tidepool start
```

This will start the Tidepool services in the kubernetes cluster via Tilt. You will see a terminal UI open that will allow you to view the both the build logs and container logs for all of the Tidepool services.

### Stop the tidepool services

You can stop the Tidepool services either by exiting the Tilt UI with `ctrl-c`, or with the following terminal command:

```bash
tidepool stop
```

### Stop the kubernetes server

```bash
tidepool server-stop
```

## Without the tidepool helper script

**NOTE:** All commands must be run from the root of this repo.

### Start the kubernetes server

```bash
docker-compose -f 'docker-compose.k8s.yml' up -d
```

### Retrieve and store the Kubernetes server config

We need to save the Kubernetes server config to ~/.kube/config. This is only required after the initial server start provisioning.

First, we need to confirm server has completely started by tailing the server logs:

```bash
docker-compose -f 'docker-compose.k8s.yml' logs -f server
```

We can move on once we see the following message:

```bash
INFO exited: start (exit status 0; expected)
```

Now that the server has started, we need to retrieve the Kubernetes config and store it to the path we exported our `KUBECONFIG` variable to.

```bash
# Replace ~/.kube/config as needed if you
# chose a different path for KUBECONFIG
curl http://127.0.0.1:10080/config > ~/.kube/config
```


### Start the tidepool services

```bash
# First, set the DOCKER_HOST variable to allow using the docker process
# inside the server container for retrieving and building images
export DOCKER_HOST=tcp://127.0.0.1:2375

# Start the tidepool services with Tilt,
# with trap to shut down properly upon exit
trap 'SHUTTING_DOWN=1 tilt down' EXIT; tilt up --port=0
```

### Stop the tidepool services

You can stop the Tidepool services either by exiting the Tilt UI with `ctrl-c`, or with the following terminal command:

```bash
export SHUTTING_DOWN=1; tilt down
```

### Stop the kubernetes server

```bash
docker-compose -f 'docker-compose.k8s.yml' stop
```

## Monitor Kubernetes state with k9s (Optional)

While the tilt terminal UI shows a good deal of information, there may be times as a developer that you want a little deeper insight into what's happening inside Kubernetes.

[K9s](https://k9ss.io/) is a CLI tool that provides a terminal UI to interact with your Kubernetes clusters.  It allows you to view in realtime the status of your Kubernetes pods and services without needing to learn the intricacies of `kubectl`, the powerful-but-complex Kubernetes CLI tool.

After [Installing the k9s CLI](https://github.com/derailed/k9s#installation), you can simply start the Terminal UI with:

```bash
k9s
```

[[back to top]](#quick-links)

# Using Tidepool

## Creating An Account

Once your local Tidepool is running, open your Chrome browser and browse to http://localhost:3000. You should see the Tidepool login page running from your local computer, assuming everything worked as expected. Go ahead and signup for a new account. Remember, all accounts and data created via this local Tidepool are _ONLY_ stored on your computer. _No_ data is stored on any of the Tidepool servers.

## Verifying An Account Email

Since your local Tidepool does not have a configured email server, no emails will be sent at all. This includes the verification email sent during account creation. To get around this when running locally, you need to verify the email account in the mongo database directly by setting the `authenticated` field to true for the user you've created, which can be found at `db.user.users`.

This can be done by connecting to the mongo client within the mongo container (out of scope for this document), or, more conveniently, with the `tidepool` helper script:

```bash
tidepool verify-account-email [user-email-address]
```

## Uploading Data

To upload diabetes device data to your local Tidepool, first make sure the [Tidepool Uploader](https://tidepool.org/products/tidepool-uploader) is installed on your computer. Follow the directions at https://tidepool.org/products/tidepool-uploader.

After installing and launching the Tidepool Uploader, _but before logging in_, right-click on the "Log In" button. From the popup menu displayed, first select "Change server" and then select "Local". This directs the Tidepool Uploader to upload data to the running local Tidepool rather than our production servers. Then, login to the Tidepool Uploader using the account just created.

NOTE: If you wish to upload to our official, production Tidepool later, you'll have to repeat these instructions, but select the "Production" server instead. Please do not use any server other than "Local" or "Production", unless explicitly instructed to do so by Tidepool staff.

## Data Retention

Remember, this is all running on your computer only. This means that all accounts you create and all data you upload to your local Tidepool are _ONLY_ stored in a Mongo database located in the local directory on your computer that you defined with the `TIDEPOOL_DOCKER_MONGO_VOLUME` environment variable (See [Environment Setup (recommended)](#environment-setup-recommended)). If you delete that directory, then all of the data you uploaded locally is gone, **permanently**. If you are going to run Tidepool locally as a permanent solution, then we very **strongly** suggest regular backups of the `mongo` directory.

Fortunately, at [Tidepool Web](https://app.tidepool.org), we worry about that for you and make sure all of your data is secure and backed up regularly.

[[back to top]](#quick-links)

# Advanced Customization

## Tilt Config Overrides

Custom Tilt configuration and overrides of the Tidepool, MongoDB, and Gateway services is done through a local copy of the `Tiltconfig.yaml` file, which should be copied to `local/Tiltconfig.yaml` and updated there.

While updates can be made directly to the root `Tiltconfig.yaml` file,making your changes to the local copy ensures that they are made in a directory that's ignored by version control.

```bash
cp Tiltconfig.yaml local/Tiltconfig.yaml
```

The overrides file is read by the `Tiltfile` (and `Tiltfile.mongodb` and `Tiltfile.proxy`) at the root of this repo, and any changes defined for the helm charts will be passed through to helm to override settings in the helm chart `values.yaml`.

In addition to the helm chart overrides, there are some extra configuration parameters to instruct Tilt on how to build local images for any of the Tidepool services.

See [Building Local Images] for more details

## Alternate Mongo Host

If you wish to use an alternate Mongo host running outside of Docker, then you'll need to do a few things.

Update the `global.mongo` section in your `local/Tiltconfig.yaml` file as required, and set the `mongodb.useExternal` flag to `true`. For example:

```yaml
global:
  mongo:
    await: 'true'                  # whether to await for mongo to be ready before starting services
    hosts: 'http://my_mongo_host'  # comma-separated list of Mongo hosts
    port: 27017                    # the Mongo port to connect to
    username: ''                   # a username in the Mongo instance
    ssl: 'false'                   # whether to use SSL to communicate with Mongo
    optParams: ''                  # optional parameters to pass on the Mongo connection string
  # ...

mongodb:
  useExternal: true
  # ...
```

If you are running Mongo natively on your local Mac (not in Docker, but via another installation, such as [Homebrew](https://brew.sh/)), then you can use the Docker-specific, container-accessible-only address `docker.for.mac.host.internal` to point to the alternate Mongo host. For example,

```yaml
global:
  mongo:
    hosts: 'docker.for.mac.host.internal'
    # ...
```

If the alternate Mongo host requires a TLS/SSL connection, be sure to set the `global.mongo.ssl` flag to `true`.

## Dexcom API integration

The Dexcom API integration will not work out of the box as it requires a private developer id and secret known only to Dexcom and Tidepool. If you wish to enable this functionality, please see https://developer.dexcom.com/.

Once you receive a developer id and secret from Dexcom, you add them to your `local/Tiltconfig.yaml` file as follows:

```yaml
global:
  secrets:
    dexcomClientId: ""
    dexcomClientSecret: ""
    # ...
```

## Running Alternate Remote Images

By default, Tilt will pull and provision the images specified in the `values.yaml` file for the tidepool helm charts from the [Docker Hub](https://hub.docker.com/).

To pull and deploy a different image from the Docker Hub, simply uncomment and update the `image` value for the given service in your `local/Tiltconfig.yaml` file with any valid `image:tag` combination (See [Tilt Config Overrides](#tilt-config-overrides) if you haven't set up your local overrides file).

For instance, to have Tilt provision the latest remote image for `shoreline`:


```yaml
### Change this:
shoreline:
  # image: tidepool-k8s-shoreline
  # hostPath: '~/go/src/github.com/tidepool-org/shoreline'
  # ...

### To this:
shoreline:
  image: tidepool/shoreline:latest
  # hostPath: '~/go/src/github.com/tidepool-org/shoreline'
  # ...
```

**IMPORTANT:** You must leave the `hostPath` value for the service commented out if you want to deploy a remote image

[[back to top]](#quick-links)

# Developing Tidepool Services

If you wish to build and run one or more Docker images locally using the latest-and-greatest source code, then you'll need to do a few more things.

## Image Source Repositories

First, you'll need to clone the GitHub repository you are interested in to your computer.

You can choose from the following active repositories:

| Repository Name                                                  | Docker Container Name (`<docker-container-name>`) | Description                     | Language                       | Git Clone URL (`<git-clone-url>`)                  | Default Clone Directory (`<default-clone-directory>`)     |
| ---------------------------------------------------------------- | ------------------------------------------------- | ------------------------------- | ------------------------------ | -------------------------------------------------- | --------------------------------------------------------- |
| [blip](https://github.com/tidepool-org/blip)                     | blip                                              | Web (ie. http://localhost:3000) | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/blip.git           | ../blip                                                      |
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
| notification          | Notifications (TBD)              |
| task                  | Background Jobs                  |
| tools                 | Tools, Utilities                 |
| user                  | Users                            |

NOTE: The Golang repositories include the extra-long directory hierarchy to ensure a unique, valid GOPATH. Read more about [Golang](https://golang.org/) and [GOPATH](https://golang.org/doc/code.html) for details.

Choose one of the above repositories and clone locally using the following command. Replace `<git-clone-url>` with the appropriate Git Clone URL from the above table. Replace `<default-clone-directory>` with the appropriate Default Clone Directory from the above table.

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
  hostPath: '~/development/tide-whisperer'
  # ...
```

**NOTE:** Ensure that any cloned Golang repositories end up in a valid GOPATH directory hierarchy.

## Building Local Images

To build and run a Docker image from the source code you just cloned, you simply need to uncomment the `image` and `hostPath` values for the given service in your `local/Tiltconfig.yaml` file (See [Tilt Config Overrides](#tilt-config-overrides) if you haven't set this up).

For instance, to have Tilt build a local image for `shoreline`:

```yaml
### Change this:
shoreline:
  # image: tidepool-k8s-shoreline
  # hostPath: '~/go/src/github.com/tidepool-org/shoreline'
  # ...

### To this:
shoreline:
  image: tidepool-k8s-shoreline
  hostPath: '~/go/src/github.com/tidepool-org/shoreline'
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
  image: tidepool-k8s-blip
  hostPath: ../blip
  dockerFile: Dockerfile.myBlip # Add custom dockerfile here
  buildTarget: myBuildTarget # Set to false if not a multistage Dockerfile
  # ...
```

## Developing Front End Services

Making changes to our primary web application, Tidepool Web, which goes by the service name `blip`, is exactly the same process as all of the other services as long as all the changes required can be made within the `blip` repository.

If a feature requires developing any of our supporting NPM libraries, such as `@tidepool/viz`, `tideline`, or `platform-client`, they need to be mounted into the `blip` service container and linked via NPM

See

### Tidepool Front End NPM Packages

Here is a list of the Tidepool npm packages you may need to make changes to:

| Package Name             | Service Name    | Repository URL                                  | Description                                                     |
| ---                      | ---             | ---                                             | ---                                                             |
| @tidepool/viz            | viz             | https://github.com/tidepool-org/viz             | Component Visualization and Data Pre-Processing                 |
| tideline                 | tideline        | https://github.com/tidepool-org/tideline        | Legacy Component Visualization and Data Pre-Processing          |
| tidepool-platform-client | platform-client | https://github.com/tidepool-org/platform-client | Client-side library to interact with the Tidepool  backend APIs |


### Working with node package managers in Docker (`npm`, `yarn`)

Running your development environment in Docker is great for a number of reasons, but it does complicate package management when working with Node.js projects.

The main issue is that you can't manage your node packages in the container using your local installation of `npm` or `yarn` (which we use) because the `node_modules` folder does not get volume-mounted into the containers.

This is for performance reasons, but also because we want the packages to be compiled for and running in the same environment/operating system (`linux` in our case).

This results in us having to issue our `yarn` commands from **_within_** the containers, instead of from our native operating system.

Docker Compose provides a couple ways for us to get _into_ the service containers to run our commands. Here are a couple of examples of how to run a `yarn install` for the `blip` service:

#### Using `docker-compose exec` to enter an interactive prompt within the container

```bash
# Shell into the container from your local terminal
docker-compose exec blip sh

# You will now be 'inside' the container in the /app directory
yarn install
# The node_modules folder will now be updated with the latest packages, and the yarn.lock file updated

# Now we exit the container and return to our local terminal shell
exit
```

This is overkill when just doing a simple command (streamlined alternative outlined below), but it's very hand when you need to perform multiple operations or simply poke around the container's file system.

#### Using `docker-compose exec` to issue a one-off command in the container with the `sh -c` flag

```bash
# Examples (from your local terminal)

# Perform an install
docker-compose exec blip sh -c "yarn install"

# Run an npm script, such as a test-watch
docker-compose exec blip sh -c "yarn run test-watch"
```

### Linking other node packages into `blip`

### Running the `viz` service

Unlike the other frontend Node.js services that blip uses, `viz` can also be run as a standalone service.

In fact, it **_must_** be running if you are planning to link it into `blip`, as the webpack bundling needs to run (which it does when the service container starts, and when mounted files change).

There are times, however, where you may want to run it on it's own without linking into `blip`, such as if you're working on new prototypes in `viz`'s Storybooks.

[[back to top]](#quick-links)

# Troubleshooting

| Issue                                     | Things to try                                                                                                                                                                                                                             |
| ---                                       | ---                                                                                                                                                                                                                                       |
| kubectl errors when provisioning services | Make sure you've set the `KUBECONFIG` environment variable. See [Environment Setup (recommended)](#environment-setup-recommended) and [Retrieve and store the Kubernetes server config](#retrieve-and-store-the-kubernetes-server-config) |
| kubectl errors when starting k9s          | Make sure you've set the `KUBECONFIG` environment variable. See [Environment Setup (recommended)](#environment-setup-recommended) and [Retrieve and store the Kubernetes server config](#retrieve-and-store-the-kubernetes-server-config) |

[[back to top]](#quick-links)

# Known Issues

## Tidepool Web becomes inaccessible

Currently, there is a known issue where at times the gateway proxy service that handles incoming requests loses track of the local blip service.

This will present itself usually with the web app getting stuck in a loading state in the browser, or possibly resolving with an error message like: `‘No healthy upstream on blip (http://localhost:3000)`

The solution is to restart the `gateway-proxy` service, which should instantly restore access:

```
tidepool restart gateway-proxy
```

[[back to top]](#quick-links)

# Tracing

If you want to capture some or all of the network traffic that flows into and between the various Tidepool services, then all it requires is setting up a reverse proxy and a few environment variable changes.

The trick to capturing network traffic is to have the Docker container expose (and service listen on) a different port than the standard port expected by clients. Using a network-capture tool acting as a reverse proxy, you can route and capture traffic from the standard port (where a client sends the request) to the service port (where the container exposed and service listens). Thus, the client request goes "through" the reverse proxy and can be logged before being forwarded to the container and service.

One tool that can be used for this purpose is [Charles Proxy](https://www.charlesproxy.com/).

## Determine Proxy Host, Standard Port, Service Port, And Port Prefix

### Proxy Host

You'll need to determine what host the proxy will run on that is accessible from within the various Docker containers. If you are running the reverse proxy on your local Mac, then you can use the Docker-specific, container-accessible-only, `docker.for.mac.host.internal` host.

### Standard Port

Each container and its contained service have their own standard port where clients will sends requests.

| Service                                                           | Standard Port(s)       |
| ----------------------------------------------------------------- | ---------------------- |
| [blip](https://github.com/tidepool-org/blip)                      | N/A (see below)        |
| [gatekeeper](https://github.com/tidepool-org/gatekeeper)          | 9123                   |
| [highwater](https://github.com/tidepool-org/highwater)            | 9191                   |
| [hydrophone](https://github.com/tidepool-org/hydrophone)          | 9157                   |
| [jellyfish](https://github.com/tidepool-org/jellyfish)            | 9122                   |
| [message-api](https://github.com/tidepool-org/message-api)        | 9119                   |
| [platform-auth](https://github.com/tidepool-org/platform)         | 9222                   |
| [platform-blob](https://github.com/tidepool-org/platform)         | 9225                   |
| [platform-data](https://github.com/tidepool-org/platform)         | 9220                   |
| [platform-migrations](https://github.com/tidepool-org/platform)   | N/A (see below)        |
| [platform-notification](https://github.com/tidepool-org/platform) | 9223                   |
| [platform-task](https://github.com/tidepool-org/platform)         | 9224                   |
| [platform-tools](https://github.com/tidepool-org/platform)        | N/A (see below)        |
| [platform-user](https://github.com/tidepool-org/platform)         | 9221                   |
| [seagull](https://github.com/tidepool-org/seagull)                | 9120                   |
| [shoreline](https://github.com/tidepool-org/shoreline)            | 9107                   |
| [tide-whisperer](https://github.com/tidepool-org/tide-whisperer)  | 9127                   |

NOTE: There is no need to capture network traffic to the `blip` container since you can already do this from within your Chrome browser when browsing to http://localhost:3000.

NOTE: The `platform-migrations` and `platform-tools` containers do not listen for incoming network traffic and do not have associated ports.

### Service Port and Port Prefix

While the only absolute requirement is that the service port must be different than the standard port (and not conflict with any other ports in use, of course), it is easiest to just add a multiple of 10000 to the port. This helps keep all of the service and standard ports straight. This is accomplished by simply prepending a port prefix, a single number (1-5), to the standard port. Thus, standard port of 4455 can become a service port of 14455, 24455, 34455, 44455, or 54455, which are all valid ports. (Typically, ports are limited to 1024-65535.)

For example, if you wanted to route `shoreline` traffic through a reverse proxy and you choose a port prefix of `2` (to offset by 20000), then the service port would be `29017`, as the standard port for `shoreline` from the above table is `9107`.

## Setup Proxy

Install a reverse proxy of your choice.

Configure the reverse proxy to route and capture traffic on the proxy host from the standard port to the service port.

For example, if you wanted to route `shoreline` traffic through a reverse proxy running on your computer with a port prefix of `2`, then you'd configure your reverse proxy to route from `:9107` to `:29107`.

## Set Host and Port Prefix Environment Variables

Now, set the values for the `TIDEPOOL_DOCKER_<docker-container-name>_HOST` and `TIDEPOOL_DOCKER_<docker-container-name>_PORT_PREFIX` environment variables in the `.env` files. Replace `<docker-container-name>` with the _uppercase_ Docker Container name. The dash to underscore replacement applies here, as mentioned above.

For example, if you wanted to route `tide-whisperer` traffic through a reverse proxy available at `docker.for.mac.host.internal` that was routing traffic from port `9127` to port `29127` (the standard `tide-whisperer` port), then you'd need to set the environment variables to:

```bash
TIDEPOOL_DOCKER_TIDE_WHISPERER_HOST=docker.for.mac.host.internal
TIDEPOOL_DOCKER_TIDE_WHISPERER_PORT_PREFIX=2
```

### Start Local Tidepool

Start your local Tidepool again, per [Starting](#starting) instructions. If already running, then this will restart the associated Docker container, use the latest built Docker image, and use the correct host and port prefixes.

Now all network traffic directed to your chosen service will first route through the reverse proxy before being forwards to the actual container and service. The reverse proxy can be configured to log this traffic.
