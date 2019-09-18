#!/usr/bin/speedy -w

# script for retrieving screens for the given correlation datatype and platform
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

our ($dbh, $stat);
my( @screen);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
$datatype = "%" if $datatype eq "all";
my $platform = $query->param("platform"); 
$platform = "%" if $platform eq "all";
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT screen_list(\'$source'\, \'$datatype'\, \'$platform'\, \'$Aconfig::sensitivity_m'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@screen = $sth->fetchrow_array()) {
    print(@screen);
	print("|");
}
$sth->finish;
$dbh->disconnect;