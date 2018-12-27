#!/usr/bin/speedy -w
# use warnings;

# file for passing password from register/login form

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $uname = $query->param('username');
my $password = $query->param('password');
my $loginresult = login($uname, $password);
print "Content-type: text/html\n\n";
print $loginresult;

sub login {
	my ($uname, $password) = @_ ;
	$dbh = HS_SQL::dbh() or die $DBI::errstr;
	$stat = qq/SELECT check_hash(\'$uname\', \'$password\')/;
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $sessionID = $sth->fetchrow_array;
	$sth->finish;
	$dbh->commit;
	$dbh->disconnect;
	return $sessionID;
}