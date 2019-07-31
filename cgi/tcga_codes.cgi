#!/usr/bin/speedy -w
# use warnings;

#this script returns available TCGA sample codes (last two digits) and meta-codes for the chosen cohort, datatype and previous datatypes
# meta-codes are "healthy", "cancer", "all"
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, $tcga_codes);

my $query = new CGI;
my $cohort = $query->param('cohort');
my $datatype = $query->param('datatype');
my $previous_datatypes = $query->param('previous_datatypes');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT get_tcga_codes(\'$cohort'\, \'$datatype'\, \'$previous_datatypes'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$tcga_codes = $sth->fetchrow_array;
print $tcga_codes;
$sth->finish;
$dbh->disconnect;