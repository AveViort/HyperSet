#!/usr/bin/speedy -w
# use warnings;

# this function returns list ids (genes, drugs) and annotations
use strict vars;
use HS_SQL;

our ($dbh, $stat);
my @id;

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
# sensitivity_m is defined in Aconfig.pm
$stat = qq/SELECT annotation_list();/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@id = $sth->fetchrow_array()) {
    print(@id);
	print("|");
}
$sth->finish;
$dbh->disconnect;