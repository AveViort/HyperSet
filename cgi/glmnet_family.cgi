#!/usr/bin/speedy -w

# script for getting available families for the given 
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @fam);

my $query = new CGI;
my $resp_datatype = $query->param('datatype');

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT glmnet_family(\'$resp_datatype'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@fam = $sth->fetchrow_array()) {
    print(@fam);
	print("|");
}
$sth->finish;
$dbh->disconnect;