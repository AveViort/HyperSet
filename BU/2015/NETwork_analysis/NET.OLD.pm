package NET;
use strict vars;
use constant TAB => "\t";
use constant TRUE => "1";
use constant SUCCESS => "1";

our(%pl, $pl, $nm, $node, $link, @links1);
return TRUE;

sub PCITConditionalIndependence { #implementation of the PCIT rule (#Ref.)
my($Rxy, $Rxz, $Ryz) = @_;
my($ThePC, $epsilon, $result);
$ThePC = partialCorrelation($Rxy, $Rxz, $Ryz);
$epsilon = (	$ThePC / $Rxy +
		partialCorrelation($Rxz, $Rxy, $Ryz) / $Rxz +
		partialCorrelation($Ryz, $Rxy, $Rxz) / $Ryz ) / 3;
$result = ((abs($ThePC) < abs($epsilon * $Rxz)) and (abs($ThePC) < abs($epsilon * $Ryz))) ? '0' : $Rxy;
#print OUT2 join("\t", (@_, sprintf("%.3f", $pc), sprintf("%.3f", partialCorrelation($Rxz, $Rxy, $Ryz)), sprintf("%.3f", partialCorrelation($Ryz, $Rxy, $Rxz)), sprintf("%.2f", $epsilon), sprintf("%.3f", $result)))."\n";
return($result);
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
my(@a, $prot1, $prot2, $Ntotal, $ff);
open IN, $tbl or die "Could not load $tbl ...\n";
print "Loading $tbl ...\n";
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
@a = split("\t", $_);
$prot1= lc($a[$pl->{$tbl}->{protein1}]); $prot2= lc($a[$pl->{$tbl}->{protein2}]);
if ($label eq 'refnet') {
#next if $a[$pl->{$tbl}->{fbs}] < $FBScutoff;
$prot1 = $WD::xref->{'en2sym_hsa'}->{'id2sym'}->{$prot1};
$prot2 = $WD::xref->{'en2sym_hsa'}->{'id2sym'}->{$prot2};
}
#($prot1, $prot2) = sort {$a cmp $b} ($prot1, $prot2);
next if !$prot1 or !$prot2;

for $ff(@{$WD::link_fields->{$label}}) {
#next if !defined($a[$pl->{$tbl}->{$ff}]);
next if defined($WD::coff{$ff}) and (abs($a[$pl->{$tbl}->{$ff}]) < $WD::coff{$ff});
$link->{$label}->{$prot1}->{$prot2}->{$ff} =
$link->{$label}->{$prot2}->{$prot1}->{revert_labels($ff)} =
sprintf("%.3f", $a[$pl->{$tbl}->{$ff}]);
}
next if !defined($link->{$label}->{$prot1}->{$prot2});
$node->{$label}->{$prot1}++; $node->{$label}->{$prot2}++;
last if  $Ntotal++ > $main::Ntestlines;
}
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
$WD::samples{$arr[$aa]} = 1 if $arr[$aa] !~ m/^gene|id|name|protein$/i;
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

