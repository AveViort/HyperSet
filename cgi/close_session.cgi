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
$dbh = HS_SQL::dbh() or die $DBI::errstr;
$stat = qq{SELECT close_session(?, ?, ?)};
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute($uname, $sign, $sid) or die $sth->errstr;
$sth->finish;
$dbh->commit;
$dbh->disconnect;
print "Content-type: text/html\n\n";
print "Success";