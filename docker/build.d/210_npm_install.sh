#!/bin/sh

install_main_npm_dependencies() {
  # install dependencies for building asset
  # --with-dev is required to install spryker/oryx (works behind npm run x)
  sectionNote "install required NPM dependencies"
  $NPM install --with-dev
}

install_composer_module_npm_dependencies() {
  wait_for_stage_step "install_composer_dependencies"
  
  # as we are collecting assets from various vendor/ composer modules
  # we also need to install possible assets-build dependencies from those
  # modules
  for i in `find vendor/ -name 'package.json' | egrep 'assets/(Zed|Yves)/package.json'`; do
    sectionNote "handle $i"
    cd `dirname $i`
    $NPM install
    cd $WORKDIR
  done
}

add_stage_step one install_main_npm_dependencies
add_stage_step one install_composer_module_npm_dependencies
