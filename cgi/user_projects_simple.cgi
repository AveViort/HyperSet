#!/usr/bin/speedy -w
# use warnings;

# file for getting all user projects and user permissions without session prolongation

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
# first, verify that session exists
$stat = qq/SELECT session_valid(\'$uname'\, \'$sign'\, \'$sid'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
print "Content-type: text/html\n\n";
my $session_status = $sth->fetchrow_array;
$sth->finish();
if ($session_status ne 0) {
	$stat = qq/SELECT user_projects(\'$uname'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;

	my @project;
	while (@project = $sth->fetchrow_array) {  # retrieve one row
		print @project;
		print "|";
	}
	$sth->finish();
}
$dbh->disconnect;