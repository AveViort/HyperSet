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
print "Content-type: text/html\n\n";
# write it as an SQL function! Temporal solution
$stat = "SELECT * from best_drug_corrs_counts;";
my  ($key_field, $tag);
@{ $key_field} = ('dataset', 'datatype', 'platform', 'screen', 'drug', 'count');
my $tables = $dbh->selectall_arrayref($stat);
$dbh->disconnect;
my ($crs, $tt, @ar, $item, $pls, $tag);
foreach my $tt(@$tables) {
	$tag = $tt->[2];
	$tag =~ s/\.//g;
	$crs->{screen}->{$tt->[3]} = 1;
	$crs->{drug}->{$tt->[3]}->{$tt->[4]} = 1;
	if (lc($tt->[1]) eq 'nea') {
		$tt->[1] = 'pw'.$tt->[1];
	}
	$crs->{lc($tt->[1])}->{lc($tag)} = $tt->[2];
}

$dbh = HS_SQL::dbh('druggable') or die $DBI::errstr;
$stat = qq/SELECT sources_and_drugs()/;
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