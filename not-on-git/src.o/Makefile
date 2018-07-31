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

pkgs		= mkisofs curl libdata-dumper-simple-perl

sprint_skid_og_gallop:
	sudo rsync -avzH configs	/opt/db2dps/etc/
	sudo cp cfg2SH_and_tmpl.pl	/opt/db2dps/bin/cfg2SH_and_tmpl
	sudo cp fnm-db-export.sh	/opt/db2dps/bin/fnm-db-export


version.sh:


version.pm:



gitinstall:	install_pkgs
	# should be made more generic
	sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  $(PROJECT)/bin/fnmconfig > /tmp/fnmconfig
	sudo /bin/mv /tmp/fnmconfig $(PROJECT)/bin/fnmconfig
	sudo chown -R $(UID):$(GID) $(PROJECT)
	sudo chmod -R 555 $(PROJECT)/bin/*
	sudo rsync -avzH --delete-before --exclude-from=$(EXCLUDE_INSTALL) $(PROJECT) $(PREFIX)

install:	hostcheck install_pkgs
	# should be made more generic
	sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  $(PROJECT)/bin/fnmconfig > /tmp/fnmconfig
	sudo /bin/mv /tmp/fnmconfig $(PROJECT)/bin/fnmconfig
	sudo chown -R $(UID):$(GID) $(PROJECT)
	sudo chmod -R 555 $(PROJECT)/bin/*
	sudo rsync -avzH --delete-before --exclude-from=$(EXCLUDE_INSTALL) $(PROJECT) $(PREFIX)

uninstall:
			echo remove everything below $(PREFIX)

hostcheck:
	@if [ "`hostname -f`" != "`echo $(TARGETHOST) | sed 's/.*@//'`" ]; then							\
		echo "make should not be executed on the wrong host ... ";									\
		echo "hostname = `hostname` expected `echo $(TARGETHOST) | sed 's/.*@//'`, bye ";			\
		exit 1;																						\
	fi

bin: $(perlfiles) $(shellfiles)
	@for exec in $(perlfiles);																		\
	do																								\
		exec=`basename $$exec .pl`  ;																\
		sudo $(RM) $$exec;																			\
		sudo sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  $$exec.pl > $$exec;	\
		sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $$exec $(BINDIR);							\
	done
	@for exec in $(shellfiles);																		\
	do																								\
		exec=`basename $$exec .sh`  ;																\
		sudo $(RM) $$exec;																			\
		sudo sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.SH' -e 'd' -e'}'  $$exec.sh > $$exec;	\
		sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $$exec $(BINDIR);							\
	done

