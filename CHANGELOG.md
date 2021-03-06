
# Changelog

## master

## 0.9.6

* [BC change] Due to problems and limitations of musl lib c we've decided to
  migrate off alpine based images over to debian ones. We will discontinue
  alpine support from now on and will only maintain the newly introduced debian
  flavour. As long as you shipped images without any further customizations
  this should have no impact to you. Otherwise you need to review your custom
  tooling.

## 0.9.5

* [fix] fix the missing files in child images by changing the onbuild copy to a wildcard
* [feature] optimize image build cache to leverage the base build more often

## 0.9.4

* [feature] Add development guide helping image maintainer and developer
* [fix] Since spryker/setup got hardcoded directory pathes we need to
  workaround some of these till https://github.com/spryker/support/issues/143
  has been fixed

## 0.9.3

* [fix] Change shebang of central shell scripts to bash in order to use
  `${BASH_SOURCE[0]}`
* [change] Remove shop skeleton and refe to the demoshop instead

## 0.9.2

* [fix] Fix bump script

## 0.9.1

* [fix] The rebase condition which decides whether the downstream shop image is
  gonna be build was broken.

## 0.9.0

* [change] Build PHP and modules in the base image instead of each downstream
  shop image build. Its nevertheless still be possible to rebuild this base
  layer via onbuild trigger in the shop image. See docs for further infos on
  that. 
* [feature] Starting with this version we ship multiple flavors of this base
  image. This spans a matrix comprising of the dimensions PHP version and linux
  distribution. For the time being we provide PHP 7.0 and 7.1 based images on
  alpine. In the near future we will reach out to support ubuntu based images as
  well.

## 0.8.4

* [feature] Add synchronization between crond and init container via redis
* [change] Upgrade to 7.0.21 of upstream php image
* [feature] Add infrastructure for executing the codeception tests via entrypoint
* [feature] Add help output to entrypoint

## 0.8.3

* [fix] CI pipeline

## 0.8.2

* [feature] Add mechanism to prevent parallel execution of cron jobs
* [fix] Add config/Zed/propel\*.yml to dockerignore
* [fix] Cron handling got typos that crept in

## 0.8.0

* [fix] Detection of yves/zed domain 
* [fix] Create data dirs during runtime (possiblity to place those dirs onto
        external storage)
* [feature] Make php installation more robust: add retry mechanism
* [change] Made build steps less verbose
* [feature] Add error handler to tail the build log in case of errors
* [feature] Apply conf.d strategy to php, fpm and nginx
* [feature] Make configurations (php, fpm, nginx) overridable via to be mounted
            files which getting symlinked into the appropriate config directories
* [change] Move php composer installation into deps layer
* [change] Make perl and bash fixed dependencies of the base image
* [feature] Provide method for reading boolean values from env

## 0.7.0

* [feature] Add time measurement to all stages
* [feature] Add hooks and entrypoint for deployment scripts (`./docker/deploy.d`)
* [refactor] Move build stages to `common.inc.sh` script
* [refactor] Rename `DEV_TOOLS` to `KEEP_DEVEL_TOOLS`
* [feature] Add `enter` action to `run` wrapper as shortcut for dropping the
  user into the container.
* [feature] Add `build.conf` var for additional `BASE_DEPENDENCIES`
* [change] Minor change to `install_packages`
* [feature] Add `SKIP_CLEANUP` build time option for debugging purposes.
* [feature] Add `CRONJOB_HANDLER` build.conf var to support jenkins and crond
  switch
* [feature] Add simple cronjob handler crond
* [fix] create missing logs dir for ZED

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
