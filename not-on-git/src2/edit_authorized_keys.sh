#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#--------------------------------------------------------------------------------------#

authorized_keys=/home/sftpgroup/newrules/.ssh/authorized_keys

trap 'echo please exit nicely' 1 2 3 13 15

hosts="ww1.ddps.deic.dk ww2.ddps.deic.dk"
me="`hostname`"
partner=`echo ${hosts} | sed "s/${me}//g;s/[[:blank:]]//g; s/[[:space:]]//g"`


sudo chattr -i $authorized_keys
sudo vi /home/sftpgroup/newrules/.ssh/authorized_keys
sudo chattr +i $authorized_keys

echo "sudo chattr -i $authorized_keys" | ssh -qt $partner 2>/dev/null
scp $authorized_keys $partner:$authorized_keys
echo "sudo chattr +i $authorized_keys" | ssh -qt $partner 2>/dev/null

exit 0

   Copyright 2017, DeiC, Niels Thomas Haugård

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
