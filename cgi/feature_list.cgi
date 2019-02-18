#!/usr/bin/speedy -w
# use warnings;

# script for retrieving drug list for each source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $stat);

$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;


$stat = qq/SELECT sources_and_drugs_old()/;
$tables = $dbh->selectcol_arrayref($stat);
$dbh->disconnect;
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
for $dty(sort {$a cmp $b} keys %{$crs}) {
	next if (!defined($Aconfig::HTPmenuList->{'correlations'}->{$dty}));
	print $Aconfig::datasetLabels{$dty};
	print "|";
	for $pl(sort {$a cmp $b} keys %{$crs->{$dty}}) {
		if (defined($pls->{$dty}->{$pl}) and defined($Aconfig::datasetLabels{$pl})) {
			print $pl;
			print "|";
			$showName = $Aconfig::datasetLabels{$pl};
			print $showName;
			print "|";
		}
	}
	print "!";
}			