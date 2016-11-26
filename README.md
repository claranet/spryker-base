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
* [ ] templating of configuration files according to container environment 
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
