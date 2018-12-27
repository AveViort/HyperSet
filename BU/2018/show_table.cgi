#!/usr/bin/perl -w

#file for displaying different matrices from result.html
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HSconfig;
use HS_SQL;
use File::Slurp;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my ($sign, $sid, $sth, $sessionstat);
my $query = new CGI;
my $project = $query->param('project_id');
my $table = $query->param('table_id');
my $uname = $query->param('username');
$dbh = HS_SQL::dbh() or die $DBI::errstr;
print CGI::header();
if ($uname ne "Anonymous") {
	$sign = $query->param('signature');
	$sid = $query->param('session_id');
	$stat = qq/SELECT session_valid(\'$uname'\, \'$sign'\, \'$sid'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$sessionstat = $sth->fetchrow_array;
	}
else {
	$sessionstat = '1';
	}
$stat = qq/SELECT is_owner(\'$uname'\, \'$project'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $ownership = $sth->fetchrow_array;
# if no ownership rights or session is not valid - terminate i.cgi
if (not($sessionstat) or not($ownership)) {
	print "Permission denied. Project: ".$project." User: ".$uname." Signature: ".$sign." SID: ".$sid." Session status: ".$sessionstat." Ownership status: ".$ownership;
	}
else {
	my $path = $HSconfig::usersTMP;
	my $html = read_file($path.$project.'/'.$table);
	print $html;
	}
$sth->finish;
$dbh->disconnect;