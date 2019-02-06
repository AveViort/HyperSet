#!/usr/bin/speedy -w
# use warnings;

# file for adding Anonymous user to the given project with Read/write permissions

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Net::SMTP;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $newsign = $query->param('new_signature');
my $session_length = $query->param('session_length');
my $project = $query->param('project_id');
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
	$stat = qq/SELECT make_public(\'$project'\, \'$uname'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	my $response = $sth->fetchrow_array;
	print $response;
	if ($response ne 0)
	{
		# send notification to all project administrators
		$stat = qq/SELECT owner FROM projects WHERE projectid LIKE \'$project'\ AND access_level=3 AND receive_notifications=true /;
		$sth = $dbh->prepare($stat) or die $dbh->errstr;
		$sth->execute( ) or die $sth->errstr;
		$sth->execute( ) or die $sth->errstr;
		my $smtp = Net::SMTP->new('localhost') or die $!;
		my $from = 'webmaster@evinet.org';
		my $subject = 'Project '.$project.' is now public';
		my $message = 'Dear EviNet project administrator, 

project '.$project.' has been successfully made public by project administrator '.$uname.'. It means that anyone who knows ProjectID can change the project. 

You can manage projects with your Settings panel. Please follow the administration guide: ...

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
		$smtp->quit(); # all done. message sent.
	}
}
$sth->finish;
$dbh->disconnect;
