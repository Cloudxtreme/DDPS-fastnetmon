#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#--------------------------------------------------------------------------------------#

echo this is for Debian only

echo se https://hostpresto.com/community/tutorials/how-to-install-influxdb-on-ubuntu-14.04/

set -x

cat << 'LAVET_HERTIL' >/dev/null

sudo apt-get update
sudo apt-get -y upgrade


apt-get install apt-transport-https curl

curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian jessie stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

apt-get update 
sudo apt-get install influxdb

test -f /etc/influxdb/influxdb.conf.org || {
	cp /etc/influxdb/influxdb.conf /etc/influxdb/influxdb.conf.org
}

LAVET_HERTIL

sed 's/reporting-disabled = false/reporting-disabled = true/' /etc/influxdb/influxdb.conf.org > /etc/influxdb/influxdb.conf

echo reporting disabled
diff /etc/influxdb/influxdb.conf.org /etc/influxdb/influxdb.conf

sudo service influxdb start

cat << EOF

InfluxDB also comes with CLI application named influx. You can connect to
InfluxDB using influx by running it wihout options. By default it will connect
to local influxdb installation on default port 8086

InfluxDB has been installed **without** authentication as I don't know if it is
required by fastnetmon ...

EOF


echo /etc/influxdb/influxdb.conf has been changed by hand as the data format is not well suited for sed ...

diff /etc/influxdb/influxdb.conf .

