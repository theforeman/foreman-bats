#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

setup() {
  tSetOSVersion

  RANDID1=$(( ( RANDOM % 252 )  + 1 ))
  RANDID2=$(( ( RANDOM % 252 )  + 1 ))
  PASS=${SAT_PASSWORD:-admin}
  VLANID1=${SAT_VLANID1:-$RANDID1}
  VLANID2=${SAT_VLANID2:-$RANDID2}
  ORG=${SAT_ORG:-MyOrg}
  LOC=${SAT_LOC:-MyLoc}
  HOME=/root

  # disable firewall - this is testing instance
  if tFileExists /usr/sbin/firewalld; then
    systemctl stop firewalld; systemctl disable firewalld
  elif tCommandExists systemctl; then
    systemctl stop iptables; systemctl disable iptables
  else
    service iptables stop; chkconfig iptables off
  fi

  # disable enforcing
  setenforce 0 && sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux

  tPackageExists curl || tPackageInstall curl
  tPackageExists yum-utils || tPackageInstall yum-utils
}

@test "install SELinux tools" {
  if tIsRedHatCompatible; then
    tPackageInstall install setools-console policycoreutils-python policycoreutils selinux-policy-devel
    sepolgen-ifgen || true
  else
    skip "not needed for this OS"
  fi
}

@test "update important system packages" {
  if tIsRedHatCompatible; then
    tPackageUpgrade bash openssh ca-certificates sudo selinux-policy\* yum\* abrt\* sos
  elif tIsDebianCompatible; then
    tPackageUpgrade bash openssh-client ca-certificates sudo
  fi
}

@test "set root password and permit login" {
  echo "root:$PASS" | chpasswd
  sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
  sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
  sed -i 's/^.*ssh-rsa/ssh-rsa/' /root/.ssh/authorized_keys
  service sshd restart
}

@test "create cloud-init symlink" {
  [ -f /var/log/cloud-init.log ] && ln -s /var/log/cloud-init.log /root/init.log
  true
}

@test "fix FQDN via /etc/hosts" {
  cat >/etc/hosts <<EOH
127.0.0.1 $(hostname -f) $(hostname -s) localhost
::1 $(hostname -f) $(hostname -s) localhost
EOH
}

@test "attach subscriptions" {
  echo "$CDN_USER" > /tmp/test
  rm -f /etc/yum.repos.d/*repo
  subscription-manager register --username=$CDN_USER --password=$CDN_PASSWORD --force
  # rhel
  subscription-manager attach --pool=8a85f9823e3d5e43013e3ddd4e2a0977
  # sat beta
  subscription-manager attach --pool=8a85f98148751d4301488e7352f725e6
  subscription-manager repos --disable '*'
}

@test "enable repositories" {
  subscription-manager repos \
    --enable rhel-${OS_VERSION}-server-satellite-6.1-rpms \
    --enable rhel-${OS_VERSION}-server-rpms \
    --enable rhel-server-rhscl-${OS_VERSION}-rpms
}

@test "setup vlans" {
  nmcli con add type vlan con-name v$VLANID1 dev eth0 id $VLANID1 ip4 192.168.$VLANID1.1/24
  nmcli con add type vlan con-name v$VLANID2 dev eth0 id $VLANID2 ip4 192.168.$VLANID2.1/24
}

@test "install satellite packages" {
  yum -y install katello
}

@test "installation 1st run" {
  katello-installer -v  --foreman-admin-password=$PASS\
    --foreman-initial-organization=$ORG \
    --foreman-initial-location=$LOC
}

@test "installation 2nd run" {
  export OAUTH_SECRET=$(grep oauth_consumer_secret /etc/foreman/settings.yaml | cut -d ' ' -f 2)
  katello-installer -v \
    --capsule-parent-fqdn $(hostname -f) \
    --capsule-dns true \
    --capsule-dns-interface eth0.$VLANID1 \
    $(for i in $(cat /etc/resolv.conf |grep nameserver|awk '{print $2}'); do echo --capsule-dns-forwarders $i;done) \
    --capsule-dns-zone v.lan \
    --capsule-dns-reverse "$VLANID1.168.192.in-addr.arpa" \
    --capsule-dhcp true \
    --capsule-dhcp-interface eth0.$VLANID1 \
    --capsule-dhcp-gateway 192.168.$VLANID1.1 \
    --capsule-dhcp-range "192.168.$VLANID1.100 192.168.$VLANID1.240" \
    --capsule-dhcp-nameservers 192.168.$VLANID1.1 \
    --capsule-tftp true \
    --capsule-puppet true \
    --capsule-puppetca true \
    --capsule-register-in-foreman true \
    --capsule-foreman-oauth-secret $OAUTH_SECRET
}

@test "initial puppet agent run" {
  puppet agent -t
}

@test "create puppet env" {
  hammer -u admin -p $PASS environment create --name fake --organizations "$ORG" --locations "$LOC"
}

@test "create media" {
  hammer -u admin -p $PASS medium create --os-family Redhat --name rhlabs_rhel --path 'http://download/pub/rhel/released/RHEL-$major/$major.$minor/Server/$arch/os/' --organizations "$ORG" --locations "$LOC"
  hammer -u admin -p $PASS medium create --os-family Redhat --name mirror_centos --path 'http://mirror.centos.org/centos-$major/$major/os/x86_64/' --organizations "$ORG" --locations "$LOC"
}

@test "create archs" {
  hammer -u admin -p $PASS os add-architecture --id 1 --architecture x86_64
  hammer -u admin -p $PASS os add-architecture --id 1 --architecture i386
}

@test "create ptable" {
  hammer -u admin -p $PASS os add-ptable --id 1 --partition-table "Kickstart default"
}

@test "associate media" {
  hammer -u admin -p $PASS medium add-operatingsystem --id 1 --operatingsystem-id 1
  hammer -u admin -p $PASS medium add-operatingsystem --id 7 --operatingsystem-id 1
}

@test "associate templates" {
  hammer -u admin -p $PASS os add-config-template --id 1 --config-template "Kickstart default"
  hammer -u admin -p $PASS os add-config-template --id 1 --config-template "Kickstart default finish"
  hammer -u admin -p $PASS os add-config-template --id 1 --config-template "Kickstart default PXELinux"
  hammer -u admin -p $PASS os add-config-template --id 1 --config-template "Kickstart default user data"
}

@test "set default templates" {
  TPL_ID=$(hammer -u admin -p $PASS --csv template list --search "name = \"Satellite Kickstart Default\" AND kind = \"provision\"" | tail -n1 | awk -F, '{print $1}')
  hammer -u admin -p $PASS os set-default-template --id 1 --config-template-id $TPL_ID
  TPL_ID=$(hammer -u admin -p $PASS --csv template list --search "name = \"Kickstart default PXELinux\" AND kind = \"PXELinux\"" | tail -n1 | awk -F, '{print $1}')
  hammer -u admin -p $PASS os set-default-template --id 1 --config-template-id $TPL_ID
  TPL_ID=$(hammer -u admin -p $PASS --csv template list --search "name = \"Satellite Kickstart Default User Data\" AND kind = \"user_data\"" | tail -n1 | awk -F, '{print $1}')
  hammer -u admin -p $PASS os set-default-template --id 1 --config-template-id $TPL_ID
  TPL_ID=$(hammer -u admin -p $PASS --csv template list --search "name = \"Satellite Kickstart Default Finish\" AND kind = \"finish\"" | tail -n1 | awk -F, '{print $1}')
  hammer -u admin -p $PASS os set-default-template --id 1 --config-template-id $TPL_ID
}

@test "create subnet" {
  hammer -u admin -p $PASS subnet create --name v.lan \
    --network 192.168.$VLANID1.0 \
    --mask 255.255.255.0 \
    --gateway 192.168.$VLANID1.1 \
    --dns-primary 192.168.$VLANID1.1 \
    --boot-mode Static \
    --ipam DHCP \
    --from 192.168.$VLANID1.100 \
    --to 192.168.$VLANID1.230 \
    --tftp-id 1 \
    --dhcp-id 1 \
    --dns-id 1 \
    --organizations "$ORG" \
    --locations "$LOC"
}

@test "create domain" {
  hammer -u admin -p $PASS domain create --name v.lan --dns-id 1 --organizations "$ORG" --locations "$LOC"
}

@test "associate domain" {
  DOMAIN_ID=$(hammer -u admin -p $PASS --csv domain list | grep v.lan | tail -n1 | awk -F, '{print $1}')
  hammer -u admin -p $PASS subnet update --id 1 --domain-ids $DOMAIN_ID
}

@test "create hostgroup" {
  hammer -u admin -p $PASS hostgroup create --name RHEL7 \
    --architecture x86_64 \
    --domain v.lan \
    --subnet v.lan \
    --operatingsystem-id 1 \
    --medium-id 1 \
    --partition-table "Kickstart default" \
    --puppet-proxy-id 1 \
    --puppet-ca-proxy-id 1 \
    --environment fake \
    --organizations "$ORG" \
    --locations "$LOC"
}

@test "set global settings" {
  echo "Setting['idle_timeout'] = 9999; Setting['entries_per_page'] = 100; Setting['root_pass'] = \"$PASS\"" | foreman-rake console
}

@test "check web app is up after CR installation" {
  curl -sk "https://$(hostname -f)/users/login" | grep -q login-form
}

@test "collect important logs" {
  tPackageExists sos || tPackageInstall sos
  sosreport --batch --tmp-dir=/root || true
}

