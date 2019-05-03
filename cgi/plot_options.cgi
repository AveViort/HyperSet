#!/usr/bin/speedy -w
# use warnings;

#this script returns available plotting options
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my $query = new CGI;
my $platform = $query->param('platform');
print "Content-type: text/html\n\n";