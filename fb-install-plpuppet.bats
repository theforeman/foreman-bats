#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

load os_helper

@test "setup Puppet Labs puppet repo" {
  [ x${PUPPET_REPO} = xstable -o -z "${PUPPET_REPO}" ] || skip "PUPPET_REPO is not set to stable"
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

@test "setup Puppet Labs PC1 repo" {
  [ x${PUPPET_REPO} = xpc1 ] || skip "PUPPET_REPO is not set to pc1"
  tSetOSVersion
  if tIsFedora; then
    tPackageExists puppetlabs-release-pc1 || \
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-pc1-fedora-${OS_VERSION}.noarch.rpm
  elif tIsRHEL; then
    tPackageExists puppetlabs-release-pc1 || \
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-pc1-el-${OS_VERSION}.noarch.rpm
  elif tIsDebianCompatible; then
    if ! tPackageExists puppetlabs-release-pc1; then
      wget http://apt.puppetlabs.com/puppetlabs-release-pc1-${OS_RELEASE}.deb
      dpkg -i puppetlabs-release-pc1-${OS_RELEASE}.deb
    fi
    apt-get update
  fi
}

@test "setup Puppet Labs nightly repos" {
  [ x${PUPPET_REPO} = xnightly ] || skip "PUPPET_REPO is not set to nightly"
  tSetOSVersion
  tPackageExists curl || tPackageInstall curl
  if tIsFedora; then
    curl -o /etc/yum.repos.d/puppet-agent-nightlies.repo \
      http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/rpm/pl-puppet-agent-latest-fedora-f${OS_VERSION}-$(uname -i).repo
    curl -o /etc/yum.repos.d/puppetserver-nightlies.repo \
      http://nightlies.puppetlabs.com/puppetserver-latest/repo_configs/rpm/pl-puppetserver-latest-fedora-f${OS_VERSION}-$(uname -i).repo
  elif tIsRHEL; then
    curl -o /etc/yum.repos.d/puppet-agent-nightlies.repo \
      http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/rpm/pl-puppet-agent-latest-el-${OS_VERSION}-$(uname -i).repo
    curl -o /etc/yum.repos.d/puppetserver-nightlies.repo \
      http://nightlies.puppetlabs.com/puppetserver-latest/repo_configs/rpm/pl-puppetserver-latest-el-${OS_VERSION}-$(uname -i).repo
  elif tIsDebianCompatible; then
    curl -o /etc/apt/sources.list.d/puppet-agent-nightlies.list \
      http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/deb/pl-puppet-agent-latest-${OS_RELEASE}.list
    curl -o /etc/apt/sources.list.d/puppetserver-nightlies.list \
      http://nightlies.puppetlabs.com/puppetserver-latest/repo_configs/deb/pl-puppetserver-latest-${OS_RELEASE}.list
    apt-key adv --keyserver pgp.mit.edu --recv-keys 8735F5AF62A99A628EC13377B8F999C007BB6C57
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
