#!/usr/bin/speedy -w
# use warnings;

# script for retrieving features for each source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $stat);

$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
print "Content-type: text/html\n\n";
$stat = qq/SELECT feature_list()/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $temp = '';
my @string, @response;
while (@response = $sth->fetchrow_array) {
		my $Text = @response[0];
		$Text =~ s/[()]//g;
		$Text =  substr($Text, 1);
		$Text =~ m|([^"]*)",(.*)|;
		if ($1 ne $temp) {
			print "!";
			print $1;
			print "|";
			$temp = $1;
		}
		print substr($2, 1, length($2)-2);
		print "|";
}
$sth->finish;
$dbh->disconnect;
			