#!/usr/bin/speedy -w

# script for retrieving datatypes for correlation analysis by given source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

our ($dbh, $stat);
my( @datatype);

my $query = new CGI;
my $source = $query->param("source"); 
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT cor_datatype_list(\'$source'\, \'$Aconfig::sensitivity_m{$source}'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@datatype = $sth->fetchrow_array()) {
    print(@datatype);
	print("|");
}
$sth->finish;
$dbh->disconnect;
