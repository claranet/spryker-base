#!/bin/sh

# install ops tools while in debugging and testing stage
[ "$DEV_TOOLS" = "off" ] || apk add vim less tree

# clean up if in production mode
[ "$DEV_TOOLS" = "on" ] || apk del .base_build_deps
