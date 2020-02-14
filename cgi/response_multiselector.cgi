#!/usr/bin/speedy -w

# script for initializing response multiselector
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my(@val);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
my $cohort = $query->param("cohort"); 
my $platform = $query->param("platform"); 
my $screen = $query->param("screen"); 
my $sensitivity = $query->param("sensitivity");
my $survival = $query->param("survival");
my $variable = $query->param("variable");

print "Content-type: text/html\n\n";
$stat = "";
if (($source eq "CCLE") && ($variable eq "tissue")) {
	$stat = qq/SELECT get_tissue_types(\'$cohort'\)/;
}
else {
	if ($source eq "TCGA") {
		$stat = qq/SELECT get_tcga_codes(\'$cohort'\, \'$datatype'\, \''\)/;
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