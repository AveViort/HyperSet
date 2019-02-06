#!/usr/bin/speedy -w
# use warnings;

# show info about one project: access level and notification status

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $project = $query->param('project_id');
# verify if session is valid
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT session_valid(\'$uname'\, \'$sign'\, \'$sid'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $session_status = $sth->fetchrow_array;
print "Content-type: text/html\n\n";
if ($session_status ne 0)
{
	$stat = qq/SELECT (access_level, receive_notifications) FROM projects WHERE (owner LIKE \'$uname'\) AND (projectid LIKE \'$project'\)/;
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	my $response = $sth->fetchrow_array;
	print $response;
}
$sth->finish;
$dbh->disconnect;