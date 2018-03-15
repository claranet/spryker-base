#!/bin/sh

skip_cleanup && return 0

cleanup

sectionText "Compressing docker build log"
gzip $BUILD_LOG
