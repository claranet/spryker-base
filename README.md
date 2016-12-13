# Spryker base docker image 

This images serves the purpose of providing the base infrastructure of Yves and
Zed. Infrastructure in terms of scripts and tooling around the shop itself.
This image does not provide a ready to use shop! In order to use the features
implemented here, build your own image including the actual implementation of a
shop derived from this image. See directory hierarchy explained below in order
to understand where to place the source code. 

## Features

* [x] process supervision via monit
* [x] nginx
* [x] php-fpm 
* [x] php7
* [x] php7 base modules 
* [x] php7 custom modules 
* [x] templating of configuration files according to container environment 
* [x] base directory hierarchy 
* [x] building of shop application (npm, php composer, ...)
* [ ] initialize the external resources 
* [ ] logging 


## Stages 

We distinct the following lifecycle stages and their corresponding responsibilities:

* Build - Runs on image level during build process (once per image)
  * CMD: `build_image`
  * Resolve dependencies 
  * Collect, merge and generate code artefacts (transfer objects, orm definitions and classes, ...)
  * Run user supplied hooks (FIXME: yet to be resolved issue)
* Init - Runs on a setup basis during runtime (once per setup)
  * CMD: `init_setup`
  * Build all the static components of the Yves and Zed part. This is an init
    setup instead a build task because we assume that assets are to be built
    once per setup because they getting served via external volume which is
    shared across the setup, both between Yves and Zed.
  * Initialize the exernal resources
  * PostgreSQL - Create and init database if not existing; otherwise migrate database schema 
  * Elasticsearch - Export database into data store
  * Redis - Export database into data store 
* Run 
  * ...

## Directory hierarchy

This hierarchy represents a typical root directory of a spryker based shop:

    /data/shop/                 -- APPLICATION_ROOT_DIR
      ./assets/                 -- Externally delivered static assets - one of
                                   the input sources to antelope. Varies on
                                   different setups, depending on where the
                                   product information will be managed and how
                                   this information will be referenced.

      ./config/                 -- Configuration files
      ./cache/                  -- Twig cache, the silex/symfony web profiler
                                   cache and further temporary files will be
                                   placed here during runtime

      ./public/{Yves,Zed}/      -- Entry point to spryker application (document root)
        ./assets                -- Output directory for antelope

      ./src/                    -- Actual implementation of this shop instance provided by you!
        ./Generated/            -- Generated code: transfer objects, search map classes
        ./Orm/                  -- Generated code: Propel schema definition and the resulting generated model classes
        ./Pyz/                  -- The project space of this very own implementation. This is the actual implemented of this shop instance.

      ./vendor/                 -- Dependencies resolved by phpcomposer
        ./spryker/              -- APPLICATION_SPRYKER_ROOT

    /data/logs/                 -- Local log files of different components
    /data/bin/                  -- Helper scripts
    /data/etc/config_local.php  -- Spryker configuration overriding the project
                                   wide ones with container local setup resp.
                                   their external dependencies

External docker volumes to be mounted are: 

  * `/data/shop/assets` -- Shared volume where static assets were imported (1)
  * `/data/shop/public/Yves/assets` -- Shared volume for serving static assets processed by antelope (2)
  * `/data/shop/public/Zed/assets` -- Shared volume for serving static assets processed by antelope (2)

## Using this image 

In order to use this docker image one must build a docker image itself by
inheriting this base image and adding custom instructions if necessary. 

Inherited properties are:

* Environment variables (`ENV`)
* Build trigger adding essential part of your codebase (`ONBUILD`)
* The entrypoint and cmd parts (`ENTRYPOINT`, `CMD`)

Sample Dockerfile:

```
FROM spryker-base:latest
```

This is the sole line required for using this image.

All the environment variables defined here in the base image will be inherited
by the child image as well. So defaults should be same. During runtime
configuration you must supply spryker with information regarding the depending
external resources like the Redis, PostgreSQL or Elasticsearch. To check which
environment variables are necessary or required have a look at the `Dockerfile`. 

Furthermore are there build trigger (`ONBUILD`) placed at the base level which
governing part of the build process of the child image. These trigger define
which part of your shop source code repository (by default) will be included to
the effective conrete docker image implementing the actual shop.

By default your code base need to supply the following parts which
automatically get added to the image:

* `./src/` -- custom part of the spryker based shop
* `./config/` -- configuration of different environments and stores
* `./package.json` -- npm dependencies 
* `./composer.json` -- php dependencies 
* `./docker/build.conf` - Shell sourcable file including variables governing the
  behaviour of the build process of the child image (e.g.: `$PHP_EXTENSIONS`).
* `./docker/build.d` - User provided scripts which will be executed during image build process (once per image).
* `./docker/init.d` - User provided scripts which will be executed during runtime as initialization procedure (once per cluster). 

## Configuration 

The abstract base infrastructure provides the derived more concrete shop docker
image with the templating features we need to feed this shop with the proper
configuration for dynamica environments. 

### Order of precedence

Spryker reads the configuration in a orderly manner: 

1. `config_default.php`
1. `config_default-[environment].php`
1. `config_default-[storename].php`
1. `config_default-[environment]_[storename].php`
1. `config_local.php`
1. `config_local_[storename].php`

### Override base configuration

Where are these configuration and how are we able to override them?

...

## On Environments

The environment definition (production, staging, development) fulfills two functions:

1. First it **configures** external resources approriate for this environment to run in
2. ... and secondly it defines a particular behaviour specific for this **mode** to be ran 

Since containerized application were always dynamically configured we do not
need this distinction for parallel configurations of different environments or
sites. But this distinction is nevertheless useful for governing the behaviour
of the application. If we want to run this app in development mode we
potentially do not want to run all the payment code, or the mail notification
code. This differs to production mode. 

Bottom line is, that we keep the semantics of this distinction. 

These environment are defined here: `vendor/spryker/library/src/Spryker/Shared/Library/Environment.php`:

```php
const DEFAULT_ENVIRONMENT = 'production';

const PRODUCTION = 'production';
const STAGING = 'staging';
const DEVELOPMENT = 'development';
const TESTING = 'testing';
```

## Scripting

As the stage above already mentioned we distinguish between different life
cycle stages. This section deals with the individual task each stage is
responsible for. 

The console commands of the deployment procedure of the vagrant box must be
fully understood and translated into appropriate build and init tasks. In some
circumstances this means that we need to rewrite console commands (alignment
between ops and spryker).

The complex console command `setup:install` does the following:

1. `cache:delete-all`
1. `setup:remove-generated-directory`
1. `propel:install --nodiff`
1. `transfer:generate`
1. `setup:init-db`
1. `setup:generate-ide-auto-completion`
1. `application:build-navigation-cache`
1. `setup:search`


Please see `Spryker\Zed\Setup\SetupConfig::getSetupInstallCommandNames` for more details


### Build Infrastructure

...


### Initializing Infrastructure

...
