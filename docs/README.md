
# Installation of DDPS fastnetmon

TODO: change text from specific with IP addresses to something more generic.

## Installation procedures

  - Installation of [10Gb drivers, fastnetmon and influxdb on the SuperMicro](10Gbs-debian-install-on-supermicro.md)
  - Testing and using [influxdb](influxdb-and-fastnetmon.md)
  - Installation of the [fastnetmon notification script](../src/README.md)

## Post install configuration 

Edit the configuration fastnetmon configuration files to suite your needs:

  - `/etc/fastnetmon.conf`
  - `/etc/networks`
  - `/etc/networks_list`
  - `/etc/networks_whitelist`

Then edit the configuration file for `fnm2db`:

  - `/opt/i2dps/etc/fnm2db.ini`

Change the following options - they must match the customer / database entries:

	customerid				= 1
	fastnetmoninstanceid	= 1
	uuid					= 00:25:90:47:2b:48
	administratorid			= 42
    ... 
	server					= 172.22.89.4
	pubkey					= /opt/i2dps/etc/ssh/id_ed25519.pub
	privkey					= /opt/i2dps/etc/ssh/id_ed25519

`customerid` matches _netdrift_ and all our networks while `fastnetmoninstanceid` should be added to the database.
The `uuid` is actually the Mac address of the 10Gb netcard (or similar - I see that it doesn't match on the first
any more). `Administratorid` must also be in the database.

The host must be able to `sftp` the _server_ address, i.e. `ddps.deic.dk`.

Check the `make install` actually made ssh keys in `/opt/i2dps/etc/ssh`. 

That done, add the ssh keys to `ddps:/home/sftpgroup/newrules/.ssh/authorized_keys`:

	ssh ddps
	cd /home/sftpgroup/newrules/.ssh/
	chattr -i /home/sftpgroup/.ssh/authorized_keys /home/sftpgroup/.ssh/authorized_keys
	
Now add `/opt/i2dps/etc/ssh/id_ed25519.pub` to
`/home/sftpgroup/.ssh/authorized_keys` and run

	chattr +i /home/sftpgroup/.ssh/authorized_keys /home/sftpgroup/.ssh/authorized_keys

Test that you can connect with sftp to _server_ but don't upload anything.

