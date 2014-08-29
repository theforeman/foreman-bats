#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

load os_helper

@test "setup puppetlabs puppet repo" {
  tSetOSVersion
  if tIsFedora; then
    tPackageExists puppetlabs-release || \
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-fedora-${OS_VERSION}.noarch.rpm
  elif tIsRHEL; then
    tPackageExists puppetlabs-release || \
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-${OS_VERSION}.noarch.rpm
  elif tIsDebianCompatible; then
    if ! tPackageExists puppetlabs-release; then
      wget http://apt.puppetlabs.com/puppetlabs-release-${OS_RELEASE}.deb
      dpkg -i puppetlabs-release-${OS_RELEASE}.deb
    fi
    apt-get update
  fi
}

@test "setup puppetlabs nightly repos" {
  [ x${PUPPET_REPO} = xnightly ] || skip "PUPPET_REPO is not set to nightly"
  tSetOSVersion
  tPackageExists curl || tPackageInstall curl
  if tIsFedora; then
    curl -o /etc/yum.repos.d/puppet-nightlies.repo \
      http://nightlies.puppetlabs.com/puppet-latest/repo_configs/rpm/pl-puppet-latest-fedora-f${OS_VERSION}-$(uname -i).repo
    curl -o /etc/yum.repos.d/facter-nightlies.repo \
      http://nightlies.puppetlabs.com/facter-latest/repo_configs/rpm/pl-facter-latest-fedora-f${OS_VERSION}-$(uname -i).repo
  elif tIsRHEL; then
    curl -o /etc/yum.repos.d/puppet-nightlies.repo \
      http://nightlies.puppetlabs.com/puppet-latest/repo_configs/rpm/pl-puppet-latest-el-${OS_VERSION}-$(uname -i).repo
    curl -o /etc/yum.repos.d/facter-nightlies.repo \
      http://nightlies.puppetlabs.com/facter-latest/repo_configs/rpm/pl-facter-latest-el-${OS_VERSION}-$(uname -i).repo
  elif tIsDebianCompatible; then
    curl -o /etc/apt/sources.list.d/puppet-nightlies.list \
      http://nightlies.puppetlabs.com/puppet-latest/repo_configs/deb/pl-puppet-latest-${OS_RELEASE}.list
    curl -o /etc/apt/sources.list.d/facter-nightlies.list \
      http://nightlies.puppetlabs.com/facter-latest/repo_configs/deb/pl-facter-latest-${OS_RELEASE}.list
    apt-get update
  fi
}

@test "upgrade puppet package" {
  if tPackageExists puppet; then
    tPackageUpgrade puppet\* facter\*
  else
    skip "Puppet not currently installed"
  fi
}
