#!/usr/bin/speedy -w

# script for retrieving survival options for the given response cohort, datatype, platform, screen and sensitivity
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @surv);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
my $cohort = $query->param("cohort"); 
my $platform = $query->param("platform"); 
my $screen = $query->param("screen"); 
my $sensitivity = $query->param("sensitivity"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT response_survival_list(\'$source'\, \'$cohort'\, \'$datatype'\, \'$platform'\, \'$screen'\, \'$sensitivity'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@surv = $sth->fetchrow_array()) {
    print(@surv);
	print("|");
}
$sth->finish;
$dbh->disconnect;