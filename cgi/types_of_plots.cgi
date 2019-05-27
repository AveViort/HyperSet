#!/usr/bin/speedy -w
# use warnings;

# this function returns list of unique plot types for given string of platforms separated by comma
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @type);

my $query = new CGI;
my $platforms = $query->param('platforms');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT available_plot_types(\'$platforms'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@type = $sth->fetchrow_array) {
		print @type;
		print "|";
}
$sth->finish;
$dbh->disconnect;