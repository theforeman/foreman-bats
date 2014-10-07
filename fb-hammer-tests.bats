#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

[ -n "$HAMMER_TEST_BRANCH" ] || HAMMER_TEST_BRANCH=master
[ -n "$HAMMER_TEST_REPO" ] || HAMMER_TEST_REPO=https://github.com/theforeman/hammer-tests.git
[ -n "$HAMMER_TEST_PATH" ] || HAMMER_TEST_PATH=/usr/share/hammer-tests
LOG_DIR=/root/hammer_test_logs

@test "checkout the tests" {
  [ -d "$HAMMER_TEST_PATH" ] && skip "$HAMMER_TEST_PATH already exists"
  git clone -b "$HAMMER_TEST_BRANCH" "$HAMMER_TEST_REPO" "$HAMMER_TEST_PATH"
}

@test "install test dependencies" {
  tPackageExists rubygems || tPackageInstall rubygems
  gem install open4 colorize
}

@test "run the tests" {
  mkdir -p "$LOG_DIR"
  pushd "$HAMMER_TEST_PATH"
  HT_FOREMAN_LOG_FILE=/var/log/foreman/production.log \
  HT_HAMMER_LOG_FILE=/root/.hammer/log/hammer.log \
  HT_LOGS_LOCATION="$LOG_DIR" \
  ./run_tests ./tests/ > /dev/null
  popd
}
