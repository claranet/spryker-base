
# Changelog

## master

* [feature] Add hooks and entrypoint for deployment scripts (`./docker/deploy.d`)
* [refactor] Move build stages to `common.inc.sh` script
* [change] Rename DEV_TOOLS to KEEP_DEVEL_TOOLS
* [feature] Add `enter` action to `run` wrapper as shortcut for dropping the
  user into the container.
* [feature] Add build.conf var for additional `BASE_DEPENDENCIES`
* [change] Minor change to `install_packages`
* [feature] Add `SKIP_CLEANUP` build time option for debugging purposes.
* [feature] Add `CRONJOB_HANDLER` build.conf var to support jenkins and crond
  switch
* [feature] Add simple cronjob handler crond

## 0.6.1

* [feature] Add `run` script as shortcut to common tasks
* [change] docker-compose setup in sekeleton folder 
* [breaking change] Use one image for both production and development, which
  means that `APPLICATION_ENV` only controls behaviour of app during runtime. 
* [feature] Add wait_for_http_services; refactor naming
* [refactor] entrypoint arguments from underscores to dashes
* [feature] Add possibility to temporarily inject credentials
* [change] Git is configured to fetch all repos via https instead of ssh. This
  behaviour - as all of the buidl steps - is overridable. 

## 0.5.0 

* [feature] split up the build process into 3 distinct stages/layers (#25ee646)

## 0.4.0 

* [feature] add build/versioning infrastructure
* [fix] copyright in license
* [change] rename skeleton folder which serves as template for a specific shop
  instance
