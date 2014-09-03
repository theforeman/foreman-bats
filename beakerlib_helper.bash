# vim: ft=sh:sw=2:et

# create dummy functions for case beakerlib is not present
rlPhaseStartTest() {
}
rlPhaseEnd() {
}

# source beakerlib support
[ -f /var/lib/beakerlib/beakerlib.sh ] && source /var/lib/beakerlib/beakerlib.sh
[ -f /usr/share/beakerlib/beakerlib.sh ] && source /usr/share/beakerlib/beakerlib.sh

