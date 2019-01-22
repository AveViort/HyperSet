#!/usr/bin/perl -w
# use warnings;

# script for retrieving drug list for each source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $stat);

$dbh = HS_SQL::dbh() or die $DBI::errstr;
print "Content-type: text/html\n\n";
# write it as an SQL function! Temporal solution
$stat = "SELECT * from best_drug_corrs_counts;";
my  ($key_field, $tag);
@{ $key_field} = ('dataset', 'datatype', 'platform', 'screen', 'drug', 'count');
my $tables = $dbh->selectall_arrayref($stat);
$dbh->disconnect;
my ($crs, $tt, @ar, $item);
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
for $screen(sort {$a cmp $b} keys %{$crs->{drug}}) {
	next if (!defined($Aconfig::datasetLabels{$screen}));
	print $Aconfig::datasetLabels{$screen};
	print "|";
	for $drug(sort {$a cmp $b} keys %{$crs->{drug}->{$screen}}) {
		print $drug;
		print "|";
	}
	print "!";
}
