#!/usr/bin/speedy -w
# use warnings;

# file for getting all user projects and user permissions

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $newsign = $query->param('new_signature');
my $session_length = $query->param('session_length');
$dbh = HS_SQL::dbh() or die $DBI::errstr;
# first, verify that session exists
# if ($newsign) {
$stat = qq/SELECT verify_prolong_session(\'$uname'\, \'$sign'\, \'$sid'\, \'$newsign'\, \'$session_length'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$dbh->commit;
# }
print "Content-type: text/html\n\n";
my $newsid = $sth->fetchrow_array;
print $newsid;
print "|";
if (($newsid ne 'Nonexisting_session') && ($newsid ne 'Session_expired'))
{
	$stat = qq/SELECT user_projects(\'$uname'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;

	my @project;
	while (@project = $sth->fetchrow_array) {  # retrieve one row
		print @project;
		print "|";
	}
}
$sth->finish;
$dbh->disconnect;