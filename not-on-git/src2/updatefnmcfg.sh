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
MY_LOGFILE=/var/log/${MYNAME}.log
VERBOSE=FALSE
DATADIR=/root/files/data/
VERBOSE=TRUE

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
    Usage: `basename $0` -g group -h host 

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
    /bin/rm -f $TMPFILE
    exit 1
}

function find_port_and_listen_address()
{
    # we run pgpool2 in production but not in the test environment, it may be installed though
    if [ -f /opt/pgpool2/etc/pgpool.conf ]; then
        # check if using pgpool2 bound to IP and PORT
        /usr/sbin/service pgpool status>/dev/null
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

    logit "Starting $0 $*"
    #
    # Process arguments
    #
    while getopts vp opt
    do
    case $opt in
        v)  VERBOSE=TRUE
        ;;
        p)  PLATFORM=$OPTARG
        ;;
        *)  echo "usage: $0 [-v]"
            exit
        ;;
    esac
    done
    shift `expr $OPTIND - 1`

    find_port_and_listen_address

    SQL="select
    *\x
    from flow.fastnetmoninstances where status = 'pending';"        # unconfigured, pending, updated failed

    export PGPASSWORD="${dbpassword}"

    while :;
    do
        echo "${SQL}" | psql -p ${PORT} -t -F' ' -h $LISTEN -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname}
        sleep 10
    done
   
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


