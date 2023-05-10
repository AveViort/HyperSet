#!/usr/bin/speedy -w

# script for writing event into SQL event log
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

our ($dbh, $stat);

my $query = new CGI;
my $source = $query->param("source");
my $level = $query->param("level"); 
my $description = $query->param("description"); 
my $options = $query->param("options"); 
my $message = $query->param("message"); 
my $user_agent = $query->param("user_agent");

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable');
$message =~ s/"/\"/g;
$stat = qq/SELECT report_event(\'$source'\, \'$level'\, \'$description'\, \'$options'\, \'$message'\, \'$user_agent'\);/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
$dbh->commit;
print 'ok';
$sth->finish;
$dbh->disconnect;