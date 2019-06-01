#!/usr/bin/speedy -w
# use warnings;

use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

my ($dbh, $stat, $sth, @jobs);

my $query = new CGI;
my $project_id = $query->param('project_id');
print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = "SELECT jid FROM projectarchives WHERE projectid=\'".$project_id."\' and jid!='';";
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
while (@jobs = $sth->fetchrow_array) {
		print @jobs;
		print "|";
}
$sth->finish;
$dbh->disconnect;