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

tIsDebianCompatible() {
  [[ -f /etc/debian_version ]]
}

tIsUbuntuCompatible() {
  [[ -f /etc/os-release ]] && grep -q ID=ubuntu /etc/os-release
}

tSetOSVersion() {
  if [[ -z "$OS_VERSION" ]]; then
    if tIsCentOSCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release)
    elif tIsFedoraCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{VERSION}' fedora-release)
    elif tIsRedHatCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{RELEASE}' redhat-release-server | awk -F. '{print $1}')
    elif tIsUbuntuCompatible; then
      OS_VERSION=$(. /etc/os-release; echo $VERSION_ID)
      OS_RELEASE=$(lsb_release -cs)
    elif tIsDebianCompatible; then
      OS_VERSION=$(cut -d. -f1 /etc/debian_version)
      OS_RELEASE=$(lsb_release -cs)
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

tIsDebian() {
  tIsDebianCompatible && ! tIsUbuntuCompatible
}

tIsUbuntu() {
  tIsUbuntuCompatible
}

tPackageExists() {
  if tIsRedHatCompatible; then
    rpm -q "$1" >/dev/null
  elif tIsDebianCompatible; then
    dpkg -s "$1" >/dev/null
  else
    false # not implemented
  fi
}

tPackageInstall() {
  if tIsRedHatCompatible; then
    yum -y install "$1"
  elif tIsDebianCompatible; then
    apt-get install -y "$1"
  else
    false # not implemented
  fi
}

tPackageUpgrade() {
  if tIsRedHatCompatible; then
    yum -y upgrade "$1"
  elif tIsDebianCompatible; then
    apt-get upgrade -y "$1"
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
