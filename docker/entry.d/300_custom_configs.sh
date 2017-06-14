#!/bin/sh

if [ -d "$CONFIG_DIR" ]; then
  cd $CONFIG_DIR
  find . \( ! -regex '.*/\..*' \) -a \( -name \*.conf -o -name \*.ini \) | while read src; do
    src_dir=$(dirname $src)
    sectionText "Symlinking custom configs: $CONFIG_DIR/$src --> /etc/$src"
    mkdir -p /etc/$src_dir
    ln -fs $CONFIG_DIR/$src /etc/$src
  done
  cd -
fi
