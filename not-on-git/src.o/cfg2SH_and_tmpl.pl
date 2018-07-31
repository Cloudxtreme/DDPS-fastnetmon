#! /usr/bin/env perl
# 
#

# fastnetmon.conf -> shell env vars
use strict;
use warnings;
 
my $filename = '';
my $shell_export_filename = "files2db.SH";

my @files   = qw(fastnetmon.conf networks_list networks_whitelist fnm2db.ini);

open(my $sh, '>', $shell_export_filename) or die "Could not open file '$shell_export_filename' $!";

foreach my $filename (@files) {

    my $tmpl_file = $filename . ".tmpl";
    open(my $tmpl, '>', $tmpl_file) or die "Could not open file '$tmpl_file' $!";

    if (open(my $fh, '<:encoding(UTF-8)', "./" . $filename))
    {
        print "reading $filename, writing $tmpl_file ...\n";
        while (my $line=<$fh>)
        {
            if ($line !~ /.*=.*/)   { print $tmpl "$line"; next };   # skip lines with no =
            if ($line =~ /^$/)      { print $tmpl "$line"; next };   # skip blank lines
            if ($line =~ /^\s+#,*/) { print $tmpl "$line"; next };   # skip lines which first non-blank char is #
            if ($line =~ /^#.*/)    { print $tmpl "$line"; next };   # skip lines which first char is #

            my $var = "";
            my $value = "";
            ($var,$value) = split /=/, $line;
            
            $var    =~ s/^\s+|\s+$//g;          # trim blanks
            my $new_var = $var;                 # prepare to fix non-shell compatible vars (logging:syslog -> logging_syslog)
            $value  =~ s/^\s+|\s+$//g;          # ditto

            my $new_line = $line;

            if ($var =~ /:/)
            {
                $new_var    =~ s/\Q:\E/_/g;                 # remove : which is not valid in shell vars
                print $sh "# using $new_var instead of $var\n";
            }

            $var    = '${' . $var . '}';
            $new_line =~ s/\Q$value\E/$var/g;

            # print all changed / set vars, rest are defined as default in db create table
            print $sh "export " . $new_var . "=" . $value . "\n";

            print $tmpl "$new_line" ;
        }
        close($fh);
    }
    else
    {
       warn "Could not open file '$filename' $!";
    }
    close($tmpl);
}

close($sh);

exit 0;

__DATA__

#eval `cat fastnetmon.conf.tmpl | awk -F'=' '
#    $0 ~ /=/  { gsub (/ /, "", $1); gsub(/#/, "", $1); print  "export " $1 " = ${" $1 "}" ; next }
#    { print; next }
#'`

# osx: go get github.com/ilkka/substenv, rename to envsubst
