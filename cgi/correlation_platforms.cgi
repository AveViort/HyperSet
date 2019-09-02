#!/usr/bin/speedy -w

# script for retrieving platforms for the given correlation datatype
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @platform);

my $query = new CGI;
my($sqltable, $order ) = ('best_drug_corrs', ' abs(correlation) DESC ');
my $datatype = $query->param("datatype"); 
$datatype = "%" if $datatype eq "all";
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT cor_platform_list(\'$datatype'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@platform = $sth->fetchrow_array()) {
    print(@platform);
	print("|");
}
$sth->finish;
$dbh->disconnect;