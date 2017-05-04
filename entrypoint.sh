#!/bin/sh

CONSOLE="execute_console_command"

# services activated for this docker container instance will be added to this string
ENABLED_SERVICES=""

source $WORKDIR/docker/build_library.sh

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
    
    install_container_services)
      execute_scripts_within_directory "$WORKDIR/docker/install_container_services.d/"
      successText "installing container services FINISHED"
      ;;
    
    build_image)
      execute_scripts_within_directory "$WORKDIR/docker/build_image.d/"
      successText "building image tasks FINISHED"
      ;;
    
    init_setup)
      execute_scripts_within_directory "$WORKDIR/docker/init_setup.d/"
      successText "Setup initialization tasks FINISHED"
    ;;
    
    *)
      sh -c "$*"
      ;;
esac
