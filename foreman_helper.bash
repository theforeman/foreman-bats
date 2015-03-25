# vim: ft=sh:sw=2:et

tForemanSetupUrl() {
  tSetOSVersion
  tIsRedHatCompatible && SYS="el"
  tIsFedoraCompatible && SYS="f"
  FOREMAN_URL=${FOREMAN_URL:-http://yum.theforeman.org/$FOREMAN_REPO/${SYS}${OS_VERSION}/x86_64/foreman-release.rpm}
}

tForemanSetLang() {
  # facter 1.7- fails to parse some values when non-US LANG and others are set
  # see: http://projects.puppetlabs.com/issues/12012
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
}

tForemanVersion() {
  (
    if tPackageExists foreman; then
      tPackageVersion foreman
    elif tPackageExists foreman-installer; then
      tPackageVersion foreman-installer
    fi
  ) | cut -d. -f1-2
}

tHammerCredentials() {
  # In 1.6+, the installer will configure ~/.hammer/
  [ x$FOREMAN_VERSION = "x1.5" -o x$FOREMAN_VERSION = "x1.4" ] && echo "-u admin -p changeme"
}

tForemanGetTemplateId() {
  # must use IDs - by name not implemented yet
  TPL_ID=$(hammer --csv template list --search "kind = \"$2\" AND name = \"$1\"" | tail -n1 | awk -F, '{print $1}')
}

