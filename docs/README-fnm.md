
# Export / Import fastnetmon host configurations

This is a set of ad-hoc tools. Part of the functionality will be obsoleted once the
Web-UI supersedes it.

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

Create ssh keys with the command (rsa due to perl library not working with ed keys)
<!--  ssh-keygen -C "fastnetmon02.vpn.ddps.deic.dk@192.168.67.2" -N '' -t ed25519 -f id_ed25519 -->

     ssh-keygen -C "fastnetmon02.vpn.ddps.deic.dk@192.168.67.2" -N '' -t rsa -b 4096 -f id_rsa

Add the new key **on both** `ww1.ddps` and `ww2.ddps`with `edit_authorized_keys` which
opens `vi`on `home/sftpgroup/newrules/.ssh/authorized_keys` and `scp` the file to the other
host afterwards, or this way:

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
  - be able to make coffee and do sub sea spot weld as well

And do a rollback if one or more tests fails. But as for now, it doesn't.

### Background updates

`fnmcfg` also runs in the background watching for configuration changes which
must be applied. Changing the field _status_ to _pending_ will trigger an update. Valid words are:

| Word           | Description                                      |
| -------------- | ------------------------------------------------ |
| unconfigured   | New unconfigured system                          |
| pending        | System changes waiting to be enforced            |
| updated        | System is up to date                             |
| failed         | Enforcing changed has failed or system is down   |
| offline        | System deliberately out of reach                 |

The table should not be edited directly. The service is started by _systemd_,
and is _pgpool2_ aware. Status may be shown with:

    service db2fnm status

### Command-line edit FastNetMon host parameters

The database may be edited with

    sudo su postgres -c "cd /tmp; psql -d netflow "

The fastnetmon configuration parameters may be edited (and updated on the host) with

    fnmcfg -v -e -i 192.168.67.2

or

    fnmcfg -v -e -n fastnetmon02.vpn.ddps.deic.dk

The command creates the file `change_fastnetmon_parameters.sql` which must be
manually edited:

````````sql
UPDATE flow.fastnetmoninstances
    SET
    -- notes:
    --      description e.g. 'M1 E2, contact NTH or NIE'
    notes = '',
    networks_list = '',
    -- mode:
    --      accept, discard, accept or rate-limit 9600
    --      accept: monitor only -- creating dummy rules
    mode = 'discard',
    networks_whitelist = '130.225.242.200/29 130.225.245.208/29',
    blocktime = '10',
    process_incoming_traffic = 'on',
    process_outgoing_traffic = 'off',
    ban_time = '10',
    threshold_pps = '20000',
    threshold_mbps = '1000',
    threshold_flows = '3500',
    threshold_tcp_mbps = '10000',
    threshold_udp_mbps = '10000',
    threshold_icmp_mbps = '10000',
    threshold_tcp_pps = '10000',
    threshold_udp_pps = '10000',
    threshold_icmp_pps = '10000',
    ban_for_tcp_bandwidth = 'on',
    ban_for_udp_bandwidth = 'on',
    ban_for_icmp_bandwidth = 'on',
    ban_for_tcp_pps = 'on',
    ban_for_udp_pps = 'on',
    ban_for_icmp_pps = 'on',
    status = 'pending'
WHERE hostname = 'fastnetmon02.vpn.ddps.deic.dk';
````````

Next run the command

    cat change_fastnetmon_parameters.sql | sudo su postgres -c "cd /tmp; psql -d netflow "

which will save the parameters in the database. The changes will be enforced by the daemonized `fnmcfg`.

### Command-line edit FastNetMon host status check

Finally you may check the status for all fastnetmon instances with the command

    fnmcfg -v -s

Example output:

````````bash
12:35:25 (25/05) Starting /opt/db2dps/bin/fnmcfg
Expected status:
           hostname            |  status  |                               notes
-------------------------------+----------+--------------------------------------------------------------------
 fastnetmon02.vpn.ddps.deic.dk | offline  | Virtuel testmaskine der normalt er slukket
 fastnetmon04.vpn.ddps.deic.dk | uptodate | Ny fnm i M1, E2
 fastnetmon03.vpn.ddps.deic.dk | uptodate | Ny fnm i M1, E2 - vi skal have fundet en anvendelse og net til den
 fastnetmon05.vpn.ddps.deic.dk | offline  | Virtuel testmaskine der normalt er slukket

Real status:
fastnetmon04.vpn.ddps.deic.dk fastnetmon is running as pid 56465. influxd is running as pid 921.
fastnetmon03.vpn.ddps.deic.dk fastnetmon is running as pid 14788. influxd is running as pid 2612.
/opt/db2dps/bin/fnmcfg: line 671: /tmp/tmpdir/announcements_status.txt: Permission denied
12:35:26 (25/05) ok: 0 announcements in database, exabgp1,2 and mx80

Announcements (rules) staus:
ok: 0 announcements in database, exabgp1,2 and mx80
no errors everything running as expected, bye
````````

