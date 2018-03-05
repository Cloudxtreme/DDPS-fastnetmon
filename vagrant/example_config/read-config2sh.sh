#!/bin/bash
#
# fastnetmon.conf -> shell env vars

#eval `cat fastnetmon.conf.tmpl | awk -F'=' '
#    $0 ~ /=/  { gsub (/ /, "", $1); gsub(/#/, "", $1); print  "export " $1 " = ${" $1 "}" ; next }
#    { print; next }
#'`

awk -F'=' '
    $1 ~ /#/    { print; next }        # skip comments
    $0 ~ /^$/   { print; next }        # skip blank lines
    $0 ~ /=/ 
    {   
        print $1 "=${" $1 "}"
        next;
     }
' fastnetmon.conf #| sed 's/ = /=/; s/^/export /'

# var = value    ==> var=${var}
#  # var = value ==> same
#  ### ...       ==> same

# osx: go get github.com/ilkka/substenv, rename to envsubst
