#!/usr/bin/speedy -w

# script for retrieving sources for correlation analysis
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my (@source);

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT DISTINCT source FROM model_guide_table WHERE table_type=\'predictor'\ AND source IS NOT NULL;/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@source = $sth->fetchrow_array) {
		print @source;
		print "|";
}
$sth->finish;
$dbh->disconnect;