#!/usr/bin/speedy -w
# use warnings;

# script for filling list of sources and associated drugs
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;

my ($dbh, $stat, $sth);
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT foo()/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $res = $sth->fetchrow_array;
print $res;
$sth->finish;
$dbh->disconnect;