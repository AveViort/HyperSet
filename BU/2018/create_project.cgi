#!/usr/bin/speedy -w

#file for creating new project: create folders and add project to 'projects' table
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HSconfig;
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $project = $query->param('project_id');
my ($sign, $sid, $newsign, $session_length, $exists, $status, $sth);
$dbh = HS_SQL::dbh() or die $DBI::errstr;
if ($uname ne "Anonymous") {
	$sign = $query->param('signature');
	$sid = $query->param('session_id');
	$newsign = $query->param('new_signature');
	$session_length = $query->param('session_length');
	$stat = qq/SELECT verify_prolong_session(\'$uname'\, \'$sign'\, \'$sid'\, \'$newsign'\, \'$session_length'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	$newsid = $sth->fetchrow_array;
}
else {
	$newsid = 'Ok'
}
print "Content-type: text/html\n\n";
print $newsid;
print "|";
if (($newsid ne 'Nonexisting_session') && ($newsid ne 'Session_expired'))
{
	# check if the project already exists
	my $projectlc = lc($project);
	$stat = qq/SELECT project_exists(\'$projectlc'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$exists = $sth->fetchrow_array;
	if ($exists) {
		$status = "Already_exists";
	}
	else {
		$stat = qq/SELECT add_project(\'$projectlc'\, \'$uname'\)/;
		$sth = $dbh->prepare($stat) or die $dbh->errstr;
		$sth->execute( ) or die $sth->errstr;
		$dbh->commit;
		my ($usersDir, $usersTMP);
		$usersTMP = $HSconfig::usersTMP.$projectlc.'/';
		$usersDir = $HSconfig::usersDir.$projectlc.'/';
		system("mkdir $usersDir 1>/dev/null 2>/dev/null");
		system("mkdir $usersTMP 1>/dev/null 2>/dev/null");
		$status = 'Success';
	}
	print $status;
}
$sth->finish;
$dbh->disconnect;