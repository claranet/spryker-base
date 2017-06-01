#!/bin/sh

if is_true $KEEP_DEVEL_TOOLS; then
  sectionHead "Installing additional development tools"
  install_packages vim less tree
fi
