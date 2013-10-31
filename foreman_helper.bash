# vim: ft=sh:sw=2:et

tForemanSetupUrl() {
  [ -f /etc/redhat-release ] && OSNV=$(rpm -q --queryformat '%{RELEASE}' redhat-release-server | awk -F. '{print $1}')
  [ -f /etc/fedora-release ] && OSNV=$(rpm -q --queryformat '%{VERSION}' fedora-release)
  FOREMAN_URL=${FOREMAN_URL:-http://yum.theforeman.org/$FOREMAN_VERSION/$OSNV/x86_64/foreman-release.rpm}
}

tForemanSetLang() {
  # facter 1.7- fails to parse some values when non-US LANG and others are set
  # see: http://projects.puppetlabs.com/issues/12012
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
}
