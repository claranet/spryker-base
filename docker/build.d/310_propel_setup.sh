#!/bin/sh

copy_propel_schema_files() {
  sectionNote "Propel - Copy schema files"
  # Copy schema files from packages to generated folder
  $CONSOLE propel:schema:copy
}

add_stage_step two copy_propel_schema_files
