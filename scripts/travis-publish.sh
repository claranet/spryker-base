#!/bin/bash
set -e -o pipefail
set -x
[ "$TRAVIS_PULL_REQUEST" != "false" ] && echo "Pull Requests are not allowed to publish image!" && exit 0

echo "Authenticating to docker hub ..."
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD";

echo "Pushing image to docker hub: $IMAGE:$VERSION_TAG"
docker push $IMAGE:$VERSION_TAG
if [ -n "$LATEST" -a "$TRAVIS_TAG" == "$LATEST" ]; then
  docker tag $IMAGE:$VERSION_TAG $IMAGE:latest
  echo "Pushing image to docker hub: $IMAGE:latest"
  docker push $IMAGE:latest
fi
