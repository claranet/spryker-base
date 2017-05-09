#!/bin/sh

cd $WORKDIR

wait_for_service $ZED_DB_HOST $ZED_DB_PORT

sectionNote "Propel - Insert PG compatibility ..."
# Adjust Propel-XML schema files to work with PostgreSQL
$CONSOLE propel:pg-sql-compat

sectionNote "Propel - Converting configuration ..."
# Write Propel2 configuration
$CONSOLE propel:config:convert

sectionNote "Propel - Build models ..."
# Build Propel2 classes
$CONSOLE propel:model:build

sectionNote "Propel - Create database ..."
# Create database if it does not already exist
$CONSOLE propel:database:create

sectionNote "Propel - Create schema diff ..."
# Generate diff for Propel2
$CONSOLE propel:diff

sectionNote "Propel - Migrate Schema ..."
# Migrate database
$CONSOLE propel:migrate

sectionNote "Propel - Initialize database ..."
# Fill the database with required data
$CONSOLE setup:init-db
