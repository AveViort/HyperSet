#! /usr/bin/perl

$proj = 'chemores';

$output = 'ROC';
$zscoreCutoff = 1.64;
$ncoffs = 100;
$minNlinks = 2;
$oldClassification = 0;

@tabsAfter = ('');
for $fi(0..$#ARGV) {
#push @tabsBefore, '';}
open IN, $ARGV[$fi] or die "Cannot open data file: $ARGV[$fi]\n";
if (lc($proj) eq 'wir') {
$file = $ARGV[$fi];
  $file =~ s/PPI\./PPI\_/i;
  $file =~ s/FC\./FC\_/i;
  @F = split('\.', $file);
  $name=$F[3]; #dir/ind
  $kind = lc($F[1]); #real / null
}
if (lc($proj) eq 'chemores') {
$file = $ARGV[$fi];
  @F = split('\.', $file);
  $name=$F[2]; #dir/ind
  $name =~ s/Human/merged4/i;
  $name =~ s/merged_all/union/i;
  $kind = lc($F[1]); #real / null
}

while ($_ = <IN>) {
if ($_ =~ m/Nlinks/) {next;}
chomp;
@ar = split("\t", $_);
undef $type;
if ($oldClassification) {
if ($ar[1] =~ m/ancer/i or $ar[1] =~ m/200/) {$type = "CANC";}
elsif ($ar[1] =~ m/tcga\-/i) {$type = "TCGA";}
elsif (!$type and ($ar[1] =~ m/kegg/i or $ar[1] =~ m/alzheimercore/i))  {$type = "KEGG";}
else {$type = "KEGG";}
}
else {
if ($ar[1] =~ m/kegg/i)  {$type = "KEGG";}
else {$type = "REST";}
}
#else {die "Could not determine TYPE \n ...".$_."\n";}
$mode = $ar[0];
next if $ar[3] < $minNlinks;
$ty{$type}++;
$na{$name}++;
$mo{$mode}++;
$ki{$kind}++;
if (($ar[6] > $zscoreCutoff) and ($ar[3] >= $minNlinks)) {
	push @{$data->{$name}->{$type}->{$mode}->{$kind}}, $ar[6];
	$pair->{$name}->{$type}->{$mode}->{$ar[2]}->{$kind} = $ar[6];

}
#print join("\t", ($name, $ar[1], $mode, $ar[6], $kind, $B++))."\n" if ($ar[6] > $zscoreCutoff);
  }
close IN;
}
@header = ('Bin', 'Z-score', 'Specificity', '');

@tabsAfter = '' x (($#ARGV + 1) * 3);
    for $name(keys(%na)) {
    for $type(keys(%ty)) {
    for $mode(keys(%mo)) {
for $w(@{$data->{$name}->{$type}->{$mode}->{real}},
     @{$data->{$name}->{$type}->{$mode}->{null}})  {
$max = $w if ($w < 1000 and $w > $max);
$min = $w if ($w < 1000 and $w < $min);
        }

push @header, join("_", ($name, $type, $mode));

undef $P; $min = $max = 0; undef %bins; undef %p_extreme; undef %zscore;

$range = $max - $min;
$range = 0.001 if !$range;
push @tabsBefore, shift(@tabsAfter);
$p_extreme{null} = $p_extreme{real} = 0;
    for $kind(keys(%ki)) {
$B = 0;
for $w(@{$data->{$name}->{$type}->{$mode}->{$kind}}) {

if ($printExtreme and $w == 1000000) {$p_extreme{$kind}++;}
else {
$bi = 100 * sprintf("%.2f", ($w - $min) / $range);
$zscore{$bi} = $w;
$bins{$bi} = 1;
$P->{$kind}->{$bi}++;
#print join("\t", ($name, $type, $mode, $w, $kind, $bi, $B++))."\n";
}
}}
$printExtreme = 0;

$TP = $TN = 0;
if ($printExtreme) {
print(join("\t", ($p_extreme{null},  @tabsBefore, $p_extreme{real}, @tabsAfter))."\n");
  } else {

    for $bi(sort {$b <=> $a} keys(%bins)) {
$TP += $P->{real}->{$bi};
$TN += $P->{null}->{$bi};
print(join("\t", ($bi, $zscore{$bi}, $TN + 0.01,  @tabsBefore, $TP + 0.01, @tabsAfter))."\n");
}}

}}}
print(join("\t", @header)."\n");

