#!/bin/bash
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD";
docker pull $image:$tagci
docker tag $image:$tagci $image:$tag;
echo "Pushing image to docker hub: $image:$tag"
docker push $image:$tag
if [ "$TRAVIS_TAG" == "$LATEST" ]; then
  docker tag $image:$tag $image:latest
  echo "Pushing image to docker hub: $image:latest"
  docker push $image:latest
fi
