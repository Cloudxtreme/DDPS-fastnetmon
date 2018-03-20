###
### Main configuration params
###
### DDPSVERSION: _DDPSVERSION_HERE_
### Logging configuration

# enable this option if you want to send logs to local syslog facility
logging:local_syslog_logging = ${local_syslog_logging}

# enable this option if you want to send logs to a remote syslog server via UDP
logging:remote_syslog_logging = ${remote_syslog_logging}

# specify a custom server and port for remote logging
logging:remote_syslog_server = ${remote_syslog_server}
logging:remote_syslog_port = ${remote_syslog_port}

# Enable/Disable any actions in case of attack
enable_ban = ${enable_ban}

# disable processing for certain direction of traffic
process_incoming_traffic = ${process_incoming_traffic}
process_outgoing_traffic = ${process_outgoing_traffic}

# How many packets will be collected from attack traffic
ban_details_records_count = ${ban_details_records_count}

# How long (in seconds) we should keep an IP in blocked state
# If you set 0 here it completely disables unban capability
ban_time = ${ban_time}

# Check if the attack is still active, before triggering an unban callback with this option
# If the attack is still active, check each run of the unban watchdog
unban_only_if_attack_finished = ${unban_only_if_attack_finished}

# enable per subnet speed meters
# For each subnet, list track speed in bps and pps for both directions
enable_subnet_counters = ${enable_subnet_counters}

# list of all your networks in CIDR format
networks_list_path = ${networks_list_path}

# list networks in CIDR format which will be not monitored for attacks
white_list_path = ${white_list_path}

# redraw period for client's screen
check_period = ${check_period}

# Connection tracking is very useful for attack detection because it provides huge amounts of information,
# but it's very CPU intensive and not recommended in big networks
enable_connection_tracking = ${enable_connection_tracking}

# Different approaches to attack detection
ban_for_pps = ${ban_for_pps}
ban_for_bandwidth = ${ban_for_bandwidth}
ban_for_flows = ${ban_for_flows}

# Limits for Dos/DDoS attacks
threshold_pps = ${threshold_pps}
threshold_mbps = ${threshold_mbps}
threshold_flows = ${threshold_flows}

# Per protocol attack thresholds
# We don't implement per protocol flow limits, sorry :(
# These limits should be smaller than global pps/mbps limits

threshold_tcp_mbps = ${threshold_tcp_mbps}
threshold_udp_mbps = ${threshold_udp_mbps}
threshold_icmp_mbps = ${threshold_icmp_mbps}

threshold_tcp_pps = ${threshold_tcp_pps}
threshold_udp_pps = ${threshold_udp_pps}
threshold_icmp_pps = ${threshold_icmp_pps}

ban_for_tcp_bandwidth = ${ban_for_tcp_bandwidth}
ban_for_udp_bandwidth = ${ban_for_udp_bandwidth}
ban_for_icmp_bandwidth = ${ban_for_icmp_bandwidth}

ban_for_tcp_pps = ${ban_for_tcp_pps}
ban_for_udp_pps = ${ban_for_udp_pps}
ban_for_icmp_pps = ${ban_for_icmp_pps}

###
### Traffic capture methods
###

# PF_RING traffic capture, fast enough but the wirespeed version needs a paid license
mirror = ${mirror}

# Port mirroring sample rate
pfring_sampling_ratio = ${pfring_sampling_ratio}

# Netmap traffic capture (very fast but needs patched drivers)
mirror_netmap = ${mirror_netmap}

# SnabbSwitch traffic capture
mirror_snabbswitch = ${mirror_snabbswitch}

# AF_PACKET capture engine
# Please use it only with modern Linux kernels (3.6 and more)
# And please install birq for irq ditribution over cores
mirror_afpacket = ${mirror_afpacket}

# use PCI-e addresses here instead of OS device names. You can find them in "lspci" output
# interfaces_snabbswitch = ${interface_snabbswitch}

# Port mirroring sampling ratio
netmap_sampling_ratio = ${netmap_sampling_ratio}

# This option should be enabled if you are using Juniper with mirroring of the first X bytes of packet: maximum-packet-length 110;
netmap_read_packet_length_from_ip_header = ${netmap_read_packet_length_from_ip_header}

# Pcap mode, very slow and thus not suitable for production
pcap = ${pcap}
# Netflow capture method with v5, v9 and IPFIX support
netflow = ${netflow}
# sFLOW capture suitable for switches
sflow = ${sflow}

# PF_RING configuration
# If you have a license for PF_RING ZC, enable this mode and it might achieve wire speed for 10GE
enable_pf_ring_zc_mode = ${enable_pf_ring_zc_mode}

# Configuration for netmap, mirror, pcap modes
# For pcap and PF_RING we could specify "any"
# For netmap and PF_RING we could specify multiple interfaces separated by comma
interfaces = ${interfaces}

# We use average values for traffic speed to certain IP and we calculate average over this time slice
average_calculation_time = ${average_calculation_time}

# We use average values for traffic speed for subnet and we calculate average over this time slice
average_calculation_time_for_subnets = ${average_calculation_time_for_subnets}

# Netflow configuration

# it's possible to specify multiple ports here, using commas as delimiter
netflow_port = ${netflow_port}
netflow_host = ${netflow_host}

# To bind to all interfaces for all protocols:       not possible yet
# To bind to all interfaces for a specific protocol: ::  or 0.0.0.0
# To bind to localhost for a specific protocol:      ::1 or 127.0.0.1

# Netflow v9 and IPFIX agents use different and very complex approaches for notifying about sample ratio
# Here you could specify a sampling ratio for all this agents
# For NetFLOW v5 we extract sampling ratio from packets directely and this option not used
netflow_sampling_ratio = ${netflow_sampling_ratio}

# In some cases with NetFlow we could get huge bursts related to aggregated data nature
# We could try to get smoother data with this option, i.e. we will divide counters on collection interval time
netflow_divide_counters_on_interval_length = ${netflow_divide_counters_on_interval_length}

# Process each netflow packet with LUA
# This option is not default and you need build it additionally
# netflow_lua_hooks_path = /usr/src/fastnetmon/src/netflow_hooks.lua

# sFLOW configuration

# It's possible to specify multiple ports here, using commas as delimiter
sflow_port = ${sflow_port}
# sflow_port = 6343,6344
sflow_host = ${sflow_host}

# process each sFLOW packet with LUA
# This option is not default and you need build it additionally
# sflow_lua_hooks_path = /usr/src/fastnetmon/src/sflow_hooks.lua

###
### Actions when attack detected
###

# This script executed for ban, unban and attack detail collection
# notify_script_path = /usr/local/bin/notify_about_attack.sh
notify_script_path = ${notify_script_path}

# pass attack details to notify_script via stdin
# Pass details only in case of "ban" call
# No details will be passed for "unban" call
notify_script_pass_details = ${notify_script_pass_details}

# collect a full dump of the attack with full payload in pcap compatible format
collect_attack_pcap_dumps = ${collect_attack_pcap_dumps}

# Execute Deep Packet Inspection on captured PCAP packets
process_pcap_attack_dumps_with_dpi = ${process_pcap_attack_dumps_with_dpi}

# Save attack details to Redis
redis_enabled = ${redis_enabled}

# Redis configuration
redis_port = ${redis_port}
redis_host = ${redis_host}

# specify a custom prefix here
redis_prefix = ${redis_prefix}

# We could store attack information to MongoDB
mongodb_enabled = ${mongodb_enabled}
mongodb_host = ${mongodb_host}
mongodb_port = ${mongodb_port}
mongodb_database_name = ${mongodb_database_name}

# If you are using PF_RING non ZC version you could block traffic on host with hardware filters
# Please be aware! We can not remove blocks with this action plugin
pfring_hardware_filters_enabled = ${pfring_hardware_filters_enabled}

# announce blocked IPs with BGP protocol with ExaBGP
exabgp = ${exabgp}
exabgp_command_pipe = ${exabgp_command_pipe}
exabgp_community = ${exabgp_community}

# specify multiple communities with this syntax:
# exabgp_community = [65001:666 65001:777]

# specify different communities for host and subnet announces
# exabgp_community_subnet = 65001:667
# exabgp_community_host = 65001:668

exabgp_next_hop = ${exabgp_next_hop}

# In complex cases you could have both options enabled and announce host and subnet simultaneously

# Announce /32 host itself with BGP
exabgp_announce_host = ${exabgp_announce_host}

# Announce origin subnet of IP address instead IP itself
exabgp_announce_whole_subnet = ${exabgp_announce_whole_subnet}

# Announce Flow Spec rules when we could detect certain attack type
# Please we aware! Flow Spec announce triggered when we collect some details about attack,
# i.e. when we call attack_details script
# Please disable exabgp_announce_host and exabgp_announce_whole_subnet if you want to use this feature
# Please use ExaBGP v4 only (Git version), for more details: https://github.com/FastVPSEestiOu/fastnetmon/blob/master/docs/BGP_FLOW_SPEC.md
exabgp_flow_spec_announces = ${exabgp_flow_spec_announces}

# GoBGP intergation
gobgp = ${gobgp}
gobgp_next_hop = ${gobgp_next_hop}
gobgp_announce_host = ${gobgp_announce_host}
gobgp_announce_whole_subnet = ${gobgp_announce_whole_subnet}

# Graphite monitoring
# InfluxDB is also supported, please check our reference:
# https://github.com/FastVPSEestiOu/fastnetmon/blob/master/docs/INFLUXDB_INTEGRATION.md
graphite = ${graphite}
graphite_host = ${graphite_host}
graphite_port = ${graphite_port}

# Default namespace for Graphite data
graphite_prefix = ${graphite_prefix}

# Add local IP addresses and aliases to monitoring list
# Works only for Linux
#monitor_local_ip_addresses = on
monitor_local_ip_addresses = ${monitor_local_ip_addresses}

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
pid_path = ${pid_path}

# Path to file where we store information for fastnetmon_client
cli_stats_file_path = ${cli_stats_file_path}

# Enable gRPC api (required for fastnetmon_api_client tool)
enable_api = ${enable_api}

###
### Client configuration
###

# Field used for sorting in client, valid values are: packets, bytes or flows
sort_parameter = ${sort_parameter}
# How much IPs will be listed for incoming and outgoing channel eaters
max_ips_in_list = ${max_ips_in_list}
