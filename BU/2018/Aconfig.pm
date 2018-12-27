package Aconfig;

#use DBI;
use CGI qw(:standard);
#use CGI::Carp qw(fatalsToBrowser);
use strict;
BEGIN {
	require Exporter;
	use Exporter;
	require 5.002;
	our($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = 1.00;
	@ISA = 			qw(Exporter);
	#@EXPORT = 		qw();
	%EXPORT_TAGS = 	();
	@EXPORT_OK	 =	qw();
}
our($src);
our $Rplots;
$Rplots->{dir} = "../users_tmp/plots/";
$Rplots->{imgSize} = 580;

our $tableDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/';
our $cols;
@{$cols} = ("dataset", "datatype", "platform", "screen", "drug", "feature", "correlation", "pvalue", "fdr", "validn", "plot");
our %colTitles = (
"plot" 		=> ' ', 
"dataset" 		=> 'Dataset', 
"datatype" 		=> 'Data type', 
"platform" 		=> 'Platform', 
"screen" 		=> 'Screen', 
"drug" 			=> 'Drug', 
"feature" 		=> 'Feature', 
"correlation" 	=> 'Correlation', 
"pvalue" 		=> 'P-value', 
"fdr" 			=> 'FDR', 
"validn" 		=> 'Valid N'
);

our %screenLabels = (
'act' => 'marcela',
'garnett' => 'garnett',
'barretina' => 'barretina',
'basu' => 'basu'
); 
#>> c _m  |gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {la = tolower($1); gsub("\\.", "", la); print "#" la "# => #" $1 "#," }'
our %datasetNames = (
'affymetrix1' => 'Affymetrix1',
'affymetrix2' => 'Affymetrix2',
'exome' => 'EXOME',
'gneaexomemgs' => 'gnea.exome.mgs',
'gneareferencemgs' => 'gnea.reference.mgs',
'gneasignificantaffymetrix1' => 'gnea.significant.affymetrix1',
'gneasignificantaffymetrix2' => 'gnea.significant.affymetrix2',
'gneasignificantcsm' => 'gnea.significant.csm',
'gneasignificantfilteredaffymetrix1maxi' => 'gnea.significant.filtered.affymetrix1.maxi',
'gneasignificantfilteredaffymetrix1mini' => 'gnea.significant.filtered.affymetrix1.mini',
'gneasignificantfilteredaffymetrix2maxi' => 'gnea.significant.filtered.affymetrix2.maxi',
'gneasignificantfilteredaffymetrix2mini' => 'gnea.significant.filtered.affymetrix2.mini',
'gneasignificantfilteredcombinedmaxi' => 'gnea.significant.filtered.combined.maxi',
'gneasignificantfilteredcombinedmini' => 'gnea.significant.filtered.combined.mini',
'gneasignificantfilteredcsmmaxi' => 'gnea.significant.filtered.csm.maxi',
'gneasignificantfilteredcsmmini' => 'gnea.significant.filtered.csm.mini',
'gneasignificantfilteredexomemaxi' => 'gnea.significant.filtered.exome.maxi',
'gneasignificantfilteredexomemini' => 'gnea.significant.filtered.exome.mini',
'gneasignificantfilteredsnp6maxi' => 'gnea.significant.filtered.snp6.maxi',
'gneasignificantfilteredsnp6mini' => 'gnea.significant.filtered.snp6.mini',
'gneasignificantsnp6' => 'gnea.significant.snp6',
'gneatop200affymetrix1' => 'gnea.top.200.affymetrix1',
'gneatop200affymetrix2' => 'gnea.top.200.affymetrix2',
'gneatop200csm' => 'gnea.top.200.csm',
'gneatop200snp6' => 'gnea.top.200.snp6',
'gneatop400affymetrix1' => 'gnea.top.400.affymetrix1',
'gneatop400affymetrix2' => 'gnea.top.400.affymetrix2',
'gneatop400csm' => 'gnea.top.400.csm',
'gneatop400snp6' => 'gnea.top.400.snp6',
'gneatotalmgs' => 'gnea.total.mgs',
'maf' => 'MAF',
'pwneaexomemgs' => 'pwnea.exome.mgs',
'pwneareferencemgs' => 'pwnea.reference.mgs',
'pwneasignificantaffymetrix1' => 'pwnea.significant.affymetrix1',
'pwneasignificantaffymetrix2' => 'pwnea.significant.affymetrix2',
'pwneasignificantcsm' => 'pwnea.significant.csm',
'pwneasignificantfilteredaffymetrix1maxi' => 'pwnea.significant.filtered.affymetrix1.maxi',
'pwneasignificantfilteredaffymetrix1mini' => 'pwnea.significant.filtered.affymetrix1.mini',
'pwneasignificantfilteredaffymetrix2maxi' => 'pwnea.significant.filtered.affymetrix2.maxi',
'pwneasignificantfilteredaffymetrix2mini' => 'pwnea.significant.filtered.affymetrix2.mini',
'pwneasignificantfilteredcombinedmaxi' => 'pwnea.significant.filtered.combined.maxi',
'pwneasignificantfilteredcombinedmini' => 'pwnea.significant.filtered.combined.mini',
'pwneasignificantfilteredcsmmaxi' => 'pwnea.significant.filtered.csm.maxi',
'pwneasignificantfilteredcsmmini' => 'pwnea.significant.filtered.csm.mini',
'pwneasignificantfilteredexomemaxi' => 'pwnea.significant.filtered.exome.maxi',
'pwneasignificantfilteredexomemini' => 'pwnea.significant.filtered.exome.mini',
'pwneasignificantfilteredsnp6maxi' => 'pwnea.significant.filtered.snp6.maxi',
'pwneasignificantfilteredsnp6mini' => 'pwnea.significant.filtered.snp6.mini',
'pwneasignificantsnp6' => 'pwnea.significant.snp6',
'pwneatop200affymetrix1' => 'pwnea.top.200.affymetrix1',
'pwneatop200affymetrix2' => 'pwnea.top.200.affymetrix2',
'pwneatop200csm' => 'pwnea.top.200.csm',
'pwneatop200snp6' => 'pwnea.top.200.snp6',
'pwneatop400affymetrix1' => 'pwnea.top.400.affymetrix1',
'pwneatop400affymetrix2' => 'pwnea.top.400.affymetrix2',
'pwneatop400csm' => 'pwnea.top.400.csm',
'pwneatop400snp6' => 'pwnea.top.400.snp6',
'pwneatotalmgs' => 'pwnea.total.mgs',
'snp6' => 'SNP6'
);
our %datasetLabels = (
'clin' 			=> 'Drug sensitivity', 
'ge' 			=> 'Gene expression', 
'mut' 			=> 'Point mutations', 
'copy' 			=> 'Gene copy number', 
'gnea' 			=> 'Gene scores from NEA', 
'pwnea' 		=> 'Pathway scores from NEA', 
'affymetrix1' 	=> 'CCLE Affymetrix (Barretina et al., 2012)',
'affymetrix2' 	=> 'CGP Affymetrix (Garnett et al., 2012)',
'cnatotal' 	=> 'COSMIC, total gene', 
'cnaminor' 	=> 'COSMIC, minor allele', 
'type' 			=> 'COSMIC, gain/loss', 
'snp6' 			=> 'CCLE gene copy number (Barretina et al., 2012)', 
'maf' 			=> 'CCLE, 1667 genes (Barretina et al., 2012)', 
'exome' 		=> 'COSMIC, exome-wide', 
'marcela' 		=> 'ACT screen, 25 drugs', 
'ACT' 			=> 'ACT screen, 25 drugs', 
'Garnett' 		=> 'CGP (Garnett et al., 2012), 138 drugs', 
'Barretina' 	=> 'CCLE (Barretina et al., 2012), 24 drugs', 
'Basu' 			=> 'CTD2 (Basu et al., 2013), 354 drugs', 
lc('ACT') 			=> 'ACT screen, 25 drugs', 
lc('Garnett') 		=> 'CGP (Garnett et al., 2012), 138 drugs', 
lc('Barretina') 	=> 'CCLE (Barretina et al., 2012), 24 drugs', 
lc('Basu' )			=> 'CTD2 (Basu et al., 2013), 354 drugs', 
##### gnea.exome.mgs          => 'Maxi-filtered COSMIC exome-wide mutation sets',
'gneareferencemgs'              => 'Mini-filtered CCLE (CCLE, 1667 genes) mutation sets', 
# 'gneasignificantaffymetrix1'            => 'CCLE: genes with expression significantly different from the collection mean', 
# 'gneasignificantaffymetrix2'            => 'CGP: genes with expression significantly different from the collection mean', 
# 'gneasignificantcsm'            => 'COSMIC: genes with copy number significantly different from the collection mean', 
# 'gneasignificantfilteredaffymetrix1maxi'      => 'CCLE: genes with expression significantly different from the collection mean, then maxi-filtered', 
# 'gneasignificantfilteredaffymetrix1mini'      => 'CCLE: genes with expression significantly different from the collection mean, then mini-filtered', 
# 'gneasignificantfilteredaffymetrix2maxi'      => 'CGP: genes with expression significantly different from the collection mean, then maxi-filtered',  
# 'gneasignificantfilteredaffymetrix2mini'      => 'CGP: genes with expression significantly different from the collection mean, then mini-filtered', 
'gneasignificantfilteredcombinedmaxi'         => 'Union of significant and mutated genes, maxi-filtered', 
'gneasignificantfilteredcombinedmini'         => 'Union of significant and mutated genes, mini-filtered', 
# 'gneasignificantfilteredcsmmaxi'              => 'COSMIC: genes with significantly different copy number, then maxi-filtered', 
# 'gneasignificantfilteredcsmmini'              => 'COSMIC: genes with significantly different copy number, then mini-filtered', 
'gneasignificantfilteredexomemaxi'            => 'Maxi-filtered COSMIC exome-wide mutation sets',
'gneasignificantfilteredexomemini'            => 'Mini-filtered COSMIC exome-wide mutation sets',
# 'gneasignificantfilteredsnp6maxi'             => 'CCLE: genes with copy number significantly different from the collection mean, then maxi-filtered', 
# 'gneasignificantfilteredsnp6mini'             => 'CCLE: genes with copy number significantly different from the collection mean, then mini-filtered', 
# 'gneasignificantsnp6'           => 'CCLE: genes with copy number significantly different from the collection mean', 
# 'gneatop200affymetrix1'                => 'CCLE: top 200 genes with expression different from the collection mean', 
# 'gneatop200affymetrix2'                => 'CGP: top 200 genes with expression different from the collection mean', 
# 'gneatop200csm'                =>  'COSMIC: top 200 genes with copy number different from the collection mean', 
# 'gneatop200snp6'               =>  'CCLE: top 200 genes with copy number different from the collection mean', 
# 'gneatop400affymetrix1'                => 'CCLE: top 400 genes with expression different from the collection mean', 
# 'gneatop400affymetrix2'                => 'CGP: top 400 genes with expression different from the collection mean', 
# 'gneatop400csm'                =>  'COSMIC: top 400 genes with copy number different from the collection mean', 
# 'gneatop400snp6'               =>  'CCLE: top 400 genes with copy number different from the collection mean', 
# 'gneatotalmgs'          =>  'Full (CCLE, 1667 genes) mutation sets', 

'pwneareferencemgs'              => 'Mini-filtered CCLE (CCLE, 1667 genes) mutation sets', 
# 'pwneasignificantaffymetrix1'            => 'CCLE: genes with expression significantly different from the collection mean', 
# 'pwneasignificantaffymetrix2'            => 'CGP: genes with expression significantly different from the collection mean', 
# 'pwneasignificantcsm'            => 'COSMIC: genes with copy number significantly different from the collection mean', 
# 'pwneasignificantfilteredaffymetrix1maxi'      => 'CCLE: genes with expression significantly different from the collection mean, then maxi-filtered', 
# 'pwneasignificantfilteredaffymetrix1mini'      => 'CCLE: genes with expression significantly different from the collection mean, then mini-filtered', 
# 'pwneasignificantfilteredaffymetrix2maxi'      => 'CGP: genes with expression significantly different from the collection mean, then maxi-filtered',  
# 'pwneasignificantfilteredaffymetrix2mini'      => 'CGP: genes with expression significantly different from the collection mean, then mini-filtered', 
'pwneasignificantfilteredcombinedmaxi'         => 'Union of significant and mutated genes, maxi-filtered', 
'pwneasignificantfilteredcombinedmini'         => 'Union of significant and mutated genes, mini-filtered', 
# 'pwneasignificantfilteredcsmmaxi'              => 'COSMIC: genes with significantly different copy number, then maxi-filtered', 
# 'pwneasignificantfilteredcsmmini'              => 'COSMIC: genes with significantly different copy number, then mini-filtered', 
'pwneasignificantfilteredexomemaxi'            => 'Maxi-filtered COSMIC exome-wide mutation sets',
'pwneasignificantfilteredexomemini'            => 'Mini-filtered COSMIC exome-wide mutation sets'#,
# 'pwneasignificantfilteredsnp6maxi'             => 'CCLE: genes with copy number significantly different from the collection mean, then maxi-filtered', 
# 'pwneasignificantfilteredsnp6mini'             => 'CCLE: genes with copy number significantly different from the collection mean, then mini-filtered', 
# 'pwneasignificantsnp6'           => 'CCLE: genes with copy number significantly different from the collection mean', 
# 'pwneatop200affymetrix1'                => 'CCLE: top 200 genes with expression different from the collection mean', 
# 'pwneatop200affymetrix2'                => 'CGP: top 200 genes with expression different from the collection mean', 
# 'pwneatop200csm'                =>  'COSMIC: top 200 genes with copy number different from the collection mean', 
# 'pwneatop200snp6'               =>  'CCLE: top 200 genes with copy number different from the collection mean', 
# 'pwneatop400affymetrix1'                => 'CCLE: top 400 genes with expression different from the collection mean', 
# 'pwneatop400affymetrix2'                => 'CGP: top 400 genes with expression different from the collection mean', 
# 'pwneatop400csm'                =>  'COSMIC: top 400 genes with copy number different from the collection mean', 
# 'pwneatop400snp6'               =>  'CCLE: top 400 genes with copy number different from the collection mean', 
# 'pwneatotalmgs'          =>  'Full (CCLE, 1667 genes) mutation sets'
);
our $HTPmenuList;
%{$HTPmenuList->{'correlations'}} = (
'ge' 				=> 'OK' 
, 'gnea' 			=> 'OK' 
, 'pwnea' 			=> 'OK'
, 'copy' 			=> 'OK' 
, 'mut' 			=> 'OK'
);
%{$HTPmenuList->{'As X axis'}} = (
'ge' 				=> 'OK' 
#, 'clin' 				=> 'OK' 
, 'copy' 			=> 'OK' 
, 'mut' 			=> 'OK'
);
%{$HTPmenuList->{'As Y axis'}} = (
'clin' 				=> 'OK' 
, 'ge' 				=> 'OK' 
, 'copy' 			=> 'OK' 
#, 'mut' 			=> 'OK'
);
%{$HTPmenuList->{'As color'}} = (
'ge' 				=> 'OK' 
, 'copy' 			=> 'OK' 
, 'mut' 			=> 'OK'
#, 'clin' 				=> 'OK' 
);
my $i;
for $i(keys(%datasetLabels)) {
$datasetLabels{maxlength} = length($datasetLabels{$i}) if (!defined($datasetLabels{maxlength}) or $datasetLabels{maxlength} < length($datasetLabels{$i}));
}

sub availableCorrelations {
my $dbh = HS_SQL::dbh();
# @{$src->{sset}} = ('CTD');
my $ss = 'CTD';
# my $stat = " SELECT distinct dataset, datatype, platform, screen from best_drug limit 10;";
my $stat = " SELECT * from best_drug_corrs_counts;"; # limit 10;";
my  ($key_field, $tag);
@{ $key_field} = ('dataset', 'datatype', 'platform', 'screen', 'drug', 'count');
my $tables = $dbh->selectall_arrayref($stat);
$dbh->disconnect;
my ($crs, $tt, @ar, $item);
# print $tables->[0]->{'datatype'};
foreach my $tt(@$tables) {
#print join(' ', @{$tt})."\n";
$tag = $tt->[2];
$tag =~ s/\.//g;
$crs->{screen}->{$tt->[3]} = 1;
$crs->{drug}->{$tt->[3]}->{$tt->[4]} = 1;
if (lc($tt->[1]) eq 'nea') {
$tt->[1] = 'pw'.$tt->[1];
}
$crs->{lc($tt->[1])}->{lc($tag)} = $tt->[2];
}
return $crs; #$src->{CTD};
}

sub dataSourcesForAnalysis {
my $dbh = HS_SQL::dbh();
@{$src->{sset}} = ('CTD');
#for 
my $ss = 'CTD';
#(@{$src->{sset}}) {
my $stat = "SELECT table_name FROM information_schema.tables  where table_type= 'BASE TABLE' and table_name like '".lc($ss)."_%';";
my $tables = $dbh->selectcol_arrayref($stat);
$dbh->disconnect;
#print @{$tables}."\n";
#}
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
return $pls; #$src->{CTD};
}

2;
__END__



