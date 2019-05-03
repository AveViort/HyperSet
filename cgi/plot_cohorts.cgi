#!/usr/bin/speedy -w
# use warnings;

#this script returns sources available for plotting
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @cohort);

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@cohort = $sth->fetchrow_array) {
		print @cohort;
		print "|";
}
$sth->finish;
$dbh->disconnect;