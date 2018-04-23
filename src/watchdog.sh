#!/bin/sh
# echo '*/5 * * * * root [ -x /opt/i2dps/bin/watchdog.sh ] && /opt/i2dps/bin/watchdog.sh' > /etc/cron.d/watchdog

MYNAME=`basename $0`

logger="/usr/bin/logger -p daemon.warn -t ${MYNAME} "
service=/usr/sbin/service

FNM=fastnetmon
IDB=influxd

for D in $FNM $IDB
do
	$service ${D} status >/dev/null
	case $? in
		0)	$logger "${D} running ok"
		;;
		*)	$logger "${D} not running, restarting"
			START=`/bin/date +%s`
			$service status ${FNM} | $logger -p daemon.warn

			$service ${FNM} stop
			$service ${IDB} stop
			$service ${IDB} start
			$service ${FNM} start

			END=`/bin/date +%s`
			DOWNTIME=`echo "$END - $START"|bc`
			$logger "restarted fastnetmon and influxdb: downtime $DOWNTIME"
		;;
	esac
done

ping -t 2 -Q -c 1 192.168.67.1
case $? in
    0)  $logger "ping 192.168.67.1 ok, openvpn up"
        ;;
    *)  $logger "ping 92.168.67.1 failed, restarting openvpn service"
        $service status openvpn | $logger -p daemon.warn
        service openvpn restart 2>&1 | $logger -p daemon.warn
        ;;
esac

exit 0

