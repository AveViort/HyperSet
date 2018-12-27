#!/usr/bin/speedy -w
# use warnings;

# verify that account is not activated and send a mail with an activation link

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Net::SMTP;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

# first part - check, if the account activated and activation mail has not been sent
my $query = new CGI;
my $uname = $query->param('username');
$dbh = HS_SQL::dbh() or die $DBI::errstr;
$stat = qq/SELECT user_active(\'$uname'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $activation_status = $sth->fetchrow_array;
print "Content-type: text/html\n\n";

# second part - send mail, if account is not activated
if ($activation_status) {
	my $smtp = Net::SMTP->new('localhost') or die $!;
	my $from = 'webmaster@evinet.org';
	$stat = qq/SELECT get_activation_key(\'$uname'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $activation_key =  $sth->fetchrow_array;
	my $url = 'https://www.evinet.org/activate.html#'.$activation_key;
	$dbh->commit;
	# Not to forget: write addresses properly!
	my $message = 'Dear EviNet user, 

your email '.$uname.' was used for registration on EviNet website. To activate your account, click the following link: '.$url.'

If you did not register an account, just ignore this email.

Regards,
EviNet

----------------------------------------------
EviNet main page: https://www.evinet.org
EviNet FAQ: https://www.evinet.org/help/faq-evi/evi-faq.html';
	my $subject = 'Confirm your email';

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
	$stat = qq/SELECT activation_mail_sent(\'$uname'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$sth->finish;
	$dbh->commit;
	$dbh->disconnect;
	print 'Success';
	}
else {
	$sth->finish;
	print 'Fail';
}