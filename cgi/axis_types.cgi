#!/usr/bin/speedy -w
# use warnings;

#this script returns axis transformation types for the chosen cohort, datatype and platform
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @axistype);

my $query = new CGI;
my $cohort = $query->param('cohort');
my $datatype = $query->param('datatype');
my $platform = $query->param('platform');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT get_available_transformations(\'$cohort'\, \'$datatype'\, \'$platform'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@axistype = $sth->fetchrow_array) {
		print @axistype;
		print "|";
}
$sth->finish;
$dbh->disconnect;