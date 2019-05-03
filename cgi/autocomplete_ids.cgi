#!/usr/bin/speedy -w
# use warnings;

# this function returns list of unique ids by cohort name, datatype, platform
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, $ids, @data);

my $query = new CGI;
my $cohort= $query->param('cohort');
my $datatype = $query->param('datatype');
my $platform = $query->param('platform');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT autocomplete_ids(\'$cohort'\,\'$datatype'\,\'$platform'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
#$ids = $sth->fetchrow_array;
while (@data = $sth->fetchrow_array()) {
    $ids = $data[0];
    print($ids);
}
print $ids;
$sth->finish;
$dbh->disconnect;