#!/usr/bin/speedy -w
# use warnings;

# script for filling list of sources and associated drugs
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $stat);

$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
print "Content-type: text/html\n\n";
$stat = qq/SELECT sources_and_drugs()/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@source = $sth->fetchrow_array) {
		print @source;
		print "|";
}
$sth->finish;
$dbh->disconnect;