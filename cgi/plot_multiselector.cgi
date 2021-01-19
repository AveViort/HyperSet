#!/usr/bin/speedy -w
# use warnings;

# this script is an extension of tcga_codes.cgi
# similar to response_multiselector.cgi works with both TCGA and CCLE (but designed for the "Plots" tab)

use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, $codes);

my $query = new CGI;
my $source = $query->param("source");
my $cohort = $query->param('cohort');
my $datatype = $query->param('datatype');
# unlike tcga_codes.cgi, this variable is not mandatory and can be empty
my $previous_datatypes = $query->param('previous_datatypes');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
my $codes = '';
if ($source eq "TCGA") {
	$stat = qq/SELECT get_tcga_codes(\'$cohort'\, \'$datatype'\, \'$previous_datatypes'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$codes = $sth->fetchrow_array;
}
else {
	$stat = qq/SELECT get_tissue_types(\'$cohort'\)/;
	# get_tissue_types() does not offer metacodes, so add manually
	$codes = 'all';
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my @tissues;
	while (@tissues = $sth->fetchrow_array()) {
		$codes = $codes.','.@tissues[0];
	}
}
print $codes;
$sth->finish;
$dbh->disconnect;