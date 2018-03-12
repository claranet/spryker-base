
# Docker Image claranet/spryker-base

[![build status badge](https://img.shields.io/travis/claranet/spryker-base/master.svg)](https://travis-ci.org/claranet/spryker-base/branches)
[![docker pull badge](https://img.shields.io/docker/pulls/claranet/spryker-base.svg)](https://hub.docker.com/r/claranet/spryker-base/)


<!-- vim-markdown-toc GFM -->

* [What?](#what)
* [Why?](#why)
* [Design](#design)
    * [Docker Image](#docker-image)
    * [Build Time Environment](#build-time-environment)
    * [Runtime Environments](#runtime-environments)
    * [Build Layer](#build-layer)
    * [Private Repositories](#private-repositories)
    * [Spryker Configuration](#spryker-configuration)
    * [Docker Volumes](#docker-volumes)
* [Conventions](#conventions)
* [Create Your Custom Image](#create-your-custom-image)
* [Build & Run](#build--run)
* [Configurations](#configurations)
    * [Runtime Environment Variables - Reference](#runtime-environment-variables---reference)
    * [Build Time Variable - Reference](#build-time-variable---reference)
    * [Injecting Custom Configurations](#injecting-custom-configurations)
        * [External Volumes](#external-volumes)
        * [Child Image Overwrites](#child-image-overwrites)
* [Customization](#customization)
    * [build.conf](#buildconf)
    * [Build Steps](#build-steps)
    * [Init](#init)
        * [Container Level](#container-level)
        * [Setup Wide](#setup-wide)
    * [Deployment](#deployment)
    * [Custom Build Steps](#custom-build-steps)
        * [Logging](#logging)
        * [Installing additional packages](#installing-additional-packages)
* [Not documented here?](#not-documented-here)
* [FAQ](#faq)
    * [Where to find logs?](#where-to-find-logs)
    * [Which base image are you using?](#which-base-image-are-you-using)
    * [Why using Alpine?](#why-using-alpine)
    * [How to further speed up image build?](#how-to-further-speed-up-image-build)
* [Issues](#issues)

<!-- vim-markdown-toc -->

## What?

This image serves the purpose of providing the base infrastructure for Yves and
Zed. Infrastructure in terms of build/init scripts and further tooling around
the shop itself. This image does not provide a ready to use shop! In order to
use the features implemented here, write your own `Dockerfile` - which uses
this base image to inherit from - along your actual implementation of a Spryker
shop.

**This project is still in BETA and will undergo possible breaking changes!**

Thats why we are keen to get feedback from you! This is a work in progress
effort which strives for making dockerizing a Spryker Shop as easy as possible.
In order to successfully achieve this goal, we need to identify common steps
worth to be generalized and put into this base image. So tell us about your
needs and your experiences.

If you want to see this image in action and how its gonna be used check out the
containerized [Spryker Demoshop](https://github.com/claranet/spryker-demoshop).
This demoshop serves as reference implementation for the base image. The same
way as Spryker is progressing their bundles and making the demoshop reflecting
those changes we use the demoshop in exactly the same way.

Core traits are:

* Provide PHP runtime environment with most common PHP modules
* Uses dockers `ONBUILD` trigger feature to hook into and control the child image build process
* Provide reasonable default FPM/nginx configuration
* Its open for customization by providing hookable build, init and configuration steps
* Expects the base structure from the [spryker-demoshop](https://github.com/spryker/demoshop)
* No further constraints, you are absolutely free to design you shop the way you want it to


## Why?

Benefits of containerization:

* Consistency
* Reproducibility
* Portablity
* Seamless deployment form local development into prod environment


## Design

### Docker Image

First premise is, that we decided to serve the Yves and Zed container from one
image. The benefit is to always consistently upgrade the shared code base
across a whole cluster. Tradeoff is slightly larger images, since requirements
of both components need to be included.

### Build Time Environment

Another premise is - and this one is crucial for your understanding of this
stack - to build one unified image across development and production
environments. This affects the usage of `APPLICATION_ENV` which gets evaluated
by the Spryker App itself.

This variable has the following impact:

1. During Build Time:
    1. Which packages are going to be installed via dependency resolution
     (composer, npm)?
    1. Differnt modes in assets building
1. During Run Time:
    1. Where does the application is about to find configuration files (propel config)?
    1. Where are external resources to be found?
    1. Shall the app enable symfony debug/devel behaviour?

The location of local configuration files and external resources is nothing
which needs extra consideration in containerized environment, since all those
stacks are isolated anyways. ***So please ensure that no configuration
statement under `./config/Shared/` will utilize `APPLICATION_ENV` for
identifying their pathes!!!***

We consider only point 1.1 worth a distinction. And since this could be
achieved with injecting proper vars into the effective containers, we do not
distinguish between environments while building the images. Since point 1.1
requires typically more dependencies to be resolved, we always build the image
with `APPLICATION_ENV` set to `development`. But in which mode the application
will actually be run is independant from the build.

This means that even the production containers will have dev dependencies
included. Primary reason for this is the requirement for dev/test/prod parity
to ensure the containers behave exactly the same in all stages and in all
environments. Tradeoff for this premise is again larger effective images.
During runtime the behaviour of the Spryker Application can be controlled by
setting `APPLICATION_ENV` which accepts either `development` or `production`.
If you use the `./docker/run` script this variables will be set automatically.

### Runtime Environments

The idea behind the scripts provided in this `./shop/docker` subfolder follow
the basic distinction between `devel` and `prod` environments. The main
difference between those environments in terms of `docker-compose` is the
employment of bind mounts in the devel mode, which enables the developer to
edit the code base from the outside while running the code in the background
within the containers.

Since this setup strives for reducing manual efforts we prepared shell scripts
which render the necessary logic and support you with shortcuts for the most
common tasks like building the image or creating or tearing down the container
setup. Check out `./docker/run help`

The `prod` environment is meant for testing the result of your work in a
near-to-prod environment, which means that no shared data between your local
repository and the container will be established. Furthermore will the
application be run with `APPLICTION_ENV=production` set which disables development
specific extensions.

### Build Layer

The concept introduced by this base image is to split up the resulting shop
image into 3 distinct layers (effectively there are more than only 3 layers,
since each statement in the `Dockerfile` results in a new layer; but the idea
of 3 distinct layers abstracts the onbuild trigger logic more easily and
understandable). There are a couple of reason for this:

* First, it should leverage the docker cache and speed up iterative rebuilds of
  the shop image. Since these layers are ordered from generic to specific, the
  need for rebuilds of the whole stack while working iteratively on the code
  base of the actual shop implementation should be reduced.

* Second, different layers could be retrieved in parallel while pulling the
  image, which speeds up the container creation time which is relevant not only
  for local development, but rather for deployments of the production setup.
  Furthermore, since generic layers do not change that often, the need not only
  for rebuilds but for refetching the whole image should be reduced as well.

Unfortunately this comes not without cost, the effective image size will be
slightly higher than the one which gets build up by just one layer. Right now
this seems to be an acceptable tradeoff.

What are the responsibilities of those layers and where are they located and
when are they going to be built?

* `claranet/spryker-base` (this image):
    * Base Layer - Install all the os level base infrastructure, PHP and the most common modules. 
* `claranet/spryker-demoshop` (the downstream shop image, e.g. the demoshop): 
    * Base Layer - Install additional PHP modules and/or override the base layer from the `spryker-base` image (mind the `$REBUILD_BASE_LAYER` build variable)
    * Dependency Layer - Resolve all the shop specific PHP/Node dependencies
    * Code Layer - Build shop specific code like ORM, tranfer objects

### Private Repositories

In case your PHP or Node dependencies need to be pulled from a private
repository, you just need to provide a `~/.netrc`. This file will be
automatically detected and temporarily as docker build arg injected into the
transient build container, used by git for cloning the appropriate
repositories, and afterwards wiped off the resuilting layer right before the
layer will be closed.

The format for the `$HOME/.netrc` is as follows:

    machine git.company.local
    login my_user_name
    password my_private_token

In order to take effect all the given dependencies must be either given as HTTP
url or they getting transformed via `git config --global
"url.https://".insteadof "git://git@` which has been already prepared by the base
image.

If you want to add more specific rules, create a build script in the dependency
layer which gets executed prior to the dependency resolution process:

    vi docker/build.d/deps/300_private_repo_override.sh
    #!/bin/sh
    sectionText "Diverting git transport from SSH to HTTPS: https://git.company.local"
    git config --global "url.https://git.company.local/".insteadof "git@git.company.local:"
    git config --global "url.https://git.company.local".insteadof "ssh://git@git.company.local"

Since git urls can be given in a arbitrary combination, this is in some
circumstances necessary.

This all is necessary because Docker refuses to implement [build time
volumes](https://github.com/moby/moby/issues/12827) which would make this
process way more easier. But they got striking reasons indeed, since suche a
feature would risk reproducibility, because `Dockerfile` is not the sole source
of build intructions. The is - like in any tech argument - no absolute truth,
only tradeoffs.

### Spryker Configuration

Since in a dockerized environment external services are reachable on different
address depending on the environment the code is running in we need some
configuration to be adjusted. We therefore use the Spryker native mechanism of
configuration file precedence in order to inject our configuration via the site
local configuration file `config/Shared/config_local.php`. Since this file is
the one which overrides all the others.

Configuration order is as the following:
* `config_default.php` - Base configuration
* `config_default-development.php` - Configuration relevant for development mode (see `APPLICATION_ENV`)
* `config_local.php` - site local configuration; in this case its the configuration for containerized environment.

This order enables you to use your config file completely independently of
the effective environment the shop will run in. You can even control different
behaviour between environments. We just override the so to say site local
settings, which this idea is originating from.

For this we needed to remove `config/Shared/config_local.php` off the
`.gitignore` list.

### Docker Volumes

Currently both environments `devel` and `prod` using unnamed volumes which is
due to the assumption of a transient environment. This means, the whole stack
gets create for the sole purpose of checking your code base aginst it. **Its is
under no circumstance meant as some production grade setup, where data needs to
persisted over recreations of containers!!!**

The assumed workflow could be described as:

1. Create environment
1. Initialize with dummy data
1. Evolve code base
1. Iterate: rebuild -> run -> init -> evolve
1. Destroy environment


## Conventions

In order to reuse the functionalities implemented here, the following aspects
need to be aligned with the base image:

* Follow Spryker reference directory hierarchy
    * `./src/Pyz` - Your shop implementation
    * `./config` - Configuration
    * `./public/{Yves,Zed}` - Entrypoints to you application (document root)
* Dependencies
    * PHP: `composer.json` and `composer.lock`
    * Node: `packages.json`, `packages.lock` and `yarn.lock`
* Make Spryker configuration consider env vars. Checkout the [shop_skel/config/Shared/config_local.php](/shop/config/Shared/config_local.php) which exemplifies what is meant by this point
* Control the dependencies you want to be installed (PHP extensions, Node deps, etc. pp.) via `./docker/build.conf`
* Control the build process of the image by placing your custom build scripts under `./docker/build.d/`
* Control the initialization process of the setup by placing your scripts under `./docker/init.d/`

Check out the [demoshop](https://github.com/claranet/spryker-demoshop)
we have prepared for using this image here. This should answer all of the
questions you might have.


## Create Your Custom Image

Since the the reference implementation is the
[demoshop](https://github.com/claranet/spryker-demoshop) which is maintained by
us, this is a pretty good starter. Either by just forking this repo or by starting from scratch.

If you want to start from scratch the only artifacts of interest which you need
from the demoshop are:
* `./docker/*`
* `./Dockerfile`
* `./.dockerignore`
* `./config/Shared/config_local.php`

By this, you are ready to populate your repository with your code
and customize it to your individual needs.

Mind the `Dockerfile` which looks as clean as this:

    FROM claranet/spryker-base:latest

This smells like reusability. :)


## Build & Run

The shop skeleton and the demoshop as well got a shell script under
`./docker/run` which provide you with shortcuts to the most common tasks.
Checkout out the [README.md](./shop/docker/README.md) there for further
details.

    # Build the image
    ./docker/run build

    # Run the demoshop in development mode
    ./docker/run devel up

    # Stop all the containers of the demoshop including their artifacts
    ./docker/run devel down -v


## Configurations

### Runtime Environment Variables - Reference

Those variables are to be provided during container creation as environment
variables.

Most of the variables getting consumed by the `config/Shared/config_local.php`
file:

* `APPLICATION_ENV="production"`
* `SPRYKER_SHOP_CC="DE"`
* `ZED_HOST="zed"`
* `YVES_HOST="yves"`
* `ES_HOST="elasticsearch"`
* `ES_PROTOCOL="http"`
* `ES_PORT="9200"`
* `REDIS_STORAGE_PROTOCOL="tcp"`
* `REDIS_STORAGE_HOST="redis"`
* `REDIS_STORAGE_PORT="6379"`
* `REDIS_STORAGE_PASSWORD=""`
* `REDIS_SESSION_PROTOCOL="tcp"`
* `REDIS_SESSION_HOST="redis"`
* `REDIS_SESSION_PORT="6379"`
* `REDIS_SESSION_PASSWORD=""`
* `ZED_DB_USERNAME="postgres"`
* `ZED_DB_PASSWORD=""`
* `ZED_DB_DATABASE="spryker"`
* `ZED_DB_HOST="database"`
* `ZED_DB_PORT="5432"`
* `JENKINS_URL="http://jenkins:8080/"`
* `RABBITMQ_HOST="rabbitmq"`
* `RABBITMQ_PORT="5672"`
* `RABBITMQ_USER="spryker"`
* `RABBITMQ_PASSWORD=""`
* `YVES_SSL_ENABLED="false"`
* `YVES_COMPLETE_SSL_ENABLED="false"`
* `ZED_SSL_ENABLED="false"`
* `ZED_API_SSL_ENABLED="false"`

Consumed by initialization hooks:

* `ZED_ADMIN_PASSWORD` --  If set the default password of the admin@spryker.com user will be reset
* `ENABLE_XDEBUG` -- The php module `xdebug` will be activated and configured.
* `ENABLE_OPCACHE` -- The php module `opcache` will be activated and configured.

### Build Time Variable - Reference

Those variables are to be provided via your project specific
`./docker/build.conf`

* `PROJECT` (mandatory) -- Controls the name prefix of the `docker-compose` created services
* `IMAGE` (mandatory) -- What is the name of the resulting docker image?
* `VERSION` (mandatory) -- Which version of the docker image are we working on?
* `BUILD_DEPENDENCIES` -- Distribution (alpine) packages to be installed during build time
* `BASE_DEPENDENCIES` -- Distribution (alpine) packages to be installed additionally
* `PHP_EXTENSIONS` -- Space seperated list of PHP extension to be installed
* `NPM_DEPENDENCIES`-- Distribution packages which will be intalled prior to the NPM handling in the deps layer
* `KEEP_DEVEL_TOOLS` (default: false) -- Shall development tools be installed and kept beyond the build?
* `SKIP_CLEANUP` (default: false) -- Skip cleanup step in each layer build stage. This helps in debugging issues. Be aware, that this skips wiping off the credentials as well! So never ever release such an image into the wild!!!
* `CRONJOB_HANDLER` -- defines where cronjobs should be registered. Currently jenkins and crond are supported.
* `REBUILD_BASE_LAYER` -- If this build var is given, the base layer will be rebuilt during downstream shop image build


### Injecting Custom Configurations

In order to control the behaviour of nginx, php-fpm or php you can either
inject configuration from the outside of the container as bind mounts or via
`Dockerfile` of child shop image. 

#### External Volumes

Configuration of services are prepared to include several files which
constituted the effective configuration.

All configurations are prepred to be expected under a specific directory where
all relevant files will

The expected locations are: 

* Nginx
    * `/etc/nginx/spryker/yves.conf.d/*.conf` 
    * `/etc/nginx/spryker/zed.conf.d/*.conf`
* PHP FPM
    * `/etc/php/fpm/yves.conf.d/*.conf`
    * `/etc/php/fpm/zed.conf.d/*.conf`
* PHP INI
    * `/etc/php/ini/*.ini`.

The default configuration is to be found under:

    /etc/php/fpm/zed.conf.d/100_base.conf
    /etc/php/fpm/zed.conf.d/200_pm.conf
    /etc/php/fpm/zed.conf.d/300_php.conf
    /etc/php/fpm/yves.conf.d/100_base.conf
    /etc/php/fpm/yves.conf.d/200_pm.conf
    /etc/php/fpm/yves.conf.d/300_php.conf
    /etc/php/ini/xdebug.ini
    /etc/php/ini/opcache.ini
    /etc/nginx/spryker/zed.conf.d/500-default.conf
    /etc/nginx/spryker/yves.conf.d/500_default.conf

In environments where you can only mount complete directories into the
container, we have prepared a mechanism which expects a directory hierarchy under `/mnt/configs` and on container creation it symlinks all files under
this location to their corresponding location under `/etc/`.

    # For example: 
    /mnt/configs/nginx/zed.conf.d/600-custom-headers.conf      -->  /etc/nginx/zed.conf.d/600-custom-headers.conf
    /mnt/configs/php/fpm/yves.conf.d/500-raise-processes.conf  -->  /etc/php/fpm/yves.conf.d/500-raise-processes.conf

#### Child Image Overwrites

Due to the nature of layered file systems the child image inheriting from this
base image can simpley overwrites configurations in order to achieve the
desired behaviour of those services. 

Those can easily be customized by supplying configuration files by yourself via the `Dockerfile`:

    FROM claranet/spryker-base:latest
    COPY my_custom_zed.conf /etc/nginx/spryker/zed.conf.d/custom.conf

Since the ONBUILD trigger will be the first directives of the child
`Dockerfile` to be executed, these overridden files will be first available
during runtime of the container.

## Customization

Most of the design decisions made in the base image are governed by the idea of
customizability and extensibility. A base image which could be used only once for
a individual shop image is pretty useless and far away from something called base.

### build.conf

The build process is pretty much as the name suggests the process which
produces the image which get shared by all derived containers during runtime
later on.

Some build scripts consider parameters you can set in `./docker/build.conf`

See reference above..

### Build Steps

Hook dir: `./docker/build.d/`

If you either want to extend the build steps inherited from the base image or
to disable them, you need to place your custom build script under
`./docker/build.d/`. There you will find 3 directories reflecting each stage/layer:

* `./docker/build.d/base/` - Base os level installations
* `./docker/build.d/deps/` - Deal with shop specific PHP/Node dependencies
* `./docker/build.d/shop/` - Deal with code generation of the actual shop code base

Scripts of each subdir get lexically ordered executed (actuall sourced).

For example, if you want to change the way the navigation cache gets built by
the base image, you must supply a script at the very same location it is
provided by the base image under
`./docker/build.d/shop/650_build_navigation_cache.sh`. Since the resulting
image as well as the container will utilize union file systems, the files
provided by the shop image get precedence over the ones provided by the bas
image. By this mechanism you can either disable a functionality simply by
supplying a script which does nothing or you can alter the behaviour by adding
a script which does something differently or additionally.


### Init

The very same mechanism described above could be employed for altering the way
the initialization of the spryker container and the whole setup shall be
executed. The base image comes with meaningful defaults valid for common
environments, but could be overridden by placing custom scripts at appropriate
locations.

The base image provides hooks for both, initialization of each of the
container, and for the initialization of the whole setup.

#### Container Level

Hook dir: `./docker/entry.d/`

The runtime entrypoint arguments (`run-yves`, `run-zed`, `run-yves-and-zed`,
`run-cron`) governing which role this actual container is having, all source
the files listed in this hook directory. Via variables the scripts decide which
services to enable and to start during runtime.

A common task would be to enable `xdebug` as requested via env var
`ENABLE_XDEBUG` on container creation.

Due to the nature all the hooks will be executed on each container start.

#### Setup Wide

Hook dir: `./docker/init.d/`

Commonly each shop instance needs to carry out initial steps to initialize such
a shop.  During this setup wide initialization all of the shell scripts under
the hook dir getting executed. For example to initialize the database with
dummy data like the demoshop does place script under
`./docker/init.d/500_import_demo_data.sh`.

This is not done implicitely, a seperate container must be spawned with the
entrypoint arg `init`.


### Deployment

Hook dir: `./docker/deploy.d/`

Same as the init procedure is the deployment procedure. This procedure will be
carried out during deployments. The lifecycle concept consists of those 2
hooks: init will be called on the first time, and deployment each time a new
version of the image will be carried out.

This is not done implicitely, a seperate container must be spawned with the
entrypoint arg `deploy`.

### Custom Build Steps

As already mentioned you are free to add your very custom build and init steps.
The `./docker/common.inc.sh` script will help you with some useful functions.
Check it out by yourself.

#### Logging

Make your build step telling by using prepared output functions:

* `errorText` - Raise an error
* `successText` - Send back success
* `sectionHead` - Print headline for a group of tasks
* `sectionText` - Print intermediate build step information

#### Installing additional packages

We provide a `install_packages` function for all included build steps.
Please make sure, that you are using it! It comes with the possibility to flag
packages as "build" dependencies. Packages flagged as build-dependencies will
be removed after the layer build finishes. To flag packages
as build dependencies just set `--build` as the first argument:

    # remove "gcc" at the end of our image build
    install_packages --build gcc
     
    # keep "top" in the resulting image
    install_packages top


## Not documented here?

We are still in the early stages of this project, so documentation might be
incomplete. If you want to learn more about features we are providing, please
take a look at [the shell library](docker/common.inc.sh).


## FAQ

### Where to find logs?

In the yves/zed instance(s) you can find nginx, php-fpm and application logs within */data/logs/*

### Which base image are you using?

We are depending on the official PHP images: https://hub.docker.com/_/php/

### Why using Alpine?

Very good question indeed! It is more or less a proof-of-concept which should
demonstrate, that even heavy lifting projects can be hosted on Alpine. The
expected benefits are reduced image sizes and faster build time as well as
faster run times.

Since this PoC hit several limitations, we are about to provide a debian based
image as well.

### How to further speed up image build?

Two things comes to mind:

* Using a local proxy which cached HTTP requests
* Using the proposed [Docker Multistage Build](https://docs.docker.com/engine/userguide/eng-image/multistage-build/)

More to come soon. :)

## Issues

Please take a look at [/issues](https://github.com/claranet/spryker-base/issues).
