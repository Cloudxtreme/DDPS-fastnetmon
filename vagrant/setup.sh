:
echo 'rm -fvr /tmp/test01.ddps.deic.dk' | ssh -q 192.168.68.2
rsync -avzL test01.ddps.deic.dk 192.168.68.2:/tmp
echo "check ... "
ssh 192.168.68.2 'bash /tmp/test01.ddps.deic.dk/postbootstrap.sh -v '
echo "build ... "
ssh 192.168.68.2 'bash /tmp/test01.ddps.deic.dk/postbootstrap.sh -v build'
echo "done"
