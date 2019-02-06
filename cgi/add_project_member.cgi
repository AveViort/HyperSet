#!/usr/bin/speedy -w
# use warnings;

# file for adding a new project member
# WARNING: this file is deprecated. Use invite_project_member.cgi instead

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Net::SMTP;
use Switch;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $newsign = $query->param('new_signature');
my $session_length = $query->param('session_length');
my $project = $query->param('project_id');
my $new_member = $query->param('new_member');
my $member_level = $query->param('member_level');

# verify if session is valid
# WARNING: the following line has been commented to disable the script normal execution
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
	# part 1 - add new member if possible
	$stat = qq/SELECT add_project_member(\'$project'\, \'$uname'\, \'$new_member'\, \'$member_level'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	my $response = $sth->fetchrow_array;
	
	# part 2 - send letter to all project administrators
	if ($response == 1) {
		$stat = qq/SELECT owner FROM projects WHERE projectid LIKE \'$project'\ AND access_level=3 /;
		$sth = $dbh->prepare($stat) or die $dbh->errstr;
		$sth->execute( ) or die $sth->errstr;
		my $access_level;
		switch($member_level) {
			case 1 {$access_level="Read-only"}
			case 2 {$access_level="Read/Write"}
			case 3 {$access_level="Administrator"}
		}
		my $smtp = Net::SMTP->new('localhost') or die $!;
		my $from = 'webmaster@evinet.org';
		my $subject = 'New member joined your project '.$project;
		my $message = 'Dear EviNet project administrator, 

user '.$new_member.' has been successfully added to project '.$project.' by project administrator '.$uname.' with the following access level: '.$access_level.'

You can manage users with your Settings panel. Please follow the administration guide: ...

Regards,
EviNet

----------------------------------------------
EviNet main page: https://www.evinet.org
EviNet FAQ: https://www.evinet.org/help/faq-evi/evi-faq.html';
		my @administrator;
		while (@administrator = $sth->fetchrow_array) {
			$smtp->mail( $from );
			$smtp->to( @administrator );
			$smtp->data();
			$smtp->datasend("To: @administrator\n");
			$smtp->datasend("From: $from\n");
			$smtp->datasend("Subject: $subject\n");
			$smtp->datasend("\n"); # done with header
			$smtp->datasend($message);
			$smtp->dataend();
		}

	# part 3 - send mail to user
		$subject = 'You have been added to EviNet project '.$project;
		$message = 'Dear EviNet user, 

you have been added to project '.$project.' by project administrator '.$uname.' with the following access level: '.$access_level.'

Regards,
EviNet';
		$smtp->mail( $from );
		$smtp->to( $new_member );
		$smtp->data();
		$smtp->datasend("To: $new_member\n");
		$smtp->datasend("From: $from\n");
		$smtp->datasend("Subject: $subject\n");
		$smtp->datasend("\n"); # done with header
		$smtp->datasend($message);
		$smtp->dataend();
		$smtp->quit(); # all done. message sent.
	}
	print $response;
}
$sth->finish;
$dbh->disconnect;