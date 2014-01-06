#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

load os_helper
load foreman_helper

setup() {
  URL_PREFIX=""
  FOREMAN_REPO=${FOREMAN_REPO:-nightly}
  tForemanSetupUrl
  tForemanSetLang

  if tIsFedora 19; then
    # missing service file in puppet
    tPackageExists "puppet" && \
      cp /usr/lib/systemd/system/puppetagent.service /etc/systemd/system/puppet.service

    # puppet selinux is a mess
    setenforce 0
  fi

  # disable firewall
  if tIsRedHatCompatible; then
    if tFileExists /usr/sbin/firewalld; then
      systemctl stop firewalld; systemctl disable firewalld
    elif tCommandExists systemctl; then
      systemctl stop iptables; systemctl disable iptables
    else
      service iptables stop; chkconfig iptables off
    fi
  fi

  tPackageExists curl || tPackageInstall curl
}

@test "stop puppet agent (if installed)" {
  tPackageExists "puppet" || skip "Puppet package not installed"
  if tIsRHEL 6; then
    service puppet stop; chkconfig puppet off
  elif tIsFedora; then
    service puppetagent stop; chkconfig puppetagent off
  elif tIsDebianCompatible; then
    service puppet stop
  fi
  true
}

@test "clean after puppet (if installed)" {
  [[ -d /var/lib/puppet/ssl ]] || skip "Puppet not installed, or SSL directory doesn't exist"
  rm -rf /var/lib/puppet/ssl
}

@test "make sure puppet not configured to other pm" {
  egrep -q "server\s*=" /etc/puppet/puppet.conf || skip "Puppet not installed, or 'server' not configured"
  sed -ir "s/^\s*server\s*=.*/server = $(hostname -f)/g" /etc/puppet/puppet.conf
}

@test "enable epel" {
  tIsRHEL || skip "EPEL not required on this operating system"
  tIsRHEL 6 || skip "EPEL not supported on this operating system"
  EPEL_REL="6-8"
  tPackageExists epel-release-$EPEL_REL || \
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-$EPEL_REL.noarch.rpm
}

@test "configure repository" {
  if tIsRedHatCompatible; then
    rpm -q foreman-release || yum -y install $FOREMAN_URL

    if [ -n "$FOREMAN_CUSTOM_URL" ]; then
      cat > /etc/yum.repos.d/foreman-custom.repo <<EOF
[foreman-custom]
name=foreman-custom
enabled=1
gpgcheck=0
baseurl=${FOREMAN_CUSTOM_URL}
EOF
      yum-config-manager --disable foreman >/dev/null
    fi
  elif tIsDebianCompatible; then
    tSetOSVersion
    echo "deb http://deb.theforeman.org/ ${OS_RELEASE} ${FOREMAN_REPO}" > /etc/apt/sources.list.d/foreman.list
    wget -q http://deb.theforeman.org/foreman.asc -O- | apt-key add -
    apt-get update
  else
    skip "Unknown operating system"
  fi
}

@test "install installer" {
  if [[ -n $FOREMAN_INSTALLER_PATH ]] ; then
    # Install build dependencies
    if tIsRedHatCompatible ; then
      tPackageExists ruby-devel || tPackageInstall ruby-devel
      tPackageExists gcc || tPackageInstall gcc
      tCommandExists bundle || tPackageInstall bundler || ((tCommandExists gem || tPackageInstall rubygems) && gem install bundler)
      tCommandExists rake || tPackageInstall rubygem-rake
      tPackageExists asciidoc || tPackageInstall asciidoc
    elif tIsDebianCompatible ; then
      tPackageExists ruby-dev || tPackageInstall ruby-dev
      tPackageExists build-essential || tPackageInstall build-essential
      tPackageExists bundler || tPackageInstall bundler
      tPackageExists rake || tPackageInstall rake
      tPackageExists asciidoc || tPackageInstall asciidoc
    else
      false  # Unsupported
    fi

    pushd $FOREMAN_INSTALLER_PATH

    if [[ -f Gemfile ]] ; then
      bundle install
    fi

    rake build PREFIX=/usr SYSCONFDIR=/etc VERSION=$(git describe)
    rake install PREFIX=/usr SYSCONFDIR=/etc VERSION=$(git describe)

    popd
  else
    tPackageExists foreman-installer || tPackageInstall foreman-installer
  fi
}

@test "run the installer" {
  foreman-installer --no-colors -v
}

@test "run the installer once again" {
  foreman-installer --no-colors -v
}

@test "wait 10 seconds" {
  sleep 10
}

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "wake up puppet agent" {
  puppet agent -t -v
}

@test "install all compute resources" {
  packages="foreman-console foreman-libvirt foreman-vmware foreman-ovirt"
  yum info foreman-gce >/dev/null 2>&1 && packages="$packages foreman-gce"
  tPackageInstall $packages
}

@test "restart foreman" {
  touch ~foreman/tmp/restart.txt
}

@test "collect important logs" {
  tail -n100 /var/log/{apache2,httpd}/*_log /var/log/foreman{-proxy,}/*log /var/log/messages > /root/last_logs || true
}
