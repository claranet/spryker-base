#!/bin/sh

if [ "$DEV_TOOLS" = "on" ]; then
  sectionNote "install ops tools"
  install_packages vim less tree
else
  sectionNote "clean up image"
  apk del .base_build_deps
fi