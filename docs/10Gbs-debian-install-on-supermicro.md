
# DDPS: Configuration and installation of fastnetmon detect engine

## 10 Gbit/s Debian install:

  1. Fetch the newest stable Debian amd64 release from
     [debian.org](https://www.debian.org/distrib/netinst#smallcd)
  1. Install via CDROM or USB ``(debian-8.7.1-amd64-netinst.iso -
     81bc2c68de1e0581d19e4c559be913968cf8bb5a)``.
  2. Select _Normal installation_ (without X and + SSH server), everything on `/`
    - English -> other -> Europe -> Denmark -> United States -> Danish
    - eth0 -> Continue -> Configure network manually -> 172.16.70.101 -> 255.255.255.0 -> 172.16.70.1 -> 8.8.8.8 -> fastnetmon2 -> deic.dk 
    - Enter the root password (default pw) and make a ‘sysadm’ user (default pw)
    - Guided - use entire disk -> SCSI1 (sda) -> All files in one partition -> Yes -> Finish partitioning and write chages to disk -> Yes
    - Denmark -> ftp.dk.debian.org -> Continue -> No
    - Uncheck “Debian desktop environment”, “print server” and add “SSH server” -> Continue
    - Install GRUB boot loader: Yes -> /dev/sda -> Continue (and remove CDROM)

Update after reboot ``apt-get update && apt-get upgrade`` after installation (reboot if required).

Connect with SSH, and follow the instruction below.

#### Install software via apt-get

    apt-get install vim
    apt-get install tcpdump
    apt-get install ethtool
    apt-get install openntpd
    apt-get install tmux

#### Change drivers

Fetch Pavel’s Netmon and ixgebe-driver install-script from GitHub:

	su -
	mkdir -p /usr/local/src/$(date '+%Y-%m-%d')
	cd /usr/local/src/$(date '+%Y-%m-%d')
	wget https://gist.githubusercontent.com/pavel-odintsov/6353bfd3bfd7dba2d99a/raw/f8b0e15ef203b343d846e17be9dfec25db1172e3/netmap_install.pl
	cp /usr/local/src/$(date '+%Y-%m-%d')/netmap_install.pl /usr/local/src/$(date '+%Y-%m-%d')/netmap_install.pl.ORIG

Change driver to _ixgbe_ from _e1000e_ in `/usr/local/src/netmap/$(date '+%Y-%m-%d')/netmap_install.pl install-script`:

From

	my $selected_driver = 'e1000e';

To

	my $selected_driver = 'ixgbe';

Run `netmap_install.pl` and move `/tmp/netmap_build..` directory to `/usr/local/src/netmap/(date)` and symlink it to `/usr/local/src/netmap`:

	chmod +x /usr/local/src/$(date '+%Y-%m-%d')/netmap_install.pl
	/usr/local/src/$(date '+%Y-%m-%d')/netmap_install.pl
	mkdir -p /usr/local/src/$(date '+%Y-%m-%d')/netmap.build.dir
	mv		/tmp/netmap*/*												\
			/usr/local/src/$(date '+%Y-%m-%d')/netmap.build.dir
	rm /usr/local/src/netmap
	ln -s	/usr/local/src/$(date '+%Y-%m-%d')/netmap.build.dir/netmap	\
			/usr/local/src/netmap

Make sure that the correct drivers are loaded when rebooting (add below to
`/etc/rc.local`):

	cat << EOF > /etc/rc.local
	#!/bin/sh -e
	#
	# rc.local
	#
	# This script is executed at the end of each multiuser runlevel.
	# Make sure that the script will "exit 0" on success or any other
	# value on error.
	#
	# In order to enable or disable this script just change the execution
	# bits.
	#
	# By default this script does nothing.

	# Make sure that netmap is loaded for 10 Gbits ixgbe driver:
	/sbin/ifconfig eth1 -promisc
	/sbin/ifconfig eth1 down
	/sbin/rmmod ixgbe
	/sbin/insmod /usr/local/src/netmap/LINUX/netmap.ko
	/sbin/modprobe vxlan
	/sbin/insmod /usr/local/src/netmap/LINUX/ixgbe/ixgbe.ko
	/sbin/ifconfig eth1 up
	/sbin/ifconfig eth1 promisc
	sleep 60

	# Disable various properties for fast performance in FastNetMon:
	/sbin/ethtool -K eth1 gro off gso off tso off lro off
	/sbin/ethtool -A eth1 rx off tx off

	exit 0
	EOF


##### Add network configuration for the 10 Gbit/s interface:

File `/etc/network/interfaces` should look this way:

	cat << EOF > /etc/network/interfaces
	# This file describes the network interfaces available on your system
	# and how to activate them. For more information, see interfaces(5).

	source /etc/network/interfaces.d/*

	# The loopback network interface
	auto lo
	iface lo inet loopback

	# Eth0: The primary network interface (Internet)
	allow-hotplug eth0
	iface eth0 inet static
			address 172.16.70.101
			netmask 255.255.255.0
			network 172.16.70.0
			broadcast 172.16.70.255
			gateway 172.16.70.1
			# dns-* options are implemented by the resolvconf package, if installed
			dns-nameservers 8.8.8.8
			dns-search deic.dk

	# Eth1: 10 Gbips monitor interface is configured with no IP and in promiscuous mode
	auto eth1
	iface eth1 inet manual
			up ifconfig eth1 up
			up ip link set eth1 promisc on
			down ip link set eth1 promisc off
			down ifconfig eth1 down

	# Eth2: LAN interface
	auto eth2
	iface eth2 inet static
	address 172.22.89.2
	netmask 255.255.255.0
	EOF


Reboot the machine to make sure that everything works after a reboot:

	reboot

Test that the 10 Gbit/s network card is working with netmap (you should see
14.881 Mpps - maximum number of valid packets on a 10 Gbit/s interface):

	/usr/local/src/netmap/LINUX/build-apps/pkt-gen/pkt-gen -i eth1 -f tx -n 500111222 -l 60 -w 5


#### Fetch FastNetMon from Pavel’s GitHub:

	su -
	cd /usr/local/src/$(date '+%Y-%m-%d')
	wget https://raw.githubusercontent.com/pavel-odintsov/fastnetmon/master/src/fastnetmon_install.pl \ 
	-O fastnetmon_install.pl
	cp	/usr/local/src/$(date '+%Y-%m-%d')/fastnetmon_install.pl	\
		/usr/local/src/$(date '+%Y-%m-%d')/fastnetmon_install.pl.ORIG

Disable pfring support in `fastnetmon_install.pl`;
change `"we_have_pfring_support=1"`:

From:

	$we_have_pfring_support = 1;
To:

	$we_have_pfring_support = 0;

Install FastNetMon from Pavel’s Perl installer (using git master):

	chmod +x /usr/local/src/$(date '+%Y-%m-%d')/fastnetmon_install.pl
	/usr/local/src/$(date '+%Y-%m-%d')/fastnetmon_install.pl --use-git-master —-do-not-track-me

Move `install-log` to `/usr/local/src/(date)` and the build dir:

	cp /tmp/fastnetmon_install.log			\
		/usr/local/src/$(date '+%Y-%m-%d')
	mkdir -p /usr/local/src/$(date '+%Y-%m-%d')/fastnetmon.build.dir
	mv /tmp/fastnetmon.build.dir.*/*		\
		/usr/local/src/$(date '+%Y-%m-%d')/fastnetmon.build.dir
	cp /etc/fastnetmon.conf					\
		/usr/local/src/$(date '+%Y-%m-%d')/fastnetmon.conf.ORIG
	cp /etc/fastnetmon.conf					\
		/etc/fastnetmon.conf.ORIG


Edit `/etc/networks_list` for FastNetMon (all the networks you want to monitor):

	cat << EOF > /etc/networks_list
	130.226.136.240/28
	EOF

Edit `/etc/networks_whitelist` for FastNetMon (all the networks you want to ignore):

	cat << EOF > /etc/networks_whitelist
	172.22.89.0/24
	EOF

Edit /etc/fastnetmon.conf to suit your needs:

	cat << EOF > /etc/fastnetmon.conf
	###
	### Main configuration params
	###

	### Logging configuration

	# enable this option if you want to send logs to local syslog facility
	logging:local_syslog_logging = off

	# enable this option if you want to send logs to a remote syslog server via UDP
	logging:remote_syslog_logging = off

	# specify a custom server and port for remote logging
	logging:remote_syslog_server = 10.10.10.10
	logging:remote_syslog_port = 514

	# Enable/Disable any actions in case of attack
	enable_ban = on

	# disable processing for certain direction of traffic
	process_incoming_traffic = on
	process_outgoing_traffic = on

	# How many packets will be collected from attack traffic
	ban_details_records_count = 500

	# How long (in seconds) we should keep an IP in blocked state
	# If you set 0 here it completely disables unban capability
	ban_time = 60

	# Check if the attack is still active, before triggering an unban callback with this option
	# If the attack is still active, check each run of the unban watchdog
	unban_only_if_attack_finished = off

	# enable per subnet speed meters
	# For each subnet, list track speed in bps and pps for both directions
	enable_subnet_counters = on

	# list of all your networks in CIDR format
	networks_list_path = /etc/networks_list

	# list networks in CIDR format which will be not monitored for attacks
	white_list_path = /etc/networks_whitelist

	# redraw period for client's screen
	check_period = 1

	# Connection tracking is very useful for attack detection because it provides huge amounts of information,
	# but it's very CPU intensive and not recommended in big networks
	enable_connection_tracking = on

	# Different approaches to attack detection
	ban_for_pps = on
	ban_for_bandwidth = on
	ban_for_flows = on

	# Limits for Dos/DDoS attacks
	threshold_pps = 20000
	threshold_mbps = 1000
	threshold_flows = 3500

	# Per protocol attack thresholds
	# We don't implement per protocol flow limits, sorry :(
	# These limits should be smaller than global pps/mbps limits

	threshold_tcp_mbps = 10000
	threshold_udp_mbps = 10000
	threshold_icmp_mbps = 10000

	threshold_tcp_pps = 10000
	threshold_udp_pps = 10000
	threshold_icmp_pps = 10000

	ban_for_tcp_bandwidth = on
	ban_for_udp_bandwidth = on
	ban_for_icmp_bandwidth = on

	ban_for_tcp_pps = on
	ban_for_udp_pps = on
	ban_for_icmp_pps = on

	###
	### Traffic capture methods
	###

	# PF_RING traffic capture, fast enough but the wirespeed version needs a paid license
	mirror = off

	# Port mirroring sample rate
	pfring_sampling_ratio = 1

	# Netmap traffic capture (very fast but needs patched drivers)
	mirror_netmap = on

	# SnabbSwitch traffic capture
	mirror_snabbswitch = off

	# AF_PACKET capture engine
	# Please use it only with modern Linux kernels (3.6 and more)
	# And please install birq for irq ditribution over cores
	mirror_afpacket = off

	# use PCI-e addresses here instead of OS device names. You can find them in "lspci" output
	#interfaces = eth1

	# Port mirroring sampling ratio
	netmap_sampling_ratio = 1

	# This option should be enabled if you are using Juniper with mirroring of the first X bytes of packet: maximum-packet-length 110;
	netmap_read_packet_length_from_ip_header = off

	# Pcap mode, very slow and thus not suitable for production
	pcap = off
	# Netflow capture method with v5, v9 and IPFIX support
	netflow = off
	# sFLOW capture suitable for switches
	sflow = off

	# PF_RING configuration
	# If you have a license for PF_RING ZC, enable this mode and it might achieve wire speed for 10GE
	enable_pf_ring_zc_mode = off

	# Configuration for netmap, mirror, pcap modes
	# For pcap and PF_RING we could specify "any"
	# For netmap and PF_RING we could specify multiple interfaces = eth0,eth1,eth2
	interfaces = eth1

	# We use average values for traffic speed to certain IP and we calculate average over this time slice
	average_calculation_time = 5

	# We use average values for traffic speed for subnet and we calculate average over this time slice
	average_calculation_time_for_subnets = 20

	# Netflow configuration

	# it's possible to specify multiple ports here, using commas as delimiter
	netflow_port = 2055
	netflow_host = 0.0.0.0

	# To bind to all interfaces = eth0,eth1,eth2
	# To bind to all interfaces = eth0,eth1,eth2
	# To bind to localhost for a specific protocol:      ::1 or 127.0.0.1

	# Netflow v9 and IPFIX agents use different and very complex approaches for notifying about sample ratio
	# Here you could specify a sampling ratio for all this agents
	# For NetFLOW v5 we extract sampling ratio from packets directely and this option not used
	netflow_sampling_ratio = 1

	# In some cases with NetFlow we could get huge bursts related to aggregated data nature
	# We could try to get smoother data with this option, I.e. we will divide counters on collection interval time
	netflow_divide_counters_on_interval_length = off

	# Process each netflow packet with LUA
	# This option is not default and you need build it additionally
	# netflow_lua_hooks_path = /usr/src/fastnetmon/src/netflow_hooks.lua

	# sFLOW configuration

	# It's possible to specify multiple ports here, using commas as delimiter
	sflow_port = 6343
	# sflow_port = 6343,6344
	sflow_host = 0.0.0.0

	# process each sFLOW packet with LUA
	# This option is not default and you need build it additionally
	# sflow_lua_hooks_path = /usr/src/fastnetmon/src/sflow_hooks.lua

	###
	### Actions when attack detected
	###

	# This script executed for ban, unban and attack detail collection
	#notify_script_path = /usr/local/bin/notify_about_attack.sh
	notify_script_path = /opt/i2dps/bin/fnm2db

	# pass attack details to notify_script via stdin
	# Pass details only in case of "ban" call
	# No details will be passed for "unban" call
	notify_script_pass_details = on

	# collect a full dump of the attack with full payload in pcap compatible format
	collect_attack_pcap_dumps = off

	# Execute Deep Packet Inspection on captured PCAP packets
	process_pcap_attack_dumps_with_dpi = off

	# Save attack details to Redis
	redis_enabled = off

	# Redis configuration
	redis_port = 6379
	redis_host = 127.0.0.1

	# specify a custom prefix here
	redis_prefix = mydc1

	# We could store attack information to MongoDB
	mongodb_enabled = off
	mongodb_host = localhost
	mongodb_port = 27017
	mongodb_database_name = fastnetmon

	# If you are using PF_RING non ZC version you could block traffic on host with hardware filters
	# Please be aware! We can not remove blocks with this action plugin
	pfring_hardware_filters_enabled = off

	# announce blocked IPs with BGP protocol with ExaBGP
	exabgp = off
	exabgp_command_pipe = /var/run/exabgp.cmd
	exabgp_community = 65001:666

	# specify multiple communities with this syntax:
	# exabgp_community = [65001:666 65001:777]

	# specify different communities for host and subnet announces
	# exabgp_community_subnet = 65001:667
	# exabgp_community_host = 65001:668

	exabgp_next_hop = 10.0.3.114

	# In complex cases you could have both options enabled and announce host and subnet simultaneously

	# Announce /32 host itself with BGP
	exabgp_announce_host = on

	# Announce origin subnet of IP address instead IP itself
	exabgp_announce_whole_subnet = off

	# Announce Flow Spec rules when we could detect certain attack type
	# Please we aware! Flow Spec announce triggered when we collect some details about attack,
	# I.e. when we call attack_details script
	# Please disable exabgp_announce_host and exabgp_announce_whole_subnet if you want to use this feature
	# Please use ExaBGP v4 only (Git version), for more details: https://github.com/FastVPSEestiOu/fastnetmon/blob/master/docs/BGP_FLOW_SPEC.md
	exabgp_flow_spec_announces = off

	# GoBGP intergation
	gobgp = off
	gobgp_next_hop = 0.0.0.0
	gobgp_announce_host = on
	gobgp_announce_whole_subnet = off

	# Graphite monitoring
	# InfluxDB is also supported, please check our reference:
	# https://github.com/FastVPSEestiOu/fastnetmon/blob/master/docs/INFLUXDB_INTEGRATION.md
	graphite = on
	graphite_host = 127.0.0.1
	graphite_port = 2003

	# Default namespace for Graphite data
	graphite_prefix = fastnetmon

	# Add local IP addresses and aliases to monitoring list
	# Works only for Linux
	monitor_local_ip_addresses = on

	# Create group of hosts with non-standard thresholds
	# You should create this group before (in configuration file) specifying any limits
	#hostgroup = my_hosts:10.10.10.221/32,10.10.10.222/32

	# Configure this group
	#my_hosts_enable_ban = off

	#my_hosts_ban_for_pps = off
	#my_hosts_ban_for_bandwidth = off
	#my_hosts_ban_for_flows = off

	#my_hosts_threshold_pps = 20000
	#my_hosts_threshold_mbps = 1000
	#my_hosts_threshold_flows = 3500

	# Path to pid file for checking "if another copy of tool is running", it's useful when you run multiple instances of tool
	pid_path = /var/run/fastnetmon.pid

	# Path to file where we store information for fastnetmon_client
	cli_stats_file_path = /tmp/fastnetmon.dat

	# Enable gRPC api (required for fastnetmon_api_client tool)
	enable_api = off

	###
	### Client configuration
	###

	# Field used for sorting in client, valid values are: packets, bytes or flows
	sort_parameter = packets
	# How much IPs will be listed for incoming and outgoing channel eaters
	max_ips_in_list = 7
	EOF

One last thing though, IPv6 needs to be disabled, or fastnetmon will attempt to connect to TCP port 2003
on ::1.



	test -f /etc/sysctl.conf.org || {
		cp /etc/sysctl.conf /etc/sysctl.conf.org
	}

	(
	cat /etc/sysctl.conf.org
	cat << EOF
	net.ipv6.conf.all.disable_ipv6 = 1
	net.ipv6.conf.default.disable_ipv6 = 1
	net.ipv6.conf.lo.disable_ipv6 = 1
	net.ipv6.conf.eth0.disable_ipv6 = 1
	EOF
	) > /etc/sysctl.conf

Run `sysctl -p` to activate changes:

	sysctl -p

Start FastNetMon from SystemD - or use /etc.rc.local to start FastNetMon?:
If you are in love with [systemd](suckless.org/sucks/systemd) you may use

	systemctl enable fastnetmon.service
	systemctl start fastnetmon.service

Or if you prefer a start without a stop system you may start fastnetmon from `/etc/rc.local`:

	cat << EOF >> /etc/rc.local
	/opt/fastnetmon/fastnetmon --daemonize
	EOF

## Installation of companion influxdb

**Warning**: InfluxDB has will be installed **without** authentication in order to
be used by fastnetmon.

The following is a receipt for installing
[influxdb](https://en.wikipedia.org/wiki/InfluxDB) on [debian
8.x](https://www.debian.org). Installation for
[Ubuntu-14.04](https://www.ubuntu.com) is described
[here](https://hostpresto.com/community/tutorials/how-to-install-influxdb-on-ubuntu-14.04/). 

Start by applying any patches and install
[curl](https://en.wikipedia.org/wiki/CURL):

	apt-get update
	apt-get -y upgrade
	apt-get install apt-transport-https curl

Next append keys and
[PPA](https://en.wikipedia.org/wiki/Personal_Package_Archive) from
influxdata.com:

	curl -sL https://repos.influxdata.com/influxdb.key				|	\
		apt-key add -
	echo "deb https://repos.influxdata.com/debian jessie stable"	|	\
		tee /etc/apt/sources.list.d/influxdb.list
	apt-get update 
	apt-get -y install influxdb

#### InfluxDB Configuration

	test -f /etc/influxdb/influxdb.conf.org || {
		cp /etc/influxdb/influxdb.conf /etc/influxdb/influxdb.conf.org
	}

Do not start the software, the configuration has to be changed first. The
changes may be done in one of two ways:

  1. copy an edited version
  1. patch the installed version

Copy with the command:

	cp ./influxdb.conf /etc/influxdb/influxdb.conf

Or patch with the commands:

	cat << EOF > influxdb.conf.patch
	--- /etc/influxdb/influxdb.conf.org	2016-11-03 15:42:21.943348924 +0100
	+++ /etc/influxdb/influxdb.conf	2016-11-03 15:43:39.163346144 +0100
	@@ -4,7 +4,7 @@
	 # The data includes a random ID, os, arch, version, the number of series and other
	 # usage data. No data from user databases is ever transmitted.
	 # Change this option to true to disable reporting.
	-reporting-disabled = false
	+reporting-disabled = true
	 
	 # we'll try to get the hostname automatically, but if it the os returns something
	 # that isn't resolvable by other servers in the cluster, use this option to
	@@ -194,11 +194,11 @@
	 ###
	 
	 [[graphite]]
	-  enabled = false
	-  # database = "graphite"
	-  # bind-address = ":2003"
	-  # protocol = "tcp"
	-  # consistency-level = "one"
	+  enabled = true
	+  database = "graphite"
	+  bind-address = ":2003"
	+  protocol = "tcp"
	+  consistency-level = "one"
	 
	   # These next lines control how batching works. You should have this enabled
	   # otherwise you could get dropped metrics or poor performance. Batching
	@@ -225,6 +225,12 @@
	   #   # Default template
	   #   "server.*",
	   # ]
	+  templates = [
	+    "fastnetmon.hosts.* app.measurement.cidr.direction.function.resource",
	+    "fastnetmon.networks.* app.measurement.cidr.direction.resource",
	+    "fastnetmon.total.* app.measurement.direction.resource"
	+  ]
	+
	 
	 ###
	 ### [collectd]
	 EOF

	 patch < ./influxdb.conf.patch

The patch was made this way:

	diff -u /etc/influxdb/influxdb.conf.org		\
   			/etc/influxdb/influxdb.conf > influxdb.conf.patch

Next start the service:

	service influxdb start

#### Testing

InfluxDB has a command line interface which is useful for testing:

	influx

`fastnetmon` will create the database _graphite_ as of its configuration file.
You may check the database is created with the `influx` command:

	show databases

Check there is data in the _graphite_ database (requires that fastnetmon can
monitor traffic):

	use graphite
	SHOW TAG KEYS
	exit

If the output does not show the _graphite_ database then restart fastnetmon with

	service fastnetmon restart

If the database does not show up then there is an error in the configuration file.
The section _must_ look like this:

	# Graphite monitoring
	graphite = on
	graphite_host = 127.0.0.1
	graphite_port = 2003
	graphite_prefix = fastnetmon

Please see the document [influxdb and fastnetmon](docs/influxdb-and-fastnetmon.md)
for further information.

For installation and configuration of the _notify script_ ``fnm2db`` see [README](../src/README.md).

TODO:

  - install an openpvn / pfsense server
  - install an [openvpn client](https://openvpn.net/index.php/access-server/docs/admin-guides/182-how-to-connect-to-access-server-with-linux-clients.html)
    and [this how-to](http://www.techrepublic.com/blog/linux-and-open-source/how-to-set-up-a-linux-openvpn-client/) on the _fastnetmon_ host.
  - 

