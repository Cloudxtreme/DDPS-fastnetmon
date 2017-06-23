#!/bin/sh
# echo '*/5 * * * * root [ -x /opt/i2dps/bin/watchdog.sh ] && /opt/i2dps/bin/watchdog.sh' > /etc/cron.d/watchdog

logger=/usr/bin/logger
systemctl=/bin/systemctl

FNM=fastnetmon.service
IDB=influxdb.service

for D in $FNM $IDB
do
	$systemctl is-active ${D} >/dev/null
	case $? in
		0)	$logger -p daemon.warn "${D} running ok"
		;;
		*)	$logger -p daemon.warn "${D} not running, restarting"
			START=`/bin/date +%s`
			$systemctl status ${FNM} | $logger -p daemon.warn

			$systemctl stop		${FNM}
			$systemctl stop		${IDB}
			$systemctl start	${IDB}
			$systemctl start	${FNM}

			END=`/bin/date +%s`
			DOWNTIME=`echo "$END - $START"|bc`
			$logger -p daemon.warn "restarted fastnetmon and influxdb: downtime $DOWNTIME"
		;;
	esac
done

exit 0

