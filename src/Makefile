# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
#TARGETHOST      = root@172.22.89.2
TARGETHOST      = root@fastnetmon2.deic.dk
#TARGETHOST      = sysadm@ddps.ssi.i2.dk
#->TARGETHOST      = sysadm@172.16.201.113
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR       = /opt/i2dps/src/

# Path to local and remote rsync
RRSYNC          = /usr/bin/rsync
LRSYNC          = /usr/bin/rsync
# Path to local ssh
SSH             = /usr/bin/ssh
# Arguments to rsync, EXCLUDE_FILE will be appended
EXCLUDE_FILE    = rsync_exclude.txt
RSYNC_ARGS      = -avzH --exclude-from
SSH_ARGS        =  -Tq -o LogLevel=error

# This directory (source)
SRCDIR          = .

# Project directory -- see project_template
PROJDIR         = ../../DDPS-fastetmon

#:REMOTE-INFO-END
#
# Makefile for /opt/i2dps/src
#
# NTHA 2016
#
# vim: set nonu ts=4 sw=4 tw=0:
#
PREFIX		= /opt/i2dps
BINDIR		= $(PREFIX)/bin
TMPDIR		= $(PREFIX)/tmp
LOGDIR		= $(PREFIX)/log
ETCDIR		= $(PREFIX)/etc
INITDIR		= $(PREFIX)/etc/init.d/

SRCDIR		= $(PREFIX)/src

iniparser 	= iniparser
libini		= $(iniparser)/src

sysinit		= /etc/init.d/fnm2db

INSTALL		= $(PREFIX)/src/install-sh
SRCTOMAN	= $(PREFIX)/src/srctoman

#GID			= sysadm
#UID			= sysadm
GID			= root
UID			= root

RC			= fnm2dbrc
CFILES		= i2dps.c concat.c strsplit.c daemonize.c version.c
HFILES		= i2dps.h version.h license.h
PRODINI		= fnm2db.ini
TESTINI		= test.ini

# apt-get -y install libnet-openssh-compat-perl libnet-openssh-compat-perl libnet-ssh2-perl
# dpkg-query -L ... select ramdon file
libnet-openssh-compat-perl	= /usr/share/perl5/Net/OpenSSH/Compat.pm
libnet-openssh-compat-perl	= /usr/share/perl5/Net/OpenSSH/Compat/SSH2/Constants.pm
libnet-ssh2-perl			= /usr/lib/x86_64-linux-gnu/perl5/5.20/Net/SSH2.pm

debdepnd					= $(libnet-openssh-compat-perl) $(libnet-openssh-compat-perl) $(libnet-ssh2-perl)

PUBKEY		= $(ETCDIR)/ssh/id_ed25519.pub
PRIKEY		= $(ETCDIR)/ssh/id_ed25519

prog		= fnm2db
target		= $(BINDIR)/fnm2db

initrc		= $(INITDIR)/$(RC)
dbini		= $(ETCDIR)/$(PRODINI)

# for comment in ssh keys only
uuid := $(shell ifconfig |sed '/HWaddr/!d; s/.*HWaddr //; s/[[:blank:]]//g; q')
fqdn := $(shell hostname -f )

default:	$(prog) $(debdepnd)

# perl-version - mimic c version: add version information, set mode and print version. Do not install
$(prog):	hostcheck fnm2db.pl version.pm
			$(RM) $(prog)
			@sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  fnm2db.pl > fnm2db
			@chmod 555 fnm2db
			./$(prog) -V

install:	hostcheck $(target) $(initrc) $(dbini) $(sysinit) $(PUBKEY)
			$(MAKE) dirs

run:		$(target) $(initrc) $(dbini)
			$(target) -v -s 2

test:		$(prog) $(TESTINI)
			$(SRCDIR)/$(prog) -V
			( sleep 10; touch `sed '/shutdown/!d; s/.*=[\t ]*//' test.ini` ) &
			$(SRCDIR)/$(prog) -v -s 2 -f $(TESTINI)

$(PUBKEY):
			$(MAKE) dirs
			ssh-keygen -C "root@$(uuid)-$(fqdn)" -N '' -t ED25519 -b 16384 -f $(PRIKEY)

hostcheck:
			@if [ "`hostname -f`" != "`echo $(TARGETHOST) | sed 's/.*@//'`" ]; then					\
				echo "make should not be executed on the wrong host ... ";							\
				echo "hostname = `hostname` expected `echo $(TARGETHOST) | sed 's/.*@//'`, bye ";	\
				exit 1;																				\
			fi
			chmod 555 $(INSTALL) $(SRCTOMAN)

# Unused article on how to Write Linux Init Scripts Based on LSB Init Standard:
# http://www.thegeekstuff.com/2012/03/lsbinit-script/
$(sysinit): $(RC)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(RC) /etc/init.d
			update-rc.d fnm2dbrc defaults
			systemctl enable fnm2dbrc
			systemctl start fnm2dbrc
			systemctl status fnm2dbrc

dirs:
			mkdir -p $(PREFIX)/bin $(PREFIX)/tmp $(PREFIX)/log $(PREFIX)/src $(PREFIX)/etc/init.d $(PREFIX)/etc/ssh/
			chown -R $(UID):$(GID) $(PREFIX)
			chmod 700 $(PREFIX)/etc/ssh/

$(initrc):	$(RC)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(RC) $(INITDIR)

$(target):	$(prog)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(prog) $(BINDIR)

$(dbini):	$(PRODINI)
			$(INSTALL) -c -m 0755 -o $(UID) -g $(GID) $(PRODINI) $(ETCDIR)

#
# Dependencies
#
install-modules:
	apt-get -y install libnet-openssh-compat-perl libnet-openssh-compat-perl libnet-ssh2-perl libnet-sftp-foreign-perl

$(libnet-openssh-compat-perl-compat.pm):
	apt-get -y install libnet-openssh-compat-perl

$(libnet-openssh-compat-perl-compat.pm):
	apt-get -y install libnet-openssh-compat-perl

$(libnet-ssh2-perl-ssh2.pm):
	t-get -y install libnet-ssh2-perl

.SUFFIXES:

.SILENT:
