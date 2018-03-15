#!/bin/bash

set -o pipefail

ROOT="$(cd `dirname $0` && cd .. && pwd )"
IMAGE=${IMAGE:-"claranet/spryker-base"}
VERSION=${VERSION:-$(cat $ROOT/VERSION)}

[[ -n "$BUILD_NUMBER" ]] && VERSION="$VERSION-$BUILD_NUMBER"

Dockerfile=$ROOT/Dockerfiles/Dockerfile

# Use given base image if present else use default image
# RegEx: get default value
BASEIMAGE=${1:-`grep 'FROM' $Dockerfile | sed 's/.*${BASE_IMAGE:-\([^}]*\)}.*/\1/'`}
#BASEIMAGE=${1:-`cat $Dockerfile | sed 's/.*${BASE_IMAGE:-\([^}]*\)}.*/\1/'`}


TAG=$VERSION-`echo $BASEIMAGE | tr : -`
File="$(dirname $Dockerfile)/Dockerfile-$TAG"

# RegEx: ${BASE_IMAGE:-DEFAULT} -> $BASEIMAGE
cat $Dockerfile | sed 's/${BASE_IMAGE:-[^}]*}/'$BASEIMAGE'/' > $File

echo "[INFO] Building: $(basename $Dockerfile) --> $IMAGE:$TAG ..."
docker build -f $File --tag $IMAGE:$TAG .
rm -v $File
