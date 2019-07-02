#!/usr/bin/speedy -w
# use warnings;

# verify that less than 3 mails were sent and send a mail with a reset link

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Net::SMTP;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

# first part - check, if less than 3 mails were sent
my $query = new CGI;
my $uname = $query->param('username');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT check_reset_notifications(\'$uname'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $reset_status = $sth->fetchrow_array;
print "Content-type: text/html\n\n";

# second part - send a mail, if less than 3 were sent
if ($reset_status) {
	my $smtp = Net::SMTP->new('localhost') or die $!;
	my $from = 'webmaster@evinet.org';
	$stat = qq/SELECT get_reset_key(\'$uname'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $reset_key =  $sth->fetchrow_array;
	$sth->finish;
	$dbh->commit;
	$dbh->disconnect;
	my $url = 'https://www.evinet.org/restore_password.html#'.$uname."?".$reset_key;
	# Not to forget: write addresses properly!
	my $message = 'Dear EviNet user, 

You have requested the password change for your account. Click the following link to do that: '.$url.'

Your current password is still valid. It will be valid before you set a new password. If you did not request the password change, ignore this mail. If you have received 3 such mails - please contact EviNet webmaster: andrej.alekseenko@scilifelab.se

Regards,
EviNet

----------------------------------------------
EviNet main page: https://www.evinet.org
EviNet FAQ: https://www.evinet.org/help/faq-evi/evi-faq.html';
	my $subject = 'Password change requested';

	$smtp->mail( $from );
	$smtp->to( $uname );
	$smtp->data();
	$smtp->datasend("To: $uname\n");
	$smtp->datasend("From: $from\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend("\n"); # done with header
	$smtp->datasend($message);
	$smtp->dataend();
	$smtp->quit(); # all done. message sent.
	print 'Success';
	}
else {
	$sth->finish;
	$dbh->disconnect;
	print 'Fail';
}