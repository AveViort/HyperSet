#!/usr/bin/speedy -w

# script for retrieving datatypes for correlation analysis
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @datatype);

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT cor_datatype_list();/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@datatype = $sth->fetchrow_array()) {
    print(@datatype);
	print("|");
}
$sth->finish;
$dbh->disconnect;
