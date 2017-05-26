#!/bin/sh

sectionText "Propel - Creating configuration ..."
$CONSOLE propel:config:convert

sectionText "Propel - Collect schema definitions ..."
$CONSOLE propel:schema:copy

sectionText "Propel - Build models ..."
$CONSOLE propel:model:build

