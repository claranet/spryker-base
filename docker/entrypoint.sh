#!/bin/sh

# services activated for this docker container instance will be added to this string
ENABLED_SERVICES=""

source $WORKDIR/docker/common.inc.sh

mkdir -pv /data/logs
cd $WORKDIR

case $1 in 
    run-yves)
      ENABLED_SERVICES="yves"
      enable_services
      start_services
      ;;

    run-zed)
      ENABLED_SERVICES="zed"
      enable_services
      start_services
      ;;

    run-yves-and-zed)
      ENABLED_SERVICES="yves zed"
      enable_services
      start_services
      ;;
    
    build)
      chapterHead "Building Base Layer"
      exec_scripts "$WORKDIR/docker/build.d/base/"
      chapterHead "Building Dependency Layer"
      exec_scripts "$WORKDIR/docker/build.d/deps/"
      chapterHead "Building Shop Layer"
      exec_scripts "$WORKDIR/docker/build.d/shop/"
      successText "Image build successfully FINISHED"
      ;;

    build-base)
      chapterHead "Building Base Layer"
      exec_scripts "$WORKDIR/docker/build.d/base/"
      ;;

    build-deps)
      chapterHead "Building Dependency Layer"
      exec_scripts "$WORKDIR/docker/build.d/deps/"
      ;;

    build-shop)
      chapterHead "Building Shop Layer"
      exec_scripts "$WORKDIR/docker/build.d/shop/"
      successText "Image build successfully FINISHED"
      ;;
    
    init)
      exec_scripts "$WORKDIR/docker/init.d/"
      successText "Setup initialization successfully FINISHED"
    ;;
    
    *)
      sh -c "$*"
      ;;
esac
