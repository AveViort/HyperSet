#!/usr/bin/speedy -w

# script for retrieving datatypes for correlation analysis by given source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @cohort);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
$datatype = "%" if $datatype eq "all";

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT model_cohort_list(\'$source'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@cohort = $sth->fetchrow_array()) {
    print(@cohort);
	print("|");
}
$sth->finish;
$dbh->disconnect;