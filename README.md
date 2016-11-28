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
* [x] php5
* [x] php5 base modules 
* [x] templating of configuration files according to container environment 
* [x] base directory hierarchy 
* [ ] logging 


## Directory hierarchy

    /data/shop/               -- APPLICATION_ROOT_DIR
      ./assets/               -- Static assets built by antelope
      ./config/               -- Configuration files
      ./cache/                -- Twig cache, the silex/symfony web profiler
                                 cache and further temporary files will be placed here during runtime
      ./public/{Yves,Zed}/    -- Entry point to spryker application (document root)
      ./src/                  -- Actual implementation of this shop instance provided by you!
        ./Generated/          -- Implementation of all collected transfer objects  of all bundles
        ./Orm/                -- All the collected Propel schema definitions (XML) of all bundles
        ./Pyz/                -- The project space of this very own implementation

      ./vendor/               -- Dependencies resolved by phpcomposer
        ./spryker/            -- APPLICATION_SPRYKER_ROOT

    /data/logs/               -- Local log files of different components

## Using this image 

... 

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
