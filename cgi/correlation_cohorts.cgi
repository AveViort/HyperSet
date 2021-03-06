#!/usr/bin/speedy -w

# script for retrieving cohorts for correlation analysis by given source and datatype
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

our ($dbh, $stat);
my( @cohort);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
$datatype = "%" if $datatype eq "all";

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT cor_cohort_list(\'$source'\, \'$datatype'\, \'$Aconfig::sensitivity_m{$source}'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@cohort = $sth->fetchrow_array()) {
    print(@cohort);
	print("|");
}
$sth->finish;
$dbh->disconnect;