#!/usr/bin/speedy -w
# use warnings;

# file for changing a password (user has to remember the previous password)

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Net::SMTP;
use Switch;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $oldpass = $query->param('old_password');
my $newpass = $query->param('new_password');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $newsign = $query->param('new_signature');
my $session_length = $query->param('session_length');

# verify if session is valid
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
	# part 1 - change password
	$stat = qq/SELECT change_password(\'$uname'\, \'$oldpass'\, \'$newpass'\, \'$newsid'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	my $response = $sth->fetchrow_array;
	
	# part 2 - send letter to user
	if ($response == 1) {
		my $smtp = Net::SMTP->new('localhost') or die $!;
		my $from = 'webmaster@evinet.org';
		my $subject = 'Your password has been changed';
		my $message = 'Dear EviNet user, 

your password has been successfully changed. If you did not do it - try to log in into your account with "Forgot password" option and change your password or contact EviNet webmaster.

Regards,
EviNet';
		$smtp->mail( $from );
		$smtp->to( $uname );
		$smtp->data();
		$smtp->datasend("To: $uname\n");
		$smtp->datasend("From: $from\n");
		$smtp->datasend("Subject: $subject\n");
		$smtp->datasend("\n"); # done with header
		$smtp->datasend($message);
		$smtp->dataend();
		$smtp->quit();
	}
	print $response;
}
$sth->finish;
$dbh->disconnect;
			