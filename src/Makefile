# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
#TARGETHOST      = root@172.22.89.2
TARGETHOST      = root@fnm-dev.deic.dk
#TARGETHOST      = sysadm@ddps.ssi.i2.dk
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR       = /opt/i2dps/src/
UPLOADDIR       = src-i2dps

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
# Makefile for i2dps
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

#sysinit		= /etc/init.d/fnm2db

INSTALL		= ./install-sh
SRCTOMAN	= ./srctoman

GID			= root
UID			= root

RC			= fnm2dbrc
CFILES		= i2dps.c concat.c strsplit.c daemonize.c version.c
HFILES		= i2dps.h version.h license.h
PRODINI		= fnm2db.ini
TESTINI		= test.ini

# required perl modules will be installed by default target (see install_perl_modules)
pkgs		= libnet-openssh-compat-perl libnet-openssh-compat-perl libnet-ssh2-perl libnet-sftp-foreign-perl

PUBKEY		= $(ETCDIR)/ssh/id_ed25519.pub
PRIKEY		= $(ETCDIR)/ssh/id_ed25519

prog		= fnm2db
target		= $(BINDIR)/fnm2db

initrc		= $(INITDIR)/$(RC)
dbini		= $(ETCDIR)/$(PRODINI)

# for comment in ssh keys (see $(PUBKEY):)
uuid := $(shell ifconfig |sed '/HWaddr/!d; s/.*HWaddr //; s/[[:blank:]]//g; q')
fqdn := $(shell hostname -f )

default:	$(prog) $(debdepnd)

$(prog):	hostcheck fnm2db.pl version.pm install_perl_modules
			$(RM) $(prog)
			@sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  fnm2db.pl > fnm2db
			@chmod 555 fnm2db
			./$(prog) -V

install:	hostcheck $(dirs) $(target) $(initrc) $(dbini) $(PUBKEY)   #$(sysinit) 

runinstall: hostcheck
			bash ./setup.sh

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

dirs:
			mkdir -p $(PREFIX)/bin $(PREFIX)/tmp $(PREFIX)/log $(PREFIX)/src $(PREFIX)/etc/init.d $(PREFIX)/etc/ssh/
			chown -R $(UID):$(GID) $(PREFIX)
			chmod 700 $(PREFIX)/etc/ssh/

$(initrc):	$(RC)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(RC) $(INITDIR)

cron:
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) watchdog.sh $(BINDIR)
			echo '*/5 * * * * root [ -x /opt/i2dps/bin/watchdog.sh ] && /opt/i2dps/bin/watchdog.sh' > /etc/cron.d/watchdog
			chmod 0640 /etc/cron.d/watchdog
			service cron restart

$(target):	$(prog)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(prog) $(BINDIR)/

$(dbini):	$(PRODINI)
			if [ -e ${dbini} ]; then													\
				echo "existing ${dbini} preserved";										\
				echo "not removing existing ${dbini}";									\
				echo "new db.ini installed as ${dbini}.new";							\
				sudo /bin/cp ${PRODINI} ${dbini}.new;									\
			else																		\
				sudo $(INSTALL) -c -m 0755 -o $(UID) -g $(GID) $(PRODINI) $(ETCDIR)/;	\
			fi

print:
	for FILE in fnm2db.pl; do								\
			BFILE=`basename $$FILE` ;						\
			echo $$BFILE ;									\
			sed '/#++/,/^#--/d' < $$BFILE |					\
				a2ps -1 --border=no --font-size 5 --stdin="$$BFILE"						\
					--right-footer="" --left-footer="" --footer="" --no-header --line-numbers=5 -o  - |	\
				pstopdf -i -o /tmp/$$BFILE.lst.pdf;			\
				file /tmp/$$BFILE.lst.pdf;					\
		done

# Install required perl modules from $(pkgs)
install_perl_modules:
	for P in $(pkgs);							\
	do											\
		dpkg -s "$$P" >/dev/null 2>&1;			\
		case $$? in								\
			0) : 								\
			;;									\
			1) sudo apt-get -y install $$P		\
			;;									\
		esac									\
	done

# debian project
dpkg:
	echo "building debian project for ${package} (sudo required at least on my mac ....) "
	sudo sh mk-deb.sh

# FreeBSD project / production
pkg:
	echo "building FreeBSD project for ${package} - myst be done on a FreeBSD host ... "
	sh mk-freebsd.sh

.SUFFIXES:

.SILENT:
