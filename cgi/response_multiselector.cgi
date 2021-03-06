#!/usr/bin/speedy -w

# script for initializing response multiselector
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my(@val);

my $query = new CGI;
my $source = $query->param("source");
my $cohort = $query->param("cohort"); 
my $datatype = $query->param("datatype"); 
my $variable = $query->param("variable");

print "Content-type: text/html\n\n";
$stat = "";
if ($source eq "CCLE") {
	if ($variable eq "tissue") {
		$stat = qq/SELECT 'all|all'/;
	}
	else {
		$stat = qq/SELECT get_tissue_types_meta_n()/;
	}
}
else {
	if ($source eq "TCGA") {
		$stat = qq/SELECT get_tcga_codes_n(\'$cohort'\, \'$datatype'\, \'$variable'\)/;
	}
}
# case when multiselector should not be initialized
if ($stat eq "") {
	print "|"
}
else {
	$dbh = HS_SQL::dbh('druggable');
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	while (@val = $sth->fetchrow_array()) {
		print(@val);
		print("|");
	}
	$sth->finish;
	$dbh->disconnect;
}