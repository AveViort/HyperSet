#!/usr/bin/speedy -w
# use warnings;

#this script returns sources available for plotting for the given source
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @source);

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT DISTINCT source FROM guide_table WHERE source IS NOT NULL/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@source = $sth->fetchrow_array) {
		print @source;
		print "|";
}
$sth->finish;
$dbh->disconnect;