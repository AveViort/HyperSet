#!/usr/bin/perl

@cols = ('FBS_MAX');
@coffs = (3, 5.9, 7, 8, 9.5);

@bases = (2, 2.71, 10);
@bases = (2);
@cols = (4..8);
for $base(@bases) {
for $i(1..12) {
$borders->{$base}->[$i] = sprintf("%.3f", ($base**$i))."\t";
}
}
$_ = <STDIN>;
readHeader($_);


while (<STDIN>) {
chomp $_;
#last if $N++ > 1000;
@ar = split("\t", $_);
for $col(@cols) {
for $base(@bases) {
next if !$ar[$col];
$counts->{$base}->{$col}->{bin($ar[$col], $base)}++;
$N{$col}++;
}}}

@line = ('POWER');
for $base(@bases) {
for $col(@cols) {
push @line, $name{$col}.'; base_'.$base;

}}
print join("\t", @line)."\n";
#for ($i = 1; $i < 13; $i += 0.5) {
for $i(1..12) {
@line = ($i);
for $base(@bases) {
for $col(@cols) {
push @line, $counts->{$base}->{$col}->{$i};
}}
print join("\t", @line)."\n";
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

sub readHeader {
    my($head) = @_;
    my(@arr, $aa);
chomp;
@arr = split("\t", $head);

for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$name{$aa} = $arr[$aa];
$pl{lc($arr[$aa])} = $aa;
}
return undef;
}
