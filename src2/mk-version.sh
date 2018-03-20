#! /bin/bash
#

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
        # NEXTP=`echo ${PATCH:=0} +1 | bc`
        echo "current version: ${VERSION}: MAJOR=${MAJOR:="1"} MINOR=${MINOR:="0"} PATCH=${PATCH:="1"}"
        #echo "assuming patch update from ${PATCH} to ${NEXTP}"
        #VERSION="${MAJOR}.${MINOR}-${NEXTP}"
    ;;
esac

echo ${VERSION} > .version
cat << EOF > version.pm
my \$version = "${VERSION}";
my \$build_date = "${build_date}";
my \$build_git_sha = "${git_sha}";
EOF
cat << EOF > version.SH
version="${VERSION}"
build_date="${build_date}"
build_git_sha="${git_sha}"
EOF

