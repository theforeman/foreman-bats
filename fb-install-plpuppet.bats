#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

load os_helper

if tIsRHEL 6; then
  @test "setup puppetlabs puppet repo" {
    REL="6-7"
    tPackageExists puppetlabs-release-$REL || \
      rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-$REL.noarch.rpm
  }
fi

if tIsRedHatCompatible; then
  @test "install puppet package" {
    rpm -q puppet || yum -y install puppet
  }
fi
