#!/usr/bin/perl -w

# my $q = new CGI; #new instance of the CGI object passed from the query page index.html
# use warnings;
use strict;
use CGI qw(-no_xhtml);
use DBI;
use Scalar::Util 'looks_like_number';
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi";
use HS_SQL;

our($nm, $pl, $columns);
#if (1 == 1) {
my $importAllDataTables = 1;
my $inputDir = "/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/";
my $mask = "ctd_gnea%";

createIndices($mask);

sub createIndices {
my($mask) = @_;
my($i, $newtable, $stat, $dbh, @indexOn, $field);
$stat = "SELECT table_name FROM information_schema.tables  where table_type= 'BASE TABLE' and table_name like '".lc($mask)."'and table_name NOT like '%_features';";
print STDERR $stat."\n";
$dbh = HS_SQL::connect2PG();
my $tables = $dbh->selectcol_arrayref($stat);
my ($pls, $tt, @ar, $item);
for $tt(@{$tables}) {

#for $field(('sample')) {
for $field(('feature', 'sample')) {
$newtable = $tt.'_'.$field.'s';
$dbh->do("DROP TABLE IF EXISTS $newtable");
my $stat = "CREATE TABLE $newtable ($field) as select distinct $field from $tt";
print STDERR $stat."\n";
$dbh->do($stat);
my $index = join('_', ($field, $newtable));
print STDERR $stat."\n";
$stat = "CREATE INDEX $index ON $newtable ($field);";
print STDERR $stat."\n";
$dbh->do($stat);
$dbh->commit;
$stat = "ANALYZE $newtable ;\n";
print STDERR $stat."\n";
$dbh->do($stat);
}}

$dbh->disconnect;
return undef;
}
# explain select * from ctd_clin_basu_features inner join ctd_clin_marcela_features on ctd_clin_marcela_features.feature = ctd_clin_basu_features.feature;

