#!/bin/sh

build_navigation_cache() {
  sectionNote "Build Zeds Navigation Cache ..."
  $CONSOLE navigation:build-cache
}

add_stage_step two build_navigation_cache
