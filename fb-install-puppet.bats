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

@test "setup Puppet 5 repos" {
  [ x${PUPPET_REPO} = xpuppet5 ] || skip "PUPPET_REPO is not set to puppet5"
  tSetOSVersion
  if tIsFedora; then
    tPackageExists puppet5-release || \
      rpm -ivh http://yum.puppetlabs.com/puppet5/puppet5-release-fedora-${OS_VERSION}.noarch.rpm
  elif tIsRHEL; then
    tPackageExists puppet5-release || \
      rpm -ivh http://yum.puppetlabs.com/puppet5/puppet5-release-el-${OS_VERSION}.noarch.rpm
  elif tIsDebianCompatible; then
    if ! tPackageExists puppet5-release; then
      wget http://apt.puppetlabs.com/puppet5-release-${OS_RELEASE}.deb
      dpkg -i puppet5-release-${OS_RELEASE}.deb
    fi
    apt-get update

    # OpenJDK 8 from backports is required to use Puppet Server 5 (SERVER-1785)
    if [ x$OS_RELEASE = xjessie ]; then
      tEnableDebianBackports
      tPackageExists openjdk-8-jre-headless || tPackageInstall -t ${OS_RELEASE}-backports openjdk-8-jre-headless
    fi
  fi
}

@test "setup Puppet Labs nightly repos" {
  [ x${PUPPET_REPO} = xnightly ] || skip "PUPPET_REPO is not set to nightly"
  tSetOSVersion
  if tIsFedora; then
    tPackageExists puppet5-nightly-release || \
      rpm -ivh http://yum.puppetlabs.com/puppet5-nightly/puppet5-nightly-release-fedora-${OS_VERSION}.noarch.rpm
  elif tIsRHEL; then
    tPackageExists puppet5-nightly-release || \
      rpm -ivh http://yum.puppetlabs.com/puppet5-nightly/puppet5-nightly-release-el-${OS_VERSION}.noarch.rpm
  elif tIsDebianCompatible; then
    if ! tPackageExists puppet5-nightly-release; then
      wget http://apt.puppetlabs.com/puppet5-nightly-release-${OS_RELEASE}.deb
      dpkg -i puppet5-nightly-release-${OS_RELEASE}.deb
    fi
    apt-get update

    # OpenJDK 8 from backports is required to use latest Puppet Server (SERVER-1785)
    if [ x$OS_RELEASE = xjessie ]; then
      tEnableDebianBackports
      tPackageExists openjdk-8-jre-headless || tPackageInstall -t ${OS_RELEASE}-backports openjdk-8-jre-headless
    fi
  fi
}

@test "install Puppet from backports" {
  [ x${PUPPET_REPO} = xbackports ] || skip "PUPPET_REPO is not set to backports"
  tIsDebian || skip "Not applicable, non-Debian OS"
  tEnableDebianBackports
  tPackageInstall -t ${OS_RELEASE}-backports puppet
}

@test "upgrade puppet package" {
  if tPackageExists puppet; then
    tPackageUpgrade puppet\* facter\*
  else
    skip "Puppet not currently installed"
  fi
}
