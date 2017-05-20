#!/bin/sh

if [ -e "$HOME/.netrc" ]; then
  sectionText "Removing temporary credentials"
  rm -rvf $HOME/.netrc
fi
