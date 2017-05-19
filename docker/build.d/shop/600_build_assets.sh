#!/bin/sh

sectionText "Building assets for Yves/Zed"

# TODO: add zed:prod and yves:prod possibility
$NPM run zed
$NPM run yves
