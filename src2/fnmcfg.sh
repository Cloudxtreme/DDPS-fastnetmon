#!/bin/bash
#
# Copyright 2017, DeiC, Niels Thomas Haugård
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
#   ~/etc/$0.ini:
#   [default]
#   default_uuid_administratorid    = $uuid_administratorid
#   bootstrap_ip                    = 192.168.68.2
#
#   -x: print all customers(s) / uuid_customerid(s) / uuid_administratorid(s)
#
# This is work in progress, and should have been written in an other language. 

WORKDIR=/tmp/tmpdir
ENDLOOP=/tmp/stop
TIMEOUT=20

MYNAME=`basename $0`
MY_LOGFILE=/tmp/${MYNAME}.log
VERBOSE=FALSE
MAKE_CONFIG_FILES=FALSE
FASTEST_INTERFACE=""
UPLINK=""
UUID=""

#INCLUDE_VERSION_SH

# functions

function logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
    LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
    STRING="$*"

    if [ -n "${STRING}" ]; then
        if [ "${VERBOSE}" = "TRUE" ]; then
            logger -p local3.info -t ${MYNAME} "${STRING}"
        fi
    else
        while read LINE
        do
            if [ -n "${LINE}" ]; then
                logger -p local3.info -t ${MYNAME} "${LINE}"
            fi
        done
    fi
}

function savefile()
{
    if [ ! -f "$1" ]; then
        echo "program error in function savefile, file '$1' not found"
        exit 0
    fi
    if [ ! -f "$1".org ]; then
        echo "$0: saving original $1 as $1.org ... "
        cp "$1" "$1".org
    fi
}

# purpose     : Change case on word
# arguments   : Word
# return value: GENDER=word; GENDER=`toLower $GENDER`; echo $GENDER
# see also    :
function toLower() {
    echo $1 | tr "[:upper:]" "[:lower:]"
}

function toUpper() {
    echo $1 | tr  "[:lower:]" "[:upper:]"
}

function assert () {
# purpose     : If condition false then exit from script with appropriate error message.
# arguments   : 
# return value: 
# see also    : e.g.: condition="$a -lt $b"; assert "$condition" "explaination"

    E_PARAM_ERR=98 
    E_ASSERT_FAILED=99 
    if [ -z "$2" ]; then        #  Not enough parameters passed to assert() function. 
        return $E_PARAM_ERR     #  No damage done. 
    fi  
    if [ ! $1 ]; then 
    # Give name of file and line number. 
        echo "Assertion failed:  \"$1\" File \"${BASH_SOURCE[1]}\", line ${BASH_LINENO[0]}"
        echo "  $1"
        exit $E_ASSERT_FAILED 
    # else 
    #   return 
    #   and continue executing the script. 
    fi  
}

usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
echo $*
cat << EOF

    Dump fastnetmon config as shell vars and build new config files
    or
    read vars from fastnetmon.conf and create shell and database export

    usage: `basename $0` [-v] < -i vpnpiaddr | -n hostname > < -a | -u | -d | -c | -p | -g >

    options:
    -v: verbose
    -i: argument is the vpn-ip-address
    -n: argument is the hostname

    arguments -a, -c -d, -p and -c are mutually exclusive

    -a: add new FastNetMon host to database. Specify hostname of vpn ipaddress
        save import.sql with default values for import with psql
    -d: export database to config files
    -e: exit a subset of fastnetmon configurations
    -c: import values from config files by saving values to import.sql
    -p: push config files to host and restart services
    -g: fetch config from hosts to .
    -s: print status for all fastnetmon instances

EOF
    exit 2
}

function find_port_and_listen_address()
{
    # we run pgpool2 in production but not in the test environment, it may be installed though
    if [ -f /opt/pgpool2/etc/pgpool.conf ]; then
        # check if using pgpool2 bound to IP and PORT
        service pgpool status>/dev/null
        case $? in
            0)  PORT=`sed "/^port/!d; s/.*=//; s/[ \t]*//; s/'//g" /opt/pgpool2/etc/pgpool.conf`
                LISTEN=`sed "/^listen_addresses/!d; s/.*=//; s/[ \t]*//; s/'//g" /opt/pgpool2/etc/pgpool.conf`
                logit "running pgpool2 detected"
                ;;
            *)  PORT=5432
                LISTEN=localhost
                logit "no running pgpool2 detected but /opt/pgpool2/etc/pgpool.conf found"
                ;;
        esac
     else
        PORT=5432
        LISTEN=localhost
    fi

    # this doesn't cover pgpool2 but is good enough
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
    export PGPASSWORD="${dbpassword}"
    PGSQL="psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname}"

}

function get_interface_information_from_bootstrap()
{
    logit "getting interface information from bootstraped host ... "
    logit "ssh to $bootstrap_ip / 192.168.68.2"

    # ix0 10Gb
    # igb0 1Gb
    # em0  1Gb

    logit "stopping openvpn and detecting uplink ... "
    cat << 'EOF' > /tmp/find_uplink.sh
    #!/bin/sh
    service openvpn stop
    netstat -rn -f inet|awk '$1 == "default" { print $NF }'>/var/tmp/uplink
    service openvpn start
    real_interfaces=`ifconfig -a| egrep '^[a-z0-9]*:'|sed 's/:.*//; /lo0/d; /tun/d'|sort -n`
    fastest_if=""
    for interface in ${real_interfaces} igb0 igb1 ix0 ix1 ix2 ix3; do
    # append 10Gb last for testing
        ifconfig $interface >/dev/null 2>&1
        case $? in
            0)  used=`ifconfig $interface|sed '/inet/!d; /0.0.0.0/d;'|wc -l | tr -d ' ' `
            if [ $used -eq 0 ]; then
                fastest_if=$interface
            fi
            ;;
            *)  : # no such interface
            ;;
        esac
    done
    echo $fastest_if > /var/tmp/fastest_interface

EOF
    scp /tmp/find_uplink.sh root@$bootstrap_ip:/tmp
    cat << EOF | ssh root@$bootstrap_ip
    chmod 555 /tmp/find_uplink.sh && /tmp/find_uplink.sh
EOF

    FASTEST_INTERFACE="`ssh -q root@$bootstrap_ip 'cat /var/tmp/fastest_interface'`"
    UPLINK="`ssh -q root@$bootstrap_ip 'cat /var/tmp/uplink'`"
}

#INCLUDE_VERSION_SH

# functions

usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
echo $*
cat << EOF

    Dump fastnetmon config as shell vars and build new config files
    or
    read vars from fastnetmon.conf and create shell and database export

    usage: `basename $0` [-v] < -i vpnpiaddr | -n hostname > < -a | -u | -d | -c | -p | -g >

    options:
    -v: verbose
    -i: argument is the vpn-ip-address
    -n: argument is the hostname

    arguments -a, -c -d, -p and -c are mutually exclusive

    -a: add new FastNetMon host to database. Specify both hostname and vpn ipaddress
        save import.sql with default values for import with psql
    -d: export database to config files
    -c: import values from config files by saving values to import.sql
    -p: push config files to host and restart services
    -g: fetch config from hosts to .

EOF
    exit 2
}

function find_port_and_listen_address()
{
    # we run pgpool2 in production but not in the test environment, it may be installed though
    if [ -f /opt/pgpool2/etc/pgpool.conf ]; then
        # check if using pgpool2 bound to IP and PORT
        service pgpool status>/dev/null
        case $? in
            0)  PORT=`sed "/^port/!d; s/.*=//; s/[ \t]*//; s/'//g" /opt/pgpool2/etc/pgpool.conf`
                LISTEN=`sed "/^listen_addresses/!d; s/.*=//; s/[ \t]*//; s/'//g" /opt/pgpool2/etc/pgpool.conf`
                logit "running pgpool2 detected"
                ;;
            *)  PORT=5432
                LISTEN=localhost
                logit "no running pgpool2 detected but /opt/pgpool2/etc/pgpool.conf found"
                ;;
        esac
     else
        PORT=5432
        LISTEN=localhost
    fi

    # this doesn't cover pgpool2 but is good enough
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
}

function get_interface_information_from_bootstrap()
{
    logit "getting interface information from bootstraped host ... "
    logit "ssh to $bootstrap_ip / 192.168.68.2"

    # ix0 10Gb
    # igb0 1Gb
    # em0  1Gb

    OK=`ssh $bootstrap_ip 'whoami' 2>&1`
    case $? in
        0) logit "ssh connection to $bootstrap_ip seems ok"
        ;;
        *) logit "ssh connection to $bootstrap_ip failed, check keys" 
           exit 1
        ;;
    esac

    logit "stopping openvpn and detecting uplink ... "
    cat << 'EOF' > /tmp/find_uplink.sh
    #!/bin/sh
    service openvpn stop
    netstat -rn -f inet|awk '$1 == "default" { print $NF }'>/var/tmp/uplink
    service openvpn start
    real_interfaces=`ifconfig -a| egrep '^[a-z0-9]*:'|sed 's/:.*//; /lo0/d; /tun/d'|sort -n`
    fastest_if=""
    for interface in ${real_interfaces} igb0 igb1 ix0 ix1 ix2 ix3; do
    # append 10Gb last for testing
        ifconfig $interface >/dev/null 2>&1
        case $? in
            0)  used=`ifconfig $interface|sed '/inet/!d; /0.0.0.0/d;'|wc -l | tr -d ' ' `
            if [ $used -eq 0 ]; then
                fastest_if=$interface
            fi
            ;;
            *)  : # no such interface
            ;;
        esac
    done
    echo $fastest_if > /var/tmp/fastest_interface

    ifconfig $fastest_if | awk '$1 == "ether" { print $NF }' > /var/tmp/fastest_interface_ether

EOF
    scp -q /tmp/find_uplink.sh root@$bootstrap_ip:/tmp 2>&1 |logit
    cat << EOF | ssh -q root@$bootstrap_ip 2>&1 |logit
    chmod 555 /tmp/find_uplink.sh && /tmp/find_uplink.sh
EOF

    FASTEST_INTERFACE="`ssh -q root@$bootstrap_ip 'cat /var/tmp/fastest_interface' 2>/dev/null`"
    UPLINK="`ssh -q root@$bootstrap_ip 'cat /var/tmp/uplink' 2>/dev/null`"
    UUID="`ssh -q root@$bootstrap_ip 'cat /var/tmp/fastest_interface_ether' 2>/dev/null`"

    assert "${UPLINK} != ''" $LINENO
    assert "${FASTEST_INTERFACE} != ''" $LINENO
    assert "${UUID} != ''" $LINENO
}

function pushcfg()
{
    for FILE in *.ovpn id_ed25519	id_ed25519.pub fastnetmon.conf fnm2db.ini influxd.conf networks_list networks_whitelist rc.conf
    do
        # check all files here
        test -s ${FILE} || {
            echo "file ${FILE} missing" ; exit 1
        }
        # check no var = ${value}
        egrep '\$' ${FILE} && {
            echo "file ${FILE} contains unexpanded shell: var = \${value}"
            exit 0
        }
        logit "ok file ${FILE} contains data and no unexpanded shell vars"
    done
    # check no var = ''
    for FILE in fastnetmon.conf fnm2db.ini rc.conf
    do
        OUTPUT=""
        OUTPUT=`awk -F'=' '
            $0 !~ /=/ { next;};
            $1 ~ /#/ { next;};
            {
                gsub(/ /, "", $2);
                if ((0 + length($2)) == 0) { print "error: " $0 }
            }' ${FILE}`
        if [ ! -z "${OUTPUT}" ]; then
            logit "error in $file: parameter missing ${OUTPUT}"
            echo "error in $file: parameter missing ${OUTPUT}"
            exit 1
        fi
        logit "ok file ${FILE} has var = value for all var"
    done
    # check no ifconfig_=
    egrep 'ifconfig_=' rc.conf && {
        echo "file rc.conf does not ifconfig interface correctly: ifconfig_= ..."
        exit 1
    }
    logit "rc.conf: interfaces ok"
    TMPFILE=/tmp/$$.out
    chmod 700 ed25519*
    ssh-keygen -y -e -f ed25519 > ${TMPFILE} 2>&1
    case $? in
        0)  logit "ssh key ed25519 ok"
            ;;
        *)  logit "ssh key ed25519 not ok"
            cat ${TMPFILE} | logit
            /bin/rm -f ${TPMFILE}
            exit
            ;;
    esac
    logit "file check passed ok"
    /bin/rm -f ${TPMFILE}

    mkdir -p etc opt/etc/ssh usr/local/etc/openvpn
    /bin/cp ed25519 ed25519.pub opt/etc/ssh
    /bin/cp fnm2db.ini opt/etc/
    /bin/cp fastnetmon.conf influxd.conf networks_list networks_whitelist usr/local/etc/
    /bin/cp *.ovpn usr/local/etc/openvpn/openvpn.conf
    /bin/cp rc.conf etc/
    chmod 744 usr/local/etc/*conf
    tar cvfpz $vpn_ip_addr.tar.gz etc opt usr

    logit "cp /opt/db2dps/etc/configs/i2dps*.txz . "
    /bin/cp /opt/db2dps/etc/configs/i2dps*.txz .

    logit "making finish.sh ... "
    cat << 'EOF' > finish.sh
#! /usr/bin/env bash

service fastnetmon stop
service influxd stop
service openvpn stop

# set hostname and ip configuration, wait 10 seconds for dhcp to settle down
hostname `sed '/hostname/!d; s/.*=//;s/\"//g' /etc/rc.conf`
/etc/rc.d/netif restart
sleep 10

# once dhcp is done, restart openvpn
service openvpn start

# restart monitor
service influxd start
service fastnetmon start

# check vpn 
ping -c 6 192.168.67.1
case $? in
    0)  : ok
    ;;
    *)  echo tunnel down, rollback
    ;;
esac

# check services
for SERVICE in influxd fastnetmon openvpn
do
    service ${SERVICE} status
    case $? in
        0)  :
        ;;
        *)  echo service not running
        ;;
    esac
done

# roll-back:
# service fastnetmon stop
# service influxd stop
# service openvpn stop
# tar Cxvfoz / /root/bootstrapped.tar.gz
# hostname `sed '/hostname/!d; s/.*=//;s/\"//g' /etc/rc.conf`
# /etc/rc.d/netif restart
# sleep 10
# service openvpn start
# service influxd start
# service fastnetmon start

EOF
    chmod 555 finish.sh

    ssh $bootstrap_ip "/bin/rm -fr /root/${vpn_ip_addr}/*"
    rsync -avzH i2dps*txz $vpn_ip_addr.tar.gz finish.sh $bootstrap_ip:/root/${vpn_ip_addr}

    cat << 'EOF' | sed "s/_vpn_ip_addr_/${vpn_ip_addr}/g" | ssh $bootstrap_ip /usr/local/bin/bash
    cd /root/_vpn_ip_addr_
    tar cvfpz /root/bootstrapped.tar.gz /etc/rc.conf $(ls /usr/local/etc/openvpn/*) $(ls /usr/local/etc/*.conf) $(ls /opt/i2dps/etc/ssh/* /opt/i2dps/etc/fnm2db.ini 2>/dev/null )
    pkg install -y i2dps*txz
    tar Cxvfoz / _vpn_ip_addr_.tar.gz
    # bad permissions prevent influxd from starting
    chmod 744               /usr/local/etc/influxd.conf
    chown influxd:influxd   /usr/local/etc/influxd.conf
    # put in background prevent premature exit
    nohub bash ./finish.sh &
EOF
    logit "done. Wait 10 seconds then please try ssh ${vpn_ip_addr}"
}

function updatecfg()
{
    # assume we are in a empty directory
    local TMPDIR=`mktemp -p /tmp/tmpdir -d XXX.updatecfg`

    # export and check the data
    db2cfg

    # do not push rc.conf nor ovpn or ssh
    FILES="fastnetmon.conf fnm2db.ini influxd.conf networks_list networks_whitelist"

    for FILE in ${FILES}
    do
        # check all files here
        test -s ${FILE} || {
            echo "file ${FILE} missing" ; exit 1
        }
    done

    # I don't know any safe way of validating fastnetmon.conf; you may do 'echo asdfsadfsadf'>> fastnetmon.conf
    # and it doesn't complain. Hmpf. In case of error of some sort, notify operator via status, don't do a rollback
    # as the db and files should be in sync
    # copy fastnetmon.conf influxd.conf networks_list networks_whitelist to /usr/local/etc
    # copy fnm2db.ini to /opt/i2dps/etc
    # service fastnetmon restart; service influxd restart
    # check output and update status

    # remove files
    # connect_to
    test -n $vpn_ip_addr && connect_to=$vpn_ip_addr
    test -n $HOSTNAME && connect_to=$HOSTNAME

    ERRORS=0

    # see man: '-k ${TIMEOUT}' '${TIMEOUT}' are two different parameters ...
    timeout  -k ${TIMEOUT} ${TIMEOUT}  ssh ${connect_to} "uptime"
    case $? in
        0)  logit "ssh on host ${connect_to} is alive"

            logit "applying fastnetmon configuration changes on $connect_to ... "
            RTMPDIR=`mktemp -u`
            ssh ${connect_to} "mkdir -p ${RTMPDIR}"
            scp ${FILES} ${connect_to}:${RTMPDIR}

            ssh  -qt ${connect_to} "cd ${RTMPDIR}; mv fastnetmon.conf networks_list networks_whitelist /usr/local/etc/; cd /tmp; rm -fr ${RTMPDIR}"

            logit "starting fastnetmon ... "
            ssh  -qt ${connect_to} "/usr/local/etc/rc.d/fastnetmon restart";  ERRORS=$((ERRORS + $?))
            ssh  -qt ${connect_to} "/usr/local/etc/rc.d/fastnetmon status"; ERRORS=$((ERRORS + $?))

            case $ERRORS in
                0)  STATUS="SUCCESS"
                    logit "fastnetmon successfully restarted with new configuration"
                    ;;
                *)  STATUS="FAIL"
                    logit "fastnetmon failed restart with new configuration"
                ;;
            esac
        ;;
        *)  logit "ssh on host ${connect_to} is NOT alive, try later"
            STATUS="FAIL"
        ;;
    esac
    echo "status = $STATUS"
    cd /tmp
    /bin/rm -fr ${TMPDIR}
}

function edit()
{
    local TMPDIR=`mktemp -p /tmp/tmpdir -d edit.XXXXXXXXXX`
    local OLDDIR=`pwd`
    cd ${TMPDIR}

    db2cfg

    RMFILES=`ls -1 |grep -v export.SH`
    (
        NOW=`date +%s `
        . export.SH
        # export 
        export status="pending"
        export SEARCH="$SEARCH"
        export QUERY="$QUERY"
        envsubst < /opt/db2dps/etc/configs/change_fastnetmon_parameters.sql.SH   > ${TMPDIR}/change_fastnetmon_parameters.sql
    )

    cd ${OLDDIR}
    if [ -f "${OLDDIR}/change_fastnetmon_parameters.sql" ]; then
        echo "existing change_fastnetmon_parameters.sql, please rename and try again"
    else
        mv ${TMPDIR}/change_fastnetmon_parameters.sql .
        echo "made change_fastnetmon_parameters.sql; edit and run"
    fi

    rm -fr ${TMPDIR}
    exit 0
}

function loop()
{
    local TMPDIR=`mktemp -p /tmp/tmpdir -d XXX.loop`
    cd ${TMPDIR}

    # loop master/client?
    Q_IS_MASTER="select pg_is_in_recovery();"

    # loop db query for changes
    Q_PENDING="select
    vpn_ip_addr, hostname
    from flow.fastnetmoninstances where status = 'pending';"        # unconfigured, pending, updated failed

    while :;
    do
        if [ -f ${ENDLOOP} ]; then
            logit "found stop signal: ${ENDLOOP}, bye"
            cd /tmp
            rm -fr ${TMPDIR}
            break
        fi
        # loop master/client?
        while :;
        do
            logit "quering for is master or client ... "
            IS_MASTER=`echo "${Q_IS_MASTER}" | PGPASSWORD="${dbpassword}" psql -t -F' ' -h 127.0.0.1 -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname}`

            case ${IS_MASTER} in
                "f")    logit "localhost is master"
                        break
                ;;
                "t")    logit "localhost is not master, sleeping"
                        sleep 60
                ;;
                "*")    logit "localhost is nither master nor client, sleeping"
                        sleep 60
                ;;
            esac
        done

        ( 
            # logit "PGPASSWORD=\"${dbpassword}\" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname}"
            echo "${Q_PENDING}" | PGPASSWORD="${dbpassword}" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} |

            logit "quering for pending hosts ... "
            echo "${Q_PENDING}" | PGPASSWORD="${dbpassword}" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} |
            sed '/Expanded display is on/d; s/\/32//g ' | while read vpn_ip_addr HOSTNAME
            do
                # only here if select ... found something
                logit "found [${HOSTNAME}] [${vpn_ip_addr}]"
                SQL="SELECT
                         *\x
                     FROM flow.fastnetmoninstances where vpn_ip_addr = '$vpn_ip_addr';"
                         SEARCH="$vpn_ip_addr"
                         QUERY="$vpn_ip_addr"

                updatecfg

                case $STATUS in
                    "SUCCESS") logit "updating status in db for $HOSTNAME with uptodate"
                                UPDATE="UPDATE flow.fastnetmoninstances set status = 'uptodate' WHERE hostname = '$HOSTNAME';"
                    ;;
                    *)  : # hmm
                                logit "updating status in db for $HOSTNAME with failed"
                                UPDATE="UPDATE flow.fastnetmoninstances set status = 'failed' WHERE hostname = '$HOSTNAME';"
                    ;;
                esac
                echo "${UPDATE}" | PGPASSWORD="${dbpassword}" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} | logit
            done
            # remove all files in '.' (TMPDIR)
            /bin/rm -f *
            logit "query done, sleeping"
        )
        sleep 1
    done
    cd /tmp
    rm -fr ${TMPDIR}
    logit "goodbye"
    /bin/rm -f ${ENDLOOP}
    exit 0
}

function getcfg()
{
    logit "TODO - not made yet: getcfg ... "
    # mktemp && $TMPDIR
    # rsync --files-from=FILE $vpn_ip_addr: .
    # ssh $vpn_ip_addr "cp file file file 
    # scp $vpn_ip_addr 
}

function status()
{
    echo "Status according to database"
    echo "select hostname, status, notes from flow.fastnetmoninstances;" | sudo su postgres -c "cd /tmp; psql -d netflow"

    echo "Status from ssh to host"
    echo "select hostname, status from flow.fastnetmoninstances;" | sudo su postgres -c "cd /tmp; psql -t -d netflow" |
    sed 's/|//; /^\s*$/d' | while read hostname status rest of line
    do
        $echo $N "$hostname $C"
        case $status in
            down|'') echo "not tested: system down"
                ;;
             *)  S="`timeout  -k ${TIMEOUT} ${TIMEOUT} sudo ssh ${hostname} \"service fastnetmon status; service influxd status\"`"
                 S="`echo $S`"
                 echo "$S"
                ;;
        esac
    done
}

function db2cfg()
{
    logit "exporting db to config files  ... "
    test -n "${dbpassword}" || usage missing dbpassword
    test -n "${SQL}"        || usage missing sql statement

    local TMPDIR=`mktemp -p /tmp/tmpdir -d XXX.db2cfg`
    logit "tmpdir: ${TMPDIR}"
    local OLDDIR=`pwd`
    cd ${TMPDIR}

    # Following gives var='value' -- notice lack of ending ;
    # echo "select * from flow.fastnetmoninstances \x\g" | psql -P format=unaligned -P fieldsep== -d netflow|sed "s/=/='/; s/$/'/"
    # but it doesn't allways work
    # this may work most of the time
    # echo "select * from flow.fastnetmoninstances \x\a\f = "|sudo su postgres -c "cd /tmp; psql -d netflow" | sed "s/=/='/; s/$/'/; /Expanded display is on/d; /Output format is unaligned/d; /Field separator is/d"

    echo "$SQL" |
        PGPASSWORD="${dbpassword}" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} |
        sed '/Expanded display is on/d; /^\s*$/d' >  export.txt
        # should also delete single ', " and ` as it may disturb the shell
    
    echo '\d+ flow.fastnetmoninstances' |
        PGPASSWORD="${dbpassword}" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} > schema.sql
    
    LINES=`wc -l < ./export.txt`
    case $LINES in
        1)  logit "host or ip not found"; exit 0
            cd /tmp
            rm -fr ${TMPDIR}
            ;;
        *)  logit "found $LINES lines in export.txt"
            ;;
    esac
    
    awk -F' ' '
       # remove /32 from hosts (cidr export) 
       # vpn_ip_addr remote_syslog_server redid_host
       # exabgp_next_hop graphite_host
       # not export hostgroup=‘my_hosts:10.10.10.221/32,10.10.10.222/32’
       $1 == "vpn_ip_addr"              { gsub(/\/32/, "", $2); print; next }
       $1 == "remote_syslog_server"     { gsub(/\/32/, "", $2); print; next }
       $1 == "redis_host"               { gsub(/\/32/, "", $2); print; next }
       $1 == "exabgp_next_hop"          { gsub(/\/32/, "", $2); print; next }
       $1 == "graphite_host"            { gsub(/\/32/, "", $2); print; next }
       { print; next }
       ' < export.txt | sed "
        /Expanded display is on/d
        s/ /='/
        s/\$/'/
        s/^/export /" > export.SH 
        #/bin/rm -f export.txt

    logit "db export saved as export.SH"

    CFGFILES="fastnetmon.conf influxd.conf fnm2db.ini networks_whitelist networks_list"
    (
        NOW=`date +%s `
        . export.SH

        for file in ${CFGFILES}
        do
            #logit "preserving existing ${file} ... "
            test -f $file && mv ${file} ${file}-${NOW}
        done
        envsubst < /opt/db2dps/etc/configs/fastnetmon.conf.SH   > fastnetmon.conf
        envsubst < /opt/db2dps/etc/configs/fnm2db.ini.SH        > fnm2db.ini
        echo "${networks_whitelist}"    | sed 's/ /\n/g' > networks_whitelist   # space must be replaced with newlines
        echo "${networks_list}"         | sed 's/ /\n/g' > networks_list

        if [ -z "${networks_list}" ]; then
            logit "error in networks_list: parameter networks_list is empty"
            echo "error in networks_list: parameter networks_list is empty"
        fi
        cp /opt/db2dps/etc/configs/influxd.conf             .

        # finally build rc.conf
        # TODO fix lan_if -> fastnetmon_if in db
        if [ -z "${fastnetmon_if}" ]; then
            export fastnetmon_if=$lan_if
        fi
        envsubst < /opt/db2dps/etc/configs/rc.conf.SH   > rc.conf
         
            for file in ${CFGFILES}
            do
                egrep '\${' ${file}
                case $? in 
                    1)  logit "${file} expanded ok"
                        ;;
                    *)  logit "${file} not expanded ok, still carries shell vars"
                        ERRORS=1
                        ;;
                esac
            logit "checking parameters in $file ... "
            OUTPUT=""
            OUTPUT=`awk -F'=' '
                $0 !~ /=/ { next;};
                $1 ~ /#/ { next;};
                {
                    gsub(/ /, "", $2);
                    if ((0 + length($2)) == 0)
                        { print "error: " $0
                        }
                }' ${file}`
            if [ -z "${OUTPUT}" ]; then
                logit "ok"
            else
                logit "error in $file: parameter missing ${OUTPUT}"
                echo "error in $file: parameter missing ${OUTPUT}"
            fi
        done
    )

    cd ${OLDDIR}
    ERROR=0
    # move everything from tmpdir to . but don't clubber existing files
    for file in $( cd ${TMPDIR}; ls )
    do
        if [ -f ${file} ]; then
            ERROR=1
            echo "file `pwd`/$file found"
        fi
    done
    case $ERROR in 
        0)  logit "no existing cfg files found, moving ... "
            mv ${TMPDIR}/* .
            /bin/rm -fr ${TMPDIR}
        ;;
        1) logit "Stop: files with same name in ${TMPDIR} and ."
            touch ${ENDLOOP}
           exit 1
        ;;
    esac
}

function cfg2db()
{
    IMPORT="import.sql"
    IMPORTSH="import.sql.SH"

    TMPEXPORT="tmp_export.SH"

    SCHEMA="schema.sql"

    TMPFILE=/tmp/$$.tmp

    FILES="fastnetmon.conf fnm2db.ini rc.conf"
    ALLFILES="${FILES} networks_list networks_whitelist"

    logit "cp template files ... "
    cp /opt/db2dps/etc/configs/import.sql.SH .

    for F in ${ALLFILES}
    do
        test -f $F || {
            echo "file $F missing $IMPORT will be incomplete"
        }
    done

    # extract var=value from all files
    (
    for FILE in ${FILES}
    do
        if [ -f ${FILE} ]; then

            awk -F'=' ' 
                $0 !~ /=/ { next;};
                $1 ~ /#/ { next;};
                {
                    gsub(/.*:/, "", $1)     # remove:part from fastnetmon vars
                    gsub(/[\t ]*/, "", $1)
                    gsub(/[\t ]*/, "", $2)
                    printf("export %s='%s'\n", $1, $2)
                }
                ' ${FILE}
        fi
    done
    ) >> ${TMPFILE}

    # extract networks_list and networks_whitelist
    networks_whitelist=`cat networks_whitelist`
    networks_whitelist="`echo ${networks_whitelist}`" # remove \n

    echo "export networks_list=`cat networks_list`" >> ${TMPFILE}
    echo "export networks_whitelist=$networks_whitelist" >> ${TMPFILE}
    logit "extracted vars saved in ${TMPFILE}"

    # fix var=value value -> var='value value'

    sed "
        s/=/='/
        s/$/'/
    " ${TMPFILE} > ${TMPEXPORT}

    cat << EOF >> ${TMPEXPORT}
    export SEARCH="${SEARCH}"
    export QUERY="${QUERY}"
EOF
    logit "extracted vars from ${TMPFILE} escaped and saved in ${TMPEXPORT}"

    # design bummer:
    # dump schema to sql template - not possible as some vars are not identical as value in db
    # while other var=value in config should not be added to db
    # so use a crafted template ${IMPORTSH} instead
    #
    # change uuid_fastnetmoninstanceid to fastnetmoninstanceid
    # change uuid_customerid to customerid
    # change uuid_administratorid to administratorid
    #
    # (
    #     echo "UPDATE flow.fastnetmoninstances"
    #     echo "    SET "
    #     head -n -1 ${SCHEMA}    | awk "{ print \"    \" \$1 \" = '\$\" \$1 \"',\" }"     # all but last line
    #     tail -1 ${SCHEMA}       | awk "{ print \"    \" \$1 \" = '\$\" \$1 \"'\" }"      # no , on last line
    #     echo "WHERE \${SEARCH} = '\${QUERY}';"
    # ) > ${IMPORTSH}

    # # source TMPEXPORT and expand
    (
        . ${TMPEXPORT}
        if [ -z ${uuid_administratorid} ]; then
            uuid_administratorid=${default_uuid_administratorid}
            logit "using default administrator id ... "
        fi

        logit "creating ${IMPORT} from ${TMPEXPORT} ... "
        envsubst < ${IMPORTSH} > ${IMPORT}
    ) 

    logit "escaping empty sql statements ... "
    sed 's/\(.*'\'''\''\)/    -- \1/g' $IMPORT > $TMPFILE; /bin/mv $TMPFILE $IMPORT
    
    # Remove trailling , from second last line (before the WHERE clause -- works on BSD, Linux and OSX
    logit "removing last trailing comma ... "
    # { echo '$-1s/,$//' ; echo "w" ; } | ed import.sql >/dev/null 2>&1
    sed -i '1h;1!H;$!d;g;s/\(.*\),/\1/' ${IMPORT}

    cat <<-'EOF' | sed "s/_IMPORT_/${IMPORT}/g"

Please check `_IMPORT_` and  import with

    cat _IMPORT_ |sudo su postgres -c "cd /tmp; psql -d netflow"

EOF
}

function addcfgtodb()
{
    test -n "${HOSTNAME}" || {
        echo "please specify hostmame with -n"
        usage
        exit 0
    }
    test -n "${vpn_ip_addr}" || {
        echo "please specify vpn ip address with -i"
        usage
        exit 0
    }

    OUTPUT=/tmp/$$.out

    cat << EOF | sudo su postgres -c "cd /tmp; psql -P format=unaligned -P fieldsep== -d netflow" | sed "s/=/='/; s/$/'/; /Expanded display is on/d;/Output format is unaligned/d; /Field separator is/d" > ${OUTPUT}
SELECT hostname, vpn_ip_addr from flow.fastnetmoninstances
WHERE hostname = '${HOSTNAME}' OR
      vpn_ip_addr = '${vpn_ip_addr}' \x\g
EOF

    egrep "${HOSTAME}|${vpn_ip_addr}" ${OUTPUT}
    case $? in
        0)  echo "hostname ${HOSTAME} or ip ${vpn_ip_addr} exists, bye"
            /bin/rm -f ${OUTPUT}
            exit 1
            ;;
        *)  :
        ;;
    esac

    /bin/rm -f ${OUTPUT}

    assert "${HOSTNAME} != ''"       $LINENO
    assert "${vpn_ip_addr} != ''"    $LINENO

    get_interface_information_from_bootstrap

    ADMINISTRATORID=42
    UUID_CUSTOMERID='f561067e-10e3-44ed-ab12-9caed904d8d9'
    UUID_ADMINISTRATORID='3611a271-50ae-4425-86c5-b58b04393242'
    CUSTOMERID=3

    logit << EOF
    Creating ./add_new_fastnetmon.sql with values:

    fastest interface: '${FASTEST_INTERFACE}'
    uplink           : '${UPLINK}'

    hostname:        : '$HOSTNAME'
    vpn_ip_addr      : '$vpn_ip_addr'
    uuid             : '$UUID'

    WARNING:
    Default (but wrong) values has been added for
    administratorid:            $ADMINISTRATORID
    uuid_customerid:            $UUID_CUSTOMERID
    uuid_administratorid:       $UUID_ADMINISTRATORID
    customerid:                 $CUSTOMERID

    Add new host with 
    
    cat add_new_fastnetmon.sql | sudo su postgres -c "cd /tmp; psql -d netflow"

EOF

        (
        export CUSTOMERID
        export UPLINK
        export FASTEST_INTERFACE
        export UUID
        export vpn_ip_addr
        export HOSTNAME
        export ADMINISTRATORID
        export UUID_CUSTOMERID
        export UUID_ADMINISTRATORID
        envsubst < /opt/db2dps/etc/configs/add_new_fastnetmon.sql.SH > add_new_fastnetmon.sql
    )

# BEGIN REPLACE
# fix due to missing default parameters (from default fastnetmon.conf)
#   EXABGP_COMMUNITY='65001:666'
#   REMOTE_SYSLOG_SERVER='10.10.10.10'
#   NETWORKS_LIST_PATH='/usr/local/etc/networks_list'
#   WHITE_LIST_PATH='/usr/local/etc/networks_whitelist'
#
#
#    cat << EOF | sudo su postgres -c "cd /tmp; psql -d netflow"
#INSERT INTO flow.fastnetmoninstances 
#(networks_list_path, white_list_path, customerid, exabgp_community, remote_syslog_server, internet_if, lan_if, uuid, mode, vpn_ip_addr, hostname, administratorid, uuid_customerid, uuid_administratorid, uuid_fastnetmoninstanceid)
#VALUES
#('${NETWORKS_LIST_PATH}', '${WHITE_LIST_PATH}', '${CUSTOMERID}', '${EXABGP_COMMUNITY}', '${REMOTE_SYSLOG_SERVER}', '${UPLINK}', '${FASTEST_INTERFACE}', '${UUID}', 'discard', '${vpn_ip_addr}', '${HOSTNAME}', '${ADMINISTRATORID}', '${UUID_CUSTOMERID}', '${UUID_ADMINISTRATORID}', uuid_generate_v4());
#EOF
#
#    db2cfg
#
#    # finally build rc.conf
#    (
#    . export.SH
#    # TODO fix lan_if -> fastnetmon_if in db
#    if [ -z "${fastnetmon_if}" ]; then
#        export fastnetmon_if=$lan_if
#    fi
#    envsubst < /opt/db2dps/etc/configs/rc.conf.SH   > rc.conf
#    )
#
#    logit << EOF
#
#    WARNING:
#    Default (but wrong) values has been added for
#    administratorid:            $ADMINISTRATORID
#    uuid_customerid:            $UUID_CUSTOMERID
#    uuid_administratorid:       $UUID_ADMINISTRATORID
#    customerid:                 $CUSTOMERID
#
#    Use
#
#    cat << EOF | sudo su postgres -c "cd /tmp; psql -d netflow"
#    UPDATE flow.fastnetmoninstances SET
#    administratorid = 'replace',
#    uuid_customerid = 'replace',
#    uuid_administratorid = 'replace'
#    WHERE ${SEARCH} = '${QUERY}';
#    EOF
#
#    This does not change anything for the config files
#
#EOF
    # reset seq
    # ALTER SEQUENCE flow.fastnetmon_instances_fastnetmon_instanceid_seq RESTART WITH 3;
    #REPLACE WITH
    # fill import.sql with default+ values, leave note on how to import once ok
    # then 
    # - export to config files
    # - push to host
    #   - test on host, prepare rollback if faileure (rc.conf move back)
    #   - test ssh access to ddps via openvpn
    #END REPLACE

}

function clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
    $echo trapped
    /bin/rm -f $TMPFILE $MY_LOGFILE
    exit 1
}

function main()
{
    # check on how to suppress newline (found in an Oracle installation script ca 1992)
    echo="/bin/echo"
    case ${N}$C in
        "") if $echo "\c" | grep c >/dev/null 2>&1; then
            N='-n'
        else
            C='\c'
        fi ;;
    esac

    find_port_and_listen_address

    default_uuid_administratorid=`sed '/^default_uuid_administratorid/!d; s/.*=[\t ]*//g' /opt/db2dps/etc/fnmcfg.ini`
    bootstrap_ip=`sed '/^bootstrap_ip/!d; s/.*=[\t ]*//g' /opt/db2dps/etc/fnmcfg.ini`

    test -d  ${WORKDIR} || mkdir ${WORKDIR}

    while getopts adcepgli:n:mvhus opt
    do
    case $opt in
        a)  DO=addcfgtodb
            ;;
        i)  SQL="select
             *\x
             from flow.fastnetmoninstances where vpn_ip_addr = '$OPTARG';"
             SEARCH="vpn_ip_addr"
             QUERY="$OPTARG"
             vpn_ip_addr="$OPTARG"
            ;;
        d)  DO=db2cfg
            ;;
        n) SQL="select
             *\x
             from flow.fastnetmoninstances where hostname = '$OPTARG';"
             SEARCH="hostname"
             QUERY="$OPTARG"
             HOSTNAME="$OPTARG"
            ;;
        c)  DO=cfg2db
            ;;
        e)  DO=edit
            ;;
        p)  DO=pushcfg
            ;;
        u)  DO=updatecfg
            ;;
        g)  DO=getcfg
            ;;
        l)  DO=loop
            ;;
        v)  VERBOSE=TRUE
            ;;
        h)  usage
            exit
            ;;
        s)  DO=status
            ;;
    	*)	usage
    		exit
    	;;
    esac
    done
    shift `expr $OPTIND - 1`
    
    logit "Starting $0 $*"

    case ${DO} in
        "") echo "wrong usage, argument missing"
            ;;
        *) $DO
            ;;
    esac
  
    /bin/rm -f $MY_LOGFILE
    exit 0

}

################################################################################
# Main
################################################################################
#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

main $*

