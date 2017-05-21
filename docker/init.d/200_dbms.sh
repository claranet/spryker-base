#!/bin/sh

cd $WORKDIR

wait_for_tcp_service $ZED_DB_HOST $ZED_DB_PORT

sectionText "Propel - Insert PG compatibility ..."
# Adjust Propel-XML schema files to work with PostgreSQL
$CONSOLE propel:pg-sql-compat

sectionText "Propel - Converting configuration ..."
# Write Propel2 configuration
$CONSOLE propel:config:convert

sectionText "Propel - Build models ..."
# Build Propel2 classes
$CONSOLE propel:model:build

sectionText "Propel - Create database ..."
# Create database if it does not already exist
$CONSOLE propel:database:create

sectionText "Propel - Create schema diff ..."
# Generate diff for Propel2
$CONSOLE propel:diff

sectionText "Propel - Migrate Schema ..."
# Migrate database
$CONSOLE propel:migrate

sectionText "Propel - Initialize database ..."
# Fill the database with required data
$CONSOLE setup:init-db
