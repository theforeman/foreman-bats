#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

[ -n "$HAMMER_TEST_PATH" ] || HAMMER_TEST_PATH=/usr/share/hammer-tests
LOG_DIR=/root/hammer_test_logs

@test "checkout the tests" {
  [ -d "$HAMMER_TEST_PATH" ] && skip "$HAMMER_TEST_PATH already exists"
  git clone https://github.com/theforeman/hammer-tests.git "$HAMMER_TEST_PATH"
}

@test "enable multi-org support" {
  foreman-installer --no-colors -v \
    --foreman-organizations-enabled=true --foreman-locations-enabled=true
  touch ~foreman/tmp/restart.txt
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
