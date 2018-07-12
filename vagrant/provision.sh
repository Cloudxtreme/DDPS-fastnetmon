#!/bin/sh
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

ISOURI="http://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/11.1/FreeBSD-11.1-RELEASE-amd64-disc1.iso"
# ISOFILE=`echo ${ISOURI} | sed 's%.*/%%'`
ISOFILE="`basename ${ISOURI}`"
NEWISO=`echo ${ISOFILE}|sed 's/.iso/-custom.iso/'`

case $* in
    "") echo "nothing special to do ... "
        ;;
    "iso")
            echo Setting up ...
            env ASSUME_ALWAYS_YES=YES pkg install rsync cdrtools
            echo Fetching ${ISOURI} ...
            mkdir -p /home/iso
            fetch -m -o /home/iso/${ISOFILE} ${ISOURI}

            echo Prepairing ${ISOFILE} ...
            mkdir -p /mnt/freebsd-iso
            mdconfig -f /home/iso/${ISOFILE}
            mount -t cd9660 /dev/md0 /mnt/freebsd-iso
            rsync -aq /mnt/freebsd-iso/ /mnt/custom-freebsd-iso

            umount /mnt/freebsd-iso
            mdconfig -d -u 0

            cp /vagrant/installerconfig /mnt/custom-freebsd-iso/etc/

            CUSTOM_ISO_TITLE=$(isoinfo -d -i /home/iso/${ISOFILE} | grep "Volume id" | awk '{print $3}')
            echo Creating iso $CUSTOM_ISO_TITLE into ${NEWISO} ...
            mkisofs --quiet -J -R -no-emul-boot -V $CUSTOM_ISO_TITLE -p "XNET" -b boot/cdboot -o /vagrant/${NEWISO} /mnt/custom-freebsd-iso

            cd /vagrant
            ./fbsd-installiso2img.sh ${NEWISO} ${NEWISO}.dmg
        ;;
    "pkg")  echo creating new version of i2dps ...
            set -e
            echo installing bash and git ...
            ASSUME_ALWAYS_YES=yes pkg install bash git
            cd /DDPS-fastetmon/src; bash ./mk-freebsd.sh; /bin/mv *xz /vagrant/
        ;;
esac

exit 0

