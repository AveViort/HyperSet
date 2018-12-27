#!/usr/bin/perl

@cols = ('FBS_MAX');
@coffs = (3, 5.9, 7, 8, 9.5, 10.5);
@cols = ('sce_ppi_intact_sce.scored');
@cols = ('hsa_ppi_intact_hsa.scored');
@coffs = (0.1, 0.3, 0.7, 0.9);
$_ = <STDIN>;
# print '0:PFC'."\t".$_."\n";
readHeader($_);


while (<STDIN>) {
chomp $_;
#last if $N++ > 1000;
@ar = split("\t", $_);
#print ."\t".$_."\n";
#print fbs2pfc($ar[$pl{fbs}])."\t".$ar[$pl{fbs}]."\n";
for $cc(@cols) {
for $ff(@coffs) {
if ($ar[$pl{lc($cc)}] > $ff) {
$cnt->{$ar[$pl{'protein1'}]}->{$cc}->{$ff}++;
$cnt->{$ar[$pl{'protein2'}]}->{$cc}->{$ff}++;
}

}
} 
}
@line = ('PROTEIN',  @coffs);
print join("\t", @line)."\n";

#for $cc(@cols) {
for $pp(sort {$a cmp $b} keys(%{$cnt})) {
@line = ($pp);
for $ff(@coffs) {
push @line, $cnt->{$pp}->{$cols[0]}->{$ff};
}
print join("\t", @line)."\n";
}



sub readHeader {
    my($head) = @_;
    my(@arr, $aa);
chomp;
@arr = split("\t", $head);

for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$pl{lc($arr[$aa])} = $aa;
$arr[$aa] =~  s/^LLR_//i;
$LLRpl{$arr[$aa]} = $aa;
$LLRnm{$aa} = $arr[$aa];
}
return undef;
}
