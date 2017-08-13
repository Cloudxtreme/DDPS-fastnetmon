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
use strict;
use warnings;
use 5.14.0;             # say, switch etc.
use sigtrap qw(die normal-signals);
use DBI;                # database

use Sys::Syslog;        # only needed for logit
use POSIX;              # only needed for logit
use Getopt::Long qw(:config no_ignore_case);
use Net::SSH2;          # ssh v2 access to postgres db
use List::MoreUtils qw(uniq);
use Proc::Daemon;
use Socket qw( inet_aton );
use NetAddr::IP;
use Path::Tiny;
use File::stat;
use File::Temp qw(tempfile);

my ($action,$customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag   );

exit 0;

#
# Documentation and  standard disclaimar
#
# Copyright (C) 2001 Niels Thomas Haugård
# UNI-C
# http://www.uni-c.dk/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#++
# NAME
#	template.pl 1
# SUMMARY
#	Short description
# PACKAGE
#	file archive exercicer
# SYNOPSIS
#	template.pl options
# DESCRIPTION
#	\fItemplate.pl\fR is used for ...
#	Bla bla.
#	More bla bla.
# OPTIONS
# .IP o
#	I'm a bullet.
# .IP o
#	So am I.
# COMMANDS
#	
# SEE ALSO
#	
# DIAGNOSTICS
#	Whatever.
# BUGS
#	Probably. Please report them to the call-desk or the author.
# VERSION
#      $Date$
# .br
#      $Revision$
# .br
#      $Source$
# .br
#      $State$
# HISTORY
#	$Log$
# AUTHOR(S)
#	Niels Thomas Haugård
# .br
#	E-mail: thomas@haugaard.net
# .br
#	UNI-C
# .br
#	DTU, Building 304
# .br
#	DK-2800 Kgs. Lyngby
# .br
#	Denmark
#--
