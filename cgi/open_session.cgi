#!/usr/bin/speedy -w
# use warnings;

# file for opening a new session

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $session_length = $query->param('session_length');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$addr = $query->remote_addr();
$stat = qq/SELECT open_session(\'$uname'\, \'$sign'\, \'$sid'\, \'$addr'\, \'$session_length'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $sessionstat = $sth->fetchrow_array;
$sth->finish;
$dbh->commit;
$dbh->disconnect;
print "Content-type: text/html\n\n";
print $sessionstat;