#!/usr/bin/speedy -w
# use warnings;

# script for filling list of sources and associated drugs
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;

print "Content-type: text/html\n\n";
my $Text = '("ACT screen, 25 drugs",LCT2290)';
$Text =~ s/[()]//g;
#$Text = m/(.*)",(.*)/;
$Text =  substr($Text, 1);
$Text =~ m|([^"]*)",(.*)|;
print $1