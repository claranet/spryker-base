#!/bin/sh

cd $WORKDIR

infoText "Propel - Copy schema files ..."
# Copy schema files from packages to generated folder
$CONSOLE propel:schema:copy
