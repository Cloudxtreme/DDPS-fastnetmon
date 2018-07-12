
# Source for fastnetmon notification script

TODO: also fix this

We have shifted from Debian to FreeBSD, making the notification script is done with

        bash mk-freebsd.sh

The `Makefile` is not used.

The _fastnetmon notification script_ is written in Perl and requires some Perl modules which
may be installed as Debian packages.

Either just deploy with `dpkg -i i2dps_1.0-18.deb; apt-get -y -f install`.
Create the debian package on Ubuntu/Debian/OSX with mk-deb

Development is done some where else than on the target host. So
  - Either copy everything to the target host, or
  - edit ``Makefile`` accordingly:
    - Change ``TARGETHOST`` and setup ssh keys etc.
	- check if everything else seems ok (paths etc)

On the fastnetmon host execute

    make install-modules
	make install

This will install the script and install a start script for fastnetmon (systemd compatible).

  - [Makefile](Makefile): makefile
  - [README.md](README.md): This file
  - [fnm2db.ini](fnm2db.ini): ini style configuration file
  - [fnm2db.pl](fnm2db.pl): source for the notification script
  - [fnm2dbrc](fnm2dbrc): start / stop script for fastnetmon
  - [mkdata.pl](mkdata.pl): test script
  - [remote.sh](remote.sh): edit locally deploy remotely, see script usage for more
  - [rsync_exclude.txt](rsync_exclude.txt): excludefile for rsync used by remote.sh

