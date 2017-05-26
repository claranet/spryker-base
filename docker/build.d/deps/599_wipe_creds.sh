#!/bin/sh

skip_cleanup && return 0

if [ -e "$HOME/.netrc" ]; then
  sectionText "Removing temporary credentials"
  rm -rvf $HOME/.netrc
fi
