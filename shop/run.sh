#!/bin/sh

WORKDIR=`dirname $0`

cd $WORKDIR

source docker/build.conf

check_system_requirements() {
  if ! which docker-compose; then
    echo "ERROR: The command 'docker-compose' is required. Please install it!"
    echo "Aborting execution"
  fi
  
  if ! which docker; then
    echo "ERROR: docker is required. Please install it!"
    echo "Aborting execution"
  fi
  
  exit 1
}



case $1 in
  build)
    docker build --no-cache --force-rm -t $IMAGE .
    ;;
  clear)
    docker rmi $IMAGE
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
