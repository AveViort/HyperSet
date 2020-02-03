#!/usr/bin/speedy -w

# script for retrieving screens for the given response cohort, datatype and platform
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @screen);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
my $cohort = $query->param("cohort"); 
my $platform = $query->param("platform"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT response_screen_list(\'$source'\, \'$cohort'\, \'$datatype'\, \'$platform'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@screen = $sth->fetchrow_array()) {
    print(@screen);
	print("|");
}
$sth->finish;
$dbh->disconnect;