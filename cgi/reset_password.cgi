#!/usr/bin/speedy -w
# use warnings;

# reset password

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $pass = $query->param('password');
my $key = $query->param('key');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT reset_password(\'$uname'\, \'$pass'\, \'$key'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $resetstat = $sth->fetchrow_array;
$sth->finish;
$dbh->commit;
$dbh->disconnect;
print "Content-type: text/html\n\n";
print $resetstat;