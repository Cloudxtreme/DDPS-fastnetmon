#!/usr/bin/env bash
#
# check all files here - especially openvpn and ssh as
# they must be copied manually

FILES="ed25519 ed25519.pub fastnetmon.conf *.ovpn fnm2db.ini i2dps_*.txz influxd.conf networks_list network
s_whitelist rc.conf"

for F in $FILES
do
        test -f $F || {
                echo file $F missing
                exit 1
        }
done

PRESERVEDIR=`hostname`

cat << EOF > /dev/null
mkdir ${PRESERVEDIR}
pkg install -y i2dps*.txz

test -d /opt/i2dps/etc/ssh || mkdir /opt/i2dps/etc/ssh
test -f /opt/i2dps/etc/ssh/* && {
        cp /opt/i2dps/etc/ssh/* ${PRESERVEDIR}
}
install -c -m 700 -o root -g wheel  ed25519* /opt/i2dps/etc/ssh
EOF
cp /opt/i2dps/etc/fnm2db.ini ${PRESERVEDIR}
install -c -m 700 -o root -g wheel fnm2db.ini /opt/i2dps/etc

# influxd and fastnetmon
for FILE in fastnetmon.conf influxd.conf networks_list networks_whitelist
do
        test -f /usr/local/etc/${FILE}  && {
                /bin/cp ${FILE} ${PRESERVEDIR}
}

/bin/cp /usr/local/etc/openvpn/openvpn.conf ${PRESERVEDIR}

install -c -m 700 -o root -g wheel  *.ovpn /usr/local/etc/openvpn/openvpn.conf

# network etc
/bin/cp /etc/rc.conf ${PRESERVEDIR}
/bin/cp rc.conf /etc/rc.conf

# now test everything
