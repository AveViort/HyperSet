#!/usr/bin/speedy -w

# script for retrieving possible response variables for given parameters
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @var);

my $query = new CGI;
my $source = $query->param("source");
my $datatype = $query->param("datatype"); 
my $cohort = $query->param("cohort"); 
my $platform = $query->param("platform"); 
my $screen = $query->param("screen"); 
my $sensitivity = $query->param("sensitivity");
my $survival = $query->param("survival"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT response_variable_list(\'$source'\, \'$cohort'\, \'$datatype'\, \'$platform'\, \'$screen'\, \'$sensitivity'\, \'$survival'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@var = $sth->fetchrow_array()) {
    print(@var);
	print("|");
}
$sth->finish;
$dbh->disconnect;