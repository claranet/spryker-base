#!/bin/sh

cd $WORKDIR

wait_for_service $ZED_DB_HOST $ZED_DB_PORT

infoText "Propel - Insert PG compatibility ..."
# Adjust Propel-XML schema files to work with PostgreSQL
$CONSOLE propel:pg-sql-compat

infoText "Propel - Converting configuration ..."
# Write Propel2 configuration
$CONSOLE propel:config:convert

infoText "Propel - Build models ..."
# Build Propel2 classes
$CONSOLE propel:model:build

infoText "Propel - Create database ..."
# Create database if it does not already exist
$CONSOLE propel:database:create

infoText "Propel - Create schema diff ..."
# Generate diff for Propel2
$CONSOLE propel:diff

infoText "Propel - Migrate Schema ..."
# Migrate database
$CONSOLE propel:migrate

infoText "Propel - Initialize database ..."
# Fill the database with required data
$CONSOLE setup:init-db
