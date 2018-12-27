#!/usr/bin/speedy -w
# use warnings;

# inviting a new member to project
# return codes:
# 0 - User does not exist, is not activated, has a project administrator role or has been already invited to this project
# 1 - Success
# 2 - Role has been successfully changed
# 3 - User does not exist, is not activated or has a project administrator role
# read the code below to understand the difference between 0 and 3. In fact, code 3 was added for better debugging.

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
$dbh = HS_SQL::dbh() or die $DBI::errstr;
$stat = qq/SELECT verify_prolong_session(\'$uname'\, \'$sign'\, \'$sid'\, \'$newsign'\, \'$session_length'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$dbh->commit;
my $newsid = $sth->fetchrow_array;
print "Content-type: text/html\n\n";
print $newsid;
print "|";
my $result;
if (($newsid ne 'Nonexisting_session') && ($newsid ne 'Session_expired'))
{
	my $smtp = Net::SMTP->new('localhost') or die $!;
	my $from = 'webmaster@evinet.org';
	my ($subject, $message, $response);
	# part 1 - check if we already had member
	$stat = qq/SELECT receive_notifications FROM projects WHERE projectid LIKE \'$project'\ AND owner LIKE \'$new_member'\ /;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$result = $sth->fetchrow_array;
	# part 2.1 - we don't have user yet
	if ($result eq "") {
		$stat = qq/SELECT invite_project_member(\'$project'\, \'$uname'\, \'$new_member'\, \'$member_level'\)/;
		$sth = $dbh->prepare($stat) or die $dbh->errstr;
		$sth->execute( ) or die $sth->errstr;
		$dbh->commit;
		$response = $sth->fetchrow_array;
		#part 2.1.1 - check response
		if ($response == 1) {
			# part 2.1.1.1 - send message to project administrators (who accepted notifications)
			$stat = qq/SELECT owner FROM projects WHERE projectid LIKE \'$project'\ AND access_level=3 AND receive_notifications=true /;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			my $access_level;
			switch($member_level) {
				case 1 {$access_level="Read-only"}
				case 2 {$access_level="Read/Write"}
				case 3 {$access_level="Administrator"}
			}
			$subject = 'New member invited to your project '.$project;
			$message = 'Dear EviNet project administrator, 

user '.$new_member.' has been successfully invited to project '.$project.' by project administrator '.$uname.' with the following access level: '.$access_level.'

You can manage users with your Project settings panel. Please follow the administration guide: https://www.evinet.org/help/user_access.htm

You can disable notifications with Project settings panel (for pecuiliar projects) or Profile settings (global settings).

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
			# part 2.1.1.2 - send message to user (if he accepts notifications)
			$stat = qq/SELECT notifications_accepted FROM users WHERE username LIKE \'$new_member'\ /;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			my $notifications = $sth->fetchrow_array;
			if ($notifications == 1) {
				$subject = 'You have been invited to EviNet project '.$project;
				$message = 'Dear EviNet user, 

you have been invited to join project '.$project.' by project administrator '.$uname.' with the following access level: '.$access_level.' You can accept or decline this invitation using your Project settings panel on the EviNet website https://www.evinet.org.

Notifications can be disable via Project settings (for particular projects) or via Profile settings (globally).

Regards,
EviNet

----------------------------------------------
EviNet main page: https://www.evinet.org
EviNet FAQ: https://www.evinet.org/help/faq-evi/evi-faq.html';
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
			$result = 1;
		}
		else {
			$result = 0;}
		$smtp->quit();
	}
	# part 2.2 - we already have user
	else {
		$stat = qq/SELECT invite_project_member(\'$project'\, \'$uname'\, \'$new_member'\, \'$member_level'\)/;
		$sth = $dbh->prepare($stat) or die $dbh->errstr;
		$sth->execute( ) or die $sth->errstr;
		$dbh->commit;
		$response = $sth->fetchrow_array;
		#part 2.1.1 - check response
		if ($response == 1) {
			$result = 2;
		}
		else {
			$result = 3;}
	}
print $result;
}
$sth->finish;
$dbh->disconnect;