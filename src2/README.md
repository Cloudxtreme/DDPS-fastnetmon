
# Export / Import fastnetmon host configurations

## Installation

This directory contains helper scripts. The scripts must be installed on `ww1`
and `ww2`. The installation is done with `make install`, which will also
install configuration templates for `infludb` and `fastnetmon`.

Install the scripts with

    rsync -avzH . ww2:/tmp; ssh ww2 'cd /tmp; make install'

## Usage - add a new FastNetMon instance

Assume the host should be owned by Netdrift, have the VPN IP address
`192.168.67.2` and host name `fastnetmon02.vpn.ddps.deic.dk`.

### Add a new FastNetMon host

Bootstrap the host, see [README.md](../vagrant/README.md).          
Initially, the new host will have the IP address `192.168.68.2`, and is
accessible from `ww1` and `ww2` as root.

Start by creating an OpenVPN key on `fw.ddps` with the command

    /root/bin/openvpn_add_client fastnetmon02.vpn.ddps.deic.dk

This will among other create the configuration file

``````
/usr/local/etc/openvpn/clients/hostname.tun1/fastnetmon02.vpn.ddps.deic.dk/fastnetmon02.vpn.ddps.deic.dk.ovpn
``````

The IP address must be static. Add the line to `/usr/local/etc/openvpn/ipp_tun1.txt`:

``````
fastnetmon02.vpn.ddps.deic.dk,192.168.67.2
``````

Also, add the host and ip address to DNS - edit the zone and forward files in
`/var/nsd/zones/master` on `fw1.ddps`. Restart the service with 

``````
kill -HUP `cat /var/nsd/run/nsd.pid`
``````

The configuration files will be sent to `fw2.ddps` once a day with `rdist`. It
may be forced from `fw1.ddps` with:

    cd /etc && rdist

The _customer_ with network and administrator(s) for the new FastNetMon host
must be in the database.

You will need the following information in order to precede:

Network which will be monitored by FastNetMon (`networks_list`)
`administratorid` `uuid_customerid` `uuid_administratorid` and `customerid`.

Default values which matches _Netdrift_ are:

``````
administratorid:            42
uuid_customerid:            f561067e-10e3-44ed-ab12-9caed904d8d9
uuid_administratorid:       3611a271-50ae-4425-86c5-b58b04393242
customerid:                 3
``````

Generate an SQL file on `ww1` or `ww2` with 

    mkdir /tmp/fastnetmon02.vpn.ddps.deic.dk    
    cd fastnetmon02.vpn.ddps.deic.dk
    fnmcfg -v -a -i 192.168.67.2 -n fastnetmon02.vpn.ddps.deic.dk

The SQL file - `add_new_fastnetmon.sql` must be edited, so at least change
`networks_list` and `mode`. The `network_list` is the networks separated by
spaces which FastNetMon will monitor, while the mode must be `discard` or
`ratelimit 9600` or `accept`. Choose `accept` if traffic should not be blocked
aka monitor mode.

E.g. monitor only for the network `130.226.1.0/24`:

```````
networks_list = '130.226.1.0/24',
mode = 'accept',
networks_whitelist = '130.225.242.200/29 130.225.245.208/29',
```````

Add the new host to database with 

    cat add_new_fastnetmon.sql | sudo su postgres -c "cd /tmp; psql -d netflow"

Create ssh keys with the command

     ssh-keygen -C "fastnetmon02.vpn.ddps.deic.dk@192.168.67.2" -N '' -t ED25519 -f ed25519

Add the new key **on both** `ww1.ddps` and `ww2.ddps`with

``````
grep fastnetmon02.vpn.ddps.deic.dk@192.168.67.2 /home/sftpgroup/newrules/.ssh/authorized_keys

sudo chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys
grep fastnetmon02.vpn.ddps.deic.dk@192.168.67.2 /home/sftpgroup/newrules/.ssh/authorized_keys || \
    cat ed25519.pub >> /home/sftpgroup/newrules/.ssh/authorized_keys
sudo chattr +i /home/sftpgroup/newrules/.ssh/authorized_keys
``````

Once added use the database vars to create configuration files for fastnetmon,
influxd and IP via rc.conf with

    fnmcfg -v -d -n fastnetmon02.vpn.ddps.deic.dk

Or

    fnmcfg -v -d -i 192.168.67.2

The files will be written to `TMPDIR` below `/tmp` and moved to '.' if no files by the same name exists there.

Check the OpenVPN and SSH files are in the same directory before proceeding,
then execute (**notice the IP address!**):

    fnmcfg -v -p -i 192.168.68.2

Which will preserve the existing `rc.conf` and other configuration files,
then install the new configuration. The existing configuration file is in `/root/192.168.68.2/bootstrapped.tar.gz`

It should also

  - check services
  - test the OpenVPN connectivity and
  - ssh upload

and do a rollback if one or more tests fails.


