#!/bin/sh

# FIXME: add zed:prod and yves:prod possibility

sectionText "Building assets for Zed"
$NPM run zed

sectionText "Building assets for Yves"
$NPM run yves
