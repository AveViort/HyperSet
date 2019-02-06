#!/usr/bin/speedy -w
# use warnings;

# file for passing password from register/login form

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

our $query = new CGI;
my $uname = $query->param('username');
my $password = $query->param('password');
my $signupresult = register($uname, $password);
print "Content-type: text/html\n\n";
print $signupresult;

sub register {
	my ($uname, $password) = @_ ;
	$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
	$stat = qq/SELECT add_user( \'$uname\', \'$password\')/;
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	my $res  = $sth->fetchrow_array;
	$sth->finish;
	$dbh->commit;
	$dbh->disconnect;
	if ($res) {
		return "success";}
	else {
		return "fail";}
	}