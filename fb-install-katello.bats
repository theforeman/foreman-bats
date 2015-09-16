#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  KATELLO_VERSION=${KATELLO_VERSION:-nightly}
  tSetOSVersion
}

@test "disable firewall" {
  if tFileExists /usr/sbin/firewalld; then
    systemctl stop firewalld; systemctl disable firewalld
  elif tCommandExists systemctl; then
    systemctl stop iptables; systemctl disable iptables
  else
    service iptables stop; chkconfig iptables off
  fi
}

@test "install git and utilities" {
  yum install -y git ruby curl screen
}

@test "clone katello-deploy repo" {
  git clone https://github.com/Katello/katello-deploy.git
}

@test "run katello-deploy" {
  cd katello-deploy/
  ./setup.rb --version $KATELLO_VERSION --installer-options "--foreman-admin-password ${KATELLO_ADMIN_PASSWORD:-admin}"
}

@test "wait 10 seconds" {
  sleep 10
}

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "set idle timeout" {
  echo 'Setting["idle_timeout"] = 9999' | foreman-rake console
}

@test "set entries per page" {
  echo 'Setting["entries_per_page"] = 100' | foreman-rake console
}
