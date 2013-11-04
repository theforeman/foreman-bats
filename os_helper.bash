# vim: ft=sh:sw=2:et

tIsRedHatCompatible() {
  [[ -f /etc/redhat-release ]]
}

tIsRHEL() {
  if [ -z "$1" ]; then
    [[ -f /etc/redhat-release && ! -f /etc/fedora-release ]]
  else
    [[ -f /etc/redhat-release && ! -f /etc/fedora-release && \
      "$1" -eq "$(rpm -q --queryformat '%{RELEASE}' redhat-release-server | awk -F. '{print $1}')" ]]
  fi
}

tIsFedora() {
  if [ -z "$1" ]; then
    [[ -f /etc/redhat-release && -f /etc/fedora-release ]]
  else
    [[ -f /etc/redhat-release && -f /etc/fedora-release && \
      "$1" -eq "$(rpm -q --queryformat '%{VERSION}' fedora-release)" ]]
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
