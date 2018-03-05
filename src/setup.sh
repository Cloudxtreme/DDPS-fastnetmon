#!/bin/sh
#
# One perl script, a number of perl/packages
 - a customer specific ini file and two customer specific ssh keys

#
# Vars
#
MYDIR=/opt/i2dps
MYNAME=`basename $0`
MY_LOGFILE=/var/log/somelogfile
VERBOSE=FALSE
TMPFILE=/tmp/${MYNAME}.tmp

ALLFILES="fnm2db.ini fnm2db.pl fnm2dbrc id_ed25519 id_ed25519.pub setup.sh version.pm watchdog.sh"
BINFILES="fnm2db"
LIBFILES="setup.sh"
ETCINITDFILES="fnm2dbrc"
SSHKEYS="id_ed25519.pub id_ed25519"
INIFILE="fnm2db.ini"
BASE="/opt/i2dps"
DIRS="${BASE}/bin ${BASE}/lib ${BASE}/tmp ${BASE}/i2dps/log ${BASE}/etc/ssh"

#
# Functions
#
usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
echo $*
cat << EOF
	Usage: `basename $0` -g group -h host 

	See man pages for more info.
EOF
	exit 2
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	/bin/rm -f $TMPFILE $MAILFILE
}

#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

pkgs="libnet-openssh-compat-perl libnet-openssh-compat-perl libnet-ssh2-perl libnet-sftp-foreign-perl"

case $1 in
    ""|"install")
        for D in ${DIRS}
        do
            install -d -o root -m 500 ${D}
        done
        chmod -R 500  ${BASE}

        sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  fnm2db.pl > fnm2db

        install -o root -m 555 $BINFILES           ${BASE}/bin/ && echo "made $BINFILES in ${BASE}/bin"
        install -o root -m 555 $LIBFILES           ${BASE}/lib/ && echo "made $LIBFILES in ${BASE}/lib"

        if [ -f "${BASE}/etc/$INIFILE" ]; then
            echo "noclobber existing ${BASE}/etc/$INIFILE"
            install -o root -m 744 $INIFILE      ${BASE}/etc/${INIFILE}.new
        else
            echo "new ${BASE}/etc/$INIFILE"
            install -o root -m 400 $INIFILE      ${BASE}/etc/$INIFILE
        fi

        install -o root -m 400 $SSHKEYS            ${BASE}/etc/ssh/ && echo "installed $SSHKEYS in ${BASE}/etc/ssh"

        # Install required perl modules from $(pkgs)
        for P in ${pkgs}
        do
            dpkg -s "$P" >/dev/null 2>&1;
            case $? in
                0) echo "allready installed: $P"
                ;;
                1) sudo apt-get -y install $P
                ;;
            esac
        done
        ${BASE}/bin/fnm2db -V   && echo "installation ok"

    ;;
    "uninstall")
        for P in $pkgs
        do
            dpkg -s "$P" >/dev/null 2>&1;
            case $? in
            1) 
                echo "$P not installed"
                ;;
            0)  
                echo removing $P ...
                sudo apt -y remove ${P}
                ;;
            esac
        done
        apt -y autoremove
        /bin/rm -fr ${BASE}
    ;;
esac

exit 0

