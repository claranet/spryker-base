
# Todo items

## Open discussion 

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
* Consider using the `ONBUILD` directive of the `Dockerfile` syntax in order to
  use the provided features of this image with a downstream image (see buildl
  time tooling below).


## Open action items

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

## Resolved
