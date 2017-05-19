#!/usr/bin/perl -w
#
# $Header$
#
#++
# ## Pseudo code for fnm2db
#
# ``fnm2db`` is failsafe, and dies silently if args or input is invalid. It
# is triggered when a DDoS attack is detected by _fastnetmon_.
#
# ## Usage:
#
# ``fnm2db`` client_ip_as_string data_direction pps action
#
#      The rest is read from ``stdin``
#
# Pseudo code:
#
#```bash
#	if [ invalid argument OR argument is unban ]
#	{
#		exit
#	}
#	while read tcpdump from stdin
#	{
#		process some 47 parameters
#	}
#	read configuration file || fail
#	build sql statement
#	if [ connect to database and insert flowspec rules ]
#	{
#		exit OK
#	}
#	else
#	{
#		exit FAIL
# }
#```
#	``fnm2db`` is written in perl, and requires the following packages on Debian GNU/Linux 8:
#
#         apt-get -y install libnet-openssh-compat-perl libnet-ssh2-perl libnet-sftp-foreign-perl
#
#--

# prototypes
sub main(@);
sub logit(@);
sub mydie(@);
sub parse_ip($);
#sub parse_ip6($);
sub parse_v4(@);
sub randstr(@);

#
# Requirements
#
use strict;
use warnings;
use sigtrap qw(die normal-signals);
use File::Temp qw(tempfile);

use Sys::Syslog;		# only needed for logit
use POSIX;				# only needed for logit
use Net::SSH2;			# ssh v2 access to postgres db
use Net::SFTP::Foreign;

#
# Global vars
#
my $usage = "\n$0	client_ip_as_string data_direction pps action\n";

# tcpdump
my ($date, $time, $src_sport, $andgt, $dst_dport, $protocol, $frag, $packets, $length, $icmp_type, $icmp_code, $flags, $str, $ttl, $ratio, $dscp);
my ($src, $sport, $dst, $dport, $ver, $ip, $port);

# fastnetmon specific
my (
	$attack_type, $Initial_attack_power, $Peak_attack_power, $attack_protocol,
	$Total_incoming_traffic, $Attack_direction, $Total_outgoing_traffic,
	$Total_incoming_pps, $Total_outgoing_pps, $Total_incoming_flows,
	$Total_outgoing_flows, $Average_incoming_traffic, $Average_outgoing_traffic,
	$Average_incoming_pps, $Average_outgoing_pps, $Average_incoming_flows,
	$Average_outgoing_flows, $Incoming_ip_fragmented_traffic,
	$Outgoing_ip_fragmented_traffic, $Incoming_ip_fragmented_pps,
	$Outgoing_ip_fragmented_pps, $Incoming_tcp_traffic, $Outgoing_tcp_traffic,
	$Incoming_tcp_pps, $Outgoing_tcp_pps, $Incoming_syn_tcp_traffic,
	$Outgoing_syn_tcp_traffic, $Incoming_syn_tcp_pps, $Outgoing_syn_tcp_pps,
	$Incoming_udp_traffic, $Outgoing_udp_traffic, $Incoming_udp_pps,
	$Outgoing_udp_pps, $Incoming_icmp_traffic, $Outgoing_icmp_traffic,
	$Incoming_icmp_pps, $Outgoing_icmp_pps, $Network_incoming_traffic,
	$Network_outgoing_traffic, $Network_incoming_pps, $Network_outgoing_pps,
	$Average_network_incoming_traffic, $Average_network_outgoing_traffic,
	$Average_network_incoming_pps, $Average_network_outgoing_pps,
	$Average_packet_size_for_incoming_traffic,
	$Average_packet_size_for_outgoing_traffic
	);

$attack_type = "";

my $verbose = 0;

my $logfile = "/opt/i2dps/tmp/" . "logfile.txt";
my $inicfg	= "/opt/i2dps/etc/fnm2db.ini";

#INCLUDE_VERSION_PM

my $show_version = 0;

################################################################################
# MAIN
################################################################################

main();

exit(0);

#
# Subs
#
sub main(@) {

	if ($ARGV[0] eq "-V")
	{
		print "version:       $version\n";
		print "build date:    $build_date\n";
		print "build_git_sha: $build_git_sha\n";
		print "inicfg:        $inicfg\n";
		print "This version only handles IPv4 by design\n";
		exit 0;

	} elsif($ARGV[0] eq "-v")
	{
			$verbose = 1;
			shift @ARGV;
	}

	my $client_ip_as_string	=	$ARGV[0];	# ipv4 address
	my $data_direction		=	$ARGV[1];	# 130.226.136.242 other 0 attack_details
	my $pps					=	$ARGV[2];	# number
	my $action				=	$ARGV[3];	# ban | unban | attack_details

	my $error_string		= "";

	logit ("start: $0 @ARGV");

	if(!defined $client_ip_as_string or !defined $data_direction or !defined $pps or !defined $action)
	{
		logit("usage: $usage");
		exit 0;
	}

	if("$action" eq "unban")
	{
		logit("action unban ignored");
		exit 0;
	}

	# check client_ip_as_string is ipv4
	($ver, $ip, $port) = parse_v4($client_ip_as_string) or mydie "'$client_ip_as_string' not an address\n";

	# read prefs from ini file
	open my $fh, '<', $inicfg or mydie "Could not open '$inicfg' $!";
	my $section;
	my %data;

	while (my $line = <$fh>) {
		if ($line =~ /^\s*#/) {
			next;        # skip comments
		}
		if ($line =~ /^\s*$/) {
			next;    # skip empty lines
		}

		if ($line =~ /^\[(.*)\]\s*$/) {
			$section = $1;
			next;
		}

		if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/) {
			my ($field, $value) = ($1, $2);
			if (not defined $section) {
				logit("Error in '$inicfg': Line outside of seciton '$line'");
				next;
			}
			$data{$section}{$field} = $value;
		}
	}

	my $uuid					= $data{'globals'}{'uuid'};
	my $fastnetmoninstanceid	= $data{'globals'}{'fastnetmoninstanceid'};
	my $administratorid			= $data{'globals'}{'administratorid'};
	my $server					= $data{'update'}{'server'};
	my $user					= $data{'update'}{'user'};
	my $pubkey					= $data{'update'}{'pubkey'};
	my $privkey					= $data{'update'}{'privkey'};
	my $passwd					= $data{'update'}{'passwd'};
	my $sftp_timeout			= $data{'update'}{'sftp_timeout'};

	my $mode					= $data{'globals'}{'mode'};
	my $blocktime				= $data{'globals'}{'blocktime'};
	my $customerid				= $data{'globals'}{'customerid'};
	my $tmp_fh = new File::Temp( UNLINK => 0, TEMPLATE => 'newrules_XXXXXXXX', DIR => '/tmp', SUFFIX => '.dat');

	my $lines = 0;

	my $full_tcpdump_seen = 0;

	close ($fh);

	my $header_printed = 0;

	# process tcpdump
	while (<STDIN>)
	{
		chomp $_;
		next if (/^$/);

		# fastnetmon
		if ($_ =~ /^Attack type:\s*(\w*)$/)									{ $attack_type = $1; };
		if ($_ =~ /^Initial attack power:\s*(\d).*$/)						{ $Initial_attack_power = $1; };
		if ($_ =~ /^Peak attack power:\s*(\d).*$/)							{ $Peak_attack_power = $1; };
		if ($_ =~ /^Attack protocol:\s*(\w*)$/)								{ $attack_protocol = $1; };
		if ($_ =~ /^Total incoming traffic:\s*(\d*).*$/)					{ $Total_incoming_traffic = $1; };
		if ($_ =~ /^Attack direction:\s*(\w*)$/)							{ $Attack_direction = $1; };
		if ($_ =~ /^Total outgoing traffic:\s*(\d).*$/)						{ $Total_outgoing_traffic = $1; };
		if ($_ =~ /^Total incoming pps:\s*(\d).*$/)							{ $Total_incoming_pps = $1; };
		if ($_ =~ /^Total outgoing pps:\s*(\d).*$/)							{ $Total_outgoing_pps = $1; };
		if ($_ =~ /^Total incoming flows:\s*(\d).*$/)						{ $Total_incoming_flows = $1; };
		if ($_ =~ /^Total outgoing flows:\s*(\d).*$/)						{ $Total_outgoing_flows = $1; };
		if ($_ =~ /^Average incoming traffic:\s*(\d).*$/)					{ $Average_incoming_traffic = $1; };
		if ($_ =~ /^Average outgoing traffic:\s*(\d).*$/)					{ $Average_outgoing_traffic = $1; };
		if ($_ =~ /^Average incoming pps:\s*(\d).*$/)						{ $Average_incoming_pps = $1; };
		if ($_ =~ /^Average outgoing pps:\s*(\d).*$/)						{ $Average_outgoing_pps = $1; };
		if ($_ =~ /^Average incoming flows:\s*(\d).*$/)						{ $Average_incoming_flows = $1; };
		if ($_ =~ /^Average outgoing flows:\s*(\d).*$/)						{ $Average_outgoing_flows = $1; };
		if ($_ =~ /^Incoming ip fragmented traffic:\s*(\d).*$/)				{ $Incoming_ip_fragmented_traffic = $1; };
		if ($_ =~ /^Outgoing ip fragmented traffic:\s*(\d).*$/)				{ $Outgoing_ip_fragmented_traffic = $1; };
		if ($_ =~ /^Incoming ip fragmented pps:\s*(\d).*$/)					{ $Incoming_ip_fragmented_pps = $1; };
		if ($_ =~ /^Outgoing ip fragmented pps:\s*(\d).*$/)					{ $Outgoing_ip_fragmented_pps = $1; };
		if ($_ =~ /^Incoming tcp traffic:\s*(\d).*$/)						{ $Incoming_tcp_traffic = $1; };
		if ($_ =~ /^Outgoing tcp traffic:\s*(\d).*$/)						{ $Outgoing_tcp_traffic = $1; };
		if ($_ =~ /^Incoming tcp pps:\s*(\d).*$/)							{ $Incoming_tcp_pps = $1; };
		if ($_ =~ /^Outgoing tcp pps:\s*(\d).*$/)							{ $Outgoing_tcp_pps = $1; };
		if ($_ =~ /^Incoming syn tcp traffic:\s*(\d).*$/)					{ $Incoming_syn_tcp_traffic = $1; };
		if ($_ =~ /^Outgoing syn tcp traffic:\s*(\d).*$/)					{ $Outgoing_syn_tcp_traffic = $1; };
		if ($_ =~ /^Incoming syn tcp pps:\s*(\d).*$/)						{ $Incoming_syn_tcp_pps = $1; };
		if ($_ =~ /^Outgoing syn tcp pps:\s*(\d).*$/)						{ $Outgoing_syn_tcp_pps = $1; };
		if ($_ =~ /^Incoming udp traffic:\s*(\d).*$/)						{ $Incoming_udp_traffic = $1; };
		if ($_ =~ /^Outgoing udp traffic:\s*(\d).*$/)						{ $Outgoing_udp_traffic = $1; };
		if ($_ =~ /^Incoming udp pps:\s*(\d).*$/)							{ $Incoming_udp_pps = $1; };
		if ($_ =~ /^Outgoing udp pps:\s*(\d).*$/)							{ $Outgoing_udp_pps = $1; };
		if ($_ =~ /^Incoming icmp traffic:\s*(\d).*$/)						{ $Incoming_icmp_traffic = $1; };
		if ($_ =~ /^Outgoing icmp traffic:\s*(\d).*$/)						{ $Outgoing_icmp_traffic = $1; };
		if ($_ =~ /^Incoming icmp pps:\s*(\d).*$/)							{ $Incoming_icmp_pps = $1; };
		if ($_ =~ /^Outgoing icmp pps:\s*(\d).*$/)							{ $Outgoing_icmp_pps = $1; };
		if ($_ =~ /^Network incoming traffic:\s*(\d).*$/)					{ $Network_incoming_traffic = $1; };
		if ($_ =~ /^Network outgoing traffic:\s*(\d).*$/)					{ $Network_outgoing_traffic = $1; };
		if ($_ =~ /^Network incoming pps:\s*(\d).*$/)						{ $Network_incoming_pps = $1; };
		if ($_ =~ /^Network outgoing pps:\s*(\d).*$/)						{ $Network_outgoing_pps = $1; };
		if ($_ =~ /^Average network incoming traffic:\s*(\d).*$/)			{ $Average_network_incoming_traffic = $1; };
		if ($_ =~ /^Average network outgoing traffic:\s*(\d).*$/)			{ $Average_network_outgoing_traffic = $1; };
		if ($_ =~ /^Average network incoming pps:\s*(\d).*$/)				{ $Average_network_incoming_pps = $1; };
		if ($_ =~ /^Average network outgoing pps:\s*(\d).*$/)				{ $Average_network_outgoing_pps = $1; };
		if ($_ =~ /^Average packet size for incoming traffic:\s*(\d).*$/)	{ $Average_packet_size_for_incoming_traffic = $1; };
		if ($_ =~ /^Average packet size for outgoing traffic:\s*(\d).*$/)	{ $Average_packet_size_for_outgoing_traffic = $1; };

		if (($header_printed == 0) && ($attack_type ne ''))
		{
			print $tmp_fh "head;fnm;doop;1;$attack_type\n";
			$header_printed = 1;
		}

		# tcpdump: I'm missing a lot of information here

		#FIXME
		if ($_ !~ />.*$client_ip_as_string.*|.*$client_ip_as_string.*<.*bytes.*packets.*/ )
		{
			#logit("line skipped: $_");
		}

		if ($_ =~ /.*>.*$client_ip_as_string.*protocol:.*bytes.*ttl:.*/)
		{
			$full_tcpdump_seen = 1;

			# example output
			# 2016-06-08 16:18:53.299994 130.225.245.210:34859 > 130.226.136.242:5001 protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1
			# 2017-03-27 14:47:43.199756   21.30.184.209:14363 > 130.226.136.242:80   protocol: tcp flags: syn frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
			# 2017-03-27 15:32:03.071697   60.28.184.234:0     > 130.226.136.242:0    protocol: icmp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1

			# re-init
			$dst = $src = $protocol = $sport = $dport = $sport = $icmp_type = $icmp_code = $flags = $length = $ttl = $dscp = "";

			if ($_ =~ /protocol:.*icmp/)
			{
				($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $frag, $str, $packets, $str, $length, $str, $str, $ttl, $str, $str, $ratio) =
				split(' ', $_);

			} elsif ($_ =~ /protocol:.*tcp/)
			{
				($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $flags, $str, $frag, $str, $packets, $str, $length, $str, $str, $ttl, $str, $str, $ratio) = 
				split(' ', $_);

			} elsif ($_ =~ /protocol:.*udp/)
			{
				($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $frag, $str, $packets, $str, $length, $str, $str, $ttl, $str, $str, $ratio) = 
				split(' ', $_);
			} else
			{
				print "unknown IP protocol\n"; next;
			}

			($src, $sport) = split(':', $src_sport);
			($dst, $dport) = split(':', $dst_dport);

			# Rule header: type;vesion;attack_info;
			# type: fnm | ...
			# version: 1
			# attack_info: icmp_flood | syn_flood | udp_flood | unknown | ...
			# Rules: networkid,uuid,administratorid,blocktime,date,time,1,2,3,4,5,6,7,8,9,10,11,12
			# Type 1 - Destination Prefix
			# Type 2 - Source Prefix
			# Type 3 - IP Protocol
			# Type 4 – Source or Destination Port
			# Type 5 – Destination Port
			# Type 6 - Source Port
			# Type 7 – ICMP Type
			# Type 8 – ICMP Code
			# Type 9 - TCP flags
			# Type 10 - Packet length
			# Type 11 – DSCP
			# Type 12 - Fragment Encoding

			# Fail-safe: only do something if everything seems ok
			# silently drop lines which does not have all info
			next if (!defined $src or !defined $sport or !defined $dst or !defined $dport or !defined $protocol or !defined $frag or !defined $packets or !defined $length or !defined $ttl or !defined $ratio or !defined $pps);

			# skip if not an address or portnumber (icmp has port 0 in output)
			($ver, $ip, $port) = parse_v4($src, $sport) or next;
			($ver, $ip, $port) = parse_v4($dst, $dport) or next;

			# skip if not numbers
			($ttl	=~ /[0-9]*/) or next;
			($ratio	=~ /[0-9]*/) or next;
			($pps	=~ /[0-9]*/) or next;

			# Clean up and assign default values
			# https://www.grc.com/port_0.htm :
			# "Port Zero" does not officially exist. It is defined as an invalid port
			# number. But valid Internet packets can be formed and sent "over the wire" to
			# and from "port 0" just as with any other ports. This will go into a database
			# so use 'null' for non-set values

			if ($sport			eq "")		{ $sport		= "null"; }
			if ($dport			eq "")		{ $dport		= "null"; }
			if ($icmp_type		eq "")		{ $icmp_type	= "null"; }
			if ($icmp_code		eq "")		{ $icmp_code	= "null"; }
			if ($flags			eq "")		{ $flags		= "null"; }
			if ($length			eq "")		{ $length		= "null"; }
			if ($ttl			eq "")		{ $ttl			= "null"; }
			if ($dscp			eq "")		{ $dscp			= "null"; }
			# https://www.wains.be/pub/networking/tcpdump_advanced_filters.txt
			if ($frag			eq "" || $frag == 0)		{ $frag			= "null"; }
			if ($attack_type	eq "")		{ $attack_type	= "null"; }

			
			# icmp has no ports so set it to null
			if ($protocol		eq "icmp")
			{
				$sport = $dport = "null";
			}

#			print<<EOF;
#
#customerid            $customerid
#uuid:                 $uuid
#fastnetmoninstanceid: $fastnetmoninstanceid
#administratorid       $administratorid
#blocktime:            $blocktime
#dst:                  $dst
#src:                  $src
#protocol:             $protocol
#sport:                $sport
#dport:                $dport
#port:                 $dport
#icmp_type:            $icmp_type
#icmp_code:            $icmp_code
#flags:                $flags
#length:               $length
#ttl:                  $ttl
#dscp:                 $dscp
#frag:                 $frag
#
#EOF

			$lines ++;
			print $tmp_fh "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$protocol;$sport;$dport;$dport;$icmp_type;$icmp_code;$flags;$length;$ttl;$dscp;$frag\n";
		}
		elsif($_ =~ /.*$client_ip_as_string.*<.*bytes.*packets.*/)
		{
			if (($full_tcpdump_seen == 0) && ($attack_type !~ m/.*_flood/))		# reduced TCP dump prepends the full -- and they are different
			{
				# example output:
				# 130.226.136.242:80 < 130.226.161.82:32768 74 bytes 1 packets
				# 130.226.136.242:80 < 130.226.161.82:42622 355 bytes 4 packets
				# So we only have $dst, $dport, $src and $sport (random) (size and packets are for the connection) and the $attack_protocol / $protocol

				($dst_dport, $str, $src_sport, $str, $str, $str) =  split(' ', $_);

				($src, $sport) = split(':', $src_sport);
				($dst, $dport) = split(':', $dst_dport);

				$icmp_type = $icmp_code = $flags = $length = $ttl = $dscp = $frag = "null";
				$protocol = $attack_protocol;
				$lines ++;
				print $tmp_fh "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$protocol;$sport;$dport;$dport;$icmp_type;$icmp_code;$flags;$length;$ttl;$dscp;$frag\n";
			}
			else
			{
				# logit("full_tcpdump_seen == $full_tcpdump_seen, unused input: $_");
			}
		}
		else
		{
			# non-tcpdump line ignored
			#logit("unused input: $_");
		}
	}
	print $tmp_fh "last-line\n";
	close($tmp_fh)||mydie "close $tmp_fh failed: $!";
	if ($full_tcpdump_seen == 1)
	{
		logit("using full TCP dump: printed new rules with $lines lines to $tmp_fh ... ");
	}
	else
	{
		logit("using no TCP dump: printed new rules with $lines lines to $tmp_fh ... ");
	}

	if ($lines != 0)
	{
		my $sftp=Net::SFTP::Foreign->new(
			host => $server,
			user => $user,
			timeout => $sftp_timeout,
			autodie => 0,
			more => [
				"-oIdentityFile=$privkey",
				'-oPreferredAuthentications=publickey',
				], );

		if ($sftp->error ne 0)
		{
			logit("Unable to establish SFTP connection: $sftp->status");
			$sftp->disconnect;
		}
		else
		{
			my $now = time();
			my $remote_file = "/upload/newrules-${uuid}-${now}-" . randstr(8, 'a'..'z', 0..9) . ".dat";
			logit("uploading $tmp_fh as $remote_file");
			$sftp->put("$tmp_fh", "$remote_file");
			if ($sftp->error ne 0)
			{
				$error_string = $sftp->error;
				logit("error:  put $user\@$server:'$remote_file' failed: $error_string");
				$error_string = $sftp->status;
				logit("status: put $user\@$server:'$remote_file' failed: $error_string");
				logit("leaving local file '$tmp_fh'");
			}
			else
			{
				logit("upload ok removing local file '$tmp_fh'");
				unlink($tmp_fh);
			}
			$sftp->disconnect;
		}
	}
	else
	{
		logit("only $lines of rules, not sending rules");
		unlink($tmp_fh);
	}
	exit(0);
}

sub parse_v4(@) {
	my ($ip, $port) = @_;
	my @quad = split(/\./, $ip);
 
	return unless @quad == 4;
	{ return if (join('.', @quad) !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) }	# prevent non digits from messing up next line
	for (@quad) { return if ($_ > 255) }
 
	if (!length $port) { $port = -1 }
	elsif ($port =~ /^(\d+)$/) { $port = $1 }
	else { return }
 
	my $h = join '' => map(sprintf("%02x", $_), @quad);
	return $h, $port
}
 
sub parse_v6($) {
	my $ip = shift;
	my $omits;
 
	return unless $ip =~ /^[\da-f:.]+$/i; # invalid char
 
	$ip =~ s/^:/0:/;
	$omits = 1 if $ip =~ s/::/:z:/g;
	return if $ip =~ /z.*z/;	# multiple omits illegal
 
	my $v4 = '';
	my $len = 8;
 
	if ($ip =~ s/:((?:\d+\.){3}\d+)$//) {
		# hybrid 4/6 ip
		($v4) = parse_v4($1)	or return;
		$len -= 2;
 
	}
	# what's left should be v6 only
	return unless $ip =~ /^[:a-fz\d]+$/i;
 
	my @h = split(/:/, $ip);
	return if @h + $omits > $len;	# too many segments
 
	@h = map( $_ eq 'z' ? (0) x ($len - @h + 1) : ($_), @h);
	return join('' => map(sprintf("%04x", hex($_)), @h)).$v4;
}
 
sub parse_ip($) {
	my $str = shift;
	$str =~ s/^\s*//;
	$str =~ s/\s*$//;
 
	if ($str =~ s/^((?:\d+\.)+\d+)(?::(\d+))?$//) {
		return 'v4', parse_v4($1, $2);
	}
 
	my ($ip, $port);
	if ($str =~ /^\[(.*?)\]:(\d+)$/) {
		$port = $2;
		$ip = parse_v6($1);
	} else {
		$port = -1;
		$ip = parse_v6($str);
	}
 
	return unless $ip;
	return 'v6', $ip, $port;
}

sub logit(@)
{
    my $msg = join(' ', @_);
    syslog("user|err", "$msg");
    my $now = strftime "%H:%M:%S (%Y/%m/%d)", localtime(time);
    print STDOUT "$now: $msg\n" if ($verbose);

    open(LOGFILE, ">>$logfile");
    print LOGFILE "$now: $msg\n";
    close(LOGFILE);
}

sub mydie(@)
{
	logit(@_);
	exit(0);
}

sub randstr(@) { join'', @_[ map{ rand @_ } 1 .. shift ] }


__DATA__

   Copyright 2017, DeiC, Niels Thomas Haugård

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
