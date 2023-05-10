#!/usr/bin/speedy -w

# toggling event status to acknowledged/not acknowledged
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);

my $query = new CGI;
my $pass = $query->param("pass");
my $timestamp = $query->param("timestamp");
my $level = $query->param("level"); 
my $status = $query->param("status");

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT toggle_event_acknowledgement_status(\'$pass'\, \'$timestamp'\, \'$level'\, $status);/;
#print $stat;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$dbh->commit;
print "ok";
$sth->finish;
$dbh->disconnect;