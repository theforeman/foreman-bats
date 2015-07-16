#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

@test "configure default umask" {
  if tIsDebianCompatible; then
    for f in /etc/pam.d/common-session /etc/pam.d/common-session-noninteractive; do
      [ -e $f ] || continue
      egrep -q "^[^#].*pam_umask" $f ||
        sed -i 's/^\(session.*pam_unix\)/session optional pam_umask.so\n\1/' $f
    done
    sed -i "
      /^UMASK/ s/[0-9]\+/${FOREMAN_UMASK}/;
      /^USERGROUPS_ENAB/ s/yes/no/;
    " /etc/login.defs
  elif tIsRedHatCompatible; then
    echo "umask ${FOREMAN_UMASK}" > /etc/profile.d/umask.sh
  else
    skip "Unknown operating system"
  fi
}
