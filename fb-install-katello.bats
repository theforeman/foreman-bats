#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "install git and ruby" {
  tPackageInstall git ruby
}

@test "clone katello-deploy repo" {
  git clone https://github.com/Katello/katello-deploy.git
}

@test "execute setup.rb" {
  pushd katello-deploy
  if tIsRHEL 6; then
    ./setup.rb rhel6
    RET=$?
  elif tIsFedora 19; then
    ./setup.rb fedora19
    RET=$?
  else
    skip "Currently only supported on some Red Hat compatible systems"
  fi
  popd
  [ $? -eq 0 ]
}
