#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "install and configure libvirt daemon" {
  if tIsRedHatCompatible; then
    tPackageExists qemu-kvm || yum -y groupinstall Virtualization
    tPackageExists libvirt || yum -y install libvirt
    service libvirtd start
    chkconfig libvirtd on
  elif tIsDebianCompatible; then
    apt-get install qemu-kvm libvirt-bin
  fi

  echo 'auth_unix_rw = "none"' >> /etc/libvirt/libvirtd.conf
  echo 'auth_tls = "none"' >> /etc/libvirt/libvirtd.conf

  service libvirtd restart && sleep 10
}

@test "configure nested network and storage" {
  virsh net-info nested && skip "already configured"
  # https://bugzilla.redhat.com/show_bug.cgi?id=1160183
  touch /tmp/nested.xml && chcon system_u:object_r:lib_t:s0 /tmp/nested.xml
  # create network
  cat >/tmp/nested.xml <<'EON'
<network>
  <name>nested</name>
  <uuid>71e5409e-59d0-11e4-8c48-3ca9f45639f8</uuid>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0' />
  <mac address='52:54:C4:9E:13:05'/>
  <ip address='192.168.222.1' netmask='255.255.255.0'>
  </ip>
</network>
EON
  virsh net-define /tmp/nested.xml
  virsh net-start nested
  virsh net-autostart nested
  # create pool
  mkdir -p /var/lib/libvirt/nested
  cat >/tmp/nested.xml <<'EOP'
<pool type='dir'>
  <name>nested</name>
  <uuid>1117824d-b2dc-441f-8543-f49308c77d2a</uuid>
  <source>
  </source>
  <target>
    <path>/var/lib/libvirt/nested</path>
    <permissions>
      <mode>0755</mode>
      <owner>-1</owner>
      <group>-1</group>
    </permissions>
  </target>
</pool>
EOP
  virsh pool-define /tmp/nested.xml
  virsh pool-autostart nested
}

@test "configure proxy and services" {
  foreman-installer -v \
    --enable-foreman-proxy \
    --foreman-proxy-tftp=true \
    --foreman-proxy-tftp-servername=192.168.222.1 \
    --foreman-proxy-dhcp=true \
    --foreman-proxy-dhcp-interface=virbr1 \
    --foreman-proxy-dhcp-gateway=192.168.222.1 \
    --foreman-proxy-dhcp-range="192.168.222.2 192.168.222.200" \
    --foreman-proxy-dhcp-nameservers="192.168.222.1" \
    --foreman-proxy-dns=true \
    --foreman-proxy-dns-interface=virbr1 \
    --foreman-proxy-dns-zone=nested.lan \
    --foreman-proxy-dns-forwarders=$(awk '/nameserver/ { print $2 ; exit }' /etc/resolv.conf) \
    --foreman-proxy-dns-reverse=222.168.192.in-addr.arpa \
    --foreman-proxy-foreman-base-url=https://$(hostname -f)
}

@test "refresh puppet facts" {
  puppet agent -t -v
}

@test "create nested libvirt compute resource" {
  hammer -d compute-resource create --provider libvirt --name libvirt --url qemu:///system
}

@test "verify expected operating system" {
  # at least one was created via puppet agent above
  test $(hammer --csv os list | wc -l) -ge 2
}

@test "create installation medium" {
  # this one is only for use in Red Hat labs
  hammer -d medium create --os-family Redhat --name rhlabs_rhel \
    --path 'http://download/pub/rhel/released/RHEL-$major/$major.$minor/Server/$arch/os/'
}

@test "associate architectures" {
  hammer -d os add-architecture --id 1 --architecture x86_64
  hammer -d os add-architecture --id 1 --architecture i386
}

@test "associate partition table" {
  hammer -d os add-ptable --id 1 --ptable "Kickstart default"
}

@test "associate installation media" {
  # must use the IDs because of http://projects.theforeman.org/issues/8231
  # we hardcode CentOS in this case
  hammer -d medium add-operatingsystem --id 1 --operatingsystem-id 1
  hammer -d medium add-operatingsystem --id 7 --operatingsystem-id 1
}

@test "associate templates" {
  # we hardcode CentOS in this case
  hammer -d os add-config-template --id 1 --config-template "Kickstart default"
  hammer -d os add-config-template --id 1 --config-template "Kickstart default finish"
  hammer -d os add-config-template --id 1 --config-template "Kickstart default PXELinux"
  hammer -d os add-config-template --id 1 --config-template "Kickstart default user data"
}

@test "set default templates" {
  # must use IDs - by name not implemented yet
  hammer -d os  set-default-template --id 1 --config-template-id 18
  hammer -d os  set-default-template --id 1 --config-template-id 20
  hammer -d os  set-default-template --id 1 --config-template-id 21
  hammer -d os  set-default-template --id 1 --config-template-id 23
}

@test "create subnet" {
  hammer -d subnet create --name nested.lan \
    --network 192.168.222.0 \
    --mask 255.255.255.0 \
    --gateway 192.168.222.1 \
    --dns-primary 192.168.222.1 \
    --boot-mode Static \
    --ipam DHCP \
    --from 192.168.222.100 \
    --to 192.168.222.200 \
    --tftp-id 1 \
    --dhcp-id 1 \
    --dns-id 1
}

@test "create domain" {
  hammer -d domain create --name nested.lan --dns-id 1
  hammer --csv domain list | grep nested.lan
}

@test "associate subnet and domain" {
  hammer -d subnet update --id 1 --domain-ids 2
}

@test "create hostgroup" {
  hammer -d hostgroup create --name bats-centos \
    --architecture x86_64 \
    --domain nested.lan \
    --subnet nested.lan \
    --operatingsystem-id 1 \
    --medium-id 1 \
    --ptable "Kickstart default" \
    --puppet-proxy-id 1 \
    --puppet-ca-proxy-id 1 \
    --environment production
}

@test "run foreman-debug" {
  foreman-debug -q -d /root/foreman-debug || true
}
