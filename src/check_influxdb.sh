#!/bin/bash
#
#  http://172.22.89.2:8086/query?q=SELECT top(value, 10) AS y, time AS x, cidr FROM graphite.autogen.hosts WHERE resource = 'bps' AND time < now() - 30m AND time > now() - 1h AND direction = 'incoming';

Q="http://172.22.89.2:8086/query?q=SELECT top(value, 10) AS y, time AS x, cidr FROM graphite.autogen.hosts WHERE resource = 'bps' AND time < now() - 30m AND time > now() - 1h AND direction = 'incoming';"

Q=`echo "$Q"|sed 's/ /+/g'`

# curl -s "$Q"

OK=`curl --connect-timeout 4 -s "$Q" | wc -l | tr -d ' '`

case $OK in
	0)	echo error
	;;
	*)	echo ok
	;;
esac
