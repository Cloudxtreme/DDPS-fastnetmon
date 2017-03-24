
# Source for fastnetmon notification script

The _fastnetmon notification script_ is written in Perl and requires some Perl modules which
may be installed as Debian packages.

Development is done some where else than on the target host. So
  - Either copy everything to the target host, or
  - edit ``Makefile`` accordingly:
    - Change ``TARGETHOST`` and setup ssh keys etc.
	- check if everything else seems ok (paths etc)

On the fastnetmon host execute

    make install-modules
	make install

This will install the script and install a start script for fastnetmon (systemd compatible).

  - [Makefile](src/Makefile): makefile
  - [README.md](src/README.md): This file
  - [fnm2db.ini](src/fnm2db.ini): ini style configuration file
  - [fnm2db.pl](src/fnm2db.pl): source for the notification script
  - [fnm2dbrc](src/fnm2dbrc): start / stop script for fastnetmon
  - [mkdata.pl](src/mkdata.pl): test script
  - [remote.sh](src/remote.sh): edit locally deploy remotely, see script usage for more
  - [rsync_exclude.txt](src/rsync_exclude.txt): excludefile for rsync used by remote.sh

