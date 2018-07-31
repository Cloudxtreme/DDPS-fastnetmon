#!/usr/bin/env bash
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
MY_LOGFILE=~/${MYNAME}.log
VERBOSE=FALSE
DATADIR=/root/files/data/
VERBOSE=FALSE

# functions

function logit()
{
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

function toLower()
{
    echo $1 | tr "[:upper:]" "[:lower:]"
}

function toUpper()
{
    echo $1 | tr  "[:lower:]" "[:upper:]"
}


assert ()
{
    E_PARAM_ERR=98
    E_ASSERT_FAILED=99
    if [ -z "$2" ]          #  Not enough parameters passed
    then                    #+ to assert() function.
        return $E_PARAM_ERR   #  No damage done.
    fi
    lineno=$2
    if [ ! $1 ] 
    then
        echo "Assertion failed:  \"$1\""
        echo "File \"$0\", line $lineno"    # Give name of file and line number.
        exit $E_ASSERT_FAILED
    # else
    #   return
    #   and continue executing the script.
    fi  
} 

usage()
{
    echo $*
    cat << EOF
        Usage: `basename $0` [-v] [buld]

        No args: check everything ok, print uuid and interfaces
        build:
            same + new rc.conf, influx and fastnetmon configs, reboot
EOF
        exit 2
}

clean_f ()
{
    echo trapped
    /bin/rm -f $TMPFILE $MAILFILE
    exit 0
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
        *)  echo "usage: $0 [-v] [build]"
            exit
        ;;
    esac
    done
    shift `expr $OPTIND - 1`

    case $1 in
        "build")    BUILD_CFGS=1
            ;;
        "")         BUILD_CFGS=0
            ;;
    esac

    MY_DIR=`dirname $0`

    # stat $0|logit 
    logit "running from '$MY_DIR' ... "
    cd ${MY_DIR} || {
        echo "chdir ${MY_DIR} failed"; exit 0
    }

    # find uplink and fastest free(no ipv4 assigned) interface for fastnetmon ...

    service openvpn status|logit
    logit "detecting vpn ip address ... "
    vpn_ip_device=`netstat -rn -f inet|awk '$1 == "default" { print $NF }'`
    vpn_ip_address=`ifconfig ${vpn_ip_device}|sed '/inet6/d; /inet/!d; s/.*inet //; s/\ .*$//'`
    assert "${vpn_ip_device} != ''" $LINENO
    assert "${vpn_ip_address} != ''" $LINENO

    logit "vpn interface and address: ${vpn_ip_device} ${vpn_ip_address}"

    logit "stopping openvpn and detecting uplink ip address ... "
    service openvpn stop|logit
    uplink=`netstat -rn -f inet|awk '$1 == "default" { print $NF }'`
    service openvpn start|logit
    logit "openvpn started ... "

    assert "${uplink} != ''" $LINENO

    # ix0 10Gb
    # igb0 1Gb
    # em0  1Gb

    # list interfaces one interface pr. line, use numeric sort to have ix before igb before e        m and exclude virtual interfaces
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

    assert "${fastest_if} != ''" $LINENO

    # uuid=`ifconfig ${fastest_if} |awk '$1 == "ether" { print $NF}'`
    # assert "${uuid} != ''" $LINENO

    logit "uplink: $uplink"
    logit "fastest interface: ${fastest_if}"
    logit "assigned vpn address: ${vpn_ip_address}"

    case ${BUILD_CFGS} in
        1)  CONFIGFILES="rc.conf fastnetmon.conf.tmpl networks_list.tmpl networks_whitelist fnm2db.ini.tmpl"
            SSH_KEYS="ed25519 ed25519.pub"
            OPENVPN_CONFIG="openvpn.conf"
            PKG_FILE="`echo i2dps_*txz`"
            EXPORTED_VARS="export.SH"
            INFLUXD="influxd.conf"

            # only CONFIGFILES will change but all files must exist
            REQUIRED_FILES="${CONFIGFILES} ${SSH_KEYS} ${OPENVPN_CONFIG} ${PKG_FILE} ${EXPORTED_VARS} ${INFLUXD}"
            for FILE in ${REQUIRED_FILES}
            do
                if [ ! -f ${FILE} ]; then
                    echo "file ${FILE} missing, bye"
                    exit 1
                else
                    logit "file ${FILE} found, ok"
                fi
            done

            logit "installing '${PKG_FILE}' ... "
            echo pkg install -y "${PKG_FILE}" 2>&1 |logit

            logit "building host specific config files ... "

            logit "reading files export ./files2db.SH ... "
            source ./files2db.SH
            logit "reading db export ./export.SH ... "
            source ./export.SH

            # sanity check
            if [ -z "${fastnetmon_if}" ]; then
                    fastnetmon_if=$fastest_if
                    logit "warn: fastnetmon_if empty, replaced with fastest interface - $fastest_if"
            fi

            if [ -z "${internet_if}" ]; then
                    internet_if=$uplink
                    logit "warn: internet_if empty, replaced with current uplink - $internet_if"
            fi

            CONFIGDIR=`mktemp -d -t xxxxx`
            if [ $? -ne 0 ]; then
                echo "$0: Can't create temp file, exiting..."
                exit 1
            fi
            logit "building config files in ${CONFIGDIR}"

            logit "/etc/rc.conf: uplink: ${uplink}, FastNetMon mirror interface: ${fastest_if} "
            /usr/local/bin/envsubst < rc.conf.tmpl > ${CONFIGDIR}/rc.conf
            # diff "${CONFIGDIR}/rc.conf" rc.conf|logit

            #cat rc.conf.tmpl| sed "
            #    s/\$internet_interface/$uplink/g
            #    s/\$fastest_if/$fastest_if/g
            #" > /etc/rc.conf

            cp influxd.conf ${CONFIGDIR}/influxd.conf

            logit "/usr/local/etc/influxd.conf:"
            diff  ${CONFIGDIR}/influxd.conf influxd.conf |logit

            # fastnetmon.conf
            # networks_list
            # networks_whitelist

            # fnm2db.ini

            logit "finally move in place if accepted && reboot .... "
            logit "done"

        ;;
        *)  echo "uplink: $uplink"
            echo "fnm interface: ${fastest_if}"

        ;;
    esac

}

################################################################################
# Main
################################################################################
#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

main $*


