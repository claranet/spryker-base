#!/bin/sh

sectionNote "Create Search Index and Mapping Types; Generate Mapping Code."
# Generate elasticsarch code classes to access indexes
$CONSOLE setup:search:index-map
