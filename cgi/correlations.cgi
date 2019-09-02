#!/usr/bin/speedy -w
# use warnings;

# script for retrieving drug list for each source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $stat);
my @row;

my $query = new CGI;
my $datatype = $query->param("datatype"); 
my $platform = $query->param("platform");
my $screen = $query->param("screen");
my $id = $query->param("id");
my $fdr = $query->param("fdr");

$datatype	= "%" if $datatype	eq "all";
$platform	= "%" if $platform	eq "all";
$screen 	= "%" if $screen	eq "all";
$id 		= "%" if $id 		eq "";

$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT retrieve_correlations(\'$datatype'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m'\, \'$id'\, \'$fdr'\);/;
print "Content-type: text/html\n\n";

my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@row = $sth->fetchrow_array()) {
    print(@row);
}
$sth->finish;
$dbh->disconnect;