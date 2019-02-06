#!/usr/bin/speedy -w
# use warnings;

# file for creating normal links from shareable

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $shared = $query->param('shared');
$dbh = HS_SQL::dbh('hyperset') or die $DBI::errstr;
$stat = qq/SELECT jid FROM projectarchives WHERE share_hash LIKE \'$shared'\ /;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $jid = $sth->fetchrow_array;
$stat = qq/SELECT species FROM projectarchives WHERE share_hash LIKE \'$shared'\ /;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $species = $sth->fetchrow_array;
$stat = qq/SELECT projectid FROM projectarchives WHERE share_hash LIKE \'$shared'\ /;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $projectID = $sth->fetchrow_array;
my $action = "sbmRestore";
my $mode = "standalone";
my $table = "table";
my $graphics = "graphics";
my $archive = "archive";
my $showself = "showself";
my $sbm = "arbor";
#my $jid = "jid";
#my $projectID = "projectID";
#my $species = "species";
print "Content-type: text/html\n\n";
print "https://www.evinet.org/cgi/i.cgi?mode=".$mode.";action=".$action.";table=".$table.";graphics=".$graphics.";archive=".$archive.";sbm-layout=".$sbm.";showself=".$showself.";project_id=".$projectID.";species=".$species.";jid=".$jid.";shared=".$shared;
$sth->finish;
$dbh->disconnect;