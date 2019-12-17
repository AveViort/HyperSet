#!/usr/bin/speedy -w

# script for retrieving platforms for the given correlation datatype
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

our ($dbh, $stat);
my( @platform);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
$datatype = "%" if $datatype eq "all";
my $cohort = $query->param("cohort"); 
$cohort = "%" if $cohort eq "all";

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT cor_platform_list(\'$source'\, \'$datatype'\, \'$cohort'\, \'$Aconfig::sensitivity_m{$source}'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@platform = $sth->fetchrow_array()) {
    print(@platform);
	print("|");
}
$sth->finish;
$dbh->disconnect;