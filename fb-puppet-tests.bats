#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tForemanSetLang
  FOREMAN_VERSION=$(tForemanVersion)
  tSetOSVersion
}

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "check smart proxy is registered" {
  count=$(hammer $(tHammerCredentials) --csv proxy list | wc -l)
  [ $count -gt 1 ]
}

@test "assert puppet version" {
  if [ x$PUPPET_REPO = xstable ]; then
    tPackageExists puppet
    # check 'puppet' package is built by PL
    if tIsDebianCompatible; then
      dpkg-query --show -f '${Maintainer}' puppet | grep 'Puppet Labs'
    elif tIsRedHatCompatible; then
      rpm -q --qf '%{VENDOR}' puppet | grep 'Puppet Labs'
    fi
  elif [ x$PUPPET_REPO = xpc1 -o x$PUPPET_REPO = xnightly ]; then
    tPackageExists puppet-agent
    # check 'puppet-agent' package is built by PL
    if tIsDebianCompatible; then
      dpkg-query --show -f '${Maintainer}' puppet-agent | grep 'Puppet Labs'
    elif tIsRedHatCompatible; then
      rpm -q --qf '%{VENDOR}' puppet-agent | grep 'Puppet Labs'
    fi
  else  # OS package
    tPackageExists puppet
    if tIsDebianCompatible; then
      dpkg-query --show -f '${Maintainer}' puppet | grep -v 'Puppet Labs'
    elif tIsRedHatCompatible; then
      rpm -q --qf '%{VENDOR}' puppet | grep -v 'Puppet Labs'
    fi
  fi
}

@test "wake up puppet agent" {
  puppet agent -t -v
}

@test "check host is registered" {
  hammer $(tHammerCredentials) host info --name $(hostname -f) | egrep "Last report:.*[[:alnum:]]+"
}

# ENC / Puppet class apply tests
@test "install puppet module" {
  modpath=/etc/puppetlabs/code/environments/production/modules
  if [ ! -d $modpath -a -e /etc/puppet/environments/production/modules ]; then
    modpath=/etc/puppet/environments/production/modules
  fi

  if [ ! -d $modpath/ntp ]; then
    if [ "x${OS_RELEASE}" != "xprecise" ]; then
      puppet module install -i $modpath -v 3.0.3 puppetlabs/ntp
    else
      # no PMT support in 2.7.11
      curl https://forgeapi.puppetlabs.com/v3/files/puppetlabs-ntp-3.0.3.tar.gz | \
        (cd $modpath && tar zxf - && mv puppetlabs-ntp* ntp)
      curl https://forgeapi.puppetlabs.com/v3/files/puppetlabs-stdlib-4.3.2.tar.gz | \
        (cd $modpath && tar zxf - && mv puppetlabs-stdlib* stdlib)
    fi
  fi
  [ -e $modpath/ntp/manifests/init.pp ]
}

@test "import ntp puppet class" {
  id=$(hammer $(tHammerCredentials) --csv proxy list | tail -n1 | cut -d, -f1)
  hammer $(tHammerCredentials) proxy import-classes --id $id
  count=$(hammer $(tHammerCredentials) --csv puppet-class list --search 'name = ntp' | wc -l)
  [ $count -gt 1 ]
}

@test "assign puppet class to host" {
  id=$(hammer $(tHammerCredentials) --csv puppet-class list --search 'name = ntp' | tail -n1 | cut -d, -f1)
  pc_ids=$(hammer $(tHammerCredentials) host update --help | awk '/class-ids/ {print $1}')
  hammer $(tHammerCredentials) host update $pc_ids $id --name $(hostname -f)
}

@test "apply class with puppet agent" {
  puppet agent -v -o --no-daemonize
  grep -i puppet /etc/ntp.conf
}

# Cleanup
@test "collect important logs" {
  tail -n100 /var/log/{apache2,httpd}/*_log /var/log/foreman{-proxy,}/*log /var/log/messages > /root/last_logs || true
  foreman-debug -q -d /root/foreman-debug || true
  if tIsRedHatCompatible; then
    tPackageExists sos || tPackageInstall sos
    sosreport --batch --tmp-dir=/root || true
  fi
}
