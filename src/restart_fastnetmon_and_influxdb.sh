#!/bin/sh
# echo '00 * * * * root [ -x /opt/i2dps/bin/restart_fastnetmon_and_influxdb.sh ] && /opt/i2dps/bin/restart_fastnetmon_and_influxdb.sh' > /etc/cron.d/restart_fnm_and_influxdb
START=`date +%s`
/usr/sbin/service fastnetmon stop
/usr/sbin/service influxdb stop
/usr/sbin/service influxdb start
/usr/sbin/service fastnetmon start
END=`date +%s`
DOWNTIME=`echo "$END - $START"|bc`
/usr/bin/logger -p daemon.warn "restarted fastnetmon and influxdb: downtime $DOWNTIME"
