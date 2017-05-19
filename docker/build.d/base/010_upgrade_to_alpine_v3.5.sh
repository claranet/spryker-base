#!/bin/sh

# upgrade to alpine 3.5 as we need some nginx packages which are only available in alpine >3.5

sectionText "Update repositories to alpine 3.5"
sed -i -e 's/3\.4/3.5/g' /etc/apk/repositories

apk update

# `apk upgrade --clean-protected` for not creating *.apk-new (config)files
sectionText "Do the upgrade"
apk upgrade --clean-protected
