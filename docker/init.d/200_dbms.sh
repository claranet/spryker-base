#!/bin/sh

cd $WORKDIR

wait_for_tcp_service $ZED_DB_HOST $ZED_DB_PORT

sectionText "Propel - Creating configuration ..."
$CONSOLE propel:config:convert

sectionText "Propel - Insert PG compatibility ..."
$CONSOLE propel:pg-sql-compat

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
