#!/usr/bin/perl

use FunCoup_software::Stat;
my $genome = 'dre';
parseParameters(join(' ', @ARGV));
defineData($pms->{spec});
readWholeSet($wholeSet);
readGOannotations($GOfile{$pms->{spec}});
readList($pms->{list});
calculateChi();

sub defineData {
my($spec) = @_;

$Niter = 100;
$chiTab{0.05} = 3.84;
$chiTab{0.01} = 6.64;
$chiTab{0.001} = 10.83;
$minObsCount = 4;
$GOfile{'zfish'} = '/afs/pdc.kth.se/home/a/andale/zfish/GO_ZfinID_ENSG_GeneID_Zfinsym.NEW.txt';
#$GOfile{'zfish'} = '/afs/pdc.kth.se/home/a/andale/zfish/Zfish.HeartExpressed.ZDB.lst';
$wholeSet = 'zfish/zfish.VersionX_with_MAdata.lst';
#$wholeSet = 'zfish/zfish.VersionX_with_MAdata.FBS6.lst';
#$wholeSet = 'zfish/zfish.VersionX_with_MAdata.FBS8.lst';
$pl{'GO ID'} = 0;
$pl{'GO description'} = 1;
$pl{'GO evidence code'} = 2;
$pl{'gene ID'} = 3;
$pl{'gene name'} = 4;

$listpl{'cluster ID'} = 0;
$listpl{'gene ID'} = 1;
}

sub RSamplingNotChiSquare {
my($cnt, $ChiSquare, $col, $row, $marginal, $total, $expected, $returnUndef, $ChiSquareLimit);
(
$selSample, 	#$list->{'GO'}->{$cl}->{$go}->{'count'}, 

$cl,

) = @_;
$ChiSquareLimit = 0.5;

if ($cnt->{left}->{upper} < 0 or $cnt->{right}->{upper} < 0 or $cnt->{left}->{bottom} < 0 or $cnt->{right}->{bottom} < 0) {
print "A negative value submitted to the RSamplingNotChiSquare function)\n";
return undef;
}
#$returnUndef = 1 if !$marginal->{$col} or !$marginal->{$row};
$Nf = scalar(keys(%{$list->{'clusters'}->{$cl}}));
@F = sort {$a cmp $b} keys(%{$list->{'clusters'}->{$cl}});
my @gol = sort {$a cmp $b} keys(%{$GO->{'genes'}});
for (1..$Niter) {
$rGOf++ if defined($GO->{'GO'}->{$gol[rand($Nf)]}->{$cl});
}
$P_GOf = $rGOf / $Niter;

return;
}

sub calculateChi {

print join("\t", (
'Selection-ID', '#AnnotGenesInSelection', 'GO-ID', '#total', '#selected', 'Nrejected', 'Nnull', 'p-value', 'pFDR', 'Description', 'Genes'))."\n"; 

for $cl(keys(%{$list->{'clusters'}})) {
undef %nRejected;
for $go(keys(%{$list->{'GO'}->{$cl}})) {
next if $list->{'GO'}->{$cl}->{$go}->{'count'} < $minObsCount;
if ($list->{'GO'}->{$cl}->{$go}->{'count'} / scalar(keys(%{$list->{'clusters'}->{$cl}})) < $GO->{'GO'}->{$go}->{'count'} / scalar(keys(%{$GO->{'genes'}}))) {
$chi = 0;
}
else {
     $chi = chiSquare2(
$list->{'GO'}->{$cl}->{$go}->{'count'},
scalar(keys(%{$list->{'clusters'}->{$cl}})),
$GO->{'GO'}->{$go}->{'count'}, 
scalar(keys(%{$GO->{'genes'}})), 
0);
}
for $p0(0.05, 0.01, 0.001) {
$nRejected{$p0}++ if $chi > $chiTab{$p0}; 
}}

for $go(keys(%{$list->{'GO'}->{$cl}})) {
next if $list->{'GO'}->{$cl}->{$go}->{'count'} < $minObsCount;
next if $list->{'GO'}->{$cl}->{$go}->{'count'} / scalar(keys(%{$list->{'clusters'}->{$cl}})) < $GO->{'GO'}->{$go}->{'count'} / scalar(keys(%{$GO->{'genes'}}));
RSamplingNotChiSquare(
$list->{'GO'}->{$cl}->{$go}->{'count'},
scalar(keys(%{$list->{'clusters'}->{$cl}})), 
$GO->{'GO'}->{$go}->{'count'}, 
scalar(keys(%{$GO->{'genes'}})), 
0);


     $chi = chiSquare2(
$list->{'GO'}->{$cl}->{$go}->{'count'}, 
scalar(keys(%{$list->{'clusters'}->{$cl}})), 
$GO->{'GO'}->{$go}->{'count'}, 
scalar(keys(%{$GO->{'genes'}})), 
0
);
next if $chi < $chiTab{0.05}; 

undef %pFDR; undef $FDRvalue; undef $pvalue; undef $nrej;
for $p0(0.05, 0.01, 0.001) {
#next if $nRejected{$p0} < $minObsCount;
$pFDR{$p0} = ($nNull * $p0 / $nRejected{$p0}) if ($chi > $chiTab{$p0}); 

if (!defined($FDRvalue) or ($pFDR{$p0} and $pFDR{$p0} < $FDRvalue)) {
$FDRvalue = $pFDR{$p0}; 
$pvalue = $p0;
$nrej = $nRejected{$p0};
}
}
###next if ($FDRvalue > 0.5); 
print join("\t", (
$cl, 
scalar(keys(%{$list->{'clusters'}->{$cl}})), 
$go, 
#sprintf("%.3f", $chi),
#$pFDR{0.05}, $nRejected{0.05}, $pFDR{0.01}, $nRejected{0.01}, $pFDR{0.001}, $nRejected{0.001},
$GO->{'GO'}->{$go}->{'count'}, 
$list->{'GO'}->{$cl}->{$go}->{'count'}, 
#scalar(keys(%{$GO->{'genes'}})), 
$nrej, 
$nNull, 
$pvalue, 
sprintf("%.3f", $FDRvalue), 
$GO->{'GO'}->{$go}->{'GO description'}, 
join('|', @{$list->{'GO gene names'}->{$cl}->{$go}})
))."\n";
}}
}

sub readGOannotations {
my($table) = @_;
open GO, $table or die "Cannot open GO\n";
$_ = <GO>;
while (<GO>) {
chomp; @arr = split("\t", $_);
#next if $arr[$pl{$scorecol}] < $scorecutoff;
next if !$set->{$arr[$pl{'gene ID'}]};
$GO->{'GO'}->{$arr[$pl{'GO ID'}]}->{'count'}++;
$GO->{'genes'}->{$arr[$pl{'gene ID'}]}->{'GO ID'}->{$arr[$pl{'GO ID'}]} = 1;
$GO->{'genes'}->{$arr[$pl{'gene ID'}]}->{'gene name'} = $arr[$pl{'gene name'}]; 
$GO->{'GO'}->{$arr[$pl{'GO ID'}]}->{'gene ID'}->{$arr[$pl{'GO ID'}]} = 1; 
$GO->{'GO'}->{$arr[$pl{'GO ID'}]}->{'GO description'} = $arr[$pl{'GO description'}]; 
$GO->{'GO'}->{$arr[$pl{'GO ID'}]}->{'GO evidence code'} = $arr[$pl{'GO evidence code'}]; 
$nCanBeTested{$arr[$pl{'GO ID'}]}++;
}
close GO;
for $go(keys(%nCanBeTested)) {
$nNull++ if ($nCanBeTested{$go} > 2);
}
return undef;
}

sub readList {
my($table) = @_;
open LIST, $table or die "Cannot open LIST\n";
while (<LIST>) {
chomp; @arr = split("\t", $_);
next if !defined($GO->{'genes'}->{$arr[$listpl{'gene ID'}]});
for $go(keys(%{$GO->{'genes'}->{$arr[$listpl{'gene ID'}]}->{'GO ID'}})) {
$list->{'GO'}->{$arr[$listpl{'cluster ID'}]}->{$go}->{'count'}++; 
push @{$list->{'GO genes'}->{$arr[$listpl{'cluster ID'}]}->{$go}}, $arr[$listpl{'gene ID'}];
push @{$list->{'GO gene names'}->{$arr[$listpl{'cluster ID'}]}->{$go}}, $GO->{'genes'}->{$arr[$listpl{'gene ID'}]}->{'gene name'};
} 
$list->{'genes'}->{$arr[$listpl{'gene ID'}]}->{$arr[$listpl{'cluster ID'}]} = 1; 
$list->{'clusters'}->{$arr[$listpl{'cluster ID'}]}->{$arr[$listpl{'gene ID'}]} = 1; 
}
close LIST;
return undef;
}

sub readWholeSet {
my($table) = @_;
open SET, $table or die "Cannot open SET\n";
while (<SET>) {
chomp; @arr = split("\t", $_);
$set->{$arr[0]} = 1;
}
close SET;
return undef;

}

sub readHeader {
    my($head) = @_;
chomp($head);
@arr = split("\t", $head);

for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$pl{lc($arr[$aa])} = $aa;
if ($arr[$aa] =~  m/^LLR_[a-z]{3}_/) {
$arr[$aa] =~  s/^LLR_//i;
$LLRpl{$arr[$aa]} = $aa;
$LLRnm{$aa} = $arr[$aa];
}
else {
  if ($arr[$aa] =~  m/colocali/i or $arr[$aa] =~  m/_ppi_/i or $arr[$aa] =~  m/pearso/i or $arr[$aa] =~  m/phylo/i) {
$SRCpl{$arr[$aa]} = $aa;
$SRCnm{$aa} = $arr[$aa];
}}}
return undef;
}

sub parseParameters ($) {
my($parameters) = @_;
my($_1, $_2);

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
$pms->{'spec'} = 'zfish' if !$pms->{'spec'};
return undef;
}

sub chiSquare2 ($$$$$) {
my($cnt, $ChiSquare, $col, $row, $marginal, $total, $expected, $returnUndef, $ChiSquareLimit);
(
$selSample, 	#$list->{'GO'}->{$cl}->{$go}->{'count'}, 
$totSample, #scalar(keys(%{$list->{'clusters'}->{$cl}})),
$selTotal, #$GO->{'GO'}->{$go}->{'count'}, 
$totTotal #scalar(keys(%{$GO->{'genes'}})),
) = @_;
$ChiSquareLimit = 0.5;

if ($cnt->{left}->{upper} < 0 or $cnt->{right}->{upper} < 0 or $cnt->{left}->{bottom} < 0 or $cnt->{right}->{bottom} < 0) {
print "A negative value submitted to the Chi-square function)\n";
return undef;
}
#$returnUndef = 1 if !$marginal->{$col} or !$marginal->{$row};
#$returnUndef = 1 if ($ChiSquareLimit and $expected < $ChiSquareLimit and !$replaceSmallCounts);
#if ($returnUndef) { print "Chi-square is returned undefined...\n" if ($main::debug >= 3 or $main::debug =~ m/chi/i); return undef;}
$expected1 = $totSample * $selTotal / $totTotal;
$ChiSquare += ($selSample - $expected1) ** 2 / $expected1;

$expected2 = $totSample * (1 - ($selTotal / $totTotal));
$ChiSquare += (($totSample - $selSample) - $expected2) ** 2 / $expected2;
#return undef if ($expected1 < $ChiSquareLimit) or ($expected2 < $ChiSquareLimit);

print join("\t", (
$selSample, 	#$list->{'GO'}->{$cl}->{$go}->{'count'}, 
$expected1,
$totSample, #scalar(keys(%{$list->{'clusters'}->{$cl}})),
$expected2, 
$selTotal, #$GO->{'GO'}->{$go}->{'count'}, 
$totTotal, #scalar(keys(%{$GO->{'genes'}})),
$ChiSquare))."\n" if 1 == 2;

return $ChiSquare;
}

sub chiSquare ($$$$$) {
my($cnt, $replaceSmallCounts, $ChiSquare, $col, $row, $marginal, $total, $expected, $returnUndef);
(
$cnt->{left}->{upper}, 		#upper left cell count
$cnt->{right}->{upper}, 
$cnt->{left}->{bottom}, 
$cnt->{right}->{bottom},  	#lower right
$replaceSmallCounts
) = @_;
$ChiSquareLimit = 0.5;

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
print join("\t", (
$cnt->{left}->{upper}, 		#upper left cell count
$cnt->{right}->{upper}, 
$cnt->{left}->{bottom}, 
$cnt->{right}->{bottom}, 
$ChiSquare))."\n" if 1 == 2;

return $ChiSquare;
}
