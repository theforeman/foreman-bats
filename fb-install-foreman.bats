#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

load os_helper
load foreman_helper

setup() {
  URL_PREFIX=""
  FOREMAN_VERSION=${FOREMAN_VERSION:-nightly}
  FOREMAN_REPO=${FOREMAN_REPO:-nightly}
  tForemanSetupUrl
  tForemanSetLang

  if tIsFedora 19; then
    # missing service file in puppet
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
}

if tIsRHEL 6; then
  @test "enable epel" {
    EPEL_REL="6-8"
    tPackageExists epel-release-$EPEL_REL || \
      rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-$EPEL_REL.noarch.rpm
  }
fi

@test "download and install release package" {
  yum -y install $FOREMAN_URL
}

@test "install installer" {
  yum -y install foreman-installer
}

@test "run the installer" {
  foreman-installer --foreman-repo $FOREMAN_REPO --foreman-proxy-repo $FOREMAN_REPO --no-colors -v
}

@test "run the installer once again" {
  foreman-installer --no-colors -v
}

@test "wait a 10 seconds" {
  sleep 10
}

@test "check web app is up" {
  "curl -sk https://localhost$URL_PREFIX/users/login | grep -q login-form"
}

@test "wake up puppet agent" {
  puppet agent -t -v
}

@test "install all compute resources" {
  yum -y install foreman-console foreman-libvirt foreman-vmware foreman-ovirt
}

@test "restart httpd server" {
  service httpd restart
}

@test "collect important logs" {
  tail -n100 /var/log/httpd/*_log /var/log/foreman{-proxy,}/*log /var/log/messages > /root/last_logs || true
}
