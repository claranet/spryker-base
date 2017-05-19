#!/bin/sh

# services activated for this docker container instance will be added to this string
ENABLED_SERVICES=""

source $WORKDIR/docker/common.inc.sh

mkdir -pv /data/logs
cd $WORKDIR

case $1 in 
    run_yves)
      ENABLED_SERVICES="yves"
      enable_services
      start_services
      ;;

    run_zed)
      ENABLED_SERVICES="zed"
      enable_services
      start_services
      ;;

    run_yves_and_zed)
      ENABLED_SERVICES="yves zed"
      enable_services
      start_services
      ;;
    
    build)
      chapterHead "Building Base Layer"
      execute_scripts_within_directory "$WORKDIR/docker/build.d/base/"
      chapterHead "Building Dependency Layer"
      execute_scripts_within_directory "$WORKDIR/docker/build.d/deps/"
      chapterHead "Building Shop Layer"
      execute_scripts_within_directory "$WORKDIR/docker/build.d/shop/"
      successText "Setup initialization successfully FINISHED"
      ;;

    build_base)
      chapterHead "Building Base Layer"
      execute_scripts_within_directory "$WORKDIR/docker/build.d/base/"
      ;;

    build_deps)
      chapterHead "Building Dependency Layer"
      execute_scripts_within_directory "$WORKDIR/docker/build.d/deps/"
      ;;

    build_shop)
      chapterHead "Building Shop Layer"
      execute_scripts_within_directory "$WORKDIR/docker/build.d/shop/"
      successText "Image build successfully FINISHED"
      ;;
    
    init)
      execute_scripts_within_directory "$WORKDIR/docker/init.d/"
      successText "Setup initialization successfully FINISHED"
    ;;
    
    *)
      sh -c "$*"
      ;;
esac
