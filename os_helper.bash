# vim: ft=sh:sw=2:et

tIsRedHatCompatible() {
  [[ -f /etc/redhat-release ]]
}

tIsCentOSCompatible() {
  [[ -f /etc/centos-release ]]
}

tIsFedoraCompatible() {
  [[ -f /etc/redhat-release && -f /etc/fedora-release ]]
}

tSetOSVersion() {
  if [[ -z "$OS_VERSION" ]]; then
    if tIsCentOSCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release)
    elif tIsRedHatCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{RELEASE}' redhat-release-server | awk -F. '{print $1}')
    elif tIsFedoraCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{VERSION}' fedora-release)
    fi
  fi
}

tIsFedora() {
  if [ -z "$1" ]; then
    tIsFedoraCompatible
  else
    tSetOSVersion
    tIsFedoraCompatible && [[ "$1" -eq "$OS_VERSION" ]]
  fi
}


tIsRHEL() {
  if [ -z "$1" ]; then
    tIsRedHatCompatible
  else
    tSetOSVersion
    tIsRedHatCompatible && [[ "$1" -eq "$OS_VERSION" ]]
  fi
}

tPackageExists() {
  if tIsRedHatCompatible; then
    rpm -q "$1" >/dev/null
  else
    false # not implemented
  fi
}

tCommandExists() {
  type -p "$1" >/dev/null
}

tFileExists() {
  [[ -f "$1" ]]
}
