#!/usr/bin/perl
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi";
use HS_SQL;

$SEP = "\t";
$mode = "purePubMed";
$mode = "PubMedAndPathways";
$aim = 'prepareSQL';
$aim = 'onlyImportToSQL';
$aim = 'splitSources';
prepareSQL() if $aim eq 'prepareSQL';
readWideTable('/home/proj/func/DATA/PathwayCommons/PathwayCommons.7.PubMedOrPathway.SQL', 'pathwaycommons') if ($aim eq 'onlyImportToSQL'); 
splitSources('All.EXTENDED_BINARY_SIF.PubMedOrPathway.seplines') if $aim eq 'splitSources';

# SEE ALSO FURTHER PROCESSING OF THE sql TABLE AS A SINGLE LINE PERL STATEMENT IN /var/www/html/research/andrej_alexeyenko/HyperSet/db/allocate_network.pl

# cat PathwayCommons.7.All.EXTENDED_BINARY_SIF.hgnc.sif | grep -v -e PARTICIPANT_TYPE -e Reference | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {split($4, a, ";"); pubmed = $5 ? $5 : ($6 ? $6 : "0"); for  (i in a) {src = a[i]; print $1 "###as###" $2 "###to###"  $3, src, pubmed}}' > All.EXTENDED_BINARY_SIF.PubMedOrPathway.seplines
# cat All.EXTENDED_BINARY_SIF.seplines | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1}' | sort -u > All.EXTENDED_BINARY_SIF.unique
# cat PathwayCommons.7.All.EXTENDED_BINARY_SIF.hgnc.sif |  grep -e PARTICIPANT_TYPE -e Reference > All.EXTENDED_BINARY_SIF.References

# FC.awk All.EXTENDED_BINARY_SIF.PubMedOrPathway.seplines 2 | Select_count.awk | sort -k2nr | grep -v -e INTERACTION_DATA_SOURCE -e No |gawk '($1)' > _distinct_sources ;

sub splitSources {
my($table) = @_;
open(LST, ' cat _distinct_sources | ');
while ($li = <LST>) {
chomp;
@ar = split(/\s+/, $li);
$src = $ar[0];
$src =~ s/\s+/_/;
$file = $src.'.pwc7';
push @head, $src;
@head = ("PARTICIPANT_A", "INTERACTION_TYPE", "PARTICIPANT_B", "EVIDENCE");
@a2 = split(/\s+/, $src);
$src =~ s/\s+/_/;
print $src."\n";
print $file."\n";
# system('cat '.$table.' | gawk \'BEGIN {FS="\t"; OFS = "\t"} {if ($4 == "'.$a2[0].'") print $1, $2, $3, $5}\'  > '.$file.'.all');
# @pair = ($1, $2, $3) if $ar[0] =~ m/^(.+)###as###(.+)###to###(.+)$/;
system('cat '.$table.' | gawk \'BEGIN {FS="\t"; OFS = "\t"} {if ($2 ~ "'.$a2[0].'") {split($1, a, "###as###");  split(a[2], b, "###to###"); print a[1], b[1], b[2], $3}}\'  > '.$file.'.all');

print $file."\n";

system('add_a_column.pl -st /home/proj/func/DATA/PathwayCommons/All.EXTENDED_BINARY_SIF.References  -se 1 -sn 2 -tt '.$file.'.all -te 1 -tn 5 -al 1 -ic 1 | grep -wvi SmallMoleculeReference  > _m');
print "_m...\n";

system('add_a_column.pl -st /home/proj/func/DATA/PathwayCommons/All.EXTENDED_BINARY_SIF.References  -se 1 -sn 2 -tt _m -te 2 -tn 6 -al 1 -ic 1 | grep -wvi SmallMoleculeReference | gawk \'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2, $3, $4}\' | sort -u > '.$file.'.genes');
if ($src eq "TRANSFAC") {
system('cat PathwayCommons.7.All.EXTENDED_BINARY_SIF.hgnc.sif | grep -w TRANSFAC| gawk \'BEGIN {la = ""; FS="\t"; OFS = "\t"} {if ($5) print $1, $2, $3, $5}\' > TRANSFAC_PubMed.genes');
}
print "Done.\n";

}
close(LST);
}


sub prepareSQL {
# my($table, $SQLtableName) = @_;
open(LST, ' cat _distinct_sources | ');
$i = 1;
@head = ("PARTICIPANT_A", "INTERACTION_TYPE", "PARTICIPANT_B", "PAIR_SIGNATURE");
while ($li = <LST>) {
chomp;
@ar = split(/\s+/, $li);
$i++;
$src = lc($ar[0]);
$src =~ s/\s+/_/;
push @head, $src;

system('cat All.EXTENDED_BINARY_SIF.PubMedOrPathway.seplines | grep -w '.$ar[0].' > _m0 ');
open(WC, ' wc _m0 | ');
$wc = <WC>;
@ww = split(/\s+/, $wc);
print "No. ".$i."\n";
print $li."\n";
print $wc."\n".$ww[1]."\n";
close(WC);
system('add_a_column.pl -tt '.(($i > 2) ? '_m'.$i : 'All.EXTENDED_BINARY_SIF.unique').'  -te 1 -tn '.$i.' -st _m0 -se 1 -sn 3 -ic 0 -al 1  > _m'.($i + 1));
}
close(LST);
open(IN, '_m'.($i + 1));
open(OUT, ' > _m');
print OUT join("\t", @head)."\tSUMMARY\n";
while (<IN>) {
chomp;
@ar = split("\t", $_);
@pair = ($1, $2, $3) if $ar[0] =~ m/^(.+)###as###(.+)###to###(.+)$/;
undef %ids;
for $j(@ar[4..($#ar - 0)]) {
if ($j) {
@pm = split(';', $j);
for $k(@pm) {
if ($k !~ m/unassigned/i) {
 if (($k =~ m/^[0-9]+$/  and ($mode eq "purePubMed")) or ($mode eq "PubMedAndPathways")) {
$ids{$k} = 1;
}
else {
die "Wrong PubMed ID ".$k." in ".$j."...\n";
}
}
}
}
}
print OUT join("\t", (@pair, $_, scalar(keys(%ids))))."\n";
}
close(IN);
close(OUT);
system('FC.awk _m 1-3 23 5-21 > PathwayCommons.7.PubMedOrPathway.SQL');

system('FC.awk PathwayCommons.7.PubMedOrPathway.SQL 1 3  | gawk \'{print tolower($0)}\' | Sort_pairs.pl | sort -u > /home/proj/func/NW/hsa/PathwayCommons7');
system('add_a_column.pl -st /home/proj/func/DATA/PathwayCommons/All.EXTENDED_BINARY_SIF.References  -se 1 -sn 2 -tt PathwayCommons7 -te 1 -tn 3 -al 1 -ic 1 | grep -wvi SmallMoleculeReference | gawk \'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2}\' > _m');
system('add_a_column.pl -st /home/proj/func/DATA/PathwayCommons/All.EXTENDED_BINARY_SIF.References  -se 1 -sn 2 -tt _m -te 2 -tn 3 -al 1 -ic 1 | grep -wvi SmallMoleculeReference | gawk \'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2}\' > _m1');
system('FC.awk _m1 1 2 | Sort_pairs.pl  | sort -u > _m2');
system('mv _m2 /home/proj/func/NW/hsa/PathwayCommons7');
}


sub readWideTable {
my($table, $SQLtableName) = @_;
# SEE ALSO FURTHER PROCESSING OF THE sql TABLE AS A SINGLE LINE PERL STATEMENT IN /var/www/html/research/andrej_alexeyenko/HyperSet/db/allocate_network.pl
our($pl, $nm, @arr);
open  IN, $table or die "Could not open the input wide table $table ...\n"; 
my $head = <IN>;
readHeader($head, $table);
close(IN);
my($aa, $line, @ar, $VA, $COL, @flds, $SQL);
my(%datatype, $i);
for $COL(@arr) {
$datatype{$COL} = uc($COL) eq "SUMMARY" ? 'int' : ($COL =~ m/participant_/i ? 'varchar(1024)' : 'text');   
}
for $COL(@arr) {
push @flds, $COL.' '.$datatype{$COL} if $COL;
} 
$SQL .= join(', ', @flds).');';

$SQL = 'CREATE TABLE '.$SQLtableName.' (';
$SQL .= join(', ', @flds).');';
my $dbh = HS_SQL::connect2PG();
$dbh->do("DROP TABLE IF EXISTS ".$SQLtableName);
# $dbh->do(<<'SQL');
$SQL =~ s/participant_a/prot1/;
$SQL =~ s/participant_b/prot2/;

print $SQL."\n";
$dbh->do($SQL); 
$dbh->commit;
$dbh->disconnect;

}

sub readHeader ($$) {
my($head, $tbl) = @_;
my($aa, $smp, $subset, @ind, $cp, $isRheader);
chomp($head);
@arr = split("\t", $head);
if (!$isRheader) {@ind = 0..$#arr;} 
else {
@ind = 1..($#arr+1);
$pl->{$tbl}->{"rowname"} = 0;
$nm->{$tbl}->{0} = "rowname";
}
for $aa(@ind) {
$cp->{$tbl}->{$aa} = $arr[$aa];
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/\,/_/g;
$arr[$aa] =~  s/\./_/g;
$arr[$aa] =~  s/\s/_/g;
$arr[$aa] =~  s/\-/m/g;
$arr[$aa] =~  s/\//_/g;
$arr[$aa] =~  s/\#/_/g;
$arr[$aa] = lc($arr[$aa]);
$pl->{$tbl}->{$arr[$aa]} = $aa;
$nm->{$tbl}->{$aa} = $arr[$aa];
$cp->{$tbl}->{$arr[$aa]} = $cp->{$tbl}->{$aa};
}
return undef;
}
