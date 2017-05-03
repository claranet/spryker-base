# Spryker base docker image 

This images serves the purpose of providing the base infrastructure of Yves and
Zed. Infrastructure in terms of scripts and tooling around the shop itself.
This image does not provide a ready to use shop! In order to use the features
implemented here, build your own image including the actual implementation of a
shop derived from this image. See directory hierarchy explained below in order
to understand where to place the source code.


<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Spryker base docker image](#spryker-base-docker-image)
- [Project specifics](#project-specifics)
	- [Roadmap](#roadmap)
	- [Default image services architecture](#default-image-services-architecture)
- [Image (Container) specifics](#image-container-specifics)
	- [Features](#features)
	- [Stages](#stages)
	- [Directory hierarchy](#directory-hierarchy)
	- [Using this image](#using-this-image)
	- [Configuration](#configuration)
		- [Order of precedence](#order-of-precedence)
		- [Override base configuration](#override-base-configuration)
	- [On Environments](#on-environments)
	- [Scripting](#scripting)
		- [Build Infrastructure](#build-infrastructure)
		- [Initializing Infrastructure](#initializing-infrastructure)

<!-- /TOC -->


# Project specifics


## Roadmap


> Please double the estimated times to get an appropriate time buffer. To be save - tripple them (normal thumb rule ;))

* 66h (8,5d), (P1: 34h, 5d) | 02.05.2017: Beta release of local dev env (I've 15 workdays from now 2017-03-21 until the beta release)
  * 2h **P1** | move project specific configs from spryker-base to shop repo
    * default_local.conf => customer gets configs via ENV ( getenv() ). we provide predefined default_local.conf with getenv() already in use to provide an example
  * 8h **P1** | create spryker-base flavors:
    * for...
      * PHP versions
      * prod / dev
      * spryker core version, based on spryker demoshop version
    * via docker tag... something like: `php-7.1_spryker-2.9_prod-latest` (7.1 PHP version, 2.9 is spryker core, prod instance env flavor)
  * - only information | we pre-build local development images (with prod/dev flavor)
    * if the customer orders a personalized repository for their own shop
    * customer has to do "git clone && cd docker/ && docker-compose -t spryker up"
    * so there is no need for a custom install script! But there is need for a good documentation!
    * if the customer want to start with the demoshop as their base, it is already prepared
    * if not => he can ask us to docker enable its repository (see first point in this list)
  * 4h **P1** | package manager (npm/yarn) customizing + init_setup disable via vars in hook vars to support customer customizing
    * customer can disable init_setup (or parts of it) to set up their own setups/init process
    * customer can write hooks, which hook into different pre/post steps
    * customer can install npm/yarn with specific versions via ENV settings (to be specified in shop-implementation)
      * choose NODEJS_PACKAGE_MANAGER=(npm|yarn) and NODEJS_PACKAGE_MANAGER_VERSION="..."
      * NODEJS_VERSION=(4.x|6.x|7.x) # 4.x is LTS, 6.x is already matured, 7.x is latest
    * it hasn't to be perfect! But should work with most common scenarios
  * - required later on | git repo: instead of upstream pull => fetch directly the tag ref for a merge!
  * 8h **P1** | clean up demoshop repo:
    * merge history of Dockerfile and docker/ folder
    * build up demoshop repo from skretch (fetch upstream tag 2.8 (for spryker core 2.x support) and in addition, tag 2.9 for spryker core 3.x support)
  * - only information | for local dev: bind-mount read only => to prevent changes in docker image and enforce the user to change files on his system
  * 4-8h **P3** | why are there diffs between devvm and docker images (e.g. vendor/spryker/library is missing in devvm, and therefore Environment.php)? (**low prio**, optimizing)
  * ?h | why not using php:70 directly, instead of building on ubuntu:xenial and managing our own PHP infrastructure? (could only find one argument against it - see "how to provide a different PHP version") (**low prio**, optimizing)
    * would require a clean up of spryker base and a simple adaption in spryker-demoshop
  * 4h **P2** | sync / check new developments in functions.sh and setup process
  * 4h **P1** | write docs for users (developers) - at least a base documentation
    * write notes about when all data in containers gets erased and what docker(-compose) commands are data save...
  * 8h **P2** | clean up entrypoint.sh (**low prio**, optimizing)
    * a lot of testing is involved here, this takes time
  * test local dev env
    * build instructions (init_setup) depend on module versions installed by php composer - how to deal with that? Currently spryker-base provides the build instructions...
      * each customer will probably have its own set of dependencies and modules, even custom build steps (affects init_setup)
      * even config structure will differ per customer (e.g. custom settings, different key/value requirements per module version
    * 8h **P1** | bind-mounts tests
    * rebuild composer/npm dependencies?
      * add variants in documentation for developers
      * via command within docker image?
      * via bind-mount, even resolved dependencies are linked in?
      * if bind-mount => how to run the setup init?
      * if bind-mount we might need to have an externally available trigger which does the init?
        * if so, how? and what about a separate Yves/Zed image while in local dev?
      * via `docker exec`! Or `docker build` by customer
    * is getting Yves/Zed separated in local dev a wanted feature? (yes it is!)
      * if so, it might make it more fragil to transfer / migrate a local dev into PROD/STAGE as envs aren't equal
      * bind-mount read only to prevent changes by docker images
    * 4h | rebuild docker images locally
      * check what env is required for this to work sufficient?
  * 4h **P3** | write script to make installation / setup easier - no aim for a one-shot-run as this might get complicated and risky (requires changes within the unknown dev env of the user)
    * not yet required! Might become a script which analyze the developers env for troubleshooting
  * 4h **P3** | provide S3 object store service and how to provide both - S3 and normal FTP?
    * look for appropriate solutions where API is fine for local dev and PROD
    * NOT YET! Superreal doesn't support S3 API
  * how to provide a different PHP version to customers? => rebuild with different versions? (yes, rebuild!)
    * or local switch? if local switch ( via env setting ) => php:70 base image is obsolete and ubuntu:xenial (or similar) is a good idea
    * if we provide different versions, automated testing is a must => this is official software development, so it represents our brand!
    * even without multiple versions - testing should be automated


## Default image services architecture

> drawing follows... this is a first draft for an overview

* nginx (gets exposed with yves and zed via port 80)
* php-fpm (2 instances - ZED and Yves, both localhost only via socket file)
  * the ZED instance provides the admin interface (admin-frontend in dev speak)
  * the YVES instance provides the "normal shop customer" frontend
* monit starts both services (nginx and php-fpm)



# Image (Container) specifics

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
  * Generate Transfer objects
  * Propel: Collect and merge schema files, build model classes. 
  * Run user supplied hooks
* Init - Runs on a setup basis during runtime (once per setup)
  * CMD: `bootstrap_external_services`
  * Build all the static components of the Yves and Zed part. This is an init
    setup instead a build task because we assume that assets are to be built
    once per setup because they're getting served via external volume which is
    shared across the setup, both between Yves and Zed.
  * Initialize the exernal resources
      * Propel:
          * Create and init database if not existing
          * Diff current models against actual database schema
          * Execute migration plan to make db schema up-to-date
      * Elasticsearch
          * Create indices and mappings
          * Generate Code
          * Export database into data store
      * Redis 
          * Export database into data store 
* Run - Image springs to live and becomes a container
  * Container initialization 
      * Generate confd template configuration - depending on real infrastruture configurations
      * Generate Propel Configuration according actually configured resources

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
        ./Generated/            -- Init generated code: transfer objects, search map classes
        ./Orm/                  -- Build generated code: Propel schema definition and the resulting generated model classes
        ./Pyz/                  -- The project space of this very own implementation. This is the actual implemented of this shop instance.

      ./vendor/                 -- Dependencies resolved by phpcomposer
        ./spryker/              -- APPLICATION_SPRYKER_ROOT

    /data/logs/                 -- Local log files of different components
    /data/bin/                  -- Helper scripts
    /data/etc/config_local.php  -- Spryker configuration overriding the project
                                   wide ones with container local setup resp.
                                   their external dependencies

External docker volumes to be mounted are: 

* `/data/shop/assets` -- Shared volume where static assets were imported (persistent volume)
* `/data/shop/public/Yves/assets` -- Shared volume for serving static assets processed by antelope (volatile volume)
* `/data/shop/public/Zed/assets` -- Shared volume for serving static assets processed by antelope (volatile volume)
* `/data/shop/src/Generated` -- Shared volume to share generated code: Mainly
  because ES init must be done during runtime, therefore we need the
  resulting generated code shared among all containers (volatile volume)

Type of volumes:

* Persistent:
    * Unique to setup
    * Shared across container of all different revisions
* Volatile:
    * Unique to revision
    * Shared among all container of same revisions

## Using this image 

In order to use this docker image one must build a docker image itself by
inheriting this base image and adding custom instructions if necessary. 

Inherited properties are:

* Environment variables (`ENV`)
* Build trigger adding essential part of your codebase (`ONBUILD`)
* The entrypoint and cmd parts (`ENTRYPOINT`, `CMD`)

Sample Dockerfile:

```docker
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
the effective concrete docker image implementing the actual shop.

By default your code base need to supply the following parts which
automatically get added to the image:

* `./src/` -- custom part of the spryker based shop
* `./config/` -- configuration of different environments and stores
* `./package.json` -- npm dependencies 
* `./composer.json` -- php dependencies 
* `./docker/build.conf` - Shell sourcable file including variables governing the
  behavior of the build process of the child image (e.g.: `$PHP_EXTENSIONS`).
* `./docker/build.d/{Shared,Yves,Zed}` - User provided scripts which will be executed during image build process (once per image).
* `./docker/init.d/{Shared,Yves,Zed}` - User provided scripts which will be executed during runtime as initialization procedure (once per cluster). 

## Configuration 

The abstract base infrastructure provides the derived more concrete shop docker
image with the templating features we need to feed this shop with the proper
configuration for dynamic environments. 

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

1. First it **configures** external resources appropriate for this environment to run in
2. ... and secondly it defines a particular behavior specific for this **mode** to be ran 

Since containerized application were always dynamically configured we do not
need this distinction for parallel configurations of different environments or
sites. But this distinction is nevertheless useful for governing the behavior
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

The complex console command `setup:install` resolves to the following subtasks:

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
