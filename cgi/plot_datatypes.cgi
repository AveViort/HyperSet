#!/usr/bin/speedy -w
# use warnings;

#this script returns datatypes available for the chosen source
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @datatype);

my $query = new CGI;
my $cohort = $query->param('cohort');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT datatype_list(\'$cohort'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@datatype = $sth->fetchrow_array) {
		print @datatype;
		print "|";
}
$sth->finish;
$dbh->disconnect;