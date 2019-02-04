#!/usr/bin/perl
use strict vars;


my($table, $doRandomization, $Niter, $Ntestlines, $debug,$id);
our($link_fields, $pms, %coff, %sign_cutoff, @mtr, %samples, $xref, $genes, $table, %metric, $metricPartial, %data, $link, $filedir, $filenames, $names, $edata, $methdata, $mutdata, $spe, $borders, $value_index, $pms, $pl, $nm, $checkPartial, $doNotProcessOrphanProbes);
parseParameters(join(' ', @ARGV));
srand();
$spe = 'hsa';
our $Ntestlines = 500000000; $doNotProcessOrphanProbes = 1;
our $debug = 1; #############
$checkPartial = 1;
define_data($spe);
for $id('cg', 'ma', 'en') {readSymbols($id, $spe);}
if ($pms->{'mode'} =~ m/prim/i) {primaryPairwise(); exit;}
if ($pms->{'mode'} =~ m/proc/i) {processPairs(); exit;}

sub processPairs {
my($ln, 
$nTested, $i, $gx, $gy, $fc, $ff, $metric, @line, $link_corr, $count);

$filenames = $filedir.'ProcessedPAIRS.TT.at_'.$$.'.PWI'; 
readLinks($table->{network}->{$spe}, 'netw'); 
readLinks($table->{primary}->{$spe}, 'prim'); #exit;
open OUT, '> '.$filenames or die "Could not open $filenames ...\n";
open OUT2, '> '.$filenames.'.purePCIT' or die "Could not open $filenames ...\n";
print "Output is sent to $filenames ...\n";
undef $nTested; 
$i = 4;
for $ff(@{$link_fields->{'prim'}}) {
push @line, ($i++.':'.$ff.'-full', $i++.':'.$ff.'-part');
}
for $ff(@{$link_fields->{'netw'}}) {
push @line, ($i++.':'.$ff);
}
print OUT join("\t", ('1:GENE1', '2:GENE2', '3:total-part', @line))."\n"; 

for $gx(keys(%{$link->{'prim'}})) { 
for $gy(keys(%{$link->{'prim'}->{$gx}})) {
undef $link_corr; undef $fc;
if ($gx ne $gy) {
$link_corr = checkPartial($gx, $gy);
$link_corr->{total} = checkPartialTotal($gx, $gy);
}
@line = ($gx, $gy); 
$fc = $link->{'netw'}->{$gx}->{$gy} if defined($link->{'netw'}->{$gx}->{$gy});
$fc = $link->{'netw'}->{$gy}->{$gx} if !defined($fc) and defined($link->{'netw'}->{$gy}->{$gx});
push @line, $link_corr->{total};
for $ff(@{$link_fields->{'prim'}}) {
push @line, (
(defined($link->{'prim'}->{$gx}->{$gy}->{$ff}) ? $link->{'prim'}->{$gx}->{$gy}->{$ff} : 'NA'), 
$link_corr->{$ff});
}
for $ff(@{$link_fields->{'netw'}}) {push @line, (defined($fc->{$ff}) ? $fc->{$ff} : 'NA');}
print OUT join("\t", @line)."\n";
#exit if $count++ > 100000;
}}
close OUT; return undef;
}
 
sub checkPartialTotal {
my($gx, $gy) = @_;
my($gz, %min, $me, $i, $me1, $me2, $partial_correlation, $minPartCorr, @line, $ff, $lxy, $lzx, $lzy, $link_corr);

$lxy = $link->{'prim'}->{$gx}->{$gy};
$i = 0;
for $me1(keys(%{$lxy})) {
if (defined($lxy->{$me1})) {
$me->[$i]->{value} = $lxy->{$me1};
$me->[$i]->{metric} = $me1;
$i++;
}}
@{$me} = sort {abs($b->{value}) <=> abs($a->{value})} @{$me};
$minPartCorr = $me->[0]->{value}; 

for $gz(keys(%{$link->{'prim'}->{$gx}})) {
next if ($gz eq $gx) or ($gz eq $gy);
undef $lzx; undef $lzy;
$lzx = $link->{'prim'}->{$gx}->{$gz};
$lzy = $link->{'prim'}->{$gy}->{$gz} if defined($link->{'prim'}->{$gy}->{$gz});
$lzy = $link->{'prim'}->{$gz}->{$gy} if !defined($lzy) and defined($link->{'prim'}->{$gz}->{$gy});
next if !defined($lzy);

for $me1(keys(%{$lzx})) { 
for $me2(keys(%{$lzy})) { 
$partial_correlation = partialCorrelation($minPartCorr, $lzx->{$me1}, $lzy->{$me2}); 
if (abs($partial_correlation) < abs($minPartCorr)) {
$minPartCorr = $partial_correlation = PCITConditionalIndependence($minPartCorr, $lzx->{$me1}, $lzy->{$me2}, $me->[0]->{metric}, $me1, $me2, $gx, $gy, $gz);
}
return '0' if !$minPartCorr;
}}}
return sprintf("%.4f", $minPartCorr);
}

sub checkPartial {
my($gx, $gy) = @_;
my($gz, %min, $me1, $partial_correlation, $minPartCorr, @line, $ff, $lxy, $lzx, $lzy, $link_corr);

$lxy = $link->{'prim'}->{$gx}->{$gy};
for $me1(keys(%{$lxy})) { 
$minPartCorr = $lxy->{$me1}; 
next if !$minPartCorr;
for $gz(keys(%{$link->{'prim'}->{$gx}})) {
next if ($gz eq $gx) or ($gz eq $gy);
undef $lzx; undef $lzy;
$lzx = $link->{'prim'}->{$gx}->{$gz};
next if !defined($lzx->{$me1});
$lzy = $link->{'prim'}->{$gy}->{$gz} if defined($link->{'prim'}->{$gy}->{$gz});
$lzy = $link->{'prim'}->{$gz}->{$gy} if !defined($lzy) and defined($link->{'prim'}->{$gz}->{$gy});
next if !defined($lzy->{$me1});
$partial_correlation = partialCorrelation($lxy->{$me1}, $lzx->{$me1}, $lzy->{$me1}); 
if (abs($partial_correlation) < abs($minPartCorr)) {
$minPartCorr = $partial_correlation = PCITConditionalIndependence($lxy->{$me1}, $lzx->{$me1}, $lzy->{$me1}, $me1, $gx, $gy, $gz);
}
last if !$minPartCorr;
}
$link_corr->{$me1} = sprintf("%.3f", $minPartCorr);
}
return $link_corr;
} 

sub PCITConditionalIndependence{
my($Rxy, $Rxz, $Ryz) = @_;
my($pc, $epsilon, $result);
$pc = partialCorrelation($Rxy, $Rxz, $Ryz);
$epsilon = (	$pc / $Rxy + 
		partialCorrelation($Rxz, $Rxy, $Ryz) / $Rxz + 
		partialCorrelation($Ryz, $Rxy, $Rxz) / $Ryz ) / 3;
$result = ((abs($pc) < abs($epsilon * $Rxz)) and (abs($pc) < abs($epsilon * $Ryz))) ? '0' : $Rxy;
#print OUT2 join("\t", (@_, sprintf("%.3f", $pc), sprintf("%.3f", partialCorrelation($Rxz, $Rxy, $Ryz)), sprintf("%.3f", partialCorrelation($Ryz, $Rxy, $Rxz)), sprintf("%.2f", $epsilon), sprintf("%.3f", $result)))."\n";
return($result);
}

sub partialCorrelation {
my($Rxy, $Rxz, $Ryz) = @_;
return undef if ($Rxz == 1) or ($Ryz == 1);
my $value = ($Rxy - $Rxz * $Ryz) / ((sqrt(1 - $Rxz ** 2) * sqrt(1 - $Ryz ** 2)));
return $value;
}

sub testCorrelationSignificance {
my($new, $old) = @_; my($sigmaXz);
return undef if abs($new) > 1 or abs($old) > 1;
$sigmaXz = 0.3705; my $zTable = 2.58; #formal z value for 1% conf. interval
my($N1, $N2) = (200, 200); #No. of observations for each variable
$sigmaXz = $zTable * sqrt((1 / ($N1 - 3)) + (1 / ($N2 - 3))); #0.1436 * 2.58
return((abs(ztransformation($new) - ztransformation($old)) > $sigmaXz) ? 1 : 0);
}

sub ztransformation {
my($value) = @_; 
return undef if abs($value) > 1;
$value = -0.999999 if $value == -1; $value =  0.999999 if $value ==  1;
return log((1 + $value) / (1 - $value)) / 2;
}

sub readLinks {
my($tbl, $label) = @_;
my(@a, $prot1, $prot2, $Ntotal, $ff);
open IN, $tbl or return undef;
print "Loading $tbl...\n";
$_ = <IN>;
readHeader($_, $tbl) if 1 == 1;# m/protein/i;
if ($label eq 'prim') {
$pl->{$tbl}->{protein1} = $pl->{$tbl}->{gene1};
$pl->{$tbl}->{protein2} = $pl->{$tbl}->{gene2};}
for $ff(@{$link_fields->{$label}}) {die "Table column for $ff undefined. \nCannot read $tbl ...\n" if !defined($pl->{$tbl}->{$ff});}
#open OOO, '> m8/_conn.funcoup';
while ($_ = <IN>) {
last if  $Ntotal++ > $Ntestlines;
chomp;
@a = split("\t", $_);
$prot1= lc($a[$pl->{$tbl}->{protein1}]); $prot2= lc($a[$pl->{$tbl}->{protein2}]); 
next if !$prot1 or !$prot2;
if ($label eq 'netw') {
#next if $a[$pl->{$tbl}->{fbs}] < $FBScutoff;
$prot1 = $xref->{'en2sym_hsa'}->{'id2sym'}->{$prot1};
$prot2 = $xref->{'en2sym_hsa'}->{'id2sym'}->{$prot2};
#print OOO $prot1."\n".$prot2."\n";
}
for $ff(@{$link_fields->{$label}}) {
next if !defined($a[$pl->{$tbl}->{$ff}]);
next if defined($coff{$ff}) and (abs($a[$pl->{$tbl}->{$ff}]) < $coff{$ff});
$link->{$label}->{$prot1}->{$prot2}->{$ff} = sprintf("%.2f", $a[$pl->{$tbl}->{$ff}]);
}}
close IN;
print scalar(keys(%{$link->{$label}})).' outgoing genes, '.$Ntotal.' links, '." in\n$tbl...\n\n";
return undef;
}

sub primaryPairwise {
my($nTested, $g1, $g2, $me, $metric1, $metric2, $comparison, $func, @line, $value, $corr_value, $start_ID, $end_ID, $processTriangles);
$filenames = $filedir.'PrimaryPAIRS.'.((defined($pms->{'star'}) and defined($pms->{'star'})) ? (join('-', ($pms->{'star'}, $pms->{'end_'}))) : '').'.at_'.$$.'.WIR'; 

open OUT, '> '.$filenames;

readMutation($spe, $table->{mutation}->{$spe}) if 1 == 1;
readMethyl($spe, $table->{methyl}->{$spe}) if 1 == 1;
readExpression($spe, $table->{expression}->{$spe}) if 1 == 1;
arrangeBySample($mutdata, 1);
arrangeBySample($methdata, 0);
arrangeBySample($edata, 0);

%data = ( #type-specific data structures
'mut' => $mutdata, 
'met' => $methdata, 
'exp' => $edata
); 
$processTriangles = 1; # if defined($pms->{'star'}) and defined($pms->{'end_'});
@mtr = sort {$a cmp $b} keys(%data);
print "Processing to $filenames ...\n";
print OUT join("\t", ('GENE1', 'GENE2', @{$link_fields->{'prim'}}))."\n";
###my @gene_list1 = sort {$b cmp $a} keys(%{$genes->{'mut'}});
###my @gene_list2 = sort {$b cmp $a} keys(%{$genes->{'mut'}});
#$start_ID = 0; $end_ID = $#gene_list1;
$start_ID = 	$pms->{'star'} if defined($pms->{'star'});
$end_ID = 	$pms->{'end_'} if defined($pms->{'end_'});
my @gene_list = sort {$b cmp $a} keys(%{$genes->{'total_list'}});
print join("\n", @gene_list)."\n"; exit;
my @gene_list1 = @gene_list[$start_ID..$end_ID];
my @gene_list2 = sort {$b cmp $a} keys(%{$genes->{'total_list'}});
print join("\t", ($start_ID, "$gene_list1[$start_ID]", $end_ID, "$gene_list1[$end_ID]"))."\n" if (defined($pms->{'star'}) and defined($pms->{'star'})); 
for $g1(@gene_list1) {
for $g2(@gene_list2) {
undef $nTested; 
@line = ($g1, $g2);
for $comparison(@{$link_fields->{'prim'}}) {
($metric1, $metric2) = ($1, $2) if $comparison =~ m/^([a-z]+)\-([a-z]+)$/i; #first term is INDEPENDENT factor
undef $value;
if (defined($genes->{$metric1}->{$g1}) and defined($genes->{$metric2}->{$g2})) {
$func = $metric{$comparison};
$value = &$func($g1, $g2, $data{$metric1}, $data{$metric2}); 
#if ((1 == 2) and abs($value) < $coff{$comparison}) {undef($value);} 
}
$nTested++ if abs($value) > $coff{$comparison};
push @line, $value;
}
next if !$nTested;
print OUT join("\t", @line)."\n";
last if $g1 eq $g2 and $processTriangles; #analyze each gene pair only once, self-pairs not excluded
}}
close OUT;
}

sub arrangeBySample {
my($tag, $replaceUndef) = @_;
my($gene, $name, $smp, $value, $n);

for $gene(keys(%{$tag})) {
for $name(keys(%{$tag->{$gene}->{samples}})) {
undef $n;
for $smp(sort {$a cmp $b} keys(%samples)) {
$value = $tag->{$gene}->{samples}->{$name}->{$smp};
$n++ if defined($value);
$value = '0' if $replaceUndef and !defined($value);
push @{$tag->{$gene}->{profile}->{$name}}, $value;
}
undef $tag->{$gene}->{profile}->{$name} if !$n;
}}
return;
}

sub correlation {
my($g1, $g2, $tag1, $tag2) = @_;
my($x, $y, @value, $max, $val, $func);

 #$func = 'pearson';
$func = 'spearman';
for $x(keys(%{$tag1->{$g1}->{profile}})) {
for $y(keys(%{$tag2->{$g2}->{profile}})) {
$val = &$func($tag1->{$g1}->{profile}->{$x}, $tag2->{$g2}->{profile}->{$y});
push @value, $val if defined($val);
}}
$max = maxabs(@value);
return(defined($max) ? sprintf("%.3f", $max) : undef);
}

sub anova {
my($g1, $g2, $tag1, $tag2) = @_; 
my($x, $y, @value, $max, $val);

for $x(keys(%{$tag1->{$g1}->{profile}})) { 
for $y(keys(%{$tag2->{$g2}->{profile}})) {
if 	($tag1 == $mutdata) {
$val = anova1way_WIR($tag1->{$g1}->{profile}->{$x}, $tag2->{$g2}->{profile}->{$y});
#$x is INDEPENDENT factor, $y is dependent continuous variable
}
elsif 	($tag2 == $mutdata) {
$val = anova1way_WIR($tag2->{$g2}->{profile}->{$y}, $tag1->{$g1}->{profile}->{$x});
}
else {$val = undef;}
push @value, $val if defined($val);
}}
$max = max(@value);

return(defined($max) ? sprintf("%.3f", $max) : undef);
}

sub chisq {
my($g1, $g2, $tag1, $tag2) = @_;
my($x, $y, @value, $max, $val, $case, $cnt);
for $x(keys(%{$tag1->{$g1}->{profile}})) {
for $y(keys(%{$tag2->{$g2}->{profile}})) {
undef $cnt;
for $case(0..$#{$tag1->{$g1}->{profile}->{$x}}) 
{
$cnt->{$tag1->{$g1}->{profile}->{$x}->[$case]}->{$tag1->{$g2}->{profile}->{$y}->[$case]}++;
}
$val = chisquare(
$cnt->{'0'}->{'0'} ? $cnt->{'0'}->{'0'} : '0', 	
$cnt->{'0'}->{'1'} ? $cnt->{'0'}->{'1'} : '0', 
$cnt->{'1'}->{'0'} ? $cnt->{'1'}->{'0'} : '0', 
$cnt->{'1'}->{'1'} ? $cnt->{'1'}->{'1'} : '0',
0);
push @value, $val if defined($val);
}}
$max = maxabs(@value);
return(defined($max) ? sprintf("%.3f", $max) : undef);
}

sub readMutation {
my($genome, $table) = @_;
my($gene, @a, $name, $n, $smp, $value);

open(IN, $table) or return undef;
print "Loading $table...\n";
$_ = <IN>; readHeader($_, $table);
while (<IN>) {
chomp;
@a = split(/\t/, $_);
undef $smp;
last if $n++ > 10000000;
$gene = $name = lc($a[$pl->{$table}->{'hugo_symbol'}]);  
$names->{'probe'}->{$name} = 1; $genes->{total_list}->{$gene} = $genes->{'mut'}->{$gene} = 1;
if ($a[$pl->{$table}->{'tumor_sample_barcode'}] =~ m/(TCGA\-.+?\-.+?\-.+?)\-/i) {$samples{lc($1)} = 1; $smp = lc($1);}
$value = (lc($a[$pl->{$table}->{'mutation_status'}]) eq 'somatic') ? '1' : undef;
#(lc($a[$pl->{$table}->{'variant_classification'}]).lc($a[$pl->{$table}->{'start_position'}]))
$mutdata->{$gene}->{samples}->{$name.'_at_'.$table}->{$smp} = $value;
}
print scalar(keys(%{$pl->{$table}})).' table columns, '.scalar(keys(%{$mutdata})).' genes, '."$n mutations in\n$table...\n\n";
close IN; 
return undef;
}

sub readMethyl {
my($genome, $table) = @_;
my($gene, @a, $name, @epl, $startcol, $namecol, $i, $j, $n, $tag, $value, $length);

$namecol = 0; $startcol = 1;
$tag = 'cg2sym_'.$genome;
open IN, 'cat '.$table.' | '  or return undef;
print "Loading $table...\n";
while (<IN>) {
chomp;
@a = split(/\t/, $_);
if ($a[0] =~ m/Hybridization/i) {
undef $pl->{$table};
readHeader($_, $table); 
$length = $#a;
}
else {
next if $a[2] =~ m/beta.*value/i;
last if $n++ > $Ntestlines;
$name = lc($a[$namecol]); 
undef $gene;
if ($name =~ m/^cg[0-9]/) {
$gene = $xref->{$tag}->{'id2sym'}->{lc($name)}; #$i = 0;
}
else {
$gene = $1 if $name =~ m/(.+?)\_/;
}
print $name."\n" if !$gene;
$gene = $name if !$gene; 
$names->{'probe'}->{$name} = 1;
$genes->{total_list}->{$gene} = $genes->{'met'}->{$gene} = 1;
for $j($startcol..$length) {
$value = ($a[$j] eq '') ? undef : sprintf("%.2f", $a[$j]);
$methdata->{$gene}->{samples}->{$name.'_at_'.$table}->{$nm->{$table}->{$j}} = $value;
}}}
print scalar(keys(%{$methdata})).' genes, '.scalar(keys(%{$names->{'probe'}})).' IDs, '.scalar(keys(%{$pl->{$table}})).' samples, '."$n ID profiles in\n$table...\n\n";
close IN; #exit;
return undef;
}

sub readExpression {
my($genome, $table) = @_;
my($gene, @a, $name, @epl, $startcol, $namecol, $i, $j, $n, $tag, $value);

$namecol = 0; $startcol = 1;
$tag = 'ma2sym_'.$genome;
open(IN, $table) or return undef;
print "Loading $table...\n";
$_ = <IN>;
@epl = split(/\t/, $_);
readHeader($_, $table);
while (<IN>) {
chomp;
@a = split(/\t/, $_);
next if $a[2] =~ m/probeset_/i;
$name = lc($a[$namecol]); 
$gene = $xref->{$tag}->{'id2sym'}->{lc($name)}; #$i = 0;
next if !$gene and $doNotProcessOrphanProbes; 
last if $n++ > $Ntestlines;
$gene = $name if !$gene; #print $name."\n" if !$gene;
$names->{'probe'}->{$name} = 1;
$genes->{total_list}->{$gene} = $genes->{'exp'}->{$gene} = 1;
for $j($startcol..$#epl) {
$value = ($a[$j] eq '') ? undef : sprintf("%.2f", $a[$j]);
$edata->{$gene}->{samples}->{$name.'_at_'.$table}->{$nm->{$table}->{$j}} = $value;
}}
print scalar(keys(%{$edata})).' genes, '.scalar(keys(%{$names->{'probe'}})).' IDs, '.scalar(keys(%{$pl->{$table}})).' samples, '."$n ID profiles in\n$table...\n\n";
close IN; #exit;
return undef;
}

sub readSymbols {
my($id, $species) = @_;
my(@a, $n);
my $tag = $id.'2sym_'.$species;
open SYM, $table->{$tag} or die("No $tag xref table...\n");
while (<SYM>) {
chomp; @a = split("\t", $_);
next if !$a[$pl->{$tag}->{'id'}] or !$a[$pl->{$tag}->{'sym'}];
$n++;
$xref->{$tag}->{'sym2id'}->{lc($a[$pl->{$tag}->{'sym'}])} = lc($a[$pl->{$tag}->{'id'}]);
$xref->{$tag}->{'id2sym'}->{lc($a[$pl->{$tag}->{'id'}])} = lc($a[$pl->{$tag}->{'sym'}]);
}
close SYM; 
print scalar(keys(%{$xref->{$tag}->{'sym2id'}})).' gene symbols, '.scalar(keys(%{$xref->{$tag}->{'id2sym'}})).' IDs, '."$n ID-symbol pairs in\n$table->{$tag}...\n\n";
return undef;
}

sub bin ($$) {
my($value, $type) = @_;
my($q, $no_of_bins, $bin);

return undef if !defined($value);
return $value_index->{$type}->{$value} if $value_index->{$type}->{$value};
if (defined($borders->{$type})) {
if ($value =~ m/^[0-9-.e]+$/) {
return '0' if $value < $borders->{$type}->[0];
return scalar(@{$borders->{$type}}) if $value >= $borders->{$type}->[$#{$borders->{$type}}];
for $q(1..$#{$borders->{$type}}) {
if (($value >= $borders->{$type}->[$q - 1]) and ($value < $borders->{$type}->[$q])) {
$bin = $q;
}}}}
return $bin if defined($bin);
#print "No bin assigned to $value of $type...\n"; # if $value =~ m/^[0-9-.e]+$/;
return(undef);
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
$pms->{'spec'} = 'hsa' if !$pms->{'spec'};
return undef;
}

sub readHeader ($$) {
    my($head, $tbl) = @_;
my(@arr, $aa, $smp);
chomp($head);
@arr = split("\t", $head);
for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/^LLR_//i;
$arr[$aa] = lc($arr[$aa]);
$pl->{$tbl}->{$arr[$aa]} = $aa;
$nm->{$tbl}->{$aa} = $arr[$aa];
if ($arr[$aa] =~ m/(TCGA\-.+?\-.+?\-.+?)\-/i) {
$samples{$1} = 1 ;
$pl->{$tbl}->{$1} = $aa;
$nm->{$tbl}->{$aa} = $1;

}}
return undef;
}

sub define_data {
#our();

$spe = 'hsa';
$table->{network}->{'hsa'} = 'm14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new'; 
$table->{mutation}->{'hsa'} = '/afs/pdc.kth.se/home/a/andale/CANCER/TCGA/TCGA_GBM_Level3_Somatic_Mutations_08.28.2008.maf';
$table->{methyl}->{'hsa'} = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CANCER/TCGA/Methyl/DNA_Methylation/JHU_USC__IlluminaDNAMethylation_OMA00?_CPI/Level_2/jhu-usc.edu__IlluminaDNAMethylation_OMA00?_CPI__beta-value';
$table->{expression}->{'hsa'} = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CANCER/TCGA/GBM/broad.mit.edu__HT_HG-U133A__probeset_rma';

$table->{'en2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/Name_2_name/SANGER47.externalGeneID_2_ENS_2_DE.Labels.New.human.txt';
#$pl->{'en2sym_hsa'}->{'id'} = 1; $pl->{'en2sym_hsa'}->{'sym'} = 0;
$pl->{'en2sym_hsa'}->{'id'} = 0; $pl->{'en2sym_hsa'}->{'sym'} = 4;

$table->{'cg2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CANCER/TCGA/Methyl/METADATA/JHU_USC__IlluminaDNAMethylation_OMA003_CPI/jhu-usc.edu_GBM.IlluminaDNAMethylation_OMA003_CPI.1.adf.txt';
$pl->{'cg2sym_hsa'}->{'id'} = 0; $pl->{'cg2sym_hsa'}->{'sym'} = 2;

$table->{'ma2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/Name_2_name/Gene_2_gnf1b_andU133.human.txt'; 
$pl->{'ma2sym_hsa'}->{'id'} = 0; $pl->{'ma2sym_hsa'}->{'sym'} = 1;

#$table->{2sym}->{'hsa'} = '';
#$table->{2sym}->{'hsa'} = '';
$I::p_minval = 3;
%metric = ( #first term is INDEPENDENT factor
#'mut-mut' => 'chisq', 
'mut-mut' => 'anova', 
'mut-exp' => 'anova', 
'mut-met' => 'anova', 
'met-mut' => 'anova', 
'met-exp' => 'correlation', 
'met-met' => 'correlation', 
'exp-mut' => 'anova', 
'exp-exp' => 'correlation', 
'exp-met' => 'correlation'
);
$metricPartial->{'exp-exp'}->{'exp'} = 
$metricPartial->{'exp-exp'}->{'met'} = 
$metricPartial->{'exp-met'}->{'exp'} = 'partialCorrelation';
$metricPartial->{'exp-met'}->{'met'} = 
$metricPartial->{'met-met'}->{'exp'} = 
$metricPartial->{'met-met'}->{'met'} = 'partialCorrelation';
$metricPartial->{'exp-exp'}->{'mut'} = 
$metricPartial->{'exp-met'}->{'mut'} = 
$metricPartial->{'met-met'}->{'mut'} = 'ancova';
$metricPartial->{'mut-exp'}->{'exp'} = $metricPartial->{'mut-met'}->{'exp'} = 'ancova';
$metricPartial->{'mut-exp'}->{'met'} = $metricPartial->{'mut-met'}->{'met'} = 'ancova';
$metricPartial->{'mut-exp'}->{'mut'} = $metricPartial->{'mut-met'}->{'mut'} = 'anova2w';


%coff = (
'fbs_max' => 3, 
'hsa' => 0, 
'mmu' => 0, 
'ppi' => 0, 
'pearson' => 0.001, 
'mut-mut' => 0.001, 
'mut-exp' => 0.001, 
'mut-met' => 0.001, 
'exp-mut' => 0.001, 
'met-mut' => 0.001, 
'exp-met' => 0.35,
'met-exp' => 0.35, 
'met-met' => 0.35, 
'exp-exp' => 0.35
);
$sign_cutoff{'Fratio'} = 4;
$coff{'partial'} = 0.3;
@{$link_fields->{'prim'}} = ('exp-exp', 'exp-met', 'met-exp', 'met-met', 'mut-exp', 'mut-met', 'exp-mut', 'met-mut', 'mut-mut');
@{$link_fields->{'netw'}} = ('fbs_max', 'hsa', 'mmu', 'rno', 'ppi', 'pearson');
$filedir = '/afs/pdc.kth.se/home/a/andale/m8/';

$table->{primary}->{$spe} = 'm8/WIR/Primary.All23Feb.WIR'; #'m8/PrimaryPAIRS..at_9755.WIR'; #
}

sub spearman ($$) {
my($x, $y) = @_;
my($xo, $yo, $xs, $ys, $i, $j, $le, $S, $ii);

if (!$x || !$y) {return(undef);}
if (scalar(@{$x}) != scalar(@{$y})) {return(undef);}
$le = scalar(@{$x});
$i = '0';
for ($j = 0; $j < $le; $j++) {
if ((defined($x->[$j]) and $x->[$j] =~ m/[0-9]/) and (defined($y->[$j]) and $y->[$j] =~ m/[0-9]/)) {
#next if !defined($x->[$j]) or !defined($y->[$j]);
#next if !($x->[$i] =~ m/[0-9]/ && $y->[$i] =~ m/[0-9]/);
$xo->[$i]->{'va'} = $x->[$j];
$xo->[$i]->{'no'} = $i;
$yo->[$i]->{'va'} = $y->[$j];
$yo->[$i]->{'no'} = $i;
$i++;
}}
return undef if !$i;
@{$xs} = sort {$a->{'va'} <=> $b->{'va'}} @{$xo};
@{$ys} = sort {$a->{'va'} <=> $b->{'va'}} @{$yo};

$i = '0';
for $ii(@{$xs}) {
$xo->[$ii->{'no'}]->{'ra'} = $i++;
}

$i = '0';
for $ii(@{$ys}) {
$yo->[$ii->{'no'}]->{'ra'} = $i++;
}

$le = scalar(@{$xo});
return undef if $le < $I::p_minval;
for ($i = 0; $i < $le; $i++) {
$S += ($xo->[$i]->{'ra'} - $yo->[$i]->{'ra'}) ** 2;
}
my $zTable = 2.58; #formal z value for 1% conf. interval
my $sigmaXz = $zTable * sqrt(1 / ($le - 3));
my $val = 1 - (6 / ($le * ($le ** 2 - 1))) * $S;
return($val) if (abs(ztransformation($val)) > $sigmaXz);
}

sub pearson ($$) {
my($x, $y) = @_;
my($r, $stds, $means, $p, $len, $le);
#the routine assumes equal sizes both $x and $y referenced arrays 
#NB: missing values from them are deleted pairwise
#it does not recognize arrays of size 1 and process them

if (!$x || !$y) {return(undef);}
$means = pwmean($x, $y);
if (!$means) {return(undef);}
$stds = pwstd($x, $y, $means);
#print "@{$means}\t@{$stds}\n";
$r = 0;
$len = scalar @{$x};
for ($p = 0; $p < $len; $p++) {
if ((defined($x->[$p]) and $x->[$p] =~ m/[0-9]/) and (defined($y->[$p]) and $y->[$p] =~ m/[0-9]/)) {
$r += ((($x->[$p] - $means->[0])/$stds->[0]) * (($y->[$p] - $means->[1])/$stds->[1]));
$le++;
}
}
#print "$means->[2]\n";
#print "R = $r at $means->[2]\n";
my $zTable = 2.58; #formal z value for 1% conf. interval
my $sigmaXz = $zTable * sqrt(1 / ($le - 3));
my $val = $r / ($means->[2]-1);
return($val)  if (abs(ztransformation($val)) > $sigmaXz);
}

sub pwmean ($$) {
my($x, $y) = @_;
my($n, $i, @sums, $len, @means);
#calculates an average of an array

$n = 0;
$len = scalar @{$x};
for ($i = 0; $i < $len; $i++) {
  if ((defined($x->[$i]) and $x->[$i] =~ m/[0-9]/) and (defined($y->[$i]) and $y->[$i] =~ m/[0-9]/)) {
    $n++;
   	$sums[0] += $x->[$i];
	$sums[1] += $y->[$i];
  }
}
return(undef) if $n < $I::p_minval;
$means[0] = $sums[0] / $n; #average x
$means[1] = $sums[1] / $n; #average y
$means[2] = $n; #N of valid cases

return(\@means);
}

sub pwstd ($$$) {
my($x, $y, $means) = @_;
my($i, @ssq, @stds, $len);

$len = scalar @{$x};
     for ($i = 0; $i < $len; $i++) {
       if ((defined($x->[$i]) && defined($y->[$i])) and ($x->[$i] =~ m/[0-9]/ && $y->[$i] =~ m/[0-9]/)) {
	 $ssq[0] += ($x->[$i] - $means->[0])**2;
	 $ssq[1] += ($y->[$i] - $means->[1])**2;
       }
     }
if ($ssq[0] == 0) {$ssq[0] += 0.000001;}
if ($ssq[1] == 0) {$ssq[1] += 0.000001;}

$stds[0] = sqrt($ssq[0] / ($means->[2] - 1));
$stds[1] = sqrt($ssq[1] / ($means->[2] - 1));
return(\@stds);
}

sub chisquare {
my($ChiSquareLimit, $cnt, $replaceSmallCounts, $ChiSquare, $col, $row, $marginal, $total, $expected, $returnUndef);
(
$cnt->{left}->{upper}, 		#upper left cell count
$cnt->{right}->{upper}, 
$cnt->{left}->{bottom}, 
$cnt->{right}->{bottom},  	#lower right
$replaceSmallCounts
) = @_;
$ChiSquareLimit = defined($main::ChiSquareLimit) ? $main::ChiSquareLimit : 1;
if ($cnt->{left}->{upper} < 0 or $cnt->{right}->{upper} < 0 or $cnt->{left}->{bottom} < 0 or $cnt->{right}->{bottom} < 0) {
print "A negative value submitted to the Chi-square function)\n";
return undef;
}
if ($main::debug >= 3) {
print "Counts as chi-square input: \n";
print $cnt->{left}->{upper}."\t".$cnt->{right}->{upper}."\n";
print $cnt->{left}->{bottom}."\t".$cnt->{right}->{bottom}."\n";
}

for $col(keys(%{$cnt})) {
for $row(keys(%{$cnt->{$col}})) {
#if ($ChiSquareLimit and $cnt->{$col}->{$row} < $ChiSquareLimit) {#return undef if !$replaceSmallCounts;}
$marginal->{$col} += $cnt->{$col}->{$row};
$marginal->{$row} += $cnt->{$col}->{$row};
}}
$total = $marginal->{left} + $marginal->{right};
die "Chi-square marginals do not match!..\n" if $total != $marginal->{upper} + $marginal->{bottom};
for $col(keys(%{$cnt})) {
for $row(keys(%{$cnt->{$col}})) {
$returnUndef = 1 if !$marginal->{$col} or !$marginal->{$row};
$expected = $marginal->{$col} * $marginal->{$row} / $total;
$returnUndef = 1 if ($ChiSquareLimit and $expected < $ChiSquareLimit and !$replaceSmallCounts);
if ($returnUndef) {
print "Chi-square is returned undefined...\n" if ($main::debug >= 3 or $main::debug =~ m/chi/i);
return undef;
}
$expected = $ChiSquareLimit if (($expected < $ChiSquareLimit) and $replaceSmallCounts);
$ChiSquare += ($cnt->{$col}->{$row} - $expected) ** 2 / $expected;
}}
print "Chi-square = $ChiSquare \n" if ($main::debug >= 3 or $main::debug =~ m/chi/i);
return $ChiSquare;
}

sub anova1way_WIR ($$) {
my($x, $profile) = @_; #$x is INDEPENDENT factor, $y is dependent continuous variable
my($i, %n, $ee, $mean, $N, $B, $SS, $MS, $variance);

my $minObs = 6;
for $i(0..$#{$x}) {
$ee = $profile->[$i]; next if !defined($ee) or $ee eq '';
$B = $x->[$i] ? $x->[$i] : '0';
$n{$B}++;
$mean->{total} += $ee; #total
$mean->{B}->{$B} += $ee;  #main factor B
}
return undef if (scalar(keys(%{$mean->{B}})) < 2);
   for $B(keys(%{$mean->{B}}))  {
return undef  if $n{$B} < 3;
$N += $n{$B};
} ###
return undef  if ($N < $minObs);

$mean->{total} /= $N;
for $B(keys(%{$mean->{B}})) {
	$mean->{B}->{$B} /= $n{$B};
	$SS->{B} += ($mean->{B}->{$B} - $mean->{total}) ** 2;
}
	for $i(0..$#{$x}) {
$ee = $profile->[$i]; next if !defined($ee) or $ee eq '';
$B = $x->[$i] ? $x->[$i] : '0';
$SS->{residual} += ($mean->{B}->{$B} - $ee) ** 2; ###
}
$MS->{B} = $SS->{B} / (scalar(keys(%{$mean->{B}})) - 1);
$MS->{residual} = $SS->{residual} / ($N - scalar(keys(%{$mean->{B}})));
$MS->{residual} = 0.000000001 if !$MS->{residual};
#$variance = $MS->{B} / ($N / (scalar(keys(%{$mean->{B}})) - 1));
$variance = ($MS->{B} - $MS->{residual}) / ($N / scalar(keys(%{$mean->{B}})));
return sqrt($variance / ($variance + $MS->{residual})) 
	if  ($MS->{B}/$MS->{residual}) > $sign_cutoff{'Fratio'}; 
#!!!returns the SQUARE ROOT of the variance component!!!
return undef;
return $MS->{residual} ? ($MS->{B}/$MS->{residual}) : 1000000; #returns F-ratio
}

sub max {
my(@ar) = @_;
my(@sar);
#finds a maximum of an array

return undef if !grep(/\w/, @ar);
return $ar[0] if scalar(@ar) == 1;
 if (grep(/[acxm]/, @ar)) {
return best_gavin(@ar);
}
@sar = sort {$b <=> $a} @ar;
  return($sar[0]);
}

sub maxabs {
my(@ar) = @_;
my(@sar);
return $ar[0] if scalar(@ar) == 1;
@sar = sort {abs($b) <=> abs($a)} @ar;
return($sar[0]);
}

#cat m8/ProcessedPAIRS.at_3853.PWI | sed '{s/NA//g}' | gawk 'BEGIN {FS="\t"; OFS="\t"; eco = 0.5; mco = 0.00 } {if ($4 > eco  || $6 > eco || $8 > eco || $10 > eco || $12 > mco || $14 > mco ||  $16 > mco ||  $18 > mco ||  $20 > mco ||$21) print $1, $2, $4, $6, $8, $10, $12, $14, $16, $18, $20, $21}' > ! m8/WIR/_sel1

#gawk 'BEGIN {for (i = 3; i<36; i++) {ca[i-2] = i} FS="\t"; OFS="\t"} {if (ARGIND == 1) {a[toupper($3) toupper($4)] = 1;} else {for (i in ca) {if ($1 > ca[i]) {tc[ca[i]]++; if (a[$6 $7] || a[$7 $6]) {co[ca[i]]++}}}}}   END {for (i in ca) {print i, ca[i], co[ca[i]], tc[ca[i]], co[ca[i]]/tc[ca[i]]}}' wir1.sql Human.Version_1.00.4classes.TCGA_SYM | sort -n > liklihoodFCinWIR.wir.txt &


