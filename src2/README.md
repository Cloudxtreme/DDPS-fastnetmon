
# Export / Import fastnetmon host configurations

## Installation

This directory contains helper scripts. The scripts must be installed on `ww1`
and `ww2`. The installation is done with `make install`, which will also
install configuration templates for `infludb` and `fastnetmon`.

Install the scripts with

    rsync -avzH . ww2:/tmp; ssh ww2 'cd /tmp; make install'

## Usage

### Add a new FastNetMon host

Bootstrap the host, see [README.md](../vagrant/README.md). The new host
will have the IP address `192.168.68.2`, and is accessible from `ww1` and `ww2` as root.

Create an OpenVPN key on `fw.ddps` with the command

    /root/bin/openvpn_add_clien client-fqdn-or-ipv4address

And ssh keys with the command

     ssh-keygen -C "hostname@ipv4-vpn-address" -N '' -t ED25519 -f ed25519

Add the new key on both `ww1.ddps` and `ww2.ddps`with

``````
sudo chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys
sudo vi        /home/sftpgroup/newrules/.ssh/authorized_keys
sudo chattr +i /home/sftpgroup/newrules/.ssh/authorized_keys
``````

The _customer_ with network and administrator(s) for the enw FastNetMon host
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

Generate an sql file on `ww1` or `ww2` with 

    fnmcfg -v -a -i ipv4-vpn-address -n hostname

The sql file - `add_new_fastnetmon.sql` must be edited, so at least change
`networks_list` and `mode`. The network_list is the networks separated by
spaces which FastNetMon will monitor, while the mode must be `discard` or
`pass`.

```````
networks_list = '',
mode = 'discard',
networks_whitelist = '130.225.242.200/29 130.225.245.208/29',
```````

Add the new host to database with 

    cat add_new_fastnetmon.sql | sudo su postgres -c "cd /tmp; psql -d netflow"

Once added use the database vars to create configuration files for fastnetmon,
influxd and IP via rc.conf with

    fnmcfg -v -d -n hostname

Or

    fnmcfg -v -d -i ipv4-vpn-address

The files will be written to `TMPDIR` below `/tmp`. Change to that directory
and copy the OpenVPN config (saved as `openvpn.conf`) and the ssh keys and
execute

    fnmcfg -v -p -i ipv4-vpn-address

Which will preserve the existing `rc.conf` and other configuration files,
then install the new configuration, check services, test the OpenVPN
connectivity and ssh upload and do a rollback if one or more tests fails.


