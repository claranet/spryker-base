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

* Build - Runs on image level during build process
  * Resolve dependencies 
  * Collect, merge and generate code artefacts (transfer objects, orm definitions and classes, ...)
  * Build all the static components of the Yves and Zed part 
* Init - Runs on a setup basis during runtime
  * Initialize the exernal resources
  * PostgreSQL - Create and init database if not existing; otherwise migrate database schema 
  * Elasticsearch - Export database into data store
  * Redis - Export database into data store 
* Run 
  * ...

## Directory hierarchy

    /data/shop/                 -- APPLICATION_ROOT_DIR
      ./assets/                 -- Static assets built by antelope
      ./config/                 -- Configuration files
      ./cache/                  -- Twig cache, the silex/symfony web profiler
                                   cache and further temporary files will be
                                   placed here during runtime
      ./public/{Yves,Zed}/      -- Entry point to spryker application (document root)
      ./src/                    -- Actual implementation of this shop instance provided by you!
        ./Generated/            -- Implementation of all collected transfer objects  of all bundles
        ./Orm/                  -- All the collected Propel schema definitions (XML) of all bundles
        ./Pyz/                  -- The project space of this very own implementation

      ./vendor/                 -- Dependencies resolved by phpcomposer
        ./spryker/              -- APPLICATION_SPRYKER_ROOT

    /data/logs/                 -- Local log files of different components
    /data/bin/                  -- Helper scripts
    /data/etc/config_local.php  -- Spryker configuration overriding the project
                                   wide ones with container local setup resp.
                                   their external dependencies

## Using this image 

In order to use this docker image one must build a docker image itself by
inheriting this base image and adding custom instructions if necessary. 

Inherited properties are:

* Environment variables (`ENV`)
* Build trigger adding essential part of your codebase (`ONBUILD`)
* The entrypoint and cmd parts (`ENTRYPOINT`, `CMD`)

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

* `./src/`
* `./package.json`
* `./composer.json`
* `./build.conf` - Shell sourcable file including variables governing the
  behaviour of the build process of the child image (e.g.: `$PHP_EXTENSIONS`).
* `./config/`

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
