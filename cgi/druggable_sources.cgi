#!/usr/bin/speedy -w
# use warnings;

# script for filling list of sources and associated drugs
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $stat);

$dbh = HS_SQL::dbh() or die $DBI::errstr;
print "Content-type: text/html\n\n";
$stat = qq/SELECT sources_and_drugs()/;
#my $sth = $dbh->prepare($stat) or die $dbh->errstr;
#$sth->execute( ) or die $sth->errstr;
#my @source, $showName;
#while (@source = $sth->fetchrow_array) {  # retrieve one row
	#if defined($Aconfig::datasetLabels{@source}) {
		#$showName = $Aconfig::datasetLabels{@source};
		#print $showName;
		#print @source;
		#print "|";
	#}
#}
#$sth->finish;
my $tables = $dbh->selectcol_arrayref($stat);
$dbh->disconnect;
my ($pls, $tt, @ar, $item, $tag);
for $tt(@{$tables}) {
	@ar = split('_', $tt);
	$tag  = join('_', (@ar[2..$#ar]));
	if (lc($ar[1]) eq 'nea') {
		$tag = 'pwnea'.$tag;
		$ar[1] = 'pw'.$ar[1];
	}
	$pls->{$ar[1]}->{$tag} = $tt;
}
my $showName;
for $dty(sort {$a cmp $b} keys %{$pls}) {
	for $pl(sort {$a cmp $b} keys %{$pls->{$dty}}) {
		if (defined($pls->{$dty}->{$pl}) and defined($Aconfig::datasetLabels{$pl})) {
			$showName = $Aconfig::datasetLabels{$pl};
			if ($pl eq "marcela") { print "act" }
			else {print $pl;}
			print "|";
			print $showName;
			print "|";
		}
	}
}
