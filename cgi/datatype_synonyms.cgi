#!/usr/bin/speedy -w
# use warnings;

# this script returns a list of external and internal datatype names

use strict vars;
use HS_SQL;

our ($dbh, $stat);
my @id;

$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT datatype_synonyms();/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@id = $sth->fetchrow_array()) {
    print(@id);
	print("|");
}
$sth->finish;
$dbh->disconnect;