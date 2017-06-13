#!/bin/sh

stage_two_build_assets() {
  sectionNote "Build assets for Yves/Zed"

  # TODO: add zed:prod and yves:prod possibility
  $NPM run zed
  $NPM run yves
}

add_stage_step two stage_two_build_assets
