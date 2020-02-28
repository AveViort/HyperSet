#!/usr/bin/speedy -w

# script for retrieving possible response variables for given parameters
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @var);

my $query = new CGI;
my $source = $query->param("source");
my $cohort = $query->param("cohort"); 
my $datatype = $query->param("datatype"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT check_ids_availability(\'$datatype'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
# this flag shows if datatype has ids or no - to hide id_input or not to hide
my $flag = $sth->fetchrow_array;
print $flag;
print "|";
$stat = qq/SELECT response_variable_list(\'$source'\, \'$cohort'\, \'$datatype'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@var = $sth->fetchrow_array()) {
    print(@var);
	print("|");
}
$sth->finish;
$dbh->disconnect;