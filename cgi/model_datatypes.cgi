#!/usr/bin/speedy -w

# script for retrieving datatypes for model predictors by given source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);
my( @datatype);

my $query = new CGI;
my $source = $query->param("source"); 
my $cohort = $query->param("cohort"); 
$dbh = HS_SQL::dbh('druggable');
print "Content-type: text/html\n\n";
$stat = qq/SELECT model_datatype_list(\'$source'\, \'$cohort'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@datatype = $sth->fetchrow_array()) {
    print(@datatype);
	print("|");
}
$sth->finish;
$dbh->disconnect;