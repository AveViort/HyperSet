#!/usr/bin/perl
use strict vars;
use mou3::Projects::NETwork_analysis::NET;
use Math::Trig;

#replaceable project-specific WD modules that define data and important specific details
our $current_proj;

my($doRandomization, $Niter, $Ntestlines, $debug, $id);
our(@mtr, $borders, $value_index, $pms, $debug);
parseParameters(join(' ', @ARGV));
#use WIR::WD; $current_proj = 'WIR';
#use CHEMORES::NET::WD; $current_proj = 'CHEMORES';
#use siRNAaroundTP53::WD; $current_proj = 'TP53';
#use CANCER::expO::WD; $current_proj = 'expO';
#use CANCER::Breast_datasets::vanAgthoven2009_GSE14513::WD; $current_proj = 'tamoxifen';
use Projects::mouse::MouseNet::WD; $current_proj = 'mouse';
if ($current_proj) {print "Current project is $current_proj.\n";}
else {die "Current project is not defined...\n";}

srand();
$debug = 1; #############
our $Ntestlines = 5000000000;

#$methWD::data = 0;
WD::define_data($WD::spe);
$WD::outputfilenames = $WD::filedir.join('.', (
'pcit4_WirPairs',
$current_proj,
#$pms->{'data'}, $pms->{'metr'},
$WD::coff{'exp-exp'},
#$WD::PCITdenominator,
uc($pms->{'mode'})
));
$WD::outputfilenames .= '.'.$pms->{'star'}.'-'.$pms->{'end_'} if ($pms->{'star'} or $pms->{'end_'});

if ($pms->{'mode'} =~ m/prim/i) {primaryPairwise(); exit;}
if ($pms->{'mode'} =~ m/proc/i) {processPairs(); exit;}
if ($pms->{'mode'} =~ m/merg/i) {mergePairs(); exit;}

sub primaryPairwise {
my($nTested, $g1, $g2, $me, $metric1, $metric2, $comparison, $func, @line, $value, $corr_value, $start_ID, $end_ID, $processTriangles, $rndLabel);

#$WD::filenames = $WD::filedir.'PrimaryPAIRS.'.((defined($pms->{'star'}) and defined($pms->{'star'})) ? (join('-', ($pms->{'star'}, $pms->{'end_'}))) : '').'.at_'.$$.'.WIR';

WD::readInputData();
open OUT, '> '.$WD::outputfilenames;
@mtr = sort {$a cmp $b} keys(%WD::data);
print "Processing to $WD::outputfilenames ...\n";
print OUT join("\t", ('GENE1', 'GENE2', @{$WD::link_fields->{'primary'}}))."\n";
$start_ID = 	$pms->{'star'} if defined($pms->{'star'});
$end_ID = 	$pms->{'end_'} if defined($pms->{'end_'});
$processTriangles = 1;  #option for parallelized computation; disable otherwise!
###my @gene_list = sort {$b cmp $a} keys(%{$WD::genes->{'total_list'}});
#my @gene_list = keys(%{$WD::genes->{'total_list'}});
my @gene_list = NET::randomizeGeneList2ndLetter(keys(%{$WD::genes->{'total_list'}}));
my @gene_list1 = @gene_list[$start_ID..$end_ID];
#my @gene_list2 = sort {$b cmp $a} keys(%{$WD::genes->{'total_list'}});
my @gene_list2 = @gene_list;
print join("\t", (
'Processing list ',
$start_ID, 
$gene_list1[0],
' to',
$end_ID,
$gene_list1[$#gene_list1]
))."\n" if (defined($pms->{'star'}) and defined($pms->{'end_'}));


for $g1(@gene_list1) {
for $g2(@gene_list2) {
last if (($g1 eq $g2) and $processTriangles); #analyze each gene pair only once, self-pairs not excluded
undef $nTested;
@line = ($g1, $g2);
for $comparison(@{$WD::link_fields->{'primary'}}) {
($metric1, $metric2) = ($1, $2) if $comparison =~ m/^([0-9a-z_]+)\-([0-9a-z_]+)$/i; #first term is INDEPENDENT factor
undef $value;
#if (defined($WD::genes->{$metric1}->{$g1}) and defined($WD::genes->{$metric2}->{$g2})) {
$func = $WD::metric{$comparison};
$rndLabel = (($metric1 =~ m/R$/ and $metric2 =~ m/R$/) ? 1 : undef);
die "Irrelevant dataset for shuffling profiles...\n" if $rndLabel and ($comparison !~ m/exp/);
$value = &$func($g1, $g2, $WD::data{$metric1}, $WD::data{$metric2}, $rndLabel);
#if ((1 == 2) and abs($value) < $WD::coff{$comparison}) {undef($value);}
#}
$nTested++ if abs($value) > $WD::coff{$comparison};
push @line, $value;
}
next if !$nTested;
print OUT join("\t", @line)."\n";
}}
close OUT;
}

sub processPairs {
my($ln, $nTested, $i, $gx, $gy, $fc, $ff, $metric, @line, $link_corr, $count);

if ($main::pms->{'data'} =~ m/aff/i) {$WD::table->{primary}->{$WD::spe} =~ s/platform/Aff/;}
elsif ($main::pms->{'data'} =~ m/agi/i) {$WD::table->{primary}->{$WD::spe} =~ s/platform/Agi/;}
if ($main::pms->{'metr'} =~ m/pears/i) {$WD::table->{primary}->{$WD::spe} =~ s/metric/pea/;}
elsif ($main::pms->{'metr'} =~ m/spear/i) {$WD::table->{primary}->{$WD::spe} =~ s/metric/spe/;}

NET::readLinks($WD::table->{network}->{$WD::spe}, 'refnet') if $WD::mapToNet;
NET::readLinks($WD::table->{primary}->{$WD::spe}, 'primary'); #exit;
open OUT, '> '.$WD::outputfilenames or die "Could not open $WD::filenames ...\n";
open OUT2, '> '.$WD::filenamesPCIT or die "Could not open $WD::filenamesPCIT ...\n" if $debug;
print "Output is sent to $WD::outputfilenames ...\n";
undef $nTested;
$i = 5;
for $ff(@{$WD::link_fields->{'primary'}}) {
push @line, ($i++.':'.$ff.'-full', $i++.':'.$ff.'-part');
}
for $ff(@{$WD::link_fields->{'refnet'}}) {
push @line, ($i++.':'.$ff) if $WD::mapToNet;
}
print OUT join("\t", ('1:GENE1', '2:GENE2', '3:total-part', '4:total-part-source', @line))."\n";

for $gx(keys(%{$NET::link->{'primary'}})) {
for $gy(keys(%{$NET::link->{'primary'}->{$gx}})) {
undef $link_corr; undef $fc;
if ($gx ne $gy) {
$link_corr = checkPartial($gx, $gy);
($link_corr->{total}, $link_corr->{total_source}) = checkPartialTotal($gx, $gy);
}
next if !$link_corr->{total} and $WD::printOnlyCausal;
@line = ($gx, $gy, $link_corr->{total}, $link_corr->{total_source});

for $ff(@{$WD::link_fields->{'primary'}}) {
push @line, (
(defined($NET::link->{'primary'}->{$gx}->{$gy}->{$ff}) ? $NET::link->{'primary'}->{$gx}->{$gy}->{$ff} : 'NA'),
$link_corr->{$ff});
}

if ($WD::mapToNet) {
$fc = $NET::link->{'refnet'}->{$gx}->{$gy} if defined($NET::link->{'refnet'}->{$gx}->{$gy});
$fc = $NET::link->{'refnet'}->{$gy}->{$gx} if !defined($fc) and defined($NET::link->{'refnet'}->{$gy}->{$gx});
if (defined($fc)) {
for $ff(@{$WD::link_fields->{'refnet'}}) {
push @line, (defined($fc->{$ff}) ? $fc->{$ff} : 'NA');
}}}
print OUT join("\t", @line)."\n";
}}
close OUT; return undef;
}

sub mergePairs {
my($ln, %pl,  $lnk, @a,
$nTested, $i, $gx, $gy, $fc, $ff, $metric, $cnt, @line, $link_corr, $count, $kind, %label, $lbl);

WD::readSymbols('en', $WD::spe);
NET::readLinks($WD::table->{network}->{$WD::spe}, 'refnet');
open IN, 'm9/WirPairs.11June.PRIM' or die "Could not open raw input file...\n"; #$WD::table->{primary}->{$WD::spe} or die "Could not open $WD::table->{primary}->{$WD::spe}\n";
$_ = <IN>; NET::readHeader($_, $WD::table->{primary}->{$WD::spe});
$pl{gene1} = $NET::pl->{$WD::table->{primary}->{$WD::spe}}->{gene1};
$pl{gene2} = $NET::pl->{$WD::table->{primary}->{$WD::spe}}->{gene2};


$WD::outputfilenames .= '.'.$pl{corr0}.$pl{corr1};
open OUT, '> '.$WD::outputfilenames or die "Could not open $WD::filenames ...\n";
print "Output is sent to $WD::outputfilenames ...\n";
@line = ('GENE1', 'GENE2', 'CORR0', 'CORR1', 'FBS', 'HSA', 'PPI', 'CO-EXPR');
@line = ('GENE1', 'GENE2', 'FBS', 'HSA', 'PPI', 'CO-EXPR', 'R-', 'R+', 'RL', 'C-', 'C+', 'CL', 'S-', 'S+', 'SL');
print OUT join("\t", @line)."\n";

while (<IN>) {
#last if  $Ntotal++ > $main::Ntestlines;
chomp;
@a = split("\t", $_);
next if !$a[$pl{gene1}] or !$a[$pl{gene2}];
undef $lnk;
$lnk = $NET::link->{'refnet'}->{lc($a[$pl{gene1}])}->{lc($a[$pl{gene2}])}
     if (defined($NET::link->{'refnet'}->{lc($a[$pl{gene1}])}) and defined($NET::link->{'refnet'}->{lc($a[$pl{gene1}])}->{lc($a[$pl{gene2}])}));
$lnk = $NET::link->{'refnet'}->{lc($a[$pl{gene2}])}->{lc($a[$pl{gene1}])}
     if (defined($NET::link->{'refnet'}->{lc($a[$pl{gene2}])}) and defined($NET::link->{'refnet'}->{lc($a[$pl{gene2}])}->{lc($a[$pl{gene1}])}));
if (defined($lnk)) {
next if (defined($WD::FBScutoff) and ($lnk->{'fbs_max'} < $WD::FBScutoff));
@line = (
$a[$pl{gene1}], $a[$pl{gene2}],
$lnk->{'fbs_max'}, $lnk->{'hsa'}, $lnk->{'ppi'}, $lnk->{'pearson'});
undef $cnt;
for $kind('REL', 'CHM', 'RND') {
if ($kind eq 'REL') {$pl{corr0} = $NET::pl->{$WD::table->{primary}->{$WD::spe}}->{'exp0-exp0'}; $pl{corr1} = $NET::pl->{$WD::table->{primary}->{$WD::spe}}->{'exp1-exp1'};}
if ($kind eq 'CHM') {$pl{corr0} = $NET::pl->{$WD::table->{primary}->{$WD::spe}}->{'exp2-exp2'}; $pl{corr1} = $NET::pl->{$WD::table->{primary}->{$WD::spe}}->{'exp3-exp3'};}
if ($kind eq 'RND') {$pl{corr0} = 6; $pl{corr1} = 7;}

undef %label;
if (1 == 2) { #   NET::testCorrelationSignificance was re-written - define N1 and N2!!!
$label{P} = 1 if NET::testCorrelationSignificance($a[$pl{corr1}], undef) and (abs($a[$pl{corr1}] - $a[$pl{corr0}]) > 0.5);
$label{N} = 1 if NET::testCorrelationSignificance($a[$pl{corr0}], undef) and (abs($a[$pl{corr1}] - $a[$pl{corr0}]) > 0.5);
$label{R} = 1 if NET::testCorrelationSignificance($a[$pl{corr0}], undef) and NET::testCorrelationSignificance($a[$pl{corr1}], undef);
$label{S} = 1 if ($label{R} and (NET::sign($a[$pl{corr1}]) ne NET::sign($a[$pl{corr0}])));
$cnt++ if defined(%label);
}
push @line, ($a[$pl{corr0}], $a[$pl{corr1}], join('', (sort {$a cmp $b} keys(%label))));
}
print OUT join("\t", @line)."\n" if $cnt;
}}
close IN;
close OUT;
return undef;
}

sub checkPartialTotal {
my($gx, $gy) = @_;
my($gz, %min, $me, $i, $me1, $me2, $partial_correlation, $minPartCorr, @line, $ff, $lxy, $lzx, $lzy, $link_corr, $src);

$lxy = $NET::link->{'primary'}->{$gx}->{$gy};
$i = 0;
for $me1(keys(%{$lxy})) {
if (defined($lxy->{$me1})) {
$me->[$i]->{value} = $lxy->{$me1};
$me->[$i]->{metric} = $me1;
$i++;
}}
@{$me} = sort {abs($b->{value}) <=> abs($a->{value})} @{$me};
$minPartCorr = $me->[0]->{value};
$src = $me->[0]->{metric};
for $gz(keys(%{$NET::link->{'primary'}->{$gx}})) {
next if ($gz eq $gx) or ($gz eq $gy);
undef $lzx; undef $lzy;
$lzx = $NET::link->{'primary'}->{$gx}->{$gz};
$lzy = $NET::link->{'primary'}->{$gy}->{$gz} if defined($NET::link->{'primary'}->{$gy}->{$gz});
$lzy = $NET::link->{'primary'}->{$gz}->{$gy} if !defined($lzy) and defined($NET::link->{'primary'}->{$gz}->{$gy});
next if !defined($lzy);

for $me1(keys(%{$lzx})) {
for $me2(keys(%{$lzy})) {
$partial_correlation = NET::partialCorrelation($minPartCorr, $lzx->{$me1}, $lzy->{$me2});
if (abs($partial_correlation) < abs($minPartCorr)) {
$minPartCorr = $partial_correlation = NET::PCITConditionalIndependence($minPartCorr, $lzx->{$me1}, $lzy->{$me2}) #, $me->[0]->{metric}, $me1, $me2, $gx, $gy, $gz);
}
return '0' if !$minPartCorr;
}}}
return(sprintf("%.3f", $minPartCorr), $src);
}

sub checkPartial {
my($gx, $gy) = @_;
my($gz, %min, $me1, $partial_correlation, $minPartCorr, @line, $ff, $lxy, $lzx, $lzy, $link_corr);

$lxy = $NET::link->{'primary'}->{$gx}->{$gy};
for $me1(keys(%{$lxy})) {
$minPartCorr = $lxy->{$me1};
next if !$minPartCorr;
for $gz(keys(%{$NET::link->{'primary'}->{$gx}})) {
next if ($gz eq $gx) or ($gz eq $gy);
undef $lzx; undef $lzy;
$lzx = $NET::link->{'primary'}->{$gx}->{$gz};
next if !defined($lzx->{$me1});
$lzy = $NET::link->{'primary'}->{$gy}->{$gz} if defined($NET::link->{'primary'}->{$gy}->{$gz});
$lzy = $NET::link->{'primary'}->{$gz}->{$gy} if !defined($lzy) and defined($NET::link->{'primary'}->{$gz}->{$gy});
next if !defined($lzy->{$me1});
$partial_correlation = NET::partialCorrelation($lxy->{$me1}, $lzx->{$me1}, $lzy->{$me1});
if (abs($partial_correlation) < abs($minPartCorr)) {
$minPartCorr = $partial_correlation =
NET::PCITConditionalIndependence(
$lxy->{$me1}, $lzx->{$me1}, $lzy->{$me1},
$me1, $gx, $gy, $gz);
}
last if !$minPartCorr;
}
$link_corr->{$me1} = sprintf("%.2f", $minPartCorr);
}
return $link_corr;
}


sub correlation {
my($g1, $g2, $tag1, $tag2, $isRand) = @_;
my($x, $y, @value, $max, $val, $func, $data1, $data2);

$func = $WD::correlation_func;
for $x(keys(%{$tag1->{$g1}->{profile}})) {
for $y(keys(%{$tag2->{$g2}->{profile}})) {
$data1 = $tag1->{$g1}->{profile}->{$x};
$data2 = $tag2->{$g2}->{profile}->{$y};
if ($isRand) {
($data1, $data2) = WD::shuffleProfiles($WD::expdata->{$g1}->{profile}->{$x}, $WD::expdata->{$g2}->{profile}->{$y});
}
$val = &$func($data1, $data2);

push @value, $val if defined($val);
}}
$max = NET::maxabs(@value);
return(defined($max) ? sprintf("%.3f", $max) : undef);
}

sub anova {
my($g1, $g2, $tag1, $tag2) = @_;
my($x, $y, @value, $max, $val);

for $x(keys(%{$tag1->{$g1}->{profile}})) { 
for $y(keys(%{$tag2->{$g2}->{profile}})) {
if 	($tag1 == $WD::mutdata) {
$val = WD::anova1way_WIR($tag1->{$g1}->{profile}->{$x}, $tag2->{$g2}->{profile}->{$y});
#$x is INDEPENDENT factor, $y is dependent continuous variable
}
elsif 	($tag2 == $WD::mutdata) {
$val = WD::anova1way_WIR($tag2->{$g2}->{profile}->{$y}, $tag1->{$g1}->{profile}->{$x});
}
else {$val = undef;}
push @value, $val if defined($val);
}}
$max = NET::max(@value);

return(defined($max) ? sprintf("%.3f", $max) : undef);
}

sub parseParameters ($) {
my($parameters) = @_;
my($_1, $_2, %sorts);

#print "$parameters\n";
$_ = $parameters;
while (m/\-(\w+)\s+([A-Za-z0-9.-_+]+)/g) {
$_1 = $1;
$_2 = $2;
if ($_2 =~ /\+/) {push @{substr(lc($_1), 0, 4)}, split(/\+/, lc($_2));}
else {$pms->{substr(lc($_1), 0, 4)} = $_2;}
}
if (defined($pms->{'sort'})) {
while ($pms->{'sort'} =~ m/([a-z0-9]){1}/sig) {
$sorts{lc($1)} = 1;
$sorts{uc($1)} = 1;
}
}
if (!defined($pms->{'mode'})) {
print "Specify at least the main mode of operation:\n
-prim : generate primary correlation network, or\n-proc : process the primary network to select most likely causative links\n
-metr : spearman or pearson correlation for expression\n
-data : optional expression platform Affi/Agilent\n
-data : tissue-specific cancer, one of: \n \t lung, liver, breast, colon, kidney, endometrium, ovary, prostate, uterus \n\t(for expO project only, otherwise see above)
\n\n";
}
$pms->{'spec'} = 'hsa' if !$pms->{'spec'};
return undef;
}


#cat m8/ProcessedPAIRS.at_3853.PWI | sed '{s/NA//g}' | gawk 'BEGIN {FS="\t"; OFS="\t"; eco = 0.5; mco = 0.00 } {if ($4 > eco  || $6 > eco || $8 > eco || $10 > eco || $12 > mco || $14 > mco ||  $16 > mco ||  $18 > mco ||  $20 > mco ||$21) print $1, $2, $4, $6, $8, $10, $12, $14, $16, $18, $20, $21}' > ! m8/WIR/_sel1

#gawk 'BEGIN {for (i = 3; i<36; i++) {ca[i-2] = i} FS="\t"; OFS="\t"} {if (ARGIND == 1) {a[toupper($3) toupper($4)] = 1;} else {for (i in ca) {if ($1 > ca[i]) {tc[ca[i]]++; if (a[$6 $7] || a[$7 $6]) {co[ca[i]]++}}}}}   END {for (i in ca) {print i, ca[i], co[ca[i]], tc[ca[i]], co[ca[i]]/tc[ca[i]]}}' wir1.sql Human.Version_1.00.4classes.TCGA_SYM | sort -n > liklihoodFCinWIR.wir.txt &



