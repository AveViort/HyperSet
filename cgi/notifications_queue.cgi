#!/usr/bin/speedy -w
# use warnings;

# file for checking queue length (if there are any unanswered invitations)

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Net::SMTP;

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');

$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT notifications_queue(\'$uname'\, \'$sign'\, \'$sid'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $notifications = $sth->fetchrow_array;
print "Content-type: text/html\n\n";
print $notifications;
$sth->finish;
$dbh->disconnect;