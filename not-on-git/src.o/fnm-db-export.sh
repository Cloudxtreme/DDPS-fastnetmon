#!/bin/bash

function usage()
{
    echo "dump fastnetmon config as shell vars"
    echo "usage: $0 -i vpn-ip-address"
    echo "usage: $0 -n hostname"
    exit 0
}


################################################################################
# Main
################################################################################

if [ -f /opt/db2dps/etc/db.ini ];
then
    eval `egrep 'dbuser|dbpassword|dbname' /opt/db2dps/etc/db.ini | sed 's/[ \t]*//g'`
else
    echo file /opt/db2dps/etc/db.ini not found
    exit 0
fi

export $dbuser
export $dbpassword
export $dbname

dbpassword="$dbpassword"

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
while getopts ai:n:v opt
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
    v)
        ;;
	*)	usage
		exit
	;;
esac
done
shift `expr $OPTIND - 1`

test -n "${dbpassword}" || usage
test -n "${SQL}" || usage

TMPDIR=`mktemp -d`
cd ${TMPDIR}

echo "$SQL" | PGPASSWORD="${dbpassword}" psql -t -F' ' -h localhost -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} |
sed '
    /Expanded display is on/d
   s/ /=/g
   s/^/export /' > export.SH



echo "In `pwd`:"

ls -1

exit 0

