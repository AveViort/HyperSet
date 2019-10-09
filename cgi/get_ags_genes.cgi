#!/usr/bin/speedy -w
# use warnings;

# this function returns list of genes for the given ags
use strict vars;
use HS_SQL;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

our ($dbh, $stat);
my @gene;

my $query = new CGI;
my $cohort = $query->param("cohort");
my $datatype = $query->param("datatype");
my $platform = $query->param("platform");
my $id = $query->param("id");
my $table_name = $cohort.'_'.$datatype;
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT DISTINCT id FROM $table_name WHERE sample=\'$id'\ LIMIT 10;/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@gene = $sth->fetchrow_array()) {
    print(@gene);
	print("|");
}
$sth->finish;
$dbh->disconnect;