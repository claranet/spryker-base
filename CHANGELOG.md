
# Changelog

## devel

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
