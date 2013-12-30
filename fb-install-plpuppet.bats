#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

load os_helper

@test "setup puppetlabs puppet repo" {
  tSetOSVersion
  if tIsRHEL; then
    tPackageExists puppetlabs-release || \
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-${OS_VERSION}.noarch.rpm
  elif tIsFedora; then
    tPackageExists puppetlabs-release || \
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-fedora-${OS_VERSION}.noarch.rpm
  elif tIsDebianCompatible; then
    if ! tPackageExists puppetlabs-release; then
      wget http://apt.puppetlabs.com/puppetlabs-release-${OS_RELEASE}.deb
      dpkg -i puppetlabs-release-${OS_RELEASE}.deb
    fi
    apt-get update
  fi
}

@test "install puppet package" {
  if tPackageExists puppet; then
    tPackageUpgrade puppet\* facter\*
  else
    tPackageInstall puppet
  fi
}
