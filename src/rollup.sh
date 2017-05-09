#! /bin/bash
#

datadir=/opt/i2dps/data
prog="/opt/i2dps/src/fnm2db -v "

case $1 in
	icmp)	gunzip -c ${datadir}/icmp.gz |	${prog} 130.226.136.242 incoming 35335 ban
	;;
	tcp)	gunzip -c ${datadir}/tcp.gz |	${prog} 130.226.136.242 incoming 35335 ban
	;;
	udp)	gunzip -c ${datadir}/udp.gz	|	${prog} 130.226.136.242 incoming 58525 ban
	;;
	1)	gunzip -c ${datadir}/1.gz		|	${prog} 130.226.136.242 incoming 8503 ban
	;;
	*)	echo unknown bye
	;;
esac

exit
