#!/usr/bin/speedy -w
# use warnings;

# file for verifying an existing session

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $sign = $query->param('signature');
my $sid = $query->param('session_id');
my $newsign = $query->param('new_signature');
my $session_length = $query->param('session_length');
my $project_id = $query->param('project_id');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT check_permission(\'$uname'\, \'$sign'\, \'$sid'\, \'$newsign'\, \'$session_length'\, \'$project_id'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $permission_status = $sth->fetchrow_array;
$sth->finish;
$dbh->commit;
$dbh->disconnect;
print "Content-type: text/html\n\n";
print $permission_status;