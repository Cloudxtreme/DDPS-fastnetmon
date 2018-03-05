#!/bin/bash

function usage()
{
    echo "usage: $0 -p password < -i vpn ip address| -n hostname >"
    exit 0
}


################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

#
# Process arguments
#
while getopts ai:n:p:v opt
do
case $opt in
    a)
        SQL="select
         *\x
        from flow.fastnetmoninstances ;"
        ;;
    i)  vpn_ip_addr=$OPTARG
        SQL="select
         *\x
        from flow.fastnetmoninstances where vpn_ip_addr = '$OPTARG';"
        ;;
    n)  specific_hostname=$OPTARG
        SQL="select
         *\x
        from flow.fastnetmoninstances where hostname = '$OPTARG';"
        ;;
	p)	PGPASSWORD=$OPTARG
	;;
    v)
    ;;
	*)	usage
		exit
	;;
esac
done
shift `expr $OPTIND - 1`

test -n "${PGPASSWORD}" || usage
test -n "${SQL}" || usage


echo "$SQL" | PGPASSWORD="${PGPASSWORD}" psql -t -F' ' -h localhost -A -U postgres -v ON_ERROR_STOP=1 -w -d netflow |
sed '
    /Expanded display is on/d
   s/ /=/g
   s/^/export /
   '


exit 0

