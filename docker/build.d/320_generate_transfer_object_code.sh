#!/bin/sh

# zed <-> yves transfer objects
# Generates transfer objects from transfer XML definition files
# time: any, static code generator
sectionNote "generate transfer object files"
$CONSOLE transfer:generate
