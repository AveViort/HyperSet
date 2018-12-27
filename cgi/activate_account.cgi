#!/usr/bin/perl -w
# use warnings;

# activate account

use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $stat);

my $query = new CGI;
my $key = $query->param('activation_key');
$dbh = HS_SQL::dbh() or die $DBI::errstr;
$stat = qq/SELECT activate_account(\'$key'\)/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $activationstat = $sth->fetchrow_array;
$sth->finish;
$dbh->commit;
$dbh->disconnect;
print "Content-type: text/html\n\n";
print $activationstat;