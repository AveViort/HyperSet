#!/usr/bin/speedy -w

# script to get DepMap ID for the given cell line
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);

my $query = new CGI;
my $line = $query->param("celline"); 

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT depmap_id FROM ccle_links WHERE sample=\'$line\'/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $depmap = $sth->fetchrow_array;
print $depmap;
$sth->finish;
$dbh->disconnect;