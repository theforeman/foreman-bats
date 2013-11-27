foreman-bats
============

BATS installation and cli end-to-end testing scripts for Foreman project

    $ git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local
    $ git clone https://github.com/lzap/foreman-bats.git && foreman-bats/install.sh /usr/local
    $ fb-install-foreman.bats
     ✓ enable epel
     ✓ download and install release package
     ✓ install installer
     ✓ run the installer
     ✓ wait a 10 seconds
     ✓ check web app is up
     ✓ wake up puppet agent
     ✓ install all compute resources
     ✓ restart httpd server
     ✓ collect important logs

    10 tests, 0 failures

There is also a helper script that automates git installation and installation
of BATS and Foreman BATS:

    curl --silent https://raw.github.com/lzap/foreman-bats/master/bootstrap.sh | bash /dev/stdin
