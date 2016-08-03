#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

URL=https://$(hostname -f)
CREDENTIALS=admin:changeme
TMP_DATA=$(mktemp /tmp/discover-host-XXXXXXXXXX)
trap "rm -f $TMP_DATA" EXIT

discover_host() {
  MAC1=$(echo -n 52:54:00:; openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/.$//')
  IP1="192.168.222.$(($RANDOM % 250 + 2))"
  cat <<EOD > $TMP_DATA
{
  "facts": {
    "discovery_version": "3.1.0",
    "interfaces": "fake1",
    "macaddress_fake1": "$MAC1",
    "ipaddress_fake1": "$IP1",
    "macaddress": "$MAC1",
    "ipaddress": "$IP1",
    "discovery_bootif": "$MAC1",
    "physicalprocessorcount": "3",
    "memorysize_mb": "900",
    "blockdevice.sda_size": "1234567890",
    "blockdevice.sdb_size": "123456700",
    "hardwaremodel": "Fake Host FH420"
  }
}
EOD
  cat $TMP_DATA
  curl -iku "$CREDENTIALS" \
    -H "Content-Type: application/json" \
    -d @$TMP_DATA -X POST $URL/api/v2/discovered_hosts/facts
}

find_discovered_host() {
  DID=$(hammer --csv discovery list | head -n2 | tail -n1 | cut -d, -f1)
}

@test "install discovery plugin" {
  yum -y install tfm-rubygem-foreman_discovery tfm-rubygem-hammer_cli_foreman_discovery
}

@test "restart foreman" {
  service httpd restart && sleep 15
}

@test "discover a host" {
  discover_host
}

@test "discover a second host" {
  discover_host
}

@test "list discovered hosts and refresh hammer cache" {
  hammer -r discovery list
}

@test "find a discovered host id" {
  find_discovered_host
  test $DID -gt 0
}

@test "show discovered host" {
  find_discovered_host
  hammer discovery info --id $DID
}

@test "provision discovered host" {
  find_discovered_host
  hammer discovery provision --id $DID --hostgroup bats-centos
}

@test "create a rule" {
  hammer discovery_rule create --name always-$RANDOM --search "cpu_count > 0" --hostgroup bats-centos
}

@test "list discovery rules" {
  hammer discovery_rule list
}

@test "show discovery rule" {
  hammer discovery_rule info --id 1
}

@test "find a discovered host id" {
  find_discovered_host
  test $DID -gt 0
}

@test "show discovered host" {
  find_discovered_host
  hammer discovery info --id $DID
}

@test "auto provision a host" {
  find_discovered_host
  hammer discovery auto-provision --id $DID
}
