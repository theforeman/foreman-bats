#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

setup() {
  tSetOSVersion

  tPackageExists screen || tPackageInstall screen
  tPackageExists wget || tPackageInstall wget
}

@test "download the script" {
  wget --no-check-certificate -O /root/script.sh "$SCRIPT"
}

@test "make it executable" {
  chmod +x /root/script.sh
}

@test "run it" {
  screen -S bats -d -m /bin/bash -c "/root/script.sh 2>&1 | tee /root/script-output.log"
}
