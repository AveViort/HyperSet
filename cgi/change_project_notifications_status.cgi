#!/usr/bin/speedy -w
# use warnings;

# change notifications setting for only one project

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
my $project = $query->param('project_id');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT verify_prolong_session(\'$uname'\, \'$sign'\, \'$sid'\, \'$newsign'\, \'$session_length'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$dbh->commit;
my $newsid = $sth->fetchrow_array;
print "Content-type: text/html\n\n";
print $newsid;
print "|";
if (($newsid ne 'Nonexisting_session') && ($newsid ne 'Session_expired'))
{
	$stat = qq/SELECT change_project_notifications_status(\'$uname'\, \'$project'\) /;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	my $notifications = $sth->fetchrow_array;
	print $notifications;
}
$sth->finish;
$dbh->disconnect;