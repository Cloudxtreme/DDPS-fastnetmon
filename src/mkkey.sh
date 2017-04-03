#!/bin/bash

#: uuid = ifconfig `netstat -rn|awk '$1 == "0.0.0.0" { print $NF }'` |sed '/HWaddr/!d; s/.*HWaddr //'

SSHDIR=/tmp/ssh

test -d $SSHDIR || {
	mkdir -p $SSHDIR
}

export extif=`netstat -rn|awk '$1 == "0.0.0.0" { print $NF }'`
export uuid=`ifconfig $extif |sed '/HWaddr/!d; s/.*HWaddr //'`

ssh-keygen -C "root@$uuid" -N '' -t ED25519 -b 16384 -f /tmp/ssh/id_rsa

