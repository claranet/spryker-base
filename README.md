
[![build status badge](https://img.shields.io/travis/claranet/spryker-base/master.svg)](https://travis-ci.org/claranet/spryker-base/branches)

This image serves the purpose of providing the base infrastructure for Yves and
Zed. Infrastructure in terms of build/init scripts and further tooling around
the shop itself. This image does not provide a ready to use shop! In order to
use the features implemented here, write your own `Dockerfile` - which uses
this base image to inherit from - along your actual implementation of a Spryker
shop. See directory hierarchy explained below in order to understand where to
place the source code.

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


# Benefits of Containerization

* Consistency
* Reproducibility
* Portablity
* Seamless deployment form local development into prod environment

# Overview

You can think of this docker image `claranet/spryker-base` as some kind of a
base image or a factory for a docker image of a specific spryker shop
implementation. So if you want to build a spryker shop container image, this
image helps you with common tasks and is trying to make most of the common
steps automatically for you.

Core traits are:

* Uses dockers `ONBUILD` trigger feature to hook into and control the child image build process
* Provide reasonable default FPM/nginx configuration
* Its open for customization by providing hookable build and init steps
* Expects the base structure from the [spryker-demoshop](https://github.com/spryker/demoshop)
* No further constraints, you are absolutely free to design you shop the way you want it to


# Interface

In order to reuse the functionalities implemented here, the following aspects
need to be aligned with the base image: 

* Follow Spryker reference directory hierarchy
    * `./src/Pyz` - Your shop implementation
    * `./config` - Configuration
    * `./public/{Yves,Zed}` - Entrypoints to you application (document root)
* Dependencies
    * PHP: `composer.json` and `composer.lock`
    * Node: `packages.json`
* Make Spryker configuration consider env vars. Checkout the [shop_skel/config/Shared/config_local.php](/shop_skel/config/Shared/config_local.php) which is exemplify what is meant here.
* Control the PHP extensions you want to be installed via `./docker/build.conf`
* Control the build process of the image by placing your scripts under `./docker/build.d/`
* Control the initialization process of the setup by placing your scripts under `./docker/init.d/`

Check out the [demoshop](https://github.com/claranet/spryker-demoshop)
we have prepared for using this image here. This should answer all of the
questions you might have.


# Create your own image

Either fork the [demoshop](https://github.com/claranet/spryker-demoshop) or
start from scratch. For the latter you need to consider the following steps.

## Forking Demoshop

## Starting from Scratch

### Create directory hierarchy

We have prepared some kind of a [skeleton](/shop) with all required files you
need to get started in order to bootstrapp your custom shop instance. 

The code below creates a `config_local.php` which is using ENV vars to configure
the shop, so you can use the resulting image in different environments and the
spryker config should adapt.

A dockerignore file ensures, we don't copy to much data into the docker image.

```sh
# change these parameters
YOUR_SHOP="/path/to/your/shops/repository"

# steps to prepare your shop
mkdir -p $YOUR_SHOP && git init $YOUR_SHOP
cp -an shop/* shop/.* "$YOUR_SHOP/"
cd "$YOUR_SHOP"
git add . && git commit -a -m "initial commit"
```

With this skeleton, you are ready to customize your repository to your individual needs. The
skeleton can be used untouched, if you want to use it for the demoshop.

## Write Spryker Configuration



## Write docker-compose.yml


```
---
version: '3'

services: 
  zed: 
    image: "your-shop-image:latest"
    command: "run-zed"
    restart: "no"
    depends_on:
      - database
      - redis
      - elasticsearch
    build:
      context: ../
      dockerfile: Dockerfile
    ports:
      - "2381:80"
    links:
      - redis
      - elasticsearch
      - database

  yves: 
    image: "your-shop-image:latest"
    command: "run-yves"
    restart: "no"
    depends_on:
      - zed
    ports:
      - "2380:80"
    links:
      - zed
      - redis
      - elasticsearch

  redis:
    image: "redis:3.2-alpine"
    restart: always

  elasticsearch:
    image: "elasticsearch:2.4-alpine"
    restart: always
    depends_on:
      - database

  database:
    image: "postgres:9.4.11-alpine"
    restart: always

  jenkins:
    image: "jenkins:alpine"
    ports: 
      - "10007:8080"
```

## Build your shop container image

We provide some docker build arguments to let you change the image build
result. You can find possible arguments via looking at the Dockerfile in this
repository. egrep for "^ONBUILD ARG" to get a list of possible `--build-arg`
arguments. Inside the Dockerfile there are more details about the arguments and
what they are doing.

After you figured out which build arguments you want (you don't need any, if
the defaults fits your needs), you can do a `docker build`:

```sh
# execute this in your repository root directory
docker build -t <your-shop-image:latest> .
```

After the build is finished, you can start a local demo via `docker-compose`:

```sh
# execute this in the previously created docker/ directory
docker-compose -p <your-shop-image> up
```

The shop image should run the initializing and after that you should be able to serve http://localhost:2380 for yves and http://localhost:2381 for zed.

If you want to get into the docker container themselves:

```sh
# to get into the yves instance
docker exec -it your-shop-image_yves_1 /bin/sh

# to get into the zed instance
docker exec -it your-shop-image_zed_1 /bin/sh
```

# Enhance / customize the build/init process for your own needs

## The build.conf file

Is essentially a shell script, but should only be used for defining variables!

Location: `docker/`

## Install additional Node dependencies

Use `NPM_DEPENDENCIES` which holds a list of distribution packages to be installed prior to resolving npm depdencies.


## Install additional PHP extensions

...

```
# in build.conf
PHP_EXTENSIONS="imagick pdo_psql"
```

## Logging

...

```
errorText
successText
sectionHead
sectionText
```

## Installing additional packages

We provide a `install_packages` function for all included (build|init) scripts. Please make sure, that you are using it! It comes with the possibility to flag packages as "build" dependencies. Packages flagged as build-dependencies will be removed after the image build finishes and `DEV_TOOLS=off`. To flag packages as build dependencies just set `--build` as the first argument:

```
# remove "gcc" at the end of our image build
install_packages --build gcc

# keep "top" in the resulting image
install_packages top
```

## Install modes

* DEV_TOOLS

...

## Not documented here?

We are still in the early stages of this project, so documentation might be incomplete. If you want to learn more about features we are providing, please take a look at [the shell library](docker/common.inc.sh).

# Inside the resulting container image

Please take a look at [the deep dive documentation](docs/README.md)

# Customization

## PHP Extensions 

...

## Build Arguments

* With `DEV_TOOLS=on`, we won't clean up the image from build tools and
  debugging tools.  Even further we will add tools like vim, tree and less.
  supported vaules are (on/off), defaults to "off"

## Build Hooks

...

## Init Hooks

...

# FAQ

## Why is the shop image artificially split up in 3 layers?

There are a couple of reason for this. First, it should leverage the docker
cache and speed up iterative rebuilds of the shop image. Since these layers are
ordered from generic to concrete, the need for rebuilds of the whole stack
while working on the code base of the actual shop implementation should be
reduced. Second, different layers could be retrieved in parallel while pulling
the image, which speeds up the container creation time. Furthermore, since
generic layers do not change that often, the need not only for rebuilds but for
refetching the whole image should be reduced as well.

Unfortunately this comes not without cost, the effective image size will be
higher than effective images which get build up by just one layer. Right now
this seems to be a acceptable tradeoff.

## How to handle private repositories?

In case your PHP or Node depdencies need to be pulled from a private
repository, you just need to provide a `~/.netrc`. This file will be
automatically detected and temporarily as docker build arg injected into the
transient build container, used by git for cloning the appropriate
repositories, and afterwards wiped off the resuilting layer right before the
layer will be closed.

The format for the `$HOME/.netrc` is as follows:

    machine git.company.local
    login my_user_name
    password my_private_token

The `docker/run.sh` script of the shop repository - as long its been generated
from this `./shop` subdir or forked from the `claranet/spryker-demoshop` -
takes care of the rest.

In order to take effect all the given dependencies must be either given as HTTP
url or they getting transformed via `git config --global
"url.https://".insteadof "git://git@` which has been already prepared by this
image. If you want to add more specific rule, create a build script in the
dependency layer which gets executed prior to the dependency resolution
process: 

    vi docker/build.d/deps/300_private_repo_override.sh
    #!/bin/sh
    sectionText "Diverting git transport from SSH to HTTPS: https://git.company.local"
    git config --global "url.https://git.company.local/".insteadof "git@git.company.local:"
    git config --global "url.https://git.company.local".insteadof "ssh://git@git.company.local"

Since git urls can be given in a arbitrary combination, this is in some
circumstances necessary.

## Where to find logs

In the yves/zed instance(s) you can find nginx, php-fpm and application logs within */data/logs/*

## Which base image are you using?

We are depending on the official alpinelinux basing [php-fpm docker images](https://hub.docker.com/_/php/)


# Issues 

Please take a look at [/issues](https://github.com/claranet/spryker-base/issues).
