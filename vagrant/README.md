
# Boot image building instructions

This is a description for creating a FreeBSD 11 boot ISO and DMG with Vagrant
for unattended installation of FastNetMon and influxd, as used in the DDPS
project.

**First** the official FreeBSD RELEASE box for Vagrant is used to bootstrap a
FreeBSD VirtualBox VM.

**Next**, the official _FreeBSD-XX.X-RELEASE-amd64-disc1.iso_ is fetched to the VM,
and customized using the `installerconfig`. The result is both a new customized
.iso and .dmg image. The images may be burned to CD or copied to an USB stick
for unattended installation.

Installation of the following is _not part of the unattended boot_ and has to
be done by hand later:

  - install host specific OpenVPN keys
  - install ssh keys which will give sftp access to DDPS
  - proper `rc.conf` with correct definition of uplink and FastNetMon mirror
    interface
  - the package providing the FastNetMon notification script
  - configuration for the notification script
  - adding the FastNetMon to the DDPS database

## Prerequisite

The installation requires the following software to be installed:

  * [VirtualBox](https://www.virtualbox.org)
  * [Vagrant](https://www.vagrantup.com)

It also requires access to the OpenVPN server and the DDPS system.

## Provisioning

When the above is installed clone this git repository to a local directory. It
should at least contain the files below:

    root
    ├── Vagrantfile
    ├── ...
    └── installerconfig

Execute from the directory containing the two textfiles:

    vagrant up

Followed by

    vagrant provision

Which will fetch and start the FreeBSD box image, NFS mount the directory
inside the box then fetch the official FreeBSD 11 installation image to
the same directory. The customized iso and dmg images will be created
and written to the same directory.

The box image is stopped with the command

    vagrant halt

Which will also stop the NFS export.


If `vagrant up` fails with the error `OpenSSL SSL_read: SSL_ERROR_SYSCALL,
errno 54` or similar, please use `vagrant --insecure --clean up` instead.
(error caused on macOS High Sierra with LibreSSL 2.2.7).

The box image It's around 1,5 GB in size, and will default be located in
`~/.vagrant.d/boxes`.

Ensure that a host based firewall not block NFS from the vagrant box to the
host OS.

Most other errors during the first run of `vagrant up` may be safely ignored.
Progress may be monitored on the console from VirtualBox.

The resulting iso may be booted on hardware (CDROM) or in VirtualBox.    
In order to copy the dmg to an USB on OSX, insert an USB stick, format it
as _FAT32_, _GUID partition map_ and name it e.g. _UNTITLED_.         
Find the device with

    diskutil list

The relevant output should look similar to:

````

/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *15.6 GB    disk2
   1:                        EFI EFI                     209.7 MB   disk2s1
   2:       Microsoft Basic Data UNTITLED                15.3 GB    disk2s2
````

The device is `/dev/disk2` in the example. Next eject the disk with

    diskutil unmountDisk /dev/disk2

The copy command requires administrative privileges. Take care as the target
disk will be erased with no questions asked.

    sudo dd bs=1m if=FreeBSD-11.1-RELEASE-amd64-disc1-custom.iso.dmg of=/dev/disk2

## Test and installation

Boot from either the CD or DMG image. The installation is unattended and will
install FreeBSD 11 with ZFS on the first single disk in the machine.        

The disk will be deleted ahead of the installation. After the installation the
machine is powered of so the installation media can be removed. Boot the
machine to finish the installation.

The installation assumes 

  - one high speed interface for FastNetMon connected to a switch mirror port
  - one interface used as uplink connected to Internet
  - ipv4 address for the uplink provided by DHCP
  - no ipv6

The installer sets up keys in __authorized_keys__ for the system administrator,
disables password based ssh access and install the software packages (see
listed in `installerconfig` below _Install packages_.

The installer also installs OpenVPN with a configuration in HUB mode. This
limits access to the system and all connections must be started from within the
DDPS network due to routing.         
The OpenVPN configuration sets the IPv4 address of the tun interface to the address
for the host `bootstrapped` in `/usr/local/etc/openvpn/ipp.txt` on `fw.ddps`. The
address is 192.168.68.2

## Finishing the configuration

The new FastNetMon host requires one more package installed and a number of
configuration files before it can go in production.

  - an unique OpenVPN configuration file
  - ssh keys used by the FastNetMon notification script which uploads rules
    to the DDPS database host
  - a specific configuration file for FastNetMon, the FastNetMon notification
    script and influxdb and specific changes to /etc/rc.conf

The customer owning the FastNetMon must exist in DDPS, and the network
protected by the FastNetMon must exist as part of the customers network.


UD Start by making a directory for files which must be applied to the new host by
UD renaming or copying the content of `example_config` to e.g. test01.ddps.deic.dk:
UD 
UD     mv example_config test01.ddps.deic.dk
UD 
UD Next
UD 
UD   - Crate customer if not already done on DDPS
UD   - create FastNetMon instance for the customer
UD   - Add FastNetMon config to the database for the customer
UD 
UD ### Generating OpenVPN configuration file and SSH keys
UD The configuration is made on `fw.ddps`. Execute
UD 
UD     /root/bin/openvpn_add_clien ${client-fqdn-or-ipv4address}
UD 
UD Add / check the IP address assigned in `/usr/local/etc/openvpn/ipp.txt`, the address
UD is referred as `ipv4-vpn-address` in this text.
UD 
UD The ssh configuration must be made with
UD 
UD     ssh-keygen -C "hostname@ipv4-vpn-address" -N '' -t ED25519 -f ed25519
UD 
UD Setting `hostname` and `ipv4-vpn-address`  as part of the key comment will make
UD it relative easy to keep a tight __authorized_keys__ on DDPS.
UD 
### Export the FastNetMon and other options from the database 

Extract the information from the database  on `ww1.ddps` or `ww2.ddps` with

    fnmcfg -v -d -n fnm.deic.dk

Or

    fnmcfg -v -d -i vpn-ipv4-address


Move `exported.SH` to `test01.ddps.deic.dk`.

Add the new key on both `ww1.ddps` and `ww2.ddps`with

``````
sudo chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys
sudo vi        /home/sftpgroup/newrules/.ssh/authorized_keys
sudo chattr +i /home/sftpgroup/newrules/.ssh/authorized_keys
``````

Then copy the latest `i2dps` package from ../src to e.g.
`test01.ddps.deic.dk/i2dps ... txz`

Create template files for the configuration files where the value is
replaced with a shell variable named the same as the var (`var = $var`), together
with all vars exported as shell vars to `files2db.SH` with the
command

``````
cd test01.ddps.deic.dk && ./cfg2SH_and_tmpl.pl
``````

You should now have the files

  - **export.SH**: exported settings from the database
  - **files2db.SH**: exported settings from the configuration files
  - **fastnetmon.conf.tmpl**: configuration file with shell vars
  - **fnm2db.ini.tmpl**: INI style configuration file with shell vars
  - **networks_list.tmpl**: configuration file with shell vars
  - **networks_whitelist.tmpl**: configuration file with shell vars

Build the config files with


---- HMM ----
Build the new configuration files with

``````
rsync -avzL test01.ddps.deic.dk 192.168.68.2:/tmp
ssh 192.168.68.2 'bash /tmp/test01.ddps.deic.dk/postbootstrap.sh build'
``````
This will build configuration files and place them in `/tmp`, and
print diff output for comparison.

If you are happy with the selected interfaces and configuration you may apply
the initial host specific configuration with the command

``````
ssh 192.168.68.2 'bash /tmp/test01.ddps.deic.dk/postbootstrap.sh apply'
``````

If you prefer to do final part of the installation by hand read on.

Modify `/etc/rc.conf` so the uplink and FastNetMon interfaces are configured
correctly and influx and fastnetmon started on boot. See example in
`example_config`.

The FastNetMon notification script is wrapped in a package (currently
`i2dps_1.0-19.txz`) and must be installed with:

    sudo pkg install -y i2dps_1.0-19.txz

The configuration file for the FastNetMon notification script is in
`/opt/i2dps/etc/fnm2db.ini` and the SSH keys must be installed in
`/opt/i2dps/etc/ssh/`, owner root:root, mode 700

Edit the config file for the FastNetMon notification script (`fnm2db.ini`), and
change `customerid`, `fastnetmoninstanceid`, `uuid` and `administratorid`, as
well as the `mode`, the information should be extracted from the DDPS database.

Test the configuration with the command from the host:

``````
ssh .. ... ...
``````

Next add monitored networks to `networks_list` and white listed networks to
`networks_whitelist`.        
At least change at least the `interfaces =  ... ` in `fastnetmon.conf`. There
should be no changes to `influxd.conf`


The file `/etc/rc.conf` must be edited as well, see `rc.conf.tmpl`. as well
as `fastnetmon.conf`, `fnm2db.ini`, `influxd.conf`, `networks_list` and
`networks_whitelist`.

### Final note

As the host keys for 192.168.68.2 will change each time a new host is installed,
the following configuration can be applied to `~/.ssh/config` to ignore the
warning from ssh (among other things):

```````
Host 192.168.68.2
    User root
    HostName   192.168.68.2
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    AddKeysToAgent no
    ProxyCommand ssh -W %h:%p fw.ddps.deic.dk
```````




