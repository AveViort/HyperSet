#!/usr/bin/perl

use FunCoup_software::Stat;
my $genome = 'dre';
parseParameters(join(' ', @ARGV));
$proj = 'hallmarks';
$proj = $pms->{'proj'} if $pms->{'proj'};
$mode = $pms->{'mode'} if $pms->{'mode'};
$mode = 'real' if !$mode;
$mode = lc($mode);
print STDERR "Current project is $proj...\n\n";
defineData();
readGOannotations($GOfile, $mode);
readList($list_file, $mode);
calculateZ();

sub defineData {
#$minObsCount = 3;
if ($proj == 'hallmarks') {
#$GO_dir = 'CHEMORES/NET/';
$GO_dir = 'CURRENT/GENELISTS/';
$GOfile = $pms->{'gofi'};
$GOfile = 'CAN_MET_SIG_GO'  if !$pms->{'gofi'};
$GOfile = $GO_dir.$GOfile;
$list_dir = 'CURRENT/GENELISTS/';
$list_file = $pms->{'list'} if $pms->{'list'};
$list_file = 'PEall.groups.txt'  if !$pms->{'list'};
$list_file = $list_dir.$list_file;
$pl{'GO ID'} = 2;
$pl{'gene ID'} = 1;

$listpl{'cluster ID'} = 2;
$listpl{'gene ID'} = 1;
}
}

sub calculateZ {

print join("\t", (
'GOID',
'SelectionID',
'Overlap',
'Z',
'GOsize', 
'Selectionsize'))."\n";

for $cl(keys(%{$list->{'clusters'}})) {
undef %nRejected;
for $go(keys(%{$list->{'GO'}->{$cl}})) {
next if $list->{'GO'}->{$cl}->{$go}->{'count'} < $minObsCount;
# $Z = zsc(
# $list->{'GO'}->{$cl}->{$go}->{'count'},
# (scalar(keys(%{$list->{'clusters'}->{$cl}})) - $list->{'GO'}->{$cl}->{$go}->{'count'}),
# $GO->{'GO'}->{$go}->{'count'},
# scalar(keys(%{$GO->{'genes'}})));
$Z = zsc(
$list->{'GO'}->{$cl}->{$go}->{'count'},
(scalar(keys(%{$list->{'clusters'}->{$cl}})) - $list->{'GO'}->{$cl}->{$go}->{'count'}),
($GO->{'GO'}->{$go}->{'count'} - $list->{'GO'}->{$cl}->{$go}->{'count'}),
(scalar(keys(%{$Genes})) - scalar(keys(%{$list->{'clusters'}->{$cl}})) - $GO->{'GO'}->{$go}->{'count'} + $list->{'GO'}->{$cl}->{$go}->{'count'}));

print join("\t", (
$go, $cl,
$list->{'GO'}->{$cl}->{$go}->{'count'},
sprintf("%.3f", $Z),
$GO->{'GO'}->{$go}->{'count'},
scalar(keys(%{$list->{'clusters'}->{$cl}}))
))."\n";
}}}

sub readGOannotations {
my($table, $mode) = @_;
open GO, $table or die "Cannot open GO\n";
$_ = <GO>; $N = 0;
while (<GO>) {
chomp; @arr = split("\t", $_); $N++;
$file->{GO}->[$N] = $arr[$pl{'GO ID'}];
$file->{gene}->[$N] = $arr[$pl{'gene ID'}];
$Genes->{$arr[$pl{'gene ID'}]} = 1;
}
close GO;
for ($i = 1; $i <= $N; $i++) {
if ($mode eq 'real') {$ge = $file->{gene}->[$i];#$go = $file->{GO}->[$i];
}
else {
$ge = splice(@{$file->{gene}}, rand($#{$file->{gene}}), 1);
#$go = splice(@{$file->{GO}}, rand($#{$file->{GO}}), 1);
}
$go = $file->{GO}->[$i];
#$ge = $file->{gene}->[$i];
$GO->{'genes'}->{$ge}->{'GO ID'}->{$go} = 1;
$GO->{'GO'}->{$go}->{'count'}++;
$nCanBeTested{$go}++;
}
print STDERR $table."\: \n";
print STDERR scalar(keys(%{$GO->{'genes'}}))." distinct genes.\n";
print STDERR scalar(keys(%{$GO->{'GO'}}))." distinct pathways/gene groups.\n";
return undef;
}

sub readList {
my($table, $mode) = @_;
open LIST, $table or die "Cannot open LIST as $table ...\n";
$N = 0;
while (<LIST>) {
chomp; @arr = split("\t", $_);
#next if !defined($GO->{'genes'}->{$arr[$listpl{'gene ID'}]});
$N++;
$file->{clus}->[$N] = $arr[$listpl{'cluster ID'}];
$file->{gene}->[$N] = $arr[$listpl{'gene ID'}];
$Genes->{$arr[$listpl{'gene ID'}]} = 1;
}
close LIST;

for ($i = 1; $i <= $N; $i++) {
if ($mode eq 'real') {
$ge = $file->{gene}->[$i];
}
else {
$ge = splice(@{$file->{gene}}, rand($#{$file->{gene}}), 1);
}

$cl = $file->{clus}->[$i];

$list->{'genes'}->{$ge}->{$cl} = 1;
$list->{'clusters'}->{$cl}->{$ge} = 1;

for $go(keys(%{$GO->{'genes'}->{$ge}->{'GO ID'}})) {
$list->{'GO'}->{$cl}->{$go}->{'count'}++;
}}
print STDERR $table."\: \n";
print STDERR scalar(keys(%{$list->{'clusters'}}))." distinct gene AGS/clusters.\n";
print STDERR scalar(keys(%{$list->{'genes'}}))." distinct genes.\n\n";
print STDERR scalar(keys(%{$Genes}))." genes in total.\n";

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

#print STDERR "$parameters\n";
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

sub zsc {
(
$A, 	#$list->{'GO'}->{$cl}->{$go}->{'count'},
$B, #scalar(keys(%{$list->{'clusters'}->{$cl}})),
$C, #$GO->{'GO'}->{$go}->{'count'},
$D #scalar(keys(%{$GO->{'genes'}})),
) = @_;
my $pseudoCnt = 0.5;
 $A = $A>0 ? $A : $pseudoCnt;
 $B = $B>0 ? $B : $pseudoCnt;
 $C = $C>0 ? $C : $pseudoCnt;
 $D = $D>0 ? $D : $pseudoCnt;
my $se = sqrt(1/$A + 1/$B + 1/$C + 1/$D);
my $oddsr = ($A*$D)/($B*$C);
return(sprintf("%.3f", (log($oddsr) / $se)));
}
