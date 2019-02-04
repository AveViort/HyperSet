package WD; #version  ~/pl/WD.TCGAfresh.pm
use strict vars;
#use warnings;
use constant TAB => "\t";
use constant TRUE => "1";
use constant SUCCESS => "1";
#use Exporter 'import';


our($spe, $table, $metricPartial, %metric, %coff, %sign_cutoff, $filedir, %samples, $genes, $doNotProcessOrphanProbes, $link, $names, $mapToNet, $filenamesPCIT, $outputfilenames, %data, $correlation_func, $pl, $chroDistCutoff, $locs, $minR, $printRectangularTable,
$mutdata, $methdata, $cnadata, $expdata, $watchChroDist, 
$link_fields, $xref, $checkPartial, $onlySignificantCorrelations, $processTriangles, $N1, $N2, $correlationSignificance_table_value, $FBScutoff, $printOnlyCausal, $p_minval);

our $label_delimiter = '-';
$processTriangles = 1; # if defined($main::pms->{'star'}) and defined($main::pms->{'end_'});
$doNotProcessOrphanProbes = 1;
$checkPartial = 1;
$correlation_func = 'NET::pearson';
#$correlation_func = 'NET::spearman';
$FBScutoff = 3;
$mapToNet = 0;
$watchChroDist = 1;
$chroDistCutoff = 100000; #(base pairs)
$minR = 0.30;
$printRectangularTable = 0; #print snapshot table of data used within th eprogram

$printOnlyCausal = 1;
#$mergeSwappedDyes = 0;
#$onlySignificantCorrelations = 1;
$correlationSignificance_table_value = 2.58; #formal z value for 1% conf. interval
#$correlationSignificance_table_value = 1.96; #formal z value for 1% conf. interval
#$sigmaXz = 0.3705;
#($N1, $N2) = (16, 16); #No. of observations for each variable
#($N1, $N2) = (8, 8) if $mergeSwappedDyes; #No. of observations for each variable
#$sigmaXz = $correlationSignificance_table_value * sqrt(1 / ($N1 - 3));
#$sigmaXz1z2 = $correlationSignificance_table_value * sqrt((1 / ($N1 - 3)) + (1 / ($N2 - 3))); #0.1436 * 2.58

$spe = 'hsa';
$p_minval = 30;

sub readInputData {
my($id, $as);

#for $id('cg', 'ma', 'en')

for $id('cg') {readSymbols($id, $spe);}
#readPhenoData() if !$mergeSwappedDyes;
if  ($printRectangularTable) {
 readMethyl($spe, $table->{methyl}->{$spe}) if 1 == 1;
 arrangeBySample($methdata, 0, 1, 0, 'methylation');
readExpression($spe, $table->{expression}->{$spe});
 arrangeBySample($expdata, 0, 1, 1, 'expression');
readCNA($spe, $table->{cna}->{$spe}) ;
arrangeBySample($cnadata, 0, 0, 0, 'cna');
exit ;
}
# readExpression($spe, $table->{expression}->{$spe}) if 1 == 1;
# arrangeBySample($expdata, 0, 1, 1);
#exit;
# 
# arrangeBySample($mutdata, 1, 0);
readMutation($spe, $table->{mutation}->{$spe}) if 1 == 1;
readExpression($spe, $table->{expression}->{$spe}) if 1 == 1;
readMethyl($spe, $table->{methyl}->{$spe}) if 1 == 1;
readCNA($spe, $table->{cna}->{$spe}) if 1 == 1;

arrangeBySample($mutdata, 1, 0);
arrangeBySample($methdata, 0, 0);
arrangeBySample($expdata, 0, 1);
arrangeBySample($cnadata, 0, 0);

%data = ( #type-specific data structures
'mut' => $mutdata,
'cna' => $cnadata,
'met' => $methdata,
'exp' => $expdata
);
}

# head -100000 pcit4_WirPairs.WIR.0.3.OV.PRIM.0-4126 | gawk 'BEGIN {co = 0.95; FS="\t"; OFS="\t"} {la = 0; for (i = 3; i <= 10; i++) {if (($i  > co) || ($i < -co)) {la = 1; print $i, la}} if (la == 1) {print la, $0}}' | m


# c _gbm.cna | rhead | grep -i tcga | gawk 'BEGIN {FS="\t"; OFS="\t"} {split($1, a, "-"); la = a[4]; la = substr(la, 1, 2); print a[1] "-" a[2] "-" a[3] "-" la, "GBM", "cna"}' | sort -u >> sample.lst
#h1 TCGA.GBM_tum.HG-U133.byGenes | rhead | grep -i tcga | gawk 'BEGIN {FS="\t"; OFS="\t"} {split($1, a, "-"); la = a[4]; la = substr(la, 1, 2); print a[1] "-" a[2] "-" a[3] "-" la, "GBM", "exp"}' | sort -u >> sample.lst
#FC.awk TCGA.GBM.All_sites.maf 16 | rhead | grep -i tcga | gawk 'BEGIN {FS="\t"; OFS="\t"} {split($1, a, "-"); la = a[4]; la = substr(la, 1, 2); print a[1] "-" a[2] "-" a[3] "-" la, "GBM", "mut"}' | sort -u >> sample.lst
#h1 GBM.HumanMethylation27.TAB | rhead | grep -i tcga | gawk 'BEGIN {FS="\t"; OFS="\t"} {split($1, a, "-"); la = a[4]; la = substr(la, 1, 2); print a[1] "-" a[2] "-" a[3] "-" la, "GBM", "met"}' | sort -u > ! sample.lst


sub define_data {
#our();

$spe = 'hsa';
$filedir = '/afs/pdc.kth.se/home/a/andale/m11/TCGAfresh/INPUT/';

$table->{primary}->{$spe} =
 $filedir.'Primary.'.$main::CancerType.'.'.$main::current_proj; 

#$table->{network}->{'hsa'} = 'm14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new';

# GBM_HMS__HG-CGH-244A.txt  OV_HMS__HG-CGH-244A.txt  TCGA.GBM.All_sites.maf        TCGA.OV.All_sites.maf
# GBMmeth.txt               OVmeth.txt               TCGA.GBM_tum.HG-U133.byGenes  TCGA.OV_tum.HG-U133.byGenes

$table->{mutation}->{'hsa'} 	= $filedir.'TCGA.'.$main::CancerType.'.All_sites.maf';
$table->{cna}->{'hsa'} 			= $filedir.$main::CancerType.'_HMS__HG-CGH-244A.txt';
$table->{methyl}->{'hsa'} 		= $filedir.$main::CancerType.'.HumanMethylation27.TAB';
$table->{expression}->{'hsa'} 	= $filedir.'TCGA.'.$main::CancerType.'_tum.HG-U133.byGenes';

#$table->{'en2sym_hsa'} = $filedir.''; $pl->{'en2sym_hsa'}->{'id'} = 0; $pl->{'en2sym_hsa'}->{'sym'} = 4;
#$table->{'ma2sym_hsa'} = ''; $pl->{'ma2sym_hsa'}->{'id'} = 0; $pl->{'ma2sym_hsa'}->{'sym'} = 1;
$table->{'cg2sym_hsa'} = $filedir.'CG2Sym.HumanMethylation27';
$table->{'locs_hsa'} = 'human_GRCh37.p3.Genes';
$NET::pl->{'cg2sym_hsa'}->{'id'} = 0; $NET::pl->{'cg2sym_hsa'}->{'sym'} = 1;

@{$link_fields->{'primary'}} = (
'exp-exp'
 # , 'exp-met', 
# 'met-met', 
# 'met-exp', 
# 'mut-exp', 'mut-met', 
# 'cna-exp', 'cna-met'
);
my($fld);
for $fld(@{$link_fields->{'primary'}}) {
$metric{$fld} = ($fld =~ m/mut/) ? 'anova': 'correlation';
}

# %metric = ( #first term is INDEPENDENT factor
'mut-mut' => 'chisq',
# 'mut-mut' => 'anova',
# 'mut-exp' => 'anova',
# 'mut-met' => 'anova', 
# 'met-mut' => 'anova',
# 'met-exp' => 'correlation',
# 'met-met' => 'correlation',
# 'exp-mut' => 'anova',

# 'cna-mut' => 'anova', 
# 'mut-cna' => 'anova', 

# 'exp-exp' => 'correlation',
# 'exp-met' => 'correlation'
# );
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

my $tempCoff = 0;
for $fld(@{$link_fields->{'primary'}}) {
$coff{$fld} = ($fld =~ m/mut/) ? 0.001: 0.300;
}

# %coff = (
# 'fbs_max' => 3, 
# 'hsa' => 0,
# 'mmu' => 0,
# 'ppi' => 0,
# 'pearson' => 0.001,
# 'mut-mut' => 0.001,
# 'mut-exp' => 0.001,
# 'mut-met' => 0.001,
# 'exp-mut' => 0.001,
# 'met-mut' => 0.001,
# 'exp-met' => 0.35,
# 'met-exp' => 0.35,
# 'met-met' => 0.35,
# 'exp-exp' => 0.35,
# 'exp0-exp0' => $tempCoff,
# 'exp1-exp1' => $tempCoff,
# 'exp2-exp2' => $tempCoff,
# 'exp3-exp3' => $tempCoff,
# 'expR-expR' => $tempCoff
# );

$sign_cutoff{'Fratio'} = 4;
$coff{'partial'} = 0.3;
}

sub arrangeBySample {
my($tag, $replaceUndef, $normalize, $byGene, $dataLabel) = @_;
my($gene, $name, $smp, $Means, $value, $n, $mean, $subsetBy, $mean);

print "Arranging a rectangular IDxSAMPLE table with ".scalar(keys(%{$tag}))." gene/probe ID rows and ".scalar(keys(%WD::samples))." sample columns ...\n";
if ($printRectangularTable) {open M1, '> '.
$filedir.join('.', 
('snapshot', $dataLabel, 
$main::CancerType, 
'ALL',
$replaceUndef, $normalize, $byGene,  
'txt')
);
}
if ($printRectangularTable) {print M1 join("\t", ("GENE", sort {$a cmp $b} keys(%WD::samples)))."\n";}
print "Normalizing with ".($byGene ? "gene" : "sample")." means ...\n" if !$byGene;

if ($normalize > 0 and !$byGene) {
for $smp(sort {$a cmp $b} keys(%WD::samples)) {
undef $n; undef $mean;
for $gene(keys(%{$tag})) {
for $name(keys(%{$tag->{$gene}->{samples}})) {
$value = $tag->{$gene}->{samples}->{$name}->{$smp};
next if (!defined($value));
$n++; $mean += $value;
}}
$Means->{bySample}->{$smp} = $mean/$n if $n;
}
}

for $gene(keys(%{$tag})) {
for $name(keys(%{$tag->{$gene}->{samples}})) {
if ($normalize and $byGene) {
for $smp(sort {$a cmp $b} keys(%WD::samples)) {
$value = $tag->{$gene}->{samples}->{$name}->{$smp};
next if (!defined($value));
$n++; $mean += $value;
}
$Means->{byGene}->{$gene}->{$name} = $mean/$n if $n;
undef $n; undef $mean;
}

for $smp(sort {$a cmp $b} keys(%WD::samples)) {
$value = $tag->{$gene}->{samples}->{$name}->{$smp};
$n++ if defined($value);
$value = '0' if ($replaceUndef and !defined($value)) ;
$mean = ($byGene ? $Means->{byGene}->{$gene}->{$name} : $Means->{bySample}->{$smp}) if ($normalize > 0);
$value =  ($mean > 0  and $value > 0)  ? sprintf("%.3f", (log($value / $mean)/log(2))) : $value
if $normalize;
push @{$tag->{$gene}->{profile}->{$name}}, $value;
}
      if ($printRectangularTable) {
	  print M1 join("\t", 
	  ($name, @{$tag->{$gene}->{profile}->{$name}})
	  )."\n";
	  }
}}
          if ($printRectangularTable) {close M1;}
return;
}

sub shuffleProfiles {
my($data1, $data2) = @_;
my($shData1, $shData2, $val, @pool);

die "Not an array in shuffleProfiles...\n" if ((ref($data1) ne 'ARRAY') or (ref($data2) ne 'ARRAY'));
die "Unequal INPUT array lengths in shuffleProfiles...\n" if ($#{$data1} != $#{$data1});
@pool = (@{$data1}, @{$data2});
my $le = scalar(@pool) / 2;
while ($val = shift(@pool)) {
if ((scalar(@{$shData1}) < $le) and rand(1) < 0.5) {push @{$shData1}, $val}
else               {push @{$shData2}, $val}
}
die "Unequal OUTPUT array lengths in shuffleProfiles...\n" if ($#{$shData1} != $#{$shData1});
return($shData1, $shData2);
}

sub reduceBarCode {
my($smp) = @_;
return(($smp =~ m/(TCGA\-[0-9]{2}\-[0-9]{4}\-[0-9]{2})/i) ? lc($1) : undef);
}

sub readMutation {
my($genome, $table) = @_;
my($gene, @a, $name, $n, $smp, $value);

open(IN, $table) or return undef;
print "Loading $table...\n";
$_ = <IN>; NET::readHeader($_, $table);
my $nm = $NET::nm;
my $pl = $NET::pl;
while (<IN>) {
chomp;
@a = split(/\t/, $_);
undef $smp;
$n++;
#last if $n > 10000000;
$gene = $name = lc($a[$pl->{$table}->{'hugo_symbol'}]);  
$names->{'probe'}->{$name} = 1; $genes->{total_list}->{$gene} = $genes->{'mut'}->{$gene} = 1;
if ($a[$pl->{$table}->{'tumor_sample_barcode'}] =~ m/(TCGA\-.+?\-.+?\-.+?)\-/i) {
#$smp = lc($1);
$smp = reduceBarCode($1);
$samples{$smp} = 1; 
}
$value = (lc($a[$pl->{$table}->{'mutation_status'}]) eq 'somatic') ? '1' : undef;
#(lc($a[$pl->{$table}->{'variant_classification'}]).lc($a[$pl->{$table}->{'start_position'}]))
$mutdata->{$gene}->{samples}->{$name.'_at_'.$table}->{$smp} = $value if $value;
}
print scalar(keys(%{$pl->{$table}})).' table columns, '.scalar(keys(%{$mutdata})).' genes, '."$n mutation records in\n$table...\n\n";
close IN; 
return undef;
}

sub readCNA {
my($genome, $table, $readAll) = @_;
my($gene, @a, $name, $n, $smp, $value);

open(IN, $table) or return undef;
print "Loading $table...\n";
$_ = <IN>; NET::readHeader($_, $table);
my $nm = $NET::nm;
my $pl = $NET::pl;
while (<IN>) {
chomp;
@a = split(/\t/, $_);
#last if $n > 100000;
$gene = $name = lc($a[$pl->{$table}->{'genename'}]);  
next if !$readAll and !defined($genes->{used_list}->{$gene});
undef $smp; $n++;
$names->{'probe'}->{$name} = 1; $genes->{total_list}->{$gene} = $genes->{'cna'}->{$gene} = 1;
if ($a[$pl->{$table}->{'sample'}] =~ m/(TCGA\-.+?\-.+?\-.+?)\-/i) {
$smp = reduceBarCode($1);
$samples{$smp} = 1; 
}

$value = $a[$pl->{$table}->{'seqmean'}];
#(lc($a[$pl->{$table}->{'variant_classification'}]).lc($a[$pl->{$table}->{'start_position'}]))
$cnadata->{$gene}->{samples}->{$name.'_at_'.$table}->{$smp} = $value;
}
print scalar(keys(%{$pl->{$table}})).' table columns, '.scalar(keys(%{$cnadata})).' genes, '."$n copy number values in\n$table...\n\n";
close IN; 
return undef;
}

sub readMethyl {
my($genome, $table) = @_;
my($gene, @arr, $name, $smp, @epl, $startcol, $namecol, $i, $j, $n, $tag, $value, $length);

$namecol = 0; $startcol = 1;
$tag = 'cg2sym_'.$genome;
open IN, 'cat '.$table.' | '  or return undef;
print "Loading $table...\n";
$_ = <IN>;
@arr = split(/\t/, $_);
NET::readHeader($_, $table); 
my $nm = $NET::nm;
my $pl = $NET::pl;
$length = scalar(@arr);

while (<IN>) {
chomp;
@arr = split(/\t/, $_);
next if $arr[2] =~ m/beta.*value/i;
#last if $n++ > $Ntestlines;
$name = lc($arr[$namecol]); 
undef $gene;
if ($name =~ m/^cg[0-9]/) {
$gene = lc($xref->{$tag}->{'id2sym'}->{lc($name)}); #$i = 0;
}
else {
$gene = lc($1) if $name =~ m/(.+?)\_/;
}
print $name."\n" if !$gene;
$gene = $name if !$gene; 
$names->{'probe'}->{$name} = 1;
$genes->{used_list}->{$gene} = $genes->{total_list}->{$gene} = $genes->{'met'}->{$gene} = 1;
for $j($startcol..$length) {
$value = ($arr[$j] eq '') ? undef : sprintf("%.3f", 2 * Math::Trig::asin(sqrt($arr[$j])) / Math::Trig::pi());
$smp = reduceBarCode($nm->{$table}->{$j});
$methdata->{$gene}->{samples}->{$name.'_at_'.$table}->{$smp} = $value;
$samples{$smp} = 1; 
}}
print scalar(keys(%{$methdata})).' genes, '.scalar(keys(%{$names->{'probe'}})).' IDs, '.scalar(keys(%{$pl->{$table}})).' samples, '."$n processedID profiles in\n$table...\n\n";
close IN; #exit;
return undef;
}

sub readExpression {
my($genome, $table) = @_;
my($gene, @a, $name, $smp, @epl, $startcol, $namecol, $i, $j, $n, $tag, $value, $subset, $subsetBy);

$namecol = 0; $startcol = 1;
$tag = 'ma2sym_'.$genome;
open(IN, $table) or return undef;
print "Loading $table...\n";
$_ = <IN>;
@epl = split(/\t/, $_);
NET::readHeader($_, $table);
while (<IN>) {
chomp;
@a = split(/\t/, $_);
next if $a[2] =~ m/probeset_/i;
$name = lc($a[$namecol]);
$gene =  defined($xref->{$tag}) ? lc($xref->{$tag}->{'id2sym'}->{lc($name)}) : $name; 
#$i = 0;
next if !$gene and $doNotProcessOrphanProbes;  #MA probes without gene assignement are skipped
last if $n++ > $main::Ntestlines;
$gene = $name if !$gene; #print $name."\n" if !$gene;
$names->{'probe'}->{$name} = 1;
$genes->{used_list}->{$gene} = $genes->{total_list}->{$gene} = $genes->{'exp'}->{$gene} = 1;
for $j($startcol..$#epl) {
$value = ($a[$j] eq '') ? undef : sprintf("%.4f", $a[$j]);
$smp = reduceBarCode($NET::nm->{$table}->{$j});
$expdata->{$gene}->{samples}->{$name.'_at_'.$table}->{$smp} = $value;
$samples{$smp} = 1; 
}}
print scalar(keys(%{$expdata})).' genes, '.scalar(keys(%{$names->{'probe'}})).' IDs, '.scalar(keys(%{$NET::pl->{$table}})).' samples, '."$n processed ID profiles in\n$table...\n\n";
close IN; #exit;
return undef;
}

sub readPhenoData {
#my($id, $species) = @_;
my(@a, $n);
my $tag = 'barcode2pheno';
open SYM, $table->{$tag} or die("No $tag xref table...\n");
while (<SYM>) {
chomp; @a = split("\t", $_);
next if !$a[$NET::pl->{$tag}->{'id'}] or !$a[$NET::pl->{$tag}->{'sym'}];
$n++;
$xref->{$tag}->{'barcode2relapse'}->{lc($a[$NET::pl->{$tag}->{'barcode'}])} = lc($a[$NET::pl->{$tag}->{'relapse'}]);
$xref->{$tag}->{'barcode2chemo'}->{lc($a[$NET::pl->{$tag}->{'barcode'}])} = lc($a[$NET::pl->{$tag}->{'chemo'}]);
}
close SYM;
print scalar(keys(%{$xref->{$tag}->{'sym2id'}})).' gene symbols, '.scalar(keys(%{$xref->{$tag}->{'id2sym'}})).' IDs, '."$n ID-symbol pairs in\n$table->{$tag}...\n\n";
return undef;
}

sub readRedoList {
my($id, $species) = @_;
my(@ar, $n, %list);

open SYM, $filedir.'_missing1.'.$main::CancerType or die("No redo table...\n");
while (<SYM>) {
chomp; @ar = split("\t", $_); $n++;
$list{$ar[0]} = 1;
}
close SYM; 
print scalar(keys(%list)).' gene symbols from '.$n.' lines ... '."\n";
return(sort {$a cmp $b} keys(%list));
}

sub readLocs {
my($table) = @_;

# 1:Associated Gene Name
# 2:Ensembl Gene ID
# 3:Chromosome Name
# 4:Gene Start (bp)
# 5:Gene End (bp)
# 6:Strand
# 7:Band
# 8:Transcript count
# 9:Gene Biotype
# 10:Status (gene)
my $nm = $NET::nm;
my $pl = $NET::pl;
my(@ar, $n);

open SYM, $filedir.$table or die("No locs table...\n");
$_ = <SYM>;
NET::readHeader($_, $table);
my $nm = $NET::nm;
my $pl = $NET::pl;
while (<SYM>) {
chomp; @ar = split("\t", lc($_)); $n++;
$locs->{$ar[$pl->{$table}->{'associated gene name'}]}->{start} = $ar[$pl->{$table}->{'gene start (bp)'}];
$locs->{$ar[$pl->{$table}->{'associated gene name'}]}->{end} = $ar[$pl->{$table}->{'gene end (bp)'}];
$locs->{$ar[$pl->{$table}->{'associated gene name'}]}->{chro} = $ar[$pl->{$table}->{'chromosome name'}];
$locs->{$ar[$pl->{$table}->{'associated gene name'}]}->{strand} = $ar[$pl->{$table}->{'strand'}];
}
close SYM; 
print scalar(keys(%{$locs})).' gene symbols from '.$n.' lines ... '."\n";
return undef; #(sort {$a cmp $b} keys(%list));

}


sub readSymbols {
my($id, $species) = @_;
my(@a, $n);
my $tag = $id.'2sym_'.$species;
open SYM, $table->{$tag} or die("No $tag xref table...\n");
while (<SYM>) {
chomp; @a = split("\t", $_);
next if !$a[$NET::pl->{$tag}->{'id'}] or !$a[$NET::pl->{$tag}->{'sym'}];
$n++;
$xref->{$tag}->{'sym2id'}->{lc($a[$NET::pl->{$tag}->{'sym'}])} = lc($a[$NET::pl->{$tag}->{'id'}]);
$xref->{$tag}->{'id2sym'}->{lc($a[$NET::pl->{$tag}->{'id'}])} = lc($a[$NET::pl->{$tag}->{'sym'}]);
}
close SYM; 
print scalar(keys(%{$xref->{$tag}->{'sym2id'}})).' gene symbols, '.scalar(keys(%{$xref->{$tag}->{'id2sym'}})).' IDs, '."$n ID-symbol pairs in\n$table->{$tag}...\n\n";
return undef;
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
	if  ($MS->{B}/$MS->{residual}) > $WD::sign_cutoff{'Fratio'};
#!!!returns the SQUARE ROOT of the variance component!!!
return undef;
return $MS->{residual} ? ($MS->{B}/$MS->{residual}) : 1000000; #returns F-ratio
}
