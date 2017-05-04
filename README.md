
This is the documentation on how to use the docker hub image of `claranet/spryker-base` from a user perspective.
If you are looking for more deep dive information how this docker image works internally,
please take a look at [our docs/ directory](docs/README.md).


# Overview

This repository is the origin of [docker hub spryker-base image](https://hub.docker.com/claranet/spryker-base). It provides an easy to use docker image to build/setup your own [spryker](https://spryker.com/) spryker shop/instance.


This docker image `claranet/spryker-base` is only a template/base image for a more concrete spryker shop docker image. So if you want to build a spryker shop container image, this image wants to help you with common tasks and is trying to make most of the common steps automatically for you.

* it makes use of dockers `ONBUILD` feature to copy common directories and their files
* it provides hookable build steps
* it expects the base structure from the [spryker-demoshop](https://github.com/spryker/demoshop)


# Prepare your own, custom shop repository


* create a [Dockerfile](https://docs.docker.com/engine/reference/builder/) with the following content: `FROM claranet/spryker-base:latest`
* create a `docker/` directory in the root of your repository
* create a `docker-compose.yml` file within the `docker/` directory with your required services and the following lines (adapt them for your needs)

```
--- 

# take a look at https://docs.docker.com/compose/compose-file/ for details

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
    # TODO: images is deprecated and maintained until the 2017-06-20
    # see https://hub.docker.com/_/elasticsearch/
    image: "elasticsearch:2.4-alpine"
    restart: always
    # just to create a simple delay for init phase in depending on the database
    depends_on:
      - database

# postgres is listening for incoming sessions even if it is not ready to serve as a service
# this needs to be considered in the setup step as `wait_for_service` does only check, if the
# given service is able to establish connections.
  database:
    image: "postgres:9.4.11-alpine"
    restart: always

  jenkins:
    image: "jenkins:alpine"
    ports: 
      - "10007:8080"
```

## Build your shop container image

We provide some docker build arguments to let you change the image build result. You can find possible arguments via looking at the Dockerfile in this repository. egrep for "^ONBUILD ARG" to get a list of possible `--build-arg` arguments. Inside the Dockerfile there are more details about the arguments and what they are doing.

After you figured out which build arguments you want (you don't need any, if the defaults fits your needs), you can do a `docker build`:

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

# FAQ

## Where to find logs

In the yves/zed instance(s) you can find nginx, php-fpm and application logs within */data/logs/*

## Which base image are you using?

We are depending on the official alpinelinux basing [php-fpm docker images](https://hub.docker.com/_/php/)
