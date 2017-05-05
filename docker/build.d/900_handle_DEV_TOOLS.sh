#!/bin/sh

if [ "$DEV_TOOLS" = "on" ]; then
  # install ops tools while in debugging and testing stage
  apk add vim less tree
else
  # clean up if in production mode
  apk del .base_build_deps
fi
