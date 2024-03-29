#! /usr/bin/env bash
#
# FreeBSD11
#
# cron:
# echo '*/5 * * * * root [ -x /opt/i2dps/bin/watchdog.sh ] && /opt/i2dps/bin/watchdog.sh' > /etc/cron.d/watchdog

VPN_ADDR=192.168.67.1

logger="/usr/bin/logger -p daemon.warn -t ${MYNAME} "
service=/usr/sbin/service

MYNAME=`basename $0`
TEST=/opt/i2dps/tmp/${MYNAME}.now.SH
YESTERDAY=/opt/i2dps/tmp/${MYNAME}.yesterday.SH
NOW=`date +%j`

if [ -f $TEST ]; then
	. ${TEST}
else
    INFLUXD_RESTART_COUNT=0
    FASTNETMON_RESTART_COUNT=0
    VPN_RESTART_COUNT=0
    TODAY=$NOW
fi

# reset counters at 00:05
if [ $NOW -ne $TODAY ]; then
    INFLUXD_RESTART_COUNT=0
    FASTNETMON_RESTART_COUNT=0
    VPN_RESTART_COUNT=0
    mv ${TEST} ${YESTERDAY}
fi


for D in fastnetmon influxd
do
	$service ${D} status >/dev/null
	case $? in
		0)	: #$logger "${D} running ok"
		;;
		*)	$logger "${D} not running, restarting"
			START=`/bin/date +%s`
			$service status fastnetmon | $logger -p daemon.warn

			$service fastnetmon stop
			$service influxd stop
			$service influxd start
			$service fastnetmon start

			END=`/bin/date +%s`
			DOWNTIME=`echo "$END - $START"|bc`
			$logger "restarted fastnetmon and influxdb: downtime $DOWNTIME"
            ((INFLUXD_RESTART_COUNT+=1))
            ((FASTNETMON_RESTART_COUNT+=1))
		;;
	esac
done

ping -t 2 -Q -c 1 ${VPN_ADDR} >/dev/null 2>&1
case $? in
    0)  : #$logger "ping ${VPN_ADDR} ok, openvpn up"
        ;;
    *)  $logger "ping ${VPN_ADDR} failed, restarting openvpn service"
        $service status openvpn | $logger -p daemon.warn
        # service openvpn restart doesn't always work
        service openvpn stop  2>&1 | $logger -p daemon.warn
        service openvpn start 2>&1 | $logger -p daemon.warn
        ((VPN_RESTART_COUNT+=1))
        ;;
esac

cat << EOF > $TEST
INFLUXD_RESTART_COUNT=$INFLUXD_RESTART_COUNT
FASTNETMON_RESTART_COUNT=$FASTNETMON_RESTART_COUNT
VPN_RESTART_COUNT=$VPN_RESTART_COUNT
TODAY=$NOW
EOF

if [ ! -f ${YESTERDAY} ]; then
    cp $TEST ${YESTERDAY}
fi

exit 0

