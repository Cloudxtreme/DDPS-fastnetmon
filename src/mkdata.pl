#!/usr/bin/perl -w
#
# $Header$
#

#
# Requirements
#
use English;
use FileHandle;
use Getopt::Long;
use Digest::MD5;
use sigtrap qw(die normal-signals);
use POSIX qw(strftime);


#
# Global vars
#
my $loop = 10;
my $minimum = 0;
my $maximum = 2;
my $sleep = 0;
my $usage = "$0	-loop|n loop\n";

#
# Subs
#

# purpose     :
# arguments   :
# return value:
# see also    :

################################################################################
# MAIN
################################################################################
#
# Parse and process options
#
if (!GetOptions('loop|s=s'		=> \$loop
	)) {
	die "$usage";
}

my $args = "130.226.136.242 incoming 1639 attack_details";

for (my $i=0; $i < $loop; $i++) {
#	$sleep = int($minimum + rand($maximum - $minimum));
#	select(undef,undef,undef,$sleep);

	my ${port} = int(2000 + rand(65000 - 2000));

	my ${date} = strftime "%Y-%m-%d %H:%M:%S", localtime;

	print "$i - $sleep: port\n";
	print "$args\n";
	print "${date}\n";

my $info = <<END_MESSAGE;

IP: 130.226.136.242
Attack type: udp_flood
Initial attack power: 1639 packets per second
Peak attack power: 1639 packets per second
Attack direction: incoming
Attack protocol: udp
Total incoming traffic: 18 mbps
Total outgoing traffic: 0 mbps
Total incoming pps: 1639 packets per second
Total outgoing pps: 0 packets per second
Total incoming flows: 0 flows per second
Total outgoing flows: 0 flows per second
Average incoming traffic: 18 mbps
Average outgoing traffic: 0 mbps
Average incoming pps: 1639 packets per second
Average outgoing pps: 0 packets per second
Average incoming flows: 0 flows per second
Average outgoing flows: 0 flows per second
Incoming ip fragmented traffic: 0 mbps
Outgoing ip fragmented traffic: 0 mbps
Incoming ip fragmented pps: 0 packets per second
Outgoing ip fragmented pps: 0 packets per second
Incoming tcp traffic: 0 mbps
Outgoing tcp traffic: 0 mbps
Incoming tcp pps: 0 packets per second
Outgoing tcp pps: 0 packets per second
Incoming syn tcp traffic: 0 mbps
Outgoing syn tcp traffic: 0 mbps
Incoming syn tcp pps: 0 packets per second
Outgoing syn tcp pps: 0 packets per second
Incoming udp traffic: 18 mbps
Outgoing udp traffic: 0 mbps
Incoming udp pps: 1639 packets per second
Outgoing udp pps: 0 packets per second
Incoming icmp traffic: 0 mbps
Outgoing icmp traffic: 0 mbps
Incoming icmp pps: 0 packets per second
Outgoing icmp pps: 0 packets per second

Network: 130.226.136.240/28
Network incoming traffic: 104 mbps
Network outgoing traffic: 0 mbps
Network incoming pps: 9044 packets per second
Network outgoing pps: 0 packets per second
Average network incoming traffic: 5 mbps
Average network outgoing traffic: 0 mbps
Average network incoming pps: 441 packets per second
Average network outgoing pps: 0 packets per second
Average packet size for incoming traffic: 1513.1 bytes 
Average packet size for outgoing traffic: 0.0 bytes 

${date}.294629 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294631 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294633 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294635 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294742 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294744 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294746 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294748 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294750 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294752 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294754 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294756 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294758 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294760 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294867 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294869 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294871 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  
${date}.294873 130.225.245.210:34856 > 130.226.136.242:${port} protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1  

DPI

[00:1D:70:83:40:C0 -> 80:71:1F:C4:78:01] [IPv4][130.225.245.210:34856 -> 130.226.136.242:${port}] [l3_proto=UDP][ip_fragmented: 0][hash=0][tos=0][tcp_seq_num=0] [caplen=1500][len=1512][parsed_header_len=0][eth_offset=0][l3_offset=14][l4_offset=34][payload_offset=42]
 protocol: BitTorrent master_protocol: Unknown

END_MESSAGE

	my $pid = open(WRITEME, "| /opt/i2dps/bin/fnm2db ${args}") or die "Couldn't fork: $!\n";
	print "pid = $pid - /opt/i2dps/bin/fnm2db ${args}\n";
	print WRITEME "$info\n";
	close(WRITEME)                              or die "Couldn't close: $!\n";

}

exit 0;

