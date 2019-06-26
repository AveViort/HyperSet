#!/usr/bin/perl -w
# use warnings;

# create a shareable link

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('sid');
my $jid = $query->param('jid');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT session_valid(\'$uname'\, \'$sign'\, \'$sid'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $sessionstat = $sth->fetchrow_array;
my $link;
#if ($sessionstat eq 1) {
	$stat = qq/SELECT get_shareable_link(\'$uname'\, \'$jid'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$link = $sth->fetchrow_array;
	$dbh->commit;
#}
#else {
#	$link = 'failed';
#}
$sth->finish;
$dbh->disconnect;
print "Content-type: text/html\n\n";
print $link; 