#!/bin/bash
#
#   Copyright 2017, DeiC, Niels Thomas Haugård
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

MYNAME=`basename $0`
MY_LOGFILE=/tmp/${MYNAME}.log
VERBOSE=FALSE
MAKE_CONFIG_FILES=FALSE

VARS="process_incoming_traffic,
process_outgoing_traffic,
ban_details_records_count,
enable_subnet_counters,
check_period,
enable_connection_tracking,
ban_for_pps,
ban_for_bandwidth,
ban_for_flows,
threshold_pps,
threshold_mbps,
threshold_flows,
threshold_tcp_mbps,
threshold_udp_mbps,
threshold_icmp_mbps,
threshold_tcp_pps,
threshold_udp_pps,
threshold_icmp_pps,
ban_for_tcp_bandwidth,
ban_for_udp_bandwidth,
ban_for_icmp_bandwidth,
ban_for_tcp_pps,
ban_for_udp_pps,
ban_for_icmp_pps,
interfaces,
average_calculation_time,
average_calculation_time_for_subnets,
max_ips_in_list,
networks_list,
networks_whitelist,
customerid,
fastnetmoninstanceid,
administratorid,
uuid,
mode,
blocktime"

# functions

function logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
    LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
    STRING="$*"

    if [ -n "${STRING}" ]; then
        $echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
        if [ "${VERBOSE}" = "TRUE" ]; then
            $echo "${LOGIT_NOW} ${STRING}"
        fi
    else
        while read LINE
        do
            if [ -n "${LINE}" ]; then
                $echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
                if [ "${VERBOSE}" = "TRUE" ]; then
                    $echo "${LOGIT_NOW} ${LINE}"
                fi
            else
                $echo "" >> ${MY_LOGFILE}
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
    if [ ! "$1" ]; then 
    # Give name of file and line number. 
        echo "Assertion failed:  \"$1\" File \"${BASH_SOURCE[1]}\", line ${BASH_LINENO[0]}"
        echo "  $2"
        exit $E_ASSERT_FAILED 
    # else 
    #   return 
    #   and continue executing the script. 
    fi  
}

logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
    LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
    STRING="$*"

    if [ -n "${STRING}" ]; then
        $echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
        if [ "${VERBOSE}" = "TRUE" ]; then
            $echo "${LOGIT_NOW} ${STRING}"
        fi
    else
        while read LINE
        do
            if [ -n "${LINE}" ]; then
                $echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
                if [ "${VERBOSE}" = "TRUE" ]; then
                    $echo "${LOGIT_NOW} ${LINE}"
                fi
            else
                $echo "" >> ${MY_LOGFILE}
            fi
        done
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

    usage: `basename $0` [-v][-m] -i vpn-ip-address
    usage: `basename $0` [-v][-m] -n hostname

    options:
    -v: verbose
    -m: make new config files from templates and database export
    -i: lookup vpn-ip-address in database
    -n: lookup hostname in database

    See man pages for more info.
EOF
    exit 2
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
    $echo trapped
    /bin/rm -f $TMPFILE $MAILFILE
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

    while getopts ai:n:mv opt
    do
    case $opt in
        a)
            SQL="select
             *\x
            from flow.fastnetmoninstances ;"
            ;;
        i)  vpn_ip_addr=$OPTARG
            VAR=vpn_ip_addr   VALUE=$OPTARG
            SQL="select
             $VARS\x
             from flow.fastnetmoninstances where vpn_ip_addr = '$OPTARG';"
            ;;
        m)  MAKE_CONFIG_FILES=TRUE
            ;;
        n)  hostname=$OPTARG
            VAR=hostname; VALUE=$OPTARG
            SQL="select
             *\x
             from flow.fastnetmoninstances where hostname = '$OPTARG';"
            ;;
        v)  VERBOSE=TRUE
            ;;
    	*)	usage
    		exit
    	;;
    esac
    done
    shift `expr $OPTIND - 1`
    
    logit "Starting $0 $*"

    test -n "${dbpassword}" || usage
    test -n "${SQL}"        || usage
    
    # FIXME should be .
    test -d /tmp/xxxxxx || mkdir /tmp/xxxxxx
    cd /tmp/xxxxxx
    logit "workingdir: `pwd`"
    
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
    
    echo "$SQL" |
        PGPASSWORD="${dbpassword}" psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} |
        sed '/Expanded display is on/d' >  export.txt
    
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
    
    sed "
        /Expanded display is on/d
       s/ /='/
       s/\$/'/
       s/^/export /" < export.txt  > export.SH 
       # /bin/rm -f export.txt
   
    #
    # make config files from templates or not
    #
    case ${MAKE_CONFIG_FILES} in
        FALSE) 
            logit "extracting values from fastnetmon.conf and fnm2db.ini while assuming they are ok"
            (
            for VAR in `echo $VARS |sed 's/,//g'`; do
                 cat fastnetmon.conf fnm2db.ini | sed "
                    /^[ \t]#/d
                    /#/d
                    /=/!d;
                    /^[ \t]*$VAR[ \t]*=/!d;
                    s/[ \t]*//g;
                    " 
            done
            echo networks_whitelist=`cat networks_whitelist`
            echo networks_list=`cat networks_list`
            )  > env_from_configs.SH
            logit "made env_from_configs.SH"
            exit 0
         ;;
        TRUE)   :   # continue ...
        ;;
    esac

    cp /opt/db2dps/etc/configs/fastnetmon.conf.SH   .
    cp /opt/db2dps/etc/configs/fnm2db.ini.SH        .
    
    CFGFILES="fastnetmon.conf influxd.conf fnm2db.ini rc.conf"
    (
        NOW=`date +%s `
        . export.SH

        for file in ${CFGFILES}
        do
            test -f $file && mv ${file} ${file}-${NOW}
        done
        envsubst < fastnetmon.conf.SH   > fastnetmon.conf
        envsubst < fnm2db.ini.SH        > fnm2db.ini
        # for file in fastnetmon.conf
        egrep '\${' fastnetmon.conf
        case $? in 
            1)  logit "fastnetmon.conf from fastnetmon.conf.SH and export.SH: seems ok"
                ;;
            *)  logit "fastnetmon.conf from fastnetmon.conf.SH and export.SH: failed still contains shell vars"
                ;;
        esac
    )
    
    echo "You still have to provide a valid uuid_administratorid for fnm2db.ini (edit it)"
    echo "The uuid_administratorid must be valid for making rules for net monitored by this FastNetMon"

    #for FILE in /opt/db2dps/etc/configs/* 
    #do
    #    test -f ${FILE} || cp ${FILE} .
    #done
    
    logit "everything is saved in `pwd`"
    
    exit 0
    
    # db2conf: only required wars are exported from the db
    # shell export: export.SH 
    # sql export..: 

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

