#!/bin/sh

cd $WORKDIR

# zed <-> yves transfer objects
# Generates transfer objects from transfer XML definition files
# time: any, static code generator
$CONSOLE transfer:generate
