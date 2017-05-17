#!/bin/sh

VENDOR=@vendor@
PROJECT=@project@

WORKDIR=`dirname $0`
PREVIOUS_DIR=`pwd`

cd $WORKDIR


check_system_requirements() {
  if ! which docker-compose; then
    echo "ERROR: The command 'docker-compose' is required. Please install it!"
    echo "Aborting execution"
  fi
  
  if ! which docker; then
    echo "ERROR: docker is required. Please install it!"
    echo "Aborting execution"
  fi
  
  cd $PREVIOUS_DIR
  exit 1
}



case $1 in
  build)
    docker build --no-cache -t $VENDOR/$PROJECT .
    ;;
  clear)
    docker rmi $VENDOR/$PROJECT
    ;;
  *)
    echo "
    A litle script to shortcut daily tasks with this repository
    -------
    
    Possible arguments:
        build     builds/rebuilds an docker image for this project
        clear     removes local cached version of the image name
    
    Please report issues and give us (Claranet) feedback on what went well and what
    can be improved.
    "
    ;;
esac

cd $PREVIOUS_DIR
