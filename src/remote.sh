#! /bin/bash
#
# $Id$
#
# This should have be written in some other language
#

# determine the directory where $0 is located. Realpath is not part of OSX
MYDIR=`dirname $0`
MYDIR=`realpath ${MYDIR}`

MYNAME=`basename $0`
MY_LOGFILE=$MYDIR/${MYNAME}.log

logit() {
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

function usage()
{
	cat << EOF

	Edit locally, push source files to remote host, comile, test install etc.

	$0 [-d][-g][-n][-v][-n] push | fetch | make ...
	-d: add developer version files (version.h,c .version)
	-g: do git add . , push origin master, commit in \$PROJDIR
	-n: dont actually do anything
	-v: be verbose
	push:   push source from `pwd` to ${TARGETHOST}:${UPLOADDIR}
	clean:	push source from `pwd` to ${TARGETHOST}:${UPLOADDIR}
	fetch:  retch source from ${TARGETHOST}:${UPLOADDIR} to ${TMPDIR}
	make:  push (rsync) then ssh 'chdir && make what-ever'
	        The argument to make should be passed to make, e.g.:
	$0 make test
	$0 make target

	Notice that 'clean' will delete everything on ${TARGETHOST}:${UPLOADDIR}

	TARGETHOST:	${TARGETHOST}
	UPLOADDIR:	${UPLOADDIR}
	TMPDIR:		${TMPDIR}

EOF
	exit 0
}

################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

MY_ARGS="$0 $*"

# Read parameters from Makefile - and here be dragons! You have been warned!
eval `sed '/#:REMOTE-INFO-BEGIN/,/#:REMOTE-INFO-END/!d; /^#/d; /^$/d; s/[	 ]*=[	 ]*\(.*\)/="\1"/' Makefile`
RSYNC_ARGS="${RSYNC_ARGS}=${EXCLUDE_FILE}"

#
# Process arguments
#
while getopts dgnmv opt
do
case $opt in
	d)	DEV=TRUE
	;;
	g)	GIT=TRUE
	;;
	v)	VERBOSE=TRUE
	;;
	n)	DRYRUN=TRUE
		RSYNC_ARGS="-n ${RSYNC_ARGS}"
		MAKE_ARGS="-n "
	;;
	m)	./srctoman - ./remote.sh|groff  -man -Tutf8 |less
		exit
	;;
	*)	usage
		exit
	;;
esac
done
shift `expr $OPTIND - 1`

# Test file expressions
for file in ${EXCLUDE_FILE} ${LRSYNC} ${SSH} ${SRCDIR} ${PROJDIR} ${MYDIR} 
do
	if ! [ -e $file ]; then
		echo "Cannot find file / directory....: $file"
		echo "Please change the line .........:`grep $file Makefile` in Makefile"
		exit 2
	fi
done
# shuld also test "${TARGETHOST}" "${UPLOADDIR}" "${TMPDIR}" "${RRSYNC}" "${RSYNC_ARGS}" "${RSYNC_ARGS}" "${SSH_ARGS}"
if [ "${DRYRUN}" = "TRUE" ]; then
	: # leave the old logfile
else
	/bin/rm -f ${MY_LOGFILE}
	logit "Begin"
	logit "called as: ${MY_ARGS}"

	git_sha=`git rev-parse HEAD`
	build_date=`date +"%Y-%m-%d %H:%M"`

	VERSION=`git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1`
	MAJOR="1"
	MINOR="0"
	PATCH="1"

	case $VERSION in
		"") echo "No version found"
			VERSION="${MAJOR}.${MINOR}-${PATCH}"
			git tag ${VERSION}
		;;

		*)	echo "Found version: VERSION = ${VERSION}"
			MAJOR=`echo ${VERSION} | awk -F'.' '$1 ~ /^[0-9]+$/ { print $1 }'`
			MINOR=`echo ${VERSION} | sed 's/^.*\.//; s/-.*//' | awk '$1 ~ /^[0-9]+$/ { print $1 }'`
			PATCH=`echo ${VERSION} | awk -F'-' '$NF ~ /^[0-9]+$/ { print $NF }'`
			NEXTP=`echo ${PATCH:=0} +1 | bc`
			echo "current version: ${VERSION}: MAJOR=${MAJOR:="1"} MINOR=${MINOR:="0"} PATCH=${PATCH:="1"}"
			echo "assuming patch update from ${PATCH} to ${NEXTP}"
			VERSION="${MAJOR}.${MINOR}-${NEXTP}"
		;;
	esac
fi

#
# Source file versioning, See
#	http://stackoverflow.com/questions/1704907/how-can-i-get-my-c-code-to-automatically-print-out-its-git-version-hash
#
if [ "${DEV}" = "TRUE" ]; then
	if [ "${DRYRUN}" = "TRUE" ]; then
		logit "not creating .version, version.c and version.h on dry-run"
	else
		logit "making developer version files ... "
		# make version.h and version.c and .version
		# VERSION=`git describe --long --dirty --tags --always`
		echo ${VERSION} > .version
		cat <<-EOF > version.pm
			my \$version = "${VERSION}";
			my \$build_date = "${build_date}";
			my \$build_git_sha = "${git_sha}";
EOF
		cat <<-EOF > version.c
			/* autogen by $0 on `date` */
			#include "version.h"
			const char * version = "${VERSION}";
			const char * build_date = "${build_date}";
			const char * build_git_sha = "${git_sha}";
EOF
		cat <<-EOF > version.h
			/* autogen by $0 on `date` */
			#ifndef VERSION_H
			#define VERSION_H
			#define VERSION "${VERSION}"
			extern const char * build_date;		/* date +"%Y-%m-%d %H:%M" - source file last edited */
			extern const char * build_git_sha;	/* git rev-parse HEAD */
			#endif /* VERSION_H */
EOF
	fi
fi	# DEV


#
# update git
#
if [ "${GIT}" = "TRUE" ]; then
	if [ "${DRYRUN}" = "TRUE" ]; then
		logit "no gitupdate on dry-run"
	else
		echo new version: $VERSION
		pushd ${PROJDIR}
		logit "exec git commands in `pwd`:"
		git tag ${VERSION}
		git push origin ${VERSION}
		git add .
		git push origin master
		git commit -m "automatic commit by $0"
		popd
	fi
fi
#
# Print variables if verbose
#
cat << EOF | logit
Environment:
git_sha:        '$git_sha'
build_date:     '$build_date'
TARGETHOST:     '$TARGETHOST'
UPLOADDIR:      '$UPLOADDIR'
EXCLUDE_FILE:   '$EXCLUDE_FILE'
TMPDIR:         '$TMPDIR'
RRSYNC:         '$RRSYNC'
LRSYNC:         '$LRSYNC'
RSYNC_ARGS:     '$RSYNC_ARGS'
SSH_ARGS:       '$SSH_ARGS'
SSH:            '$SSH'
SRCDIR:         '$SRCDIR'
PROJDIR:        '$PROJDIR'
MYDIR:          '$MYDIR'
EOF

#
# Let me know where the source was pushed from
#
if [ "${DRYRUN}" = "TRUE" ]; then
	logit "no .source_info update in dryrun"
else
	cat << EOF > .source_info

Last update on `date`.

Maintained on `hostname` in `pwd` by `whoami`

EOF
fi

case $1 in
	git)
		if [ "${DRYRUN}" = "TRUE" ]; then
			logit "no git in dryrun"
		else
			$echo $N "message: [automatic commit by $0] $C"
			read MESSAGE
			case ${MESSAGE} in
				"") MESSAGE="automatic commit by $0"
				;;
				*)	:
				;;
			esac
			pushd ${PROJDIR}
			logit "exec git commands in `pwd`:"
			git add .
			git push origin master
			git commit -m "automatic commit by $0"
			popd
		fi
		;;
	clean)	
		CMD="${LRSYNC} ${RSYNC_ARGS} --delete-excluded --rsync-path ${RRSYNC} ${MYDIR}/ ${TARGETHOST}:${UPLOADDIR}/"
		logit "command: ${CMD}"
		echo ""
		echo "This will remove everything not local including compiled libraries and non-local source files"
		for f in 10 9 8 7 6 5 4 3 2 1; do $echo $N "$f $C"; sleep 1; done
		${CMD} | logit
	;;
	push)	
		CMD="${LRSYNC} ${RSYNC_ARGS} --rsync-path ${RRSYNC} ${MYDIR}/ ${TARGETHOST}:${UPLOADDIR}/"
		logit "command: ${CMD}"
		${CMD} | logit
	;;
	fetch)
		CMD="${LRSYNC} ${RSYNC_ARGS} --rsync-path ${RRSYNC} ${TARGETHOST}:${UPLOADDIR}/ ${TMPDIR}/"
		logit "command: ${CMD}"
		${CMD} | logit
	;;
	make)
		logit "rsync files to ${TARGETHOST} ... "
		CMD="${LRSYNC} ${RSYNC_ARGS} --rsync-path ${RRSYNC} ${MYDIR}/ ${TARGETHOST}:${UPLOADDIR}/"
		logit "command: ${CMD}"
		${CMD} | logit
		logit "exec 'make ${MAKE_ARGS} $2' on ${TARGETHOST} ... "
		cat << EOF | ${SSH} ${SSH_ARGS} ${TARGETHOST} 2>&1 | logit
cd ${UPLOADDIR}
pwd
make ${MAKE_ARGS} $2
EOF
	;;
	*)	usage
	;;
esac

logit "done"

exit 0


#
# Documentation and  standard disclaimar
#
# Copyright (C) 2010 Niels Thomas Haugård, thomas@haugaard.net
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#++
# NAME
#	remote.sh 1
# SUMMARY
#	edit locally, push source files to remote host
# PACKAGE
#	project_template
# SYNOPSIS
#	remote.sh push [-d][-g][-n][-v][-n] push | fetch | make ...
# DESCRIPTION
#	Access to a restricted \fCgit\fP server and your personal enviromnent
#	may not always be an option. The alternative is either to edit the
#	files locally and push changes to the target host or edit the files
#	on a target host (and live with the host IDE and enviromnent) and
#	fetch the edited files when finished.
#
#	\fCremote.sh\fP is - together with a \fCMakefile\fP an approach to
#	automate the process of editing locally, test and deploy remotely.
#
# FILES
# .RS
# .TP
#	\fCproject_template/src/Makefile\fR
#	Default makefile with extra parameters at the top. Change to your
#	heart desere but leave the top with the correct parameters.
# .TP
#	\fCproject_template/src/remote.sh\fR
#	This script.
# .RE
#	
# OPTIONS
# .TP
#	\fC-d\fP
#	add \fIversion info\fR by creating / updating \fCversion{c.h}\fP and
#	\fC.version\fP with git information.
# .TP
#	\fC-g\fP
#	Update git.
# .TP
#	\fC-n\fP
#	Dry-run: don't do anything but print commands.
# .TP
#	\fC-v\fP
#	Be verbose.
#
# MAKEFILE
# 	The default syntax for Makefiles is \fIvar = value\fR.
# .nf
#	\fC

	#:REMOTE-INFO-BEGIN
	TARGETHOST		= root@vagt
	UPLOADDIR		= /usr/local/src/vagt-scripts

	# Path to local and remote rsync
	RRSYNC			= /usr/bin/rsync
	LRSYNC			= /usr/bin/rsync
	# Path to local ssh
	SSH				= /usr/bin/ssh
	# Arguments to rsync, EXCLUDE_FILE will be appended
	EXCLUDE_FILE	= rsync_exclude.txt
	RSYNC_ARGS		= -avzH --exclude-from
	SSH_ARGS		=  -Tq -o LogLevel=error 

	# This directory (source)
	SRCDIR			= .

	# Project directory -- see 
	PROJDIR			= ../../vagt-scripts
	#:REMOTE-INFO-END
	 
# .fi
#	\fR
#
#	Pay attention to quotes and shell metacharacter - the variables are
#	evaled by bash. This may be a security risk to your project so pay
#	attention.
#
# COMMANDS
#	\fCbash(1)\fR, \fCssh(1)\fR, \fCrsync(1)\fR, \fCsed(1)\fR and \fCawk(1)\fR.
# SEE ALSO
#	Documentation on the internal gitlab server
# DIAGNOSTICS
#	Errors of any kind should be printed on std-err and std-out.
# BUGS
#	Please report any errors to the author.
# VERSION
#	See git
# HISTORY
#	See git
# AUTHOR(S)
#	Niels Thomas Haugård
# .br
#	E-mail: thomas@haugaard.net
# .br
#	DeIC / i2.dk
# .br
#	DTU, Building 304
# .br
#	DK-2800 Kgs. Lyngby
#--
