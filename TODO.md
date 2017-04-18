# Todo items

## just a bunch of small reminders

* add ability to provide...
  * 404 page / destination
  * maintenance.html (which might be exported to be delivered externally by the LB)
  * error page for 5xx
* clean up alpine linux container for sleeker images
* clean up nginx config and make it more robust
* secure php installation (disable functions/classes, set open_basedir, ...)
* clean up commit history
* write user documentation

## Open discussion 

* We need to maintain two branches of this docker image, one for PHP5.6 and one
  for PHP7 environments. The customer should be able to chose between those two
  runtime environments. Questions is, how do we keep the required maintenance
  effort low?
* Split up Yves/Zed from the very beginning or providing a unified image
  instead and leave this question open to the engineer running this setup? He
  could decide to split both parts in order to be able to scale them
  independently. But this could be done even if we provide a unified image. A
  unified image further has the advantage of easier handling for developers who
  want their shop built as a docker image and therefore need only to consider
  one image.
* Split up the dynamic and the static part? 
* How to implement shops for different countries? Do we need separated VHosts
  for this? Will this be achied by env settings of the nginx vhost? 
* Do we need to split up the components shop wise? One database for DE another for US? 
* How do we want to handle different shops based on country codes? Depending nginx
  vhost, spryker and database might be handled differently? 
  * [TW] I would recommend to setup one pool of docker instances per locale. So
    locale changes would be handled by a loadbalancer (via source, cookie, url,
    domain, ...) This would also include the ability to scale different locales
    individualy. But will increase amount of docker instances. Each locale
    needs a different code configuration.
      * [FD] Especially because this possibly results in a significant higher
        number of containers, I vote against it. Because the setup will be way
        more complex to manage. And since there is barely - as we heard today
        in the webex with Spryker - any code changes but rather configuration
        changes there might arise different options which are easier to handle.
        Better would be a mechanism covering this scenario. Like configuring
        environment variables governing the available country codes for the
        different shops. We considering these variable during build and init
        time. 
      * [FD] Furthermore, i suppose that each of CC shops rely on shared
        stateful (db, redis) information.
      * [FD] We should prepare the images of a single shop instance with the
        possibility of different localized versions of the very same shop. If
        the customer wants to run independent shops for each country instance,
        they just need to bootstrap different container pools for this and
        therefore running completely different setups. 
* How do we implement a rolling upgrade? This questions falls apart in two categories:
    * How do handle the infrastructure part on k8s and via docker-compose as well 
    * What about the application part? Imagine a running cluster and you wanna
      push a new shop image. This includes code as well as static assets. The
      challenge starts if go even further and consider shop upgrade which have
      some impact on the database schema or the something similiar on the
      Redis/ES side. How do we cope with this scenario? 
* Split off generic and demoshop specific build/init jobs and move them to user
  supplied hooks. This heavily depends on the bundles being used by the common
  shops. Which console jobs are reasonbly placed at the generic base image? For
  example, is the navigation cache for zed to be expected to be used for all or
  most of the shops out there? 


## Open action items

* Prepare Jenkins to be incorporated
* Update images to rely on recently version 2.4 of the demoshop which runs on
  PHP 7.1.
* Scan all config files for external resource definitions and consider moving
  them into the config_local.php. Rationale behind these decisions must be the
  weighing up whether the configuration option in question better fits into the
  generic layer or into the shop layer.
* Make some of the nginx configuration configurable from the outside of the
  container. Think of something comparable like the build trigger, but rather
  for the nginx to be included.
* Spryker: Remove auth token off configuration (AuthConstants::AUTH_DEFAULT_CREDENTIALS)
* Implement mail solution different to local maildrop. Newsletter are commonly
  sent via a mail provider reachable via API, but locally emitted notifications
  like user registration expects a running mail setup. 
* Find different solution for cronjobs than simply running them in one single
  container? Either use kubernetes scheduled cron jobs or use dkron.  Replace
  the cronjobs under `./config/Zed/cronjobs`. In order to stay infrastructure
  agnostic, it is recommended to implement the cron service as substantial
  service within the cluster, instead of relying on something from the outside
  like k8s cron jobs.
* Implement proper health checks for php-fpm channeled through nginx and
  evaluated by monit which in turn must propagate the state of the application
  to the outside world (docker).
* Utilize the HEALTHCHECK directive of the Dockerfile format - even if its not
  evaluated in k8s deployment contexts. 
* [Optimization] Try to find some potential in reducing the size of the docker
  images. Right now the base image is of 400MB weight. Plus the demoshop we
  reach 700MB. Thats for now acceptable but tends to grow. Therefore check what
  effectively is included in the image and if its necessary. Antelope alone
  needs 94MB (`/usr/lib/node_modeules/antelope`). 
    * Do we need antelope after we've built the artifacts during the child image build?
        * Yes, unfortunately, since search setup involves (a) creating the
          indizes at elasticsearch, and (b) creating code which represents the
          mapping as class. 
        * But since the assets are moved off the container into external
          volumes which are shared across the cluster, we might create a second
          image including all the dependencies for initializing the cluster and
          remove these deps from the shop image which needs to be distributed
          across the docker cluster. 
        * Think of something like a tooling docker image. 
* [Optimization] Same applies to image layers. Optimize were feasible and reasonable.
* [Optimization] Identify the places within the docker image where data gets
  written. This might pose a threat to either performance or storage usage -
  possibly both. Watch and check if these places need housekeeping efforts like
  cleaning jobs.
    * `/data/shop/data/`
    * `/data/logs/`

## Resolved

* Add possibility to differentiate user supplied hooks for not only the
  component like Yves and Zed, but for the environment as well. 
    -> Not implemented, since this information is available to the hook scripts
       via environment variables so that they are able to differentiate by
       theirselves. 
* Migrate from php5 to php7
* Make the list of to be installed php extensions configurable. Right now its a
  static list fixiated in the base image. 
* Consider using the `ONBUILD` directive of the `Dockerfile` syntax in order to
  use the provided features of this image with a downstream image (see buildl
  time tooling below).
* Split up the build and init console commands. We need strictly need to
  differentiate between build commands like collecting and merging all the
  propel definitions and init commands like diff'ing and migrating the propel
  definition in an actual database. The first takes place during image build
  process and the ladder during cluster runtime.
* Write tooling for init during build time 
    * collects the schema definitions
    * collects the transfer objects
    * run antelope and build all the static assets
* Prepare hooks where user provided scripts may be ran at the build and the
  init level. For instance, the demoshop imports sample data. This would not be
  covered by the base image, since this is  specific to the demoshop. 
    * One approach would be to expect - from the view of the base image -
      folders with scripts to be executed. `./docker/build.d/` and `./docker/init.d/`
* Write tooling for init during runtime: entrypoint script which implements
    * templatable configuration files 
    * initial database/redis/elasticsarch refuelling
