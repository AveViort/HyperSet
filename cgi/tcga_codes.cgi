#!/usr/bin/speedy -w
# use warnings;

#this script returns available TCGA sample codes (last two digits) and meta-codes for the chosen cohort, datatype, platform and previous datatypes and platforms
# meta-codes are "healthy", "cancer", "all"
# this script does not return counts for the retrieved codes
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, $tcga_codes);

my $query = new CGI;
my $cohort = $query->param('cohort');
my $datatype = $query->param('datatype');
my $platform = $query->param('platform');
my $previous_datatypes = $query->param('previous_datatypes');
my $previous_platforms = $query->param('previous_platforms');

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT get_tcga_codes(\'$cohort'\, \'$datatype'\, \'$platform'\, \'$previous_datatypes'\, \'$previous_platforms'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$tcga_codes = $sth->fetchrow_array;
print $tcga_codes;
$sth->finish;
$dbh->disconnect;