#! /bin/bash
#
# debian project
# Either use debian/ubuntu or on
# osx: brew install dpkg
# <project>_<major version>.<minor version>-<project revision>

project="i2dps"
spectmpl=control.tmpl
version=`git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1`
package=${project}_${version}
specfile=${package}/DEBIAN/control

major_version=`echo ${VERSION} | awk -F'.' '$1 ~ /^[0-9]+$/ { print $1 }'`
minor_version=`echo ${VERSION} | sed 's/^.*\.//; s/-.*//' | awk '$1 ~ /^[0-9]+$/ { print $1 }'`

prefix="${package}/opt/${project}/"
    test -d ${package}/DEBIAN    || mkdir -p ${package}/DEBIAN
    test -d $package}/etc/cron.d || mkdir -p ${package}/etc/cron.d
    test -d ${prefix}/bin        || mkdir -p ${prefix}/bin
    test -d ${prefix}/etc/ssh    || mkdir -p ${prefix}/etc/ssh
    test -d ${prefix}/etc/init.d || mkdir -p ${prefix}/etc/init.d
    test -d ${prefix}/tmp        || mkdir -p ${prefix}/tmp
    test -d ${prefix}/log        || mkdir -p ${prefix}/log

	chmod -R 0500  ${prefix}

    sed "                                              
    s/__project__/${project}/g;                        
    s/__version__/${version}/g;            
    " < ${spectmpl}  > ${specfile}
	# diff ${spectmpl} ${specfile}

BINFILES="fnm2db watchdog.sh"
ETCINITDFILES="fnm2dbrc"
SSHKEYS="id_ed25519.pub id_ed25519"
INIFILE="fnm2db.ini"
BASE="/opt/i2dps"

sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  fnm2db.pl > fnm2db

echo '*/5 * * * * root [ -x /opt/i2dps/bin/watchdog.sh ] && /opt/i2dps/bin/watchdog.sh'  > ${package}/etc/cron.d/watchdog
chmod 640 ${package}/etc/cron.d/watchdog
chown 0:0 ${package}/etc/cron.d/watchdog

cp $BINFILES        ${prefix}/bin/
chown 0:0           ${prefix}/bin/*
chmod 555           ${prefix}/bin/*

cp $INIFILE         ${prefix}/etc/
chmod 744           ${prefix}/etc/*.ini
touch               ${prefix}/etc/ssh/.keep

chmod -R 700        ${prefix}/etc/ssh

#install -o root -m 555 $BINFILES           ${package}/bin/
#install -o root -m 744 $INIFILE            ${package}/etc/

#if [ ! -f ${BASE}/etc/$INIFILE ]; then
#    install -o root -m 400 $ETCINITDFILES      ${package}/etc/init.d/
#else
#    install -o root -m 400 $ETCINITDFILES      ${package}/etc/init.d/${ETCINITDFILES}.new
#fi
#install -o root -m 400 $SSHKEYS            ${package}/etc/ssh/


dpkg-deb --build ${package}

exit 0


