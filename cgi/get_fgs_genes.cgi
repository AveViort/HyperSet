#!/usr/bin/speedy -w
# use warnings;

# this function returns list of genes for the given ags
use strict vars;
use HS_SQL;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

our ($dbh, $stat);
my $genes;

my $query = new CGI;
my $fgs = $query->param("fgs");
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT genes FROM fgs WHERE pathway=\'$fgs'\;/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$genes = $sth->fetchrow_array;
print $genes;

$sth->finish;
$dbh->disconnect;