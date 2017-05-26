#!/bin/sh

sectionText "Propel - Collect schema definitions ..."
$CONSOLE propel:schema:copy

sectionText "Propel - Converting configuration ..."
$CONSOLE propel:config:convert

sectionText "Propel - Build models ..."
$CONSOLE propel:model:build

