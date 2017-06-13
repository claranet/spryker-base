#!/bin/sh


# configures git to use https instead of git+ssh for github.com sources
stage_one_configure_git() {
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  git config --global url.https://.insteadOf git://
}

add_stage_step one stage_one_configure_git
