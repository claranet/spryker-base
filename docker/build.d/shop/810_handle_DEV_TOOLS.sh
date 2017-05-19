#!/bin/sh

if [ "$DEV_TOOLS" = "on" ]; then
  sectionHead "Installing ops tools"
  install_packages vim less tree
fi
