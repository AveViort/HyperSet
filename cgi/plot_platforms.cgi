#!/usr/bin/speedy -w
# use warnings;

#this script returns platforms available for the chosen source and datatype
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @platform);

my $query = new CGI;
my $cohort = $query->param('cohort');
my $datatype = $query->param('datatype');
my $previous_platforms = $query->param('previous_platforms');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT check_ids_availability(\'$datatype'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
# this flag shows if datatype has ids or no - to hide id_input or not to hide
my $flag = $sth->fetchrow_array;
print $flag;
print "|";
$stat = qq/SELECT platform_list(\'$cohort'\, \'$datatype'\, \'$previous_platforms'\, \'hard\')/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@platform = $sth->fetchrow_array) {
		print @platform;
		print "|";
}
$sth->finish;
$dbh->disconnect;