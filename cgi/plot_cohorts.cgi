#!/usr/bin/speedy -w
# use warnings;

#this script returns cohorts available for plotting for the given source
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @cohort);

my $query = new CGI;
my $source = $query->param('source');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT cohort_list(\'$source'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@cohort = $sth->fetchrow_array) {
		print @cohort;
		print "|";
}
$sth->finish;
$dbh->disconnect;