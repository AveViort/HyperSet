#!/usr/bin/speedy -w

# check if project was created by Anonymous user. Note: you cannot access database with projects directly from cgi
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HSconfig;
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $project = $query->param('project_id');
my ($status, $sth, $projectlc);
$dbh = HS_SQL::dbh() or die $DBI::errstr;

print "Content-type: text/html\n\n";
$projectlc = lc($project);
$stat = qq/SELECT project_anonymous(\'$projectlc'\)/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$status = $sth->fetchrow_array;
print $status;
$sth->finish;
$dbh->disconnect;