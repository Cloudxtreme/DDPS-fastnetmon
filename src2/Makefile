# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
TARGETHOST      = root@ddps-dev
#TARGETHOST      = uninth@ddps.deic.dk
#TARGETHOST      = uninth@ww1.ddps.deic.dk
#TARGETHOST      = uninth@ww2.ddps.deic.dk
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR       = mkiso-src/

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
PROJDIR         = ../../DDPS-db2dps

#:REMOTE-INFO-END
#
# NTHA 2016
#
PREFIX		= /opt/db2dps
PROJECT		= db2dps/

GID			= root
UID			= root

EXCLUDE_INSTALL	= exclude_from_install.txt

SERVICEFILE		= db2fnm.service

pkgs		= mkisofs curl libdata-dumper-simple-perl

install: version.SH
	sudo rsync -avzH configs	/opt/db2dps/etc/
	sudo sed -e '/#INCLUDE_VERSION_SH/ {' -e 'r version.SH' -e 'd' -e'}'  fnmcfg.sh > /tmp/fnmcfg
	sudo mv /tmp/fnmcfg /opt/db2dps/bin/fnmcfg
	sudo chown root:root /opt/db2dps/bin/fnmcfg && sudo chmod 555 /opt/db2dps/bin/fnmcfg
	sudo cp fnmcfg.ini /opt/db2dps/etc/
	sudo cp db2fnm /opt/db2dps/etc/init.d
	sudo chmod 555 /opt/db2dps/etc/init.d/db2fnm
	sudo cp $(SERVICEFILE) /etc/systemd/system/
	sudo systemctl enable $(SERVICEFILE)
	sudo systemctl stop $(SERVICEFILE) || 1
	sudo systemctl start $(SERVICEFILE)
	echo done

version.SH: fnmcfg.sh
	./mk-version.sh

version.pm:
	./mk-version.sh

uninstall:
			echo remove everything below $(PREFIX)

hostcheck:
	@if [ "`hostname -f`" != "`echo $(TARGETHOST) | sed 's/.*@//'`" ]; then							\
		echo "make should not be executed on the wrong host ... ";									\
		echo "hostname = `hostname` expected `echo $(TARGETHOST) | sed 's/.*@//'`, bye ";			\
		exit 1;																						\
	fi


.IGNORE:

.SILENT:

