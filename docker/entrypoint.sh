#!/bin/bash

# services activated for this docker container instance will be added to this string
ENABLED_SERVICES=""

source $WORKDIR/docker/common.inc.sh

mkdir -pv /data/logs
cd $WORKDIR

case $1 in
    run-yves)
      ENABLED_SERVICES="yves"
      run
      ;;

    run-zed)
      ENABLED_SERVICES="zed"
      run
      ;;

    run-yves-and-zed)
      ENABLED_SERVICES="yves zed"
      run
      ;;

    run-crond)
      ENABLED_SERVICES="crond"
      run
      ;;

    run-jenkins)
      ENABLED_SERVICES="jenkins"
      run
      ;;

    build)
      build_image
      ;;

    build-base)
      build_start
      build_base_layer
      ;;

    rebuild-base)
      build_start
      if is_true $REBUILD_BASE_LAYER;  then
          rebuild_base_layer
      fi
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

    codeception)
      shift
      run_codeception $*
      ;;

    --help|help)
      help
      ;;

    *)
      sh -c "$*"
      ;;
esac
