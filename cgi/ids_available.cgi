#!/usr/bin/speedy -w

# script to check if we have ids for the given datatype
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);

my $query = new CGI;
my $datatype = $query->param("datatype"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT check_ids_availability(\'$datatype'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
# this flag shows if datatype has ids or no - to hide id_input or not to hide
my $flag = $sth->fetchrow_array;
print $flag;
$sth->finish;
$dbh->disconnect;