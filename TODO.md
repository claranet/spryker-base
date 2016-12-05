
# Todo items

## Open discussion 

* We need to maintain two branches of this docker image, one for PHP5 and one
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
* How do want to handle different shops based on country codes? Depending nginx
  vhost, spryker and database might be handles differently? 
* How do we implement a rolling upgrade? This questions falls apart in two categories:
    * How do handle the infrastructure part on k8s and via docker-compose as well 
    * What about the application part? Imagine a running cluster and you wanna
      push a new shop image. This includes code as well as static assets. The
      challenge starts if go even further and consider shop upgrade which have
      some impact on the database schema or the something similiar on the
      Redis/ES side. How do we cope with this scenario? 


## Open action items


* Split up the build and init console commands. We need strictly need to
  differentiate between build commands like collecting and merging all the
  propel definitions and init commands like diff'ing and migrating the propel
  definition in an actual database. The first takes place during image build
  process and the ladder during cluster runtime.
* Spryker: Remove auth token off configuration (AuthConstants::AUTH_DEFAULT_CREDENTIALS)
* Implement mail solution different to local maildrop
* Find different solution for cronjobs than simply running them in one single
  container? Either use kubernetes scheduled cron jobs or use dkron.
  Replace the cronjobs under `./config/Zed/cronjobs`
* Implement proper health checks for php-fpm channeled through nginx and
  evaluated by monit which in turn must propagate the state of the application
  to the outside world (docker).
* Write tooling for init during build time 
    * collects the schema definitions
    * collects the transfer objects
    * run antelope and build all the static assets
* Write tooling for init during runtime: entrypoint script which implements
    * templatable configuration files 
    * initial database/redis/elasticsarch refuelling
* Utilize the HEALTHCHECK directive of the Dockerfile format - even if its not
  evaluated in k8s deployment contexts. 
* [Optimization] Try to find some potential in reducing the size of the docker
  images. Right now the base image is of 400MB weight. Plus the demoshop we
  reach 600MB. Thats for now acceptable but tends to grow. Therefore check what
  effectively is included in the image and if its necessary. Antelope alone
  needs 94MB (`/usr/lib/node_modeules/antelope`). Do we need antelope after
  we've built the artifacts during the child image build?
* [Optimization] Same applies to image layers. Optimize were feasible and reasonable.
* [Optimization] Identify the places within the docker image where data gets
  written. This might pose a threat to either performance or storage usage -
  possibly both. Watch and check if these places need housekeeping efforts like
  cleaning jobs.
    * `/data/shop/data/`
    * `/data/logs/`

## Resolved

* Migrate from php5 to php7
* Make the list of to be installed php extensions configurable. Right now its a
  static list fixiated in the base image. 
* Consider using the `ONBUILD` directive of the `Dockerfile` syntax in order to
  use the provided features of this image with a downstream image (see buildl
  time tooling below).
