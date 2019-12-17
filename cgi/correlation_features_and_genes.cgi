#!/usr/bin/speedy -w
# use warnings;

# this function returns list of unique ids by cohort name and platform
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

our ($dbh, $stat);
my @id;

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
$datatype = "%" if $datatype eq "all";
my $cohort = $query->param("cohort"); 
$cohort = "%" if $cohort eq "all";
my $platform = $query->param("platform"); 
$platform = "%" if $platform eq "all";
my $screen = $query->param("screen"); 
$screen = "%" if $screen eq "all";

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
# sensitivity_m is defined in Aconfig.pm
$stat = qq/SELECT feature_gene_list(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@id = $sth->fetchrow_array()) {
    print(@id);
	print("|");
}
$sth->finish;
$dbh->disconnect;