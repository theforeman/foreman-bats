#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  URL_PREFIX=""
  tSetOSVersion

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
  if tIsRedHatCompatible; then
    tPackageExists yum-utils || tPackageInstall yum-utils
  fi
}

@test "test CPU virtualization support" {
  grep -E '(vmx|svm)' /proc/cpuinfo
}

@test "wait max 30 secs until network is up" {
  ping -c1 -w30 8.8.8.8
}

@test "subscribe and attach channels" {
  tRHSubscribeAttach
}

@test "enable epel" {
  tRHEnableEPEL
}

@test "configure repository" {
  OVIRT_RELEASE=${OVIRT_RELEASE:-34}
  if tIsRedHatCompatible; then
    yum -y localinstall http://resources.ovirt.org/pub/yum-repo/ovirt-release${OVIRT_RELEASE}.rpm
  else
    skip "Unknown operating system for this test, setup repo manually"
  fi
}

# There are known bugs in oVirt 3.5 All-In-One setup with SELinux
@test "set permissive SELinux" {
  if tIsRedHatCompatible; then
    setenforce 0
  fi
}

@test "install all-in-one installer" {
  tPackageInstall ovirt-engine ovirt-engine-setup-plugin-allinone
}

@test "workarounds for known issues" {
  if tIsRedHatCompatible; then
    # system must be always up-to-date
    yum -y upgrade
    # http://bugzilla.redhat.com/1171603
    systemctl restart rpcbind.service
    # http://bugzilla.redhat.com/1250376
    tPackageInstall virt-v2v
  fi
  true
}

@test "run the installer (credentials: admin@internal/ovirt)" {
  cat >/tmp/ovirt-answer-file.conf <<EOAF
# action=setup
[environment:default]
OSETUP_RPMDISTRO/enableUpgrade=none:None
OSETUP_RPMDISTRO/requireRollback=none:None
OVESETUP_AIO/configure=bool:True
OVESETUP_AIO/storageDomainDir=str:/var/lib/images
OVESETUP_AIO/storageDomainName=str:local_domain
OVESETUP_APACHE/configureRootRedirection=bool:True
OVESETUP_APACHE/configureSsl=bool:True
OVESETUP_CONFIG/adminPassword=str:ovirt
OVESETUP_CONFIG/applicationMode=str:both
OVESETUP_CONFIG/firewallManager=str:iptables
OVESETUP_CONFIG/fqdn=str:$(hostname -f)
OVESETUP_CONFIG/isoDomainACL=str:0.0.0.0/0.0.0.0(rw)
OVESETUP_CONFIG/isoDomainMountPoint=str:/var/lib/exports/iso
OVESETUP_CONFIG/isoDomainName=str:ISO_DOMAIN
OVESETUP_CONFIG/remoteEngineHostRootPassword=none:None
OVESETUP_CONFIG/remoteEngineHostSshPort=none:None
OVESETUP_CONFIG/remoteEngineSetupStyle=none:None
OVESETUP_CONFIG/storageIsLocal=bool:False
OVESETUP_CONFIG/storageType=str:nfs
OVESETUP_CONFIG/updateFirewall=bool:True
OVESETUP_CONFIG/websocketProxyConfig=bool:True
OVESETUP_CORE/engineStop=none:None
OVESETUP_DB/database=str:engine
OVESETUP_DB/fixDbViolations=none:None
OVESETUP_DB/host=str:localhost
OVESETUP_DB/password=str:R3f527AblD9vA0Tk5xiGQb
OVESETUP_DB/port=int:5432
OVESETUP_DB/secured=bool:False
OVESETUP_DB/securedHostValidation=bool:False
OVESETUP_DB/user=str:engine
OVESETUP_DIALOG/confirmSettings=bool:True
OVESETUP_ENGINE_CORE/enable=bool:True
OVESETUP_PKI/organization=str:TestOrganization
OVESETUP_PROVISIONING/postgresProvisioningEnabled=bool:True
OVESETUP_SYSTEM/memCheckEnabled=bool:True
OVESETUP_SYSTEM/nfsConfigEnabled=bool:True
OVESETUP_VMCONSOLE_PROXY_CONFIG/vmconsoleProxyConfig=bool:True
EOAF
  engine-setup --config-append=/tmp/ovirt-answer-file.conf
}

@test "setup SCL and Foreman repos" {
  tIsRedHatCompatible || skip "Not needed"
  cat >/etc/yum.repos.d/scl-ruby193.repo <<SCLREPO
[scl-ruby193]
name=SCL ruby193
baseurl=https://www.softwarecollections.org/repos/rhscl/ruby193/epel-$OS_VERSION-\$basearch/
enabled=1
gpgcheck=0
SCLREPO

  cat >/etc/yum.repos.d/foreman.repo<<FOREPO
[foreman-nightly]
name=Foreman Nightly
baseurl=http://yum.theforeman.org/nightly/el$OS_VERSION/\$basearch/
enabled=1
gpgcheck=0
FOREPO
}

@test "install ruby193 and dependencies" {
  if tIsRHEL; then
    tPackageInstall ruby193-rubygem-rails ruby193-rubygem-rspec* ruby193-rubygem-rake ruby193-rubygem-nokogiri ruby193-rubygem-rest-client
  elif tIsFedoraCompatible; then
    tPackageInstall rubygem-rails rubygem-rspec* rubygem-rake rubygem-nokogiri rubygem-rest-client
  else
    skip "Not supported on this distro, install deps manually"
  fi
}

@test "perform integration tests" {
  # some integration tests are longish and http timeouts
  export RBOVIRT_REST_TIMEOUT=500
  test -d rbovirt || git clone https://github.com/abenari/rbovirt
cat >rbovirt/spec/endpoint.yml <<ENDPOINT
url: "https://$(hostname -f)/api"
user: "admin@internal"
password: "ovirt"
datacenter: "local_datacenter"
cluster: "local_cluster"
network: "ovirtmgmt"
ENDPOINT
  pushd rbovirt
  if tIsRHEL; then
    scl enable ruby193 "rake spec --trace"
  else
    rake spec --trace
  fi
  popd
}
