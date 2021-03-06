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
my $platform = $query->param("platform");
my $id = $query->param("id");
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT $platform FROM ags WHERE sample=\'$id'\;/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$genes = $sth->fetchrow_array;
print $genes;

$sth->finish;
$dbh->disconnect;