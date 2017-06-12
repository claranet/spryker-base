#!/bin/bash

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

    run-crond)
      configure_crond
      crond -f -L /dev/stdout
      ;;

    build)
        build_image
      ;;

    build-base)
        build_start
        build_base_layer
      ;;

    build-deps)
        build_deps_layer
      ;;

    build-shop)
        build_shop_layer
      ;;

    build-end)
        build_end
      ;;

    init)
      init
    ;;

    deploy)
      deploy
    ;;

    *)
      sh -c "$*"
      ;;
esac
