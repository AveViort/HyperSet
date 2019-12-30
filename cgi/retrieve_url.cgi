#!/usr/bin/speedy -w
# use warnings;

# this function returns list of unique ids by cohort name and platform
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my $url;

my $query = new CGI;
my $id = $query->param("id");

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
# sensitivity_m is defined in Aconfig.pm
$stat = qq/SELECT get_url(\'$id'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$url = $sth->fetchrow_array();
print($url);

$sth->finish;
$dbh->disconnect;