#! /usr/local/bin/bash
#
# FreeBSD project
#
# <project>_<major version>.<minor version>-<project revision>

project="i2dps"
version=`git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1`
package=${project}_${version}
prefix="FreeBSD-${package}/opt/${project}/"
root="FreeBSD-${package}/"
manifest="${root}/+MANIFEST"
pre_deinstall="${root}/+PRE_DEINSTALL"
post_deinstall="${root}/+POST_DEINSTALL"
pre_install="${root}/+PRE_INSTALL"
post_install="${root}/+POST_INSTALL"

plist="${root}/plist"
rm -fr "${root}"

echo "creating tmp dir ${prefix} .. "

test -d ${root}/etc/cron.d      || mkdir -p ${root}/etc/cron.d
test -d ${prefix}/bin           || mkdir -p ${prefix}/bin
test -d ${prefix}/etc/ssh       || mkdir -p ${prefix}/etc/ssh
test -d ${prefix}/etc/init.d    || mkdir -p ${prefix}/etc/init.d
test -d ${prefix}/tmp           || mkdir -p ${prefix}/tmp
test -d ${prefix}/log           || mkdir -p ${prefix}/log
chmod -R 0500  ${prefix}

BINFILES="fnm2db watchdog-freebsd.sh"
ETCINITDFILES="fnm2dbrc"
SSHKEYS="id_ed25519.pub id_ed25519"
INIFILE="fnm2db.ini"
BASE="/opt/i2dps"

sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  fnm2db.pl > fnm2db

echo '*/5 * * * * root [ -x /opt/i2dps/bin/watchdog.sh ] && /opt/i2dps/bin/watchdog.sh'  > ${root}/etc/cron.d/watchdog
chmod 640 ${root}/etc/cron.d/watchdog
chown 0:0 ${root}/etc/cron.d/watchdog

cp $BINFILES        ${prefix}/bin/
chown 0:0           ${prefix}/bin/*
chmod 555           ${prefix}/bin/*

( cd ${prefix}/bin/; rm -f watchdog.sh; mv watchdog-freebsd.sh watchdog.sh )

cp $INIFILE         ${prefix}/etc/
chmod 744           ${prefix}/etc/*.ini

chmod -R 700        ${prefix}/etc/ssh

# arch: pkg -vv | awk  '$1 == "ABI" { print $NF }'
ARCH="FreeBSD:11:amd64"

echo "Generating the stub manifest in ${root}/+MANIFEST"
cat >"$manifest" <<EOF
name: ${package}
version: ${version}
origin: local/${package}
comment: DDPS Notification script for FastNetMon
arch: $ARCH
www: https://www.deic.dk
maintainer: Niels Thomas Haugård
prefix: /
desc: Perl version of DDPS notification script used by FastNetMon
Categories: local
deps: {
EOF

pkg query "  %n: { version: \"%v\", origin: %o }" perl5                 >> "$manifest"
pkg query "  %n: { version: \"%v\", origin: %o }" p5-Net-SFTP-Foreign   >> "$manifest"
pkg query "  %n: { version: \"%v\", origin: %o }" p5-Net-OpenSSH        >> "$manifest"
pkg query "  %n: { version: \"%v\", origin: %o }" p5-Net-SSH2           >> "$manifest"

echo "}"                                                                >> "$manifest"

# https://github.com/freebsd/pkg
echo "Generating the directory and file list fro ${root} ... "
(
    cd $root
    echo "files: {"
    find . -type f | grep -v ./+| grep -v plist| while read file ; do
        [ "$file" = "$manifest" ] && continue
        mode=$(stat -f%p "$file" | cut -c 3-)
        sha256sum=`sha256 $file |awk '{ print $NF }'`
        file=`echo $file|sed 's/^\.//'`
        echo "  $file: { sum: $sha256sum, uname: root, gname: wheel, perm: $mode }"
    done
    echo "}"
    
    echo "directories: {"
    find . -type d|sed 's/^\.//; /^$/d' | grep -v '^/etc' | while read directory; do
        echo "  $directory: 'y';"
    done
    echo "}"

)>>"$manifest"

# `sha256 $file`

# Create +PRE_DEINSTALL, +POST_DEINSTALL, +PRE_INSTALL as well as +POST_INSTALL
cat >> ${pre_deinstall} <<EOF
# :
:
EOF

echo "creating plist ... "
echo "/opt/i2dps/etc/${INIFILE}" > ${plist}

pkg create -r ${root}/ -m ${root} -o .

file=`echo ${package}_${version}*txz`

if [ -f "${file}" ]; then
    /bin/mv ${file} ${package}_${version}.txz
fi

echo made *txz

exit 0

