

. files2db.SH
. export.SH

TMPDIR=`mktemp -d`

mkdir -p ${TMPDIR}/opt/i2dps/etc ${TMPDIR}/usr/local/etc

envsubst < fastnetmon.conf.tmpl > ${TMPDIR}/usr/local/etc/fastnetmon.conf
envsubst < influxd.conf.tmpl > ${TMPDIR}/usr/local/etc/influxd.conf
envsubst < fnm2db.ini.tmpl > ${TMPDIR}/opt/i2dps/etc/fnm2db.ini

