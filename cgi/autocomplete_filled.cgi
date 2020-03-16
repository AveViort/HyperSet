#!/usr/bin/speedy -w

# script to check if autocomplete contains records for the given platform: use it for debug purposes
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);

my $query = new CGI;
my $cohort = $query->param("cohort");
my $platform = $query->param("platform"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT EXISTS(SELECT \'$platform'\ FROM druggable_ids WHERE cohort=\'$cohort'\ AND '\$platform\' IS NOT NULL)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
# this flag shows if datatype has ids or no - to hide id_input or not to hide
my $flag = $sth->fetchrow_array;
print $flag;
$sth->finish;
$dbh->disconnect;