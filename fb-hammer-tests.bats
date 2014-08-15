#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

TEST_DIR=/usr/share/hammer-tests
LOG_DIR=/root/hammer_test_logs

@test "checkout the tests" {
  if [ ! -d "$TEST_DIR" ]; then
    git clone https://github.com/theforeman/hammer-tests.git "$TEST_DIR"
  fi
}

@test "install test dependencies" {
  tPackageExists rubygems || tPackageInstall rubygems
  gem install open4 colorize
}

@test "run the tests" {
  mkdir -p "$LOG_DIR"
  pushd "$TEST_DIR"
  HT_FOREMAN_LOG_FILE=/var/log/foreman/production.log \
  HT_HAMMER_LOG_FILE=/root/.hammer/log/hammer.log \
  HT_LOGS_LOCATION="$LOG_DIR" \
  ./run_tests ./tests/ > /dev/null
  popd
}
