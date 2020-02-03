#!/usr/bin/speedy -w

# script for retrieving platforms for the given datatype (dependent variable)
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @platform);

my $query = new CGI;
my $source = $query->param("source");
my $cohort = $query->param("cohort"); 
my $datatype = $query->param("datatype"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT response_platform_list(\'$source'\, \'$cohort'\, \'$datatype'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@platform = $sth->fetchrow_array()) {
    print(@platform);
	print("|");
}
$sth->finish;
$dbh->disconnect;