#!/usr/bin/env bash
#

LOCK=/tmp/update_in_progress
ERRORS=/tmp/errors
MY_LOGFILE=/tmp/logfile.txt
STATUS="unknown"

function update_lock() {
    logit "locking update ... "
    while :;
    do
        if  [ -f $LOCK ]; then
            ps -p `cat $LOCK` >/dev/null 2>&1 || /bin/rm $LOCK
        else
            break
        fi
        sleep 1
    done
    echo $$ > $LOCK
    logit "lock acquired"
}

function release_lock()
{
    /bin/rm $LOCK
    logit "lock released"
}

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

function backup_current_configuration()
{

    e=/usr/local/etc
    c=/etc

    tar cvfpz   /root/prev.backup.tar.gz 	\
                $e/fastnetmon.conf			\
                $e/networks_list			\
                $e/networks_whitelist		\
                $e/influxd.conf				\
                $e/openvpn/openvpn.conf		\
                $c/rc.conf				    \
                /opt/i2dps/etc/ssh/*		>/dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "status: creating archive of prev. configuration failed, stop"
        exit 0
    fi
    logit "backup of current configuration successful saved as /root/prev.backup.tar.gz"
}

function update_configuration()
{
    logit "updating configuration files ... "
    ALL_FILES="fastnetmon.conf influxd.conf networks_list networks_whitelist rc.conf fnm2db.ini" # openvpn.conf id_ed25519 id_ed25519.pub

    for FILE in ${ALL_FILES}
    do
        test -f ${FILE} || {
            echo "required file $FILE missing, abort"
            exit 1
    }
    done
    cp fastnetmon.conf influxd.conf networks_list networks_whitelist /usr/local/etc/
    chown influxd:influxd /usr/local/etc/influxd.conf
    cp fnm2db.ini /opt/i2dps/etc/

    logit "done. Restarting and testing services ... "

    # too risky for now
    # cp rc.conf /etc
    # chmod 755 /etc/rc.conf
    #cp id_ed25519* /opt/i2dps/etc/ssh/
    #cp openvpn.conf /usr/local/etc/openvpn/
    #chmod 700 /usr/local/etc/openvpn/openvpn.conf

    echo "begin:0:`date`" >> $ERRORS

    #hostname `sed '/hostname/!d; s/.*=//;s/\"//g' /etc/rc.conf` 
    #/etc/rc.d/netif restart >/dev/null 2>&1
    #echo netstart:$? >> $ERRORS
    #service openvpn restart >/dev/null 2>&1
    #echo openvpn:$? >> $ERRORS

    service fastnetmon stop >/dev/null 2>&1
    service influxd stop >/dev/null 2>&1

    service influxd start >/dev/null 2>&1
    echo influxd:$? >> $ERRORS

    service fastnetmon start >/dev/null 2>&1
    echo fastnetmon:$? >> $ERRORS

    ping -c 10 192.168.67.1 >/dev/null 2>&1
    echo ping:$? >> $ERRORS
    echo "end:0:`date`" >> $ERRORS
}

function test_configuration() {
    service influxd status >/dev/null 2>&1
    echo influxd_status:$? >> $ERRORS
    service fastnetmon status >/dev/null 2>&1
    echo fastnetmon_status:$? >> $ERRORS
    ping -c 10 192.168.67.1 >/dev/null 2>&1
    echo ping:$? >> $ERRORS

    grep -v ':0' $ERRORS
    case $? in
        1)	logit "services running ok"
            STATUS="success"
        ;;
        *) 	echo "faileure: `cat $ERRORS`"
        ;;
        *) 	STATUS="faileure"
        ;;
    esac
}

function rollback() {
    cd /; tar xfpz root/prev.backup.tar.gz
    service influxd restart
    service fastnetmon restart
    hostname `sed '/hostname/!d; s/.*=//;s/\"//g' /etc/rc.conf` 
    /etc/rc.d/netif restart
    service openvpn restart
    # and hope for the best ...
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

    while getopts v opt
    do
        case $opt in
            v)  VERBOSE=TRUE
                ;;
        esac
    done
    shift `expr $OPTIND - 1`
 
    DIR=$1
    cd ${DIR} || {
        echo "program error: cd ${DIR} failed, bye"
        exit 1
    }

    logit "starting ..."
    update_lock

    backup_current_configuration

    update_configuration

    test_configuration
    case $STATUS in
        "success")  :
        ;;
        "faileure") rollback
                    test_configuration      # no options in case of faileures
        ;;
        *)          :# program error?!
        ;;
    esac

    rm -f $ERRORS

    release_lock

    echo "$STATUS"
}

################################################################################
# Main
################################################################################
#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

main $*

exit 0

