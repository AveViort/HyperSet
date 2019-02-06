#!/usr/bin/speedy -w
# use warnings;

# returns if user receives notifications or not

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT session_valid(\'$uname'\, \'$sign'\, \'$sid'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $session_status = $sth->fetchrow_array;
print "Content-type: text/html\n\n";
print $session_status;
print "|";
if ($session_status ne 0)
{
	$stat = qq/SELECT notifications_accepted FROM users WHERE username LIKE \'$uname'\ /;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $notifications = $sth->fetchrow_array;
	print $notifications;
}
$sth->finish;
$dbh->disconnect;
