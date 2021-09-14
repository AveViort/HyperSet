#!/usr/bin/speedy -w
# use warnings;

# this script generates a list of available platforms (for CLIN/IMMUNO) or a list of available ids for the given platform
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @res);

my $query = new CGI;
my $cohort = $query->param('cohort');
my $datatype = $query->param('datatype');
my $platform;
# use special variable for fool-proof query decision
my $flag = 0;
if (not($datatype eq "CLIN") and not($datatype eq "IMMUNO")) {
	$platform = $query->param('platform');
	$flag = 1;
}

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
# if flag==0 - show visible platforms for the given platforms and datatype
if ($flag == 0) {
	$stat = qq/SELECT platform_list(\'$cohort'\, \'$datatype'\);/;
}
# else - list ids
else {
	#$stat = qq/SELECT autocomplete_ids(\'$cohort'\, \'$platform'\)/;
	#if (not($datatype eq "DRUG")) {
	#	$stat = qq/SELECT DISTINCT upper(id) FROM $cohort\_$datatype WHERE $platform IS NOT NULL;/;
	#} else {
	#	$stat = qq/SELECT DISTINCT upper(drug) FROM $cohort\_$datatype;/;
	#}
	$stat = qq/SELECT autocomplete_ids_simplified(\'$cohort'\, \'$platform'\)/;
}
#print $stat;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my @temp;
while (@res = $sth->fetchrow_array) {
	if ($flag == 0) {
		@temp = split /\|/, $res[0];
		print $temp[0].'<br>';
	}
	else {
		#@temp = split /\|\|/, $res[0];
		#foreach(@temp) {
		#	print $_.'<br>';
		#}
		print $res[0].'<br>';
	}
}

$sth->finish;
$dbh->disconnect;