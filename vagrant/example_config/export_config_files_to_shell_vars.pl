#! /usr/bin/env perl
# 
#
# The other way around
# - from files to db:
# - read files, print to shell export vars
# - export/insert in db

# fastnetmon.conf -> shell env vars
while (my $line=<STDIN>)
{
    next unless $line   =~ /.*=.*/;     # skip lines with no =
    next if $line       =~ /^$/;        # skip blank lines
    next if $line       =~ /^\s+#,*/;   # skip lines which first non-blank char is #
    next if $line       =~ /^#.*/;      # skip lines which first char is #

    my ($var,$value)= split /=/, $line;
    
    $var    =~ s/^\s+|\s+$//g;          # trim blanks
    $value  =~ s/^\s+|\s+$//g;          # ditto

    if ($var =~ /:/) {
        print "# hmm fix $var\n";
    }
    $var    =~ tr/:/_/;                 # remove : which is not valid in shell vars
    print "export " . $var . "=" . $value . "\n";   # print all changed / set vars, rest are defined as default in db create table
}

# networks_list

# networks_whitelist

# rc.conf -- uplink and fastnetmon mirror port only

# influxdb


exit 0;

__DATA__

#eval `cat fastnetmon.conf.tmpl | awk -F'=' '
#    $0 ~ /=/  { gsub (/ /, "", $1); gsub(/#/, "", $1); print  "export " $1 " = ${" $1 "}" ; next }
#    { print; next }
#'`

# osx: go get github.com/ilkka/substenv, rename to envsubst
