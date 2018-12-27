package NET;
use strict vars;
use constant TAB => "\t";
use constant TRUE => "1";
use constant SUCCESS => "1";
our(%pl, $pl, $nm, $node, $link, @links1);
our $NOT_NEIGHBORS = 10000000000;
return TRUE;


sub compileAGS {
my($jid, $AGSfile, $AGSselected, $gene_column_id, $group_column_id, $Genewise, $species) = @_;
 print join(' | ', @_).'<br>' if $main::debug;
if ((uc($Genewise) ne 'FALSE') and (uc($Genewise) ne 'TRUE')) {die 'Wrong parameter "Genewise"...';}
my($op, @ar, $tmpAGS, %selected, $line, $group, $gene, $genes, $gene_list, $hsgene, $fcgenes, $takeIt,
$venn, @a1, @a2);
$tmpAGS = main::tmpFileName('AGS', $jid);
open OUT, '> '.$tmpAGS or die "Could not create temporary file ...\n";
my $i = 0; 
print $AGSfile if $main::debug;
print(join(' ', @{$AGSselected})) if $main::debug;	
if ($AGSfile eq '#venn_lists') {
# print 'L2: '.scalar(@{$AGSselected}).'<br>';
# print 'VENN: '.join('; ', @{$AGSselected}).'<br>';
for $venn(@{$AGSselected}) {
@a1 = split(':', $venn);
$op = $a1[0];
@a2 = split(';', $a1[1]);
for $gene(@a2) {
$i++;
print OUT join("\t", ($gene, $gene, (uc($Genewise) eq 'TRUE') ? $gene : $op))."\n";
}
}
} else {

for $op(@{$AGSselected}) {
print "DIR". $gene_column_id.' '. $group_column_id.' Genew' . $Genewise.'<br>'  if $main::debug;
if  ($AGSfile =~ m/\#sgs_list/) {
$op =~ s/\s//g;
$group = (uc($Genewise) eq 'TRUE') ? $op : $HSconfig::users_single_group.'_AGS';
$genes->{$op} = $group; 
# print OUT join("\t", ($op, $op, $group))."\n" ;  $i++;# print selected genes directly to the agsFile
} else {
# print '<br>Selected AGS member: '.uc($op).'<br>';
$selected{uc($op)} = 1;
}}
# print '<br>AGS file: '.$AGSfile.'<br>'  if ($AGSfile ne '#sgs_list');
if ($AGSfile !~ m/\#sgs_list/) {
print STDERR $AGSfile;
# local($/) = "\r" if $main::q->param("useCR");  
# print 'useCR: ++'.$main::q->param("useCR").'++<br>'."\n"  if $main::debug;
open  IN, $AGSfile or die "Could not re-open AGS file $AGSfile ...\n"; #otherwise, 
while ($_ = <IN>) {
$takeIt = 0;
# print 'IN '.$_.'<br>'."\n" ;
$line = $_;
chomp;
@ar = split("\t", $_);
$gene = $ar[$gene_column_id];   
$gene =~ s/\s//g;

if ($group_column_id < 0) {
$group = (uc($Genewise) eq 'FALSE') ? $HSconfig::users_single_group.'_AGS' : $gene;
$takeIt = 1;
} else {
$group = $ar[$group_column_id];
$group =~ s/\s//g;
$takeIt = 1 if $selected{uc($group)};
$group = (uc($Genewise) eq 'FALSE') ? $group : $gene;
}
# print 'Gene '.$gene.'<br>'."\n"  ;
next if !$takeIt;
$genes->{$gene} = $group;
# print OUT join("\t", ($gene, $gene, $group))."\n";$i++; 
}}
#
@{$gene_list} = keys(%{$genes});
  # print 'ALL AGS GENES: '.join(" ",@{$gene_list} ).'<br>'."\n"  ;
$fcgenes = HS_SQL::gene_synonyms($gene_list, $species, 'ags');
for $gene(@{$gene_list}) {
 # print 'Gene '.$gene.'<br>'."\n" ;
for $hsgene(do { my %seen; grep { !$seen{$_}++ } @{$HS_bring_subnet::submitted_genes->{$species}->{uc($gene)}->{'hsnames'}}}) {
# for $hsgene(@{$HS_bring_subnet::submitted_genes->{$species}->{uc($gene)}->{'hsnames'}}) {
 $i++; 
 # print 'HS_gene '.$i.': '.$hsgene.'<br>'."\n"  ;
 print OUT join("\t", ($hsgene, $hsgene, ( uc($Genewise) eq 'TRUE' and defined($HS_bring_subnet::submitted_genes->{$species}->{uc($gene)})) ? $hsgene : $genes->{$gene}))."\n";
}}
close IN;
}
 close OUT;
die 'The AGS file is empty...<br>'."\n" if !$i;
return($tmpAGS);
}

sub compileFGS {
my($jid, $FGStype, $FGSselected, $Genewise) = @_;
my($op, $tmpFGS, $pl, $line, @ar, $file, $group);
$tmpFGS = main::tmpFileName('FGS', $jid);
my $fgsA = $HSconfig::fgsAlias;
my $coff = 0; my $spe = $main::q->param("species");

open OUT, '> '.$tmpFGS or die "Could not create temporary file ...\n";
#print '> '.$HSconfig::usersTMP.$tmpFGS if $main::debug;
my $i = 0;
for $op(@{$FGSselected}) {
if  ($FGStype eq '#cpw_list') {
$op =~ s/\s//g;
$group = ($Genewise and (uc($Genewise) ne 'FALSE')) ? $op : $HSconfig::users_single_group.'_as_FGS';
print OUT join("\t", ($op, $op, $group))."\n";  $i++; # print selected genes directly to the agsFile
}
else {
$file = $HSconfig::fgsDir.$spe.'/'.$fgsA->{$spe}->{$op};
$pl->{$file}->{gene} = 1;
$pl->{$file}->{group} = 2;
print '<br>FGS file: '.$file.'<br>' if $main::debug;
open  IN, $file or die "Could not re-open FGS file $file ...\n";
while ($_ = <IN>) {
chomp;
@ar = split("\t", $_); 
$line = join("\t", (
uc($ar[$pl->{$file}->{gene}] ), 
uc($ar[$pl->{$file}->{gene}] ), 
($Genewise and (uc($Genewise) ne 'FALSE')) ? uc($ar[$pl->{$file}->{gene}]) : uc($ar[$pl->{$file}->{group}]), 
$op ));
print OUT $line."\n"; $i++; # if defined($selected{uc($ar[$pl->{$AGSfile}->{group}])});
}
close IN;
}}
close OUT;
die 'The FGS file is empty...<br>'."\n" if !$i;
return($tmpFGS);
}

sub compileNet {
my($jid, @options) = @_;
my($op, $tmpNet, $pl, $line, @ar, $file);
$tmpNet = main::tmpFileName('Net', $jid);
my $netA = $HSconfig::netAlias;
my $coff = 0; my $spe = $main::q->param("species");
   
open OUT, '> '.$tmpNet or die "Could not create temporary file ...\n";
my $i = 0;
for $op(@options) {
$file = $HSconfig::netDir.$main::q->param("species").'/'.$netA->{$spe}->{$op};

$pl->{$file}->{gene1} = 0;
$pl->{$file}->{gene2} = 1;
$pl->{$file}->{confidence} = 2;
print '<br>NET file: '.$file.'<br>'  if $main::debug;
open  IN, $file or die "Could not re-open $file ...\n";
while ($_ = <IN>) {
chomp;
@ar = split("\t", $_);
if (!$ar[$pl->{$file}->{confidence}] or ($ar[$pl->{$file}->{confidence}] >= $coff)) {
$line = join("\t", (
$ar[$pl->{$file}->{gene1}], 
$ar[$pl->{$file}->{gene2}]
));
print OUT $line."\n"; $i++;
}}
close IN;
}
close OUT;
die 'The NET file is empty...<br>'."\n" if !$i;
return($tmpNet);
}

sub PCITConditionalIndependence { #implementation of the PCIT rule (#Ref.)
my($Rxy, $Rxz, $Ryz) = @_;
my($ThePC, $epsilon, $result);
$ThePC = partialCorrelation($Rxy, $Rxz, $Ryz);
$epsilon = (	$ThePC / $Rxy +
		partialCorrelation($Rxz, $Rxy, $Ryz) / $Rxz +
		partialCorrelation($Ryz, $Rxy, $Rxz) / $Ryz ) / 3;
$result = ((abs($ThePC) < abs($epsilon * $Rxz)) and (abs($ThePC) < abs($epsilon * $Ryz))) ? '0' : $Rxy;
return($result);
}

sub chroDistBP {#distance between the genes in basepairs
my($gene1, $gene2, $locs) = @_;
my($distance, $start1, $end1, $start2, $end2, $cnum1, $cnum2);
#print "@_\n";
$cnum1 = $locs->{$gene1}->{chro};
$cnum2 = $locs->{$gene2}->{chro};
return $NOT_NEIGHBORS if  !$cnum1 or !$cnum2;
return $NOT_NEIGHBORS  if $cnum1 ne $cnum2;

$start1 = $locs->{$gene1}->{start};
$end1 = $locs->{$gene1}->{end};
$start2 = $locs->{$gene2}->{start};
$end2 = $locs->{$gene2}->{end};
$end1 = $start1 if !defined($end1);
$end2 = $start2 if !defined($end2);
$start1 = $end1 if !defined($start1);
$start2 = $end2 if !defined($start2);

if ($start1 < $start2) {
$distance = $start2 - $end1;
}
else {
$distance = $start1 - $end2;
}
return($distance);
}

sub partialCorrelation {
my($Rxy, $Rxz, $Ryz) = @_;
$Rxy = 0 if (abs($Rxy) > 0.99);
$Rxz = 0 if (abs($Rxz) > 0.99);
$Ryz = 0 if (abs($Ryz) > 0.99);
#return undef if (abs($Rxz) > 0.99) or (abs($Ryz) > 0.99);
my $value = ($Rxy - $Rxz * $Ryz) / ((sqrt(1 - $Rxz ** 2) * sqrt(1 - $Ryz ** 2)));
return $value;
}

sub testCorrelationSignificance {
my($new, $N1, $old, $N2) = @_;
return undef if abs($new) > 1 or abs($old) > 1;

if (!defined($old)) {
return((abs(ztransformation($new)) > sigmaX($N1)) ? 1 : 0);
}
else{
return((abs(ztransformation($new) - ztransformation($old)) > sigmaX($N1, $N2)) ? 1 : 0);
}}

sub sigmaX {
my($N1, $N2) = @_;
die "Define correlationSignificance_table_value in WD.pm...\n" if !defined($WD::correlationSignificance_table_value);
if (!defined($N2)) {
return($WD::correlationSignificance_table_value * sqrt(1 / ($N1 - 3)));
}
else {
return($WD::correlationSignificance_table_value * sqrt((1 / ($N1 - 3)) + (1 / ($N2 - 3))));
}}

sub ztransformation {
my($value) = @_;
return undef if abs($value) > 1;
$value = -0.999999 if $value == -1; $value = 0.999999 if $value ==  1;
return log((1 + $value) / (1 - $value)) / 2;
}

sub randomizeList {
my($groups) = @_;
my($Rgroups, $gr, @pool, $gene);

for $gr(keys(%{$groups})) {push @pool, keys(%{$groups->{$gr}});}

for $gr(keys(%{$groups})) {
while (scalar(keys(%{$Rgroups->{$gr}})) < scalar(keys(%{$groups->{$gr}}))) {
$gene = $pool[rand($#pool)];
$Rgroups->{$gr}->{$gene} = 1 if !defined($Rgroups->{$gr}->{$gene});
}}
return $Rgroups;
}

sub randomizeNetwork {
my($link) = @_;
my($swaps, $nlinks, $Rlink, $Astart, $Aend, @Astarts, $Bstart, $Bend, @endsBstart, @Bstarts, $Ascore, $Bscore, $tt, @test, $time, %nodeCnt, $signature, %copied_edge);

$time = time();
#@test = @links1[0..1000];
undef %nodeCnt;
for $Astart(keys(%{$link})) {
for $Aend(keys(%{$link->{$Astart}})) {
$signature = join('-#-#-#-', sort {$a cmp $b} ($Astart, $Aend)); #protects against importing duplicated edges
next if defined($copied_edge{$signature});
$Rlink->{$Astart}->{$Aend} = $link->{$Astart}->{$Aend};
$copied_edge{$signature} = 1;
$nlinks++;
$nodeCnt{$Astart} = $nodeCnt{$Aend} = 1;
}}
print $nlinks.' edges, '.scalar(keys(%nodeCnt))." nodes before network randomization \n" if $main::debug;

@Astarts = keys(%{$Rlink});
while ($Astart = splice(@Astarts, rand($#Astarts + 1), 1)) {
@Bstarts = keys(%{$Rlink});
next if !$Astart;
for $Aend(keys(%{$Rlink->{$Astart}})) {
next if !$Aend or !defined($Rlink->{$Astart}->{$Aend});

while ($Bstart = splice(@Bstarts, rand($#Bstarts + 1), 1)) {
next if (!$Bstart or
($Bstart eq $Astart) or ($Bstart eq $Aend) or 
defined($Rlink->{$Bstart}->{$Aend}));

@endsBstart = keys(%{$Rlink->{$Bstart}});
while ($Bend = splice(@endsBstart, rand($#endsBstart + 1), 1)) {
next if (
!$Bend or 
($Astart eq $Bend) or
!defined($Rlink->{$Bstart}->{$Bend}) or
defined($Rlink->{$Astart}->{$Bend}));

$Ascore = $Rlink->{$Astart}->{$Aend};
$Bscore = $Rlink->{$Bstart}->{$Bend};
delete $Rlink->{$Astart}->{$Aend};
delete $Rlink->{$Bstart}->{$Bend};
$Rlink->{$Astart}->{$Bend} = $Ascore;
$Rlink->{$Bstart}->{$Aend} = $Bscore;
$swaps++;
last;
}
last;
}}}
# for $tt(@test) {
# print  join("\t", ($tt, scalar(keys(%{$link->{$tt}})), scalar(keys(%{$Rlink->{$tt}}))))."\n" if scalar(keys(%{$link->{$tt}})) != scalar(keys(%{$Rlink->{$tt}}));
# }
$nlinks = 0;
for $Astart(keys(%{$Rlink})) {
for $Aend(keys(%{$Rlink->{$Astart}})) {
$nlinks++;
$nodeCnt{$Astart} = $nodeCnt{$Aend} = 1;
}}
print $nlinks.' randomized edges, '.scalar(keys(%nodeCnt))." nodes after ".$swaps." edge swaps in ".(time() - $time)." s\n" if $main::debug;
$time = time();
return $Rlink;
}

sub readLinks {
my($tbl, $label) = @_;
my(@a, $hi, $prot1, $prot2, $Ntotal, $n, $ff, $la );
open IN, $tbl or die "Could not load $tbl ...\n";
print STDERR "Loading $tbl ...\n";
$_ = <IN>;
NET::readHeader($_, $tbl) if 1 == 1;# m/protein/i;
if ($label eq 'primary') {
$pl->{$tbl}->{protein1} = $pl->{$tbl}->{gene1};
$pl->{$tbl}->{protein2} = $pl->{$tbl}->{gene2};
}
for $ff(@{$WD::link_fields->{$label}}) {die "Table column for $ff undefined. \nCannot read $tbl ...\n" if !defined($pl->{$tbl}->{$ff});}
#open OOO, '> m8/_conn.funcoup';
while ($_ = <IN>) {
chomp;
print $Ntotal.' out of '.$n." links... \n" if ++$n%1000000 == 0;
#print "$i\n" if $i%10000 == 0;
@a = split("\t", $_);
$prot1= lc($a[$pl->{$tbl}->{protein1}]); $prot2= lc($a[$pl->{$tbl}->{protein2}]);
if ($label eq 'refnet') {
#next if $a[$pl->{$tbl}->{fbs}] < $FBScutoff; 
$prot1 = $WD::xref->{'en2sym_hsa'}->{'id2sym'}->{$prot1};
$prot2 = $WD::xref->{'en2sym_hsa'}->{'id2sym'}->{$prot2};
}
#($prot1, $prot2) = sort {$a cmp $b} ($prot1, $prot2);
next if !$prot1 or !$prot2;
$la = 0; $hi = 0;
for $ff(@{$WD::link_fields->{$label}}) {
next if !defined($a[$pl->{$tbl}->{$ff}]) or !$a[$pl->{$tbl}->{$ff}];
$hi++ if (defined($WD::minR) and (abs($a[$pl->{$tbl}->{$ff}]) > $WD::minR));
next if defined($WD::coff{$ff}) and (abs($a[$pl->{$tbl}->{$ff}]) < $WD::coff{$ff});
$link->{$label}->{$prot1}->{$prot2}->{$ff} =
$link->{$label}->{$prot2}->{$prot1}->{revert_labels($ff)} =
$a[$pl->{$tbl}->{$ff}] ? sprintf("%.2f", $a[$pl->{$tbl}->{$ff}]) : undef;
}

if (!$hi) {
delete $link->{$label}->{$prot1}->{$prot2};
delete $link->{$label}->{$prot2}->{$prot1};
}

next if !defined($link->{$label}->{$prot1}->{$prot2});
$node->{$label}->{$prot1}++; $node->{$label}->{$prot2}++;
last if  $Ntotal++ > $main::Ntestlines;
}
print $n." links total. \n" ;

close IN;
print scalar(keys(%{$node->{$label}})).' gene nodes, '.$Ntotal.' links, '." in\n$tbl...\n\n";
return undef;
}

sub revert_labels {
my($ff) = @_;

my @aa = split($WD::label_delimiter, $ff);
return(join($WD::label_delimiter, ($aa[1], $aa[0])));
}

sub readHeader ($$) {
    my($head, $tbl) = @_;
my(@arr, $aa, $smp, $subset);
chomp($head);
@arr = split("\t", $head);
for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/^LLR_//i;
$arr[$aa] = lc($arr[$aa]);
$pl->{$tbl}->{$arr[$aa]} = $aa;
$nm->{$tbl}->{$aa} = $arr[$aa];
#$WD::samples{$arr[$aa]} = 1 if $arr[$aa] !~ m/^gene|id|name|protein$/i;
#$pl->{$tbl}->{$1} = $aa;
#$nm->{$tbl}->{$aa} = $1;}
}
return undef;
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

sub bin ($$) {
my($value, $type) = @_;
my($q, $no_of_bins, $bin);

return undef if !defined($value);
return $main::value_index->{$type}->{$value} if $main::value_index->{$type}->{$value};
if (defined($main::borders->{$type})) {
if ($value =~ m/^[0-9-.e]+$/) {
return '0' if $value < $main::borders->{$type}->[0];
return scalar(@{$main::borders->{$type}}) if $value >= $main::borders->{$type}->[$#{$main::borders->{$type}}];
for $q(1..$#{$main::borders->{$type}}) {
if (($value >= $main::borders->{$type}->[$q - 1]) and ($value < $main::borders->{$type}->[$q])) {
$bin = $q;
}}}}
return $bin if defined($bin);
#print "No bin assigned to $value of $type...\n"; # if $value =~ m/^[0-9-.e]+$/;
return(undef);
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
return undef if $le < $WD::p_minval;
for ($i = 0; $i < $le; $i++) {
$S += ($xo->[$i]->{'ra'} - $yo->[$i]->{'ra'}) ** 2;
}
#my $table_value = 2.58; #formal z value for 1% conf. interval
#my $sigmaXz = $table_value * sqrt(1 / ($le - 3));
my $val = 1 - (6 / ($le * ($le ** 2 - 1))) * $S;
return($val) if testCorrelationSignificance($val, $le);
}

sub pearson ($$) {
my($x, $y) = @_;
my($r, $stds, $means, $p, $len, $le);
#the routine assumes equal sizes both $x and $y referenced arrays
#NB: missing values from them are deleted pairwise
#it does not recognize arrays of size 1 and process them

if (!$x || !$y) {return(undef);}
if (scalar(@{$x}) != scalar(@{$y})) {return(undef);}
$means = pwmean($x, $y);
if (!$means) {return(undef);}
$stds = pwstd($x, $y, $means);
$r = 0;
$len = scalar @{$x};
for ($p = 0; $p < $len; $p++) {
if ((defined($x->[$p]) and $x->[$p] =~ m/[0-9]/) and (defined($y->[$p]) and $y->[$p] =~ m/[0-9]/)) {
$r += ((($x->[$p] - $means->[0])/$stds->[0]) * (($y->[$p] - $means->[1])/$stds->[1]));
$le++;
}
}
#my $table_value = 2.58; #formal z value for 1% conf. interval
#my $sigmaXz = $table_value * sqrt(1 / ($le - 3));
my $val = $r / ($means->[2]-1);
return($val) if testCorrelationSignificance($val, $le);

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
return(undef) if $n < $WD::p_minval;
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

sub maxabs {
my(@ar) = @_;
my(@sar);
return $ar[0] if scalar(@ar) == 1;
@sar = sort {abs($b) <=> abs($a)} @ar;
return($sar[0]);
}

sub sign {
my($v) = @_;
return undef if !$v;
return(($v > 0) ? '+' : '-');
}

sub parseParameters ($) {
my($parameters) = @_;
my($_1, $_2, %sorts, $pms);

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
return $pms;
}

sub randomizeGeneList {
my(@items) = @_;
my(@Ritems);
srand();
my $length = $#items;
while ($#items > -1) {push @Ritems, splice(@items, rand($#items), 1);}
die "Permutation of the gene list failed...\n" if $length != $#Ritems;
return(@Ritems);
}

sub randomizeGeneList2ndLetter {
my(@items) = @_;
my(%list, $it);
for $it(sort {$a cmp $b} @items) {
	$list{$it} = substr($it, 2, 1).substr($it, 0, 1).substr($it, 1, 1);
	}
return(sort {$list{$a} cmp $list{$b}} @items);
}

sub read_group_list {
my(%pl, $genelist, $random, $delimiter, $min_size, $max_size, $ty, $skipHeader);
($genelist, $random, $pl{mut_gene_name}, $pl{group}, $delimiter, $ty, $skipHeader) = @_;

my($GR, @arr, $groupID, $thegene, $file, $N, $i, $ge);
# sed '{s/\r/\r\n/g}'
#$pl{mut_gene_name} = 1;  $pl{group} = 2;
# local($/) = "\r" if $useCR; 
#open(GS, "<:crlf", "my.txt");
#open( GS, "<:crlf", $genelist) or die "Cannot open file $genelist\n";
open GS,  $genelist or die "Cannot open file $genelist\n";
#http://perldoc.perl.org/perlport.html#Newlines
#$_ = <GS>; 
$N = 0;
$_ = <GS> if $skipHeader;
while (<GS>) {
chomp; @arr = split($delimiter, $_); $N++;
$thegene = lc($arr[$pl{mut_gene_name}]);
# print "BEFORE: ".$thegene."\n";
die "ID $thegene submitted at line $N in $genelist contains an empty space..." if $thegene =~ m/[A-Z0-9_\.]\s[A-Z0-9_\.]/i;
$thegene =~ s/\s//g; #$thegene =~ s/\n//g; $thegene =~ s/\r//g;
# print "AFTER: ".$thegene."\n";
$file->{GS}->[$N] = (($pl{group} > -1) and $arr[$pl{group}]) ? lc($arr[$pl{group}]): $HSconfig::users_single_group.$ty;
# print "GROUP: ".$file->{GS}->[$N]."\n";

$file->{GS}->[$N] =~ s/\s//g;
$file->{gene}->[$N] = $thegene;
$file->{gene}->[$N] =~ s/\s//g;
$main::Genes -> {$thegene} = 1;
}
close GS;

for ($i = 1; $i <= $N; $i++) {
$ge = $file->{gene}->[$i];
$groupID = $file->{GS}->[$i];
$GR->{$groupID}->{$ge} = 1;
$main::GS->{$ge}->{$groupID} = 1;
}
for $groupID(keys(%{$GR})) {
delete($GR->{$groupID}) if (defined($min_size) and (scalar(keys(%{$GR->{$groupID}})) <= $min_size));
delete($GR->{$groupID}) if (defined($max_size) and (scalar(keys(%{$GR->{$groupID}})) >= $max_size));
}

if ($random) {
	my($permge, $permGR);
for $groupID(keys(%{$GR})) {
for $ge(keys(%{$GR->{$groupID}})) {
while (scalar(keys(%{$permGR->{$groupID}})) < scalar(keys(%{$GR->{$groupID}}))) {
$permge = $file->{gene}->[rand($#{$file->{gene}})];
$permGR->{$groupID}->{$permge} = 1;
}}
$GR->{$groupID} = $permGR->{$groupID};
}}
close IN;
print STDERR scalar(keys(%{$GR})).' group IDs in '.$genelist."...\n\n" if $main::debug;
return $GR;
}
