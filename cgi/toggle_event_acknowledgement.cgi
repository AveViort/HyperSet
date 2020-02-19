#!/usr/bin/speedy -w

# toggling event status to acknowledged/not acknowledged
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);

my $query = new CGI;
my $pass = $query->param("pass");
my $timestamp = $query->param("timestamp");
my $source = $query->param("source");
my $level = $query->param("level"); 
my $description = $query->param("description"); 
my $platform = $query->param("platform"); 
my $options = $query->param("options"); 
my $user_agent = $query->param("user_agent");
my $status = $query->param("status");

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT toggle_event_acknowledgement_status(\'$pass'\, \'$timestamp'\, \'$source'\, \'$level'\, \'$description'\, \'$options'\, \'$user_agent'\, $status);/;
#print $stat;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$dbh->commit;
print "ok";
$sth->finish;
$dbh->disconnect;