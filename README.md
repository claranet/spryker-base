
This images serves the purpose of providing the base infrastructure of Yves and
Zed. Infrastructure in terms of build/init scripts and further tooling around
the shop itself.  This image does not provide a ready to use shop! In order to
use the features implemented here, write your own `Dockerfile` - which uses
this base image to inherit from - along your actual implementation of a Spryker
shop. See directory hierarchy explained below in order to understand where to
place the source code.

**This project is in ALPHA stage and will eat your children!** 

Thats why we are keen to get feedback from you! This is a work in progress
effort which strives for making dockerizing a Spryker Shop as easy as possible.
In order to successfully achieve this goal, we need to identify common steps
worth to be generalized and put into this base image. So tell us about you
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
template/base image for a concrete spryker shop implementation.  So if you want
to build a spryker shop container image, this image helps you with common tasks
and is trying to make most of the common steps automatically for you.

Core traits are:

* Uses dockers `ONBUILD` trigger feature to hook into and control the child image build process
* Provide reasonable default FPM/nginx configuration
* Its open for customization by providing hookable build and init routines
* Expects the base structure from the [spryker-demoshop](https://github.com/spryker/demoshop)
* No further constraints, you are absolutely free to design you shop the way you want it to


# Interface

In order to reuse the functionalities implemented here, the following aspects
need to be aligned with the base image: 

* Follow Spryker reference directory hierarchy
    * `./src/` - Your shop implementation
    * `./config` - Configuration
    * `./public/{Yves,Zed}` - Entrypoints to you application (document root)
* Dependencies
    * PHP: `composer.json` and `composer.lock`
    * Node: `packages.json`
* Make Spryker configuration consider env vars. Checkout the `config/Shared/config_local.php` of the [demoshop](https://github.com/claranet/spryker-demoshop) exemplify what is meant here.
* Control the PHP extension you want to be installed via `./docker/build.conf`
* Control the build process of the image by placing your scripts under `./docker/build.d/`
* Control the initialization process of the setup by placing your scripts under `./docker/init.d/`

Again, check out the [demoshop](https://github.com/claranet/spryker-demoshop)
we have prepared for using this image here. This should answer all of the
questions you might have. 


# Create your own image

Either fork the [demoshop](https://github.com/claranet/spryker-demoshop) or
start from scratch. For the latter you need to consider the following steps.


## Create a Dockerfile

Create a [Dockerfile](https://docs.docker.com/engine/reference/builder/) which
just inherits from the base image as following: 

    FROM claranet/spryker-base:latest

For most of the cases this is pretty much everything you need.


## Prepare file hierachy

What is needed is a `./docker` subfolder where the base image resp. the on
build trigger are expecting modifications the build and initializations
routines. 

    $ mkdir -p docker

## Write Spryker Configuration


## Write docker-compose.yml


```
---
version: '3'

services: 
  zed: 
    image: "your-shop-image:latest"
    command: "run_zed"
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
    command: "run_yves"
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

If you want to get into the docker container theirselves:

```sh
# to get into the yves instance
docker exec -it your-shop-image_yves_1 /bin/sh

# to get into the zed instance
docker exec -it your-shop-image_zed_1 /bin/sh
```

# Inside the resulting container image

Please take a look at [the deep dive documentation](docs/README.md)

# Customization

## PHP Extensions 

...

## Build Arguments

* With `DEV_TOOLS=on`, we won't clean up the image from build tools and
  debugging tools.  Even further we will add tools like vim, tree and less.
  supported vaules are (on/off), defaults to "off"
* `APPLICATION_ENV` decides in which mode the application is installed/runned.
  so if you choose development here, e.g. composer and npm/yarn will also
  install dev dependencies! There are more modifications, which depend on this
  switch.  defaults to "production"
* Choose node version by supplying `NODEJS_VERSION` as ARG to switch between
  nodejs 6.x and 7.x.
* `NODEJS_PACKAGE_MANAGER`: you can, additionally to npm, install yarn; if you
  select yarn here also, if yarn is selected, it would be used while running
  the base installation

## Build Hooks

...

## Init Hooks

...

# FAQ

## Where to find logs

In the yves/zed instance(s) you can find nginx, php-fpm and application logs within */data/logs/*

## Which base image are you using?

We are depending on the official alpinelinux basing [php-fpm docker images](https://hub.docker.com/_/php/)


# Issues 

## PHP Version 7.0.17

We currently stick to 7.0.17 as 7.0.18 breaks spryker predis usage. See
https://github.com/php/php-src/commit/bab0b99f376dac9170ac81382a5ed526938d595a
for details and PHP bug report: https://bugs.php.net/bug.php?id=74429
