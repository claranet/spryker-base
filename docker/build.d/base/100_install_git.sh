#!/bin/sh

install_packages git

# configures git to use https instead of git+ssh for github.com sources
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global url.https://.insteadOf git://
