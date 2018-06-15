# Welcome!

Welome to [Tidepool](https://tidepool.org) at GitHub!

This GitHub repository is your launching pad to running and developing the Tidepool software on your very own computer. You can use it to run your own installation of Tidepool, take a quick peek at the Tidepool code, and even help us at Tidepool design and develop the next new and amazing feature!

Of course, if you haven't already done so, you should check out [Tidepool](https://tidepool.org) and [Tidepool Web](https://app.tidepool.org). It's a snap to create an account, upload your or your loved one's diabetes device data, and visualize it all in one place. We've already done the hard work of setting up the servers, software, databases, backups, and more, so you don't have to. Check it out!

# Setup

It's easy to get up and running quickly as long as you know a bit about your computer and your way around a terminal window.

## Install Docker

The Tidepool stack relies on [Docker](https://www.docker.com) to run all of the code on your computer. Follow the directions at https://www.docker.com/community-edition to install and run Docker on your computer.

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

# Starting

Now, if you just want to get it running as quickly as possible, execute the following commands in a terminal window. As before, remember to replace `<local-directory>` with the directory where you cloned this repository.

```bash
cd <local-directory>
docker-compose up -d
```

NOTE: Due to timing issues not seen outside of Docker, the `hydrophone` and `tide-whisperer` services may not properly connect to `shoreline`. We are looking at how to fix this problem. To resolve this problem for now, execute the following commands to restart these containers and services.

```bash
docker-compose restart hydrophone tide-whisperer
```

NOTE: Executing `docker-compose up -d` will do nothing if all of the containers are already running. However, if one or more containers are stopped or their associated Docker images have been rebuilt, then it will start or restart those containers as you'd expect. In summary, feel free to run `docker-compose up -d` if you aren't sure if everything is running and up-to-date as there's no harm if there's nothing to be done.

For more information about `docker-compose`, please see https://docs.docker.com/compose.

# Creating An Account

Once your local Tidepool is running, open your Chrome browser and browse to http://localhost:3000. You should see the Tidepool login page running from your local computer, assuming everything worked as expected. Go ahead and signup for a new account. Remember, all accounts and data created via this local Tidepool are _ONLY_ stored on your computer. _No_ data is stored on any of the Tidepool servers.

NOTE: Since your local Tidepool does not have a configured email server, no emails will be sent at all. This includes the verification email sent during account creation. To get around this when running locally you can add `+skip` to your email address. Your local Tidepool will allow you to login with that email address even without email verification. For example, if the email address you were going to use was `jdoe@mail.com`, use `jdoe+skip@mail.com` instead. You'll need to use this new email address whenever you login.

# Uploading

To upload diabetes device data to your local Tidepool, first make sure the [Tidepool Uploader](https://tidepool.org/products/tidepool-uploader) is installed on your computer. Follow the directions at https://tidepool.org/products/tidepool-uploader.

After installing and launching the Tidepool Uploader, _but before logging in_, right-click on the "Log In" button. From the popup menu displayed, first select "Change server" and then select "Local". This directs the Tidepool Uploader to upload data to the running local Tidepool rather than our production servers. Then, login to the Tidepool Uploader using the account just created.

NOTE: If you wish to upload to our official, production Tidepool later, you'll have to repeat these instructions, but select the "Production" server instead. Please do not use any server other than "Local" or "Production", unless explicitly instructed to do so by Tidepool staff.

NOTE: The Dexcom API integration will not work as it requires a private developer id and secret known only to Dexcom and Tidepool. If you wish to enable this functionality, please see https://developer.dexcom.com/. Once you receive a developer id and secret from Dexcom, please contact us at support@tidepool.org so we can help you make the appropriate local configuration changes.

# Data Retention

Remember, this is all running on your computer only. This means that all accounts you create and all data you upload to your local Tidepool are _ONLY_ stored in a Mongo database located in the `<local-directory>/mongo` directory on your computer. If you delete that directory, then all of the data you uploaded locally is gone, **permanently**. If you are going to run Tidepool locally as a permanent solution, then we very **strongly** suggest regular backups of the `mongo` directory.

Fortunately, at [Tidepool Web](https://app.tidepool.org), we worry about that for you and make sure all of your data is secure and backed up regularly.

# Stopping

To stop running your local Tidepool, execute the following commands in a terminal window.

```bash
cd <local-directory>
docker-compose down
```

This will stop all Docker containers used by your local Tidepool.

You can now quit the Docker application, if you wish.

# Customization

## Configuration Secrets, Hash Salts, and TLS Certificate

Your local Tidepool includes a number of environment variables that specify configuration secrets, hash salts, and a self-signed TLS certificate that can be customized to uniquely secure your installation. The default values for these environment variables were copied from the previous local development setup in order to maintain backwards compatibility. However, if your local Tidepool is to be used for anything more than development purposes, you should change these environment variables for security reasons.

NOTE: Changing some of these environment variables **will** cause existing data in your Mongo database to become unusable. It is highly recommended that you change the above environment variables _only_ if you are willing to create a new Mongo database, thus losing all previously created accounts and uploaded data.

### Stop Local Tidepool

Ensure your local Tidepool is stopped, per [Stopping](#stopping) instructions, but keep the Docker application running.

Delete your local Mongo database volume or directory.

### Configuration Secrets and Hash Salts

In the `.env` file, the following environment variables should have new, random string values assigned. Longer and more random values provide better security.

* `TIDEPOOL_DOCKER_SERVER_SECRET`
* `TIDEPOOL_DOCKER_SERVICE_PROVIDER_DEXCOM_STATE_SALT`
* `TIDEPOOL_DOCKER_GATEKEEPER_SECRET`
* `TIDEPOOL_DOCKER_HIGHWATER_SALT`
* `TIDEPOOL_DOCKER_JELLYFISH_SALT`
* `TIDEPOOL_DOCKER_PLATFORM_AUTH_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_BLOB_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_DATA_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_NOTIFICATION_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_TASK_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_PLATFORM_USER_SERVICE_SECRET`
* `TIDEPOOL_DOCKER_SEAGULL_SALT`
* `TIDEPOOL_DOCKER_SHORELINE_API_SECRET`
* `TIDEPOOL_DOCKER_SHORELINE_LONG_TERM_KEY`
* `TIDEPOOL_DOCKER_SHORELINE_SALT`
* `TIDEPOOL_DOCKER_SHORELINE_VERIFICATION_SECRET` - should always start with "`+`"

### TLS Certificate

While not strictly a security risk (beyond being a self-signed certificate), you can also replace the default self-signed TLS certificate and private key in the `.env` file with the following environment variables.

* `TIDEPOOL_DOCKER_STYX_TLS_CERTIFICATE`
* `TIDEPOOL_DOCKER_STYX_TLS_PRIVATE_KEY`

Search the web for "create self signed certificate" plus the name of your computer OS (e.g. "mac", "windows", "linux") for instructions on how to create your own self-signed TLS certificate.

Replace all newlines in the resulting TLS certificate and private key files with "`\n`" in order to encode the entire certificate or private key into a single-line environment variable as shown in the `.env` file.

### Start Local Tidepool

Start your local Tidepool again, per [Starting](#starting) instructions.

## Custom Compose File Overrides

Throughout this documentation, you'll find references to changes that can be made to to the `docker-compose.yml` file supplied in this repo.

Changes can be made directly to this file, but if you prefer to leave this file untouched, Docker Compose allows you to maintain your own `docker-compose.override.yml` file which will be automatically read when running `docker-compose` commands so long as it is placed alongside the `docker-compose.yml` file.

The primary advantage of using a compose override file for your changes is that all of your customizations will be kept outside of version control (it's listed in the `.gitignore` file), which avoids having to deal with any potential merge conflicts when pulling in updates.

For those contributing back to this repo, it also ensures you won't accidentally commit any local keys or secrets.

See [Docker's Multiple Compose files documentation](https://docs.docker.com/compose/extends/#multiple-compose-files) for details on how to structure your override files.

## Alternate Mongo Directory

If you wish to store your local data in a Mongo directory other than the default `<local-directory>/mongo`, then you'll need to update an environment variable.

### Stop Local Tidepool

Ensure your local Tidepool is stopped, per [Stopping](#stopping) instructions, but keep the Docker application running.

### Set Mongo Directory Environment Variable

Set the value of the `TIDEPOOL_DOCKER_MONGO_VOLUME` environment variable in the `.env` file to the absolute or relative (to the `docker-compose.yml` file) path to the directory you prefer. For example, if you want to store the Mongo data in the `~/MyMongoData` directory, then just replace the value of the environment variable to:

```bash
TIDEPOOL_DOCKER_MONGO_VOLUME=~/MyMongoData
```

NOTE: If you previously started Tidepool locally and created an account, then any data for that account will be stored in the _old_ Mongo data directory. You can either create a new account after changing the environment variable and restarting your local Tidepool, or you can move the data directory or files manually (which is outside the scope of this document).

### Start Local Tidepool

Start your local Tidepool again, per [Starting](#starting) instructions.

## Alternate Mongo Host

If you wish to use an alternate Mongo host running outside of Docker, then you'll need to do a few things.

### Stop Local Tidepool

Ensure your local Tidepool is stopped, per [Stopping](#stopping) instructions, but keep the Docker application running.

### Remove Mongo Container

Comment out the entire `mongo:` section in the `docker-compose.yml` file. For example,

```bash
  # mongo:
  #   image: mongo:3.2
  #   volumes:
  #     - ${TIDEPOOL_DOCKER_MONGO_VOLUME}:/data/db
  #   ports:
  #     - '27017:27017'
```

### Set Mongo Host Environment Variable

Set the value of the `TIDEPOOL_DOCKER_MONGO_HOST` environment variable in the `.env` file to the address of the alternate Mongo host.

If you are running Mongo natively on your local Mac (not in Docker, but via another installation, such as [Homebrew](https://brew.sh/)), then you can use the Docker-specific, container-accessible-only address `docker.for.mac.host.internal` to point to the alternate Mongo host. For example,

```bash
TIDEPOOL_DOCKER_MONGO_HOST=docker.for.mac.host.internal
```

If the alternate Mongo host requires a TLS/SSL connection, then set the `TIDEPOOL_DOCKER_MONGO_TLS` environment variable in the `.env` file to `true`.

### Start Local Tidepool

Start your local Tidepool again, per [Starting](#starting) instructions.

# Build Docker Images Locally

If you wish to build and run one or more Docker images locally using the latest-and-greatest source code, then you'll need to do a few more things.

## Clone Source Respository

First, you'll need to clone the GitHub repository you are interested in to your computer.

You can choose from the following active repositories:

| Repository Name                                                  | Docker Container Name (`<docker-container-name>`) | Description                     | Language                       | Git Clone URL (`<git-clone-url>`)                  | Default Clone Directory (`<default-clone-directory>`)     |
| ---------------------------------------------------------------- | ------------------------------------------------- | ------------------------------- | ------------------------------ | -------------------------------------------------- | --------------------------------------------------------- |
| [blip](https://github.com/tidepool-org/blip)                     | blip                                              | Web (ie. http://localhost:3000) | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/blip.git           | blip                                                      |
| [gatekeeper](https://github.com/tidepool-org/gatekeeper)         | gatekeeper                                        | Permissions                     | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/gatekeeper.git     | gatekeeper                                                |
| [hakken](https://github.com/tidepool-org/hakken)                 | hakken                                            | Discovery                       | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/hakken.git         | hakken                                                    |
| [highwater](https://github.com/tidepool-org/highwater)           | highwater                                         | Metrics                         | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/highwater.git      | highwater                                                 |
| [hydrophone](https://github.com/tidepool-org/hydrophone)         | hydrophone                                        | Email, Invitations              | [Golang](https://golang.org/)  | https://github.com/tidepool-org/hydrophone.git     | hydrophone/src/github.com/tidepool-org/hydrophone         |
| [jellyfish](https://github.com/tidepool-org/jellyfish)           | jellyfish                                         | Data Ingestion [LEGACY]         | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/jellyfish.git      | jellyfish                                                 |
| [message-api](https://github.com/tidepool-org/message-api)       | message-api                                       | Notes                           | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/message-api.git    | message-api                                               |
| [platform](https://github.com/tidepool-org/platform)             | (see below)                                       | (see below)                     | [Golang](https://golang.org/)  | https://github.com/tidepool-org/platform.git       | platform/src/github.com/tidepool-org/platform             |
| [seagull](https://github.com/tidepool-org/seagull)               | seagull                                           | Metadata                        | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/seagull.git        | seagull                                                   |
| [shoreline](https://github.com/tidepool-org/shoreline)           | shoreline                                         | Authentication                  | [Golang](https://golang.org/)  | https://github.com/tidepool-org/shoreline.git      | shoreline/src/github.com/tidepool-org/shoreline           |
| [styx](https://github.com/tidepool-org/styx)                     | styx                                              | Router                          | [Node.js](https://nodejs.org/) | https://github.com/tidepool-org/styx.git           | styx                                                      |
| [tide-whisperer](https://github.com/tidepool-org/tide-whisperer) | tide-whisperer                                    | Download                        | [Golang](https://golang.org/)  | https://github.com/tidepool-org/tide-whisperer.git | tide-whisperer/src/github.com/tidepool-org/tide-whisperer |

Please note that the `platform` repository actually contains source code for multiple Docker containers, specifically:

| Docker Container Name | Description                      |
| --------------------- | -------------------------------- |
| platform-auth         | Authentication                   |
| platform-blob         | Blob Storage                     |
| platform-data         | Data Ingestion (next generation) |
| platform-migrations   | Database Migrations              |
| platform-notification | Notifications (TBD)              |
| platform-task         | Background Jobs                  |
| platform-tools        | Tools, Utilities                 |
| platform-user         | Users                            |

NOTE: The Golang repositories include the extra-long directory hierarchy to ensure a unique, valid GOPATH. Read more about [Golang](https://golang.org/) and [GOPATH](https://golang.org/doc/code.html) for details.

Choose one of the above repositories and clone locally using the following command. Replace `<git-clone-url>` with the appropriate Git Clone URL from the above table. Replace `<local-directory>` with the directory where this repository was cloned, per previous [Clone This Repository](#clone-this-repository) instructions. Replace `<default-clone-directory>` with the appropriate Default Clone Directory from the above table.

```bash
git clone <git-clone-url> <local-directory>/<default-clone-directory>
```

For example, if you wanted to clone the `shoreline` repository and the `<local-directory>` was `~/Tidepool/development`, then execute the command:

```bash
git clone https://github.com/tidepool-org/shoreline.git ~/Tidepool/development/shoreline/src/github.com/tidepool-org/shoreline
```

### Alternate Source Repository Directory

You can alternatively clone the source repository to any directory on your computer. To do so, clone the repository to the directory of your choosing and update the value of the `TIDEPOOL_DOCKER_<docker-container-name>_DIR` environment variable in the `.env` file to the absolute or relative (to the `docker-compose.yml` file) path to that directory. Replace `<docker-container-name>` with the _uppercase_ Docker Container Name from the above table.

Note: Due to environment variable limitations, any dash in the Docker Container Name needs to be replaced with an underscore. So, `message-api` becomes `MESSAGE_API` and `tide-whisperer` becomes `TIDE_WHISPERER`.

For example, if you wanted the `tide-whisperer` source code to be cloned into the `~/go/src/github.com/tidepool-org/tide-whisperer` directory, then execute the command:

```bash
git clone https://github.com/tidepool-org/tide-whisperer.git ~/go/src/github.com/tidepool-org/tide-whisperer
```

and update the `.env` file with the environment variable:

```bash
TIDEPOOL_DOCKER_TIDE_WHISPERER_DIR=~/go/src/github.com/tidepool-org/tide-whisperer
```

NOTE: Ensure that any cloned Golang repositories end up in a valid GOPATH directory hierarchy.

## Update docker-compose.yml

Edit the `docker-compose.yml` file, find the container section pertaining to the Docker image you want to build locally and uncomment the entire `build:` section.

For example, if you want to build the `shoreline` image locally, you'd change this:

```bash
  shoreline:
    image: tidepool/shoreline
    depends_on:
      - hakken
      - mongo
    # build:
    #   context: ${TIDEPOOL_DOCKER_SHORELINE_DIR}
    #   target: ${TIDEPOOL_DOCKER_SHORELINE_BUILD_TARGET}
    # volumes:
    #   - ${TIDEPOOL_DOCKER_SHORELINE_DIR}:/go/src/github.com/tidepool-org/shoreline:cached
    #   - /go/src/github.com/tidepool-org/shoreline/dist
    ports:
      - '${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107:${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107'
    environment:
      ... (remove for brevity) ...
```

to this:

```bash
  shoreline:
    image: tidepool/shoreline
    depends_on:
      - hakken
      - mongo
    build:
      context: ${TIDEPOOL_DOCKER_SHORELINE_DIR}
      target: ${TIDEPOOL_DOCKER_SHORELINE_BUILD_TARGET}
    # volumes:
    #   - ${TIDEPOOL_DOCKER_SHORELINE_DIR}:/go/src/github.com/tidepool-org/shoreline:cached
    #   - /go/src/github.com/tidepool-org/shoreline/dist
    ports:
      - '${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107:${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107'
    environment:
       ... (remove for brevity) ...
```

Note that the `build:` section in the second example is uncommented.

## Building

To build the Docker image from the source code you just cloned, execute the following commands in a terminal window. Replace `<docker-container-name>` with the Docker Container Name from the above tables.

```bash
cd <local-directory>
docker-compose build <docker-container-name>
```

For example, if you wanted to build `shoreline`, you'd execute:

```bash
cd <local-directory>
docker-compose build shoreline
```

### Start Local Tidepool

Start your local Tidepool again, per [Starting](#starting) instructions. If already running, then this will restart the associated Docker container and use the latest built Docker image for this service.

# Developing

If you wish to make changes to or write new code, then there are two options you can consider.

In either case, you'll need to first follow the [Build Docker Images Locally](#build-docker-images-locally) instructions for the service you wish to develop.

## Edit Locally, Rebuild Image, and Restart

The first choice for development is fairly simple, but can be time consuming if you make frequent or extensive changes.

The workflow is as follows:

1. Edit any files in the cloned respository using your favorite text editor.
1. Rebuild the associated Docker image using `docker-compose build <docker-container-name>`. See [Building](#building) instructions.
1. Restart the associated Docker containers using `docker-compose up -d`. See [Starting](#starting) instructions.
1. Repeat steps 1-3 as you go.

Obviously, the cycle from editing code to being able to use it can be time consuming due to the rebuild and restart steps. This works perfectly fine if you are just trying things out or making small changes, but can get a bit clunky when you are making frequent or significant changes, or if it was your full-time job.

## Mount Local Volume

The second choice for development is more complex to setup initially, but once completed can speed your development efforts significantly.

The workflow is as follows:

1. Edit any files in the cloned respository using your favorite text editor.
1. The running container detects changes you made and takes appropriate action to rebuild and restart. In some containers, this will happen automatically while others require a simple command to kick off the rebuild and restart. In any case, the rebuild and restart process is comparatively quick.

Obviously, this is far more streamlined than the first choice.

NOTE: All `platform` services require you "tell" the associated Docker container you want to build the new code (or otherwise even single save would cause a new build). To do so, execute `SERVICE=<docker-container-name> make service-restart` in a terminal window at the root of the cloned `platform` repository. Replace `<docker-container-name>` with the Docker Container Name from the above table.

NOTE: Unfortunately, the second step will not work for the `hydrophone`, `shoreline`, and `tide-whisperer` services right at the moment. You'll need to either shell into the running container and execute `./build.sh`, or install the correct version of Golang on your computer and run `./build.sh` locally. We'll be fixing this in the near future so these extra steps will be unnecessary.

### Setup

To setup your computer for this development workflow you'll need to follow a few steps.

#### Update docker-compose.yml

Edit the `docker-compose.yml` file, find the appropriate container section and uncomment the entire `volumes:` section. The `build:` section should already be uncommented when you completed the [Build Docker Images Locally](#build-docker-images-locally) instructions.

For example, if you want to mount the repository to the `shoreline` container, you'd change this:

```bash
  shoreline:
    image: tidepool/shoreline
    depends_on:
      - hakken
      - mongo
    build:
      context: ${TIDEPOOL_DOCKER_SHORELINE_DIR}
      target: ${TIDEPOOL_DOCKER_SHORELINE_BUILD_TARGET}
    # volumes:
    #   - ${TIDEPOOL_DOCKER_SHORELINE_DIR}:/go/src/github.com/tidepool-org/shoreline:cached
    #   - /go/src/github.com/tidepool-org/shoreline/dist
    ports:
      - '${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107:${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107'
    environment:
       ... (remove for brevity) ...
```

to this:

```bash
  shoreline:
    image: tidepool/shoreline
    depends_on:
      - hakken
      - mongo
    build:
      context: ${TIDEPOOL_DOCKER_SHORELINE_DIR}
      target: ${TIDEPOOL_DOCKER_SHORELINE_BUILD_TARGET}
    volumes:
      - ${TIDEPOOL_DOCKER_SHORELINE_DIR}:/go/src/github.com/tidepool-org/shoreline:cached
      - /go/src/github.com/tidepool-org/shoreline/dist
    ports:
      - '${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107:${TIDEPOOL_DOCKER_SHORELINE_PORT_PREFIX}9107'
    environment:
       ... (remove for brevity) ...
```

Note that the `volumes:` section in the second example is uncommented.

#### Set Build Target Environment Variable

If the repository language is Golang, then it uses a multi-target `Dockerfile` to build the Docker images. This means there is a `development` target, which includes all of the necessary development tools, and a `release` target, which contains only the final binaries. The default, if no target is specified, is `release` (as it is the last target specified in the `Dockerfile`).

Set the value of the `TIDEPOOL_DOCKER_<docker-container-name>_BUILD_TARGET` environment variable in the `.env` file to `development`. Replace `<docker-container-name>` with the _uppercase_ Docker Container Name. The dash to underscore replacement applies here, as mentioned above.

For example, if you wanted to develop the `tide-whisperer` service, update the `.env` file with the following environment variable.

```bash
TIDEPOOL_DOCKER_TIDE_WHISPERER_BUILD_TARGET=development
```

### Start Local Tidepool

Start your local Tidepool again, per [Starting](#starting) instructions. If already running, then this will restart the associated Docker container, use the latest built Docker image, and mount the volumes specified.

### Develop Away

Go ahead and edit the source files as you wish. Note the above caveats regarding automatic rebuild in the [Mount Local Volume](mount-local-volume) instructions.

## Developing for Front End services

When developing the front end services `blip` (our primary web application) and `viz` (our visualization library), there are a few extra steps needed in addition to the generalized development instructions above.

### Mounting Local Volumes

This is far recommended over rebuilding the images when making changes, as full container builds will be quite time-consuming due to the `yarn install`'s being called.

Note that in the case of the `blip` service, we only need the primary container volumes (those whose mounted paths are within the `/app` directory).

The other commented-out paths are for supporting frontend repos that only need to be volume-mounted if they're to be developed via `yarn link`. See [Linking other node packages into blip](#linking-other-node-packages-into-blip).

```bash
  blip:
    image: tidepool/blip
    depends_on:
      - hakken
    # build: ${TIDEPOOL_DOCKER_BLIP_DIR}
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

    # ...
```

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

When you need develop other supporting front end tidepool Node.js packages in `blip`, you'll need to `yarn link` them so that the changes you make are picked up and compiled in your running blip instance.

For example, if you need to make some changes to the `tideline` (our legacy visualization provider) and `viz` packages, you would first need to volume mount the source code for those packages into the `blip` service:
```bash
  blip:
      # ...
      volumes:
        - ${TIDEPOOL_DOCKER_BLIP_DIR}:/app:cached
        - /app/node_modules
        - /app/dist
        # - ${TIDEPOOL_DOCKER_PLATFORM_CLIENT_DIR}:/tidepool-platform-client:cached
        # - /tidepool-platform-client/node_modules
        - ${TIDEPOOL_DOCKER_TIDELINE_DIR}:/tideline:cached
        - /tideline/node_modules
        - ${TIDEPOOL_DOCKER_VIZ_DIR}:/@tidepool/viz:cached
        - viz-dist:/@tidepool/viz/dist:ro
      # ...
```

**NOTE:** The above example is somewhat incomplete.  When choosing to mount and link the `@tidepool/viz` package, we need to also run the `viz` service, which is commented out completely in the `docker-compose.yml` by default. See [Running the viz service](#running-the-viz-service) below for details.

Next, we need to `exec` into the container and link the packages

```bash
# Shell into the container from your local terminal
docker-compose exec blip sh

# Navigate to the directories we mounted the packages to and register them as linked packages
# NOTE: we only need to run the yarn install if this is the first time (or the package.json dependancies have changed)
cd /tideline && yarn install && yarn link
cd /@tidepool/viz && yarn install && yarn link

# Navigate to the main app directory and link the registered packages
cd /app && yarn link tideline @tidepool/viz

# Now we exit the container and return to our local terminal shell
exit

# Restart the blip service from your local terminal
docker-compose stop blip && docker-compose start blip
```

You may have noticed that I used separate stop and start commands, instead of the more obvious `docker-compose restart`. I've found that there are times (possibly due to `yarn` caching) that the full stop and start is required for the linking to take effect.

As with the `yarn install` example earlier, this can be run as a one-off command, though it's fairly verbose:

```bash
docker-compose run blip /bin/sh -c "cd /@tidepool/viz && yarn link && cd /tideline && yarn link && cd /app && yarn link tideline @tidepool/viz
```

Again, we want to follow up with a restart:

```bash
docker-compose stop blip && docker-compose start blip
```

### Unlinking previously linked node packages in `blip`

To unlink a linked node package, we simply reverse our linking with `yarn unlink`:

```bash
# Shell into the container from your local terminal
docker-compose exec blip sh

# You will be in the /app directory by default after exec-ing into the container
yarn unlink tideline @tidepool/viz

# Navigate to the directories we mounted the packages to and deregister them as linked packages
cd /tideline && yarn unlink
cd /@tidepool/viz && yarn unlink

# We now should remove the node_modules directory and force a reinstall.
# Otherwise, we may end up with the previously linked packages still used from the yarn cache
cd /app
rm -rf node_modules
yarn install --force

# Now we exit the container and return to our local terminal shell
exit

# Restart the blip service from your local terminal
docker-compose stop blip && docker-compose start blip
```

And the one-liner:

```bash
docker-compose run blip /bin/sh -c "yarn unlink tideline @tidepool/viz && cd /@tidepool/viz && yarn unlink && cd /tideline && yarn unlink && cd /app && rm -rf node_modules && yarn install --force"
```

Again, we want to follow up with a restart:

```bash
docker-compose stop blip && docker-compose start blip
```

### Running the `viz` service

Unlike the other frontend Node.js services that blip uses, `viz` can also be run as a standalone service.

In fact, it **_must_** be running if you are planning to link it into `blip`, as the webpack bundling needs to run (which it does when the service container starts, and when mounted files change).

There are times, however, where you may want to run it on it's own without linking into `blip`, such as if you're working on new prototypes in `viz`'s Storybooks.

The `viz` service is commented out by default. To run it, simply uncomment it in the `docker-compose.yml` file.

```bash
  viz:
    image: tidepool/viz
    volumes:
      - ${TIDEPOOL_DOCKER_VIZ_DIR}:/app:cached
      - /app/node_modules
      - viz-dist:/app/dist
    environment:
      NODE_ENV: development
    ports:
      - '8081:8081'
      - '8082:8082'
```

The open ports are for running the storybooks in the browser.

NOTE: the storybooks don't run by default. You need to start them manually:

```bash
# Run the general UI storybook on http://localhost:8081
docker-compose exec viz sh -c "yarn run stories"

# Run the stories for diabetes data type visualizations on http://localhost:8082
docker-compose exec viz sh -c "yarn run typestories"
```
# Tidepool Helper Script

Included in the `bin` directory of this repo is a bash script named `tidepool_docker`.

It's intended to provide a streamlined interface for managing the docker stack and services.

This is especially helpful for working with the Node.js services, as common tasks such as running NPM scripts and various other `yarn` commands can be a quite verbose and time-consuming when working in a docker stack.

You can run the script from the root directory of this repo from your terminal with:

```bash
# Show the help text
bin/tidepool_docker help
```

It's recommended, however, to add the `bin` directory to your $PATH (e.g. in `~/.bashrc`) so that you can run the script from anywhere as `tidepool_docker`.

```bash
export PATH=$PATH:/path/to/this/repo/bin
```

You can now easily manage your stack and services from anywhere

```bash
# Provision and start the stack
tidepool_docker up

# Link or unlink supporting packages in `blip`
tidepool_docker link blip @tidepool/viz
tidepool_docker link blip tideline
tidepool_docker unlink blip @tidepool/viz

# Run npm (yarn) scripts in a service
tidepool_docker yarn blip install
tidepool_docker yarn tideline test-watch
tidepool_docker yarn viz stories

# Tail logs for the `blip` service
tidepool_docker logs blip

# Stop the stack
tidepool_docker stop
```

This script will only work in a Linux or MacOS environment (though Windows users may be able to get it working in [GitBash](https://git-for-windows.github.io/) or the new [Bash integration in Windows 10](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide))

The following commands are provided (note that some commands only apply to Node.js services):

| Command                       | Description                                                                                                                                                         |
|-------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `up [service]`                | start and/or (re)build the entire tidepool stack or the specified service                                                                                           |
| `down`                        | shut down and remove the entire tidepool stack                                                                                                                      |
| `stop`                        | shut down the entire tidepool stack or the specified service                                                                                                        |
| `restart [service]`           | restart the entire tidepool stack or the specified service                                                                                                          |
| `pull [service]`              | pull the latest images for the entire tidepool stack or the specified service                                                                                       |
| `logs [service]`              | tail logs for the entire tidepool stack or the specified service                                                                                                    |
| `rebuild [service]`           | rebuild and run image for all services in the tidepool stack or the specified service                                                                               |
| `exec service [...cmds]`      | run arbitrary shell commands in the currently running service container                                                                                             |
| `link node_service package`   | yarn link a mounted package and restart the Node.js service (package must be mounted into a root directory that matches it's name)                                  |
| `unlink node_service package` | yarn unlink a mounted package, reinstall the remote package, and restart the Node.js service (package must be mounted into a root directory that matches it's name) |
| `yarn node_service [...cmds]` | shortcut to run yarn commands against the specified Node.js service                                                                                                 |
| `help`                        | show more detailed usage text than what's listed here                                                                                                               |

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
| [hakken](https://github.com/tidepool-org/hakken)                  | 8000                   |
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
| [styx](https://github.com/tidepool-org/styx)                      | 8009, 8010 (see below) |
| [tide-whisperer](https://github.com/tidepool-org/tide-whisperer)  | 9127                   |

NOTE: There is no need to capture network traffic to the `blip` container since you can already do this from within your Chrome browser when browsing to http://localhost:3000.

NOTE: The `platform-migrations` and `platform-tools` containers do not listen for incoming network traffic and do not have associated ports.

NOTE: The `styx` container actually listens on two ports (one each for HTTP and HTTPS traffic), so you'll need to setup both separately.

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

# Environment Variables Overview

All environment variables use a `TIDEPOOL_DOCKER_` prefix, followed by an _uppercase_ Docker container name with underscore replacing all dashes, followed by one of the following suffix.

`_BUILD_TARGET` - Specifies which target to build in a multi-target `Dockerfile`. Only applies to Golang containers. See [Developing](#developing).

`_DIR` - Absolute or relative (to `docker-compose.yml` file) path to a host directory (not within a container). See [Alternate Source Repository Directory](#alternate-source-repository-directory) for details.

`_HOST` - Docker container name or address of the host providing a specific service. A container name must be one of the containers specified in the `docker-compose.yml` file. An address implies that the service is hosted outside of the `docker-compose.yml` file (or at least routes outside before
being directed back to a container, say to a reverse proxy for tracing). See [Set Mongo Host Environment Variable](#set-mongo-host-environment-variable) and [Tracing](#tracing) for more details.

`_PORT_PREFIX` - Prefix added to a port number. Must be an empty string, 1, 2, 3, 4, or 5. Allows the service port to be different from the standard port. See [Tracing](#tracing) for more details.

`_VOLUME` - Volume name or absolute or relative (to `docker-compose.yml` file) path to a host directory (not within a container) where data should be stored for the mounted volume. See [Alternate Mongo Directory](#alternate-mongo-directory) for details.

Note: All environment variables found in the `docker-compose.yml` file must be defined (if only to an empty string as it the case with the default `PORT_PREFIX`) to avoid warnings from Docker.

Note: Rather than modifying the `.env` file you can set all the same environment variables in your shell (e.g. in `~/.bashrc`) where they will take precedence over those found in the `.env` file.
