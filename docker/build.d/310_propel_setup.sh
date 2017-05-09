#!/bin/sh

sectionNote "Propel - Copy schema files"
# Copy schema files from packages to generated folder
$CONSOLE propel:schema:copy
