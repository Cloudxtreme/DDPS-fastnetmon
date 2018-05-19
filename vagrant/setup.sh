:
IP=192.168.68.3
IP=root@10.33.0.102

echo 'rm -fvr /var/tmp/test01.ddps.deic.dk' | ssh -q ${IP}
rsync -avzL test01.ddps.deic.dk ${IP}:/var/tmp
echo "check ... "
ssh ${IP} 'bash /var/tmp/test01.ddps.deic.dk/postbootstrap.sh -v | tee -a /var/tmp/test01.ddps.deic.dk/build.log'
echo "build ... "
ssh ${IP} 'bash /var/tmp/test01.ddps.deic.dk/postbootstrap.sh -v build | tee -a /var/tmp/test01.ddps.deic.dk/build.log'
echo "done"
