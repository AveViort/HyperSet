#!/usr/bin/perl -w

# my $q = new CGI; #new instance of the CGI object passed from the query page index.html
# use warnings;
use strict;
use CGI qw(-no_xhtml);
use DBI;
use Scalar::Util 'looks_like_number';
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi";
use HS_SQL;

# cd /home/proj/func/DATA/PathwayCommons

 # perl -e '{open IN, "_m"; while ($_ = <IN>) {chomp($_); @a = split("\t", $_); $pa = $a[0]."\t".$a[2]; push @{$int{$pa}}, $a[1]; for $j(4..$#a) {$pairs->{$pa}->{$j} .= $a[$j];}} for $pa(keys(%pairs)) {print join("\t", $pairs{$pa})."\n";}}'

#  gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; } {print $1, $2, $3}' /home/proj/func/NW/hsa/FC.2010.HUGO |  gawk '{print toupper($0)}' | Sort_pairs.pl | sort  -u | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_fc_lim"} {sign = $1 "###" $2;  edge[sign] = edge[sign] + $3;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign]; } }' > fc_lim_hsa.withheader
# gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2, $3}' /home/proj/func/NW/mmu/FC.2010.GENE | Sort_pairs.pl | sort  -u | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_fc_lim"} {sign = $1 "###" $2;  edge[sign] = edge[sign] + $3;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign]; } }' > fc_lim_mmu.withheader                  

# gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2, $3}' /home/proj/func/NW/rno/FClim_ref | Sort_pairs.pl | sort  -u | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_fc_lim"} {sign = $1 "###" $2;  edge[sign] = edge[sign] + $3;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign]; } }' > fc_lim_rno.withheader

# gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2, $3}' /var/www/html/research/andrej_alexeyenko/HyperSet/NW_web/ath/FC3_ref | Sort_pairs.pl | sort  -u | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_fc3"} {sign = $1 "###" $2;  edge[sign] = edge[sign] + $3;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign]; } }' > fc3_ath.withheader

# gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2, $3}' /home/proj/func/NW/ath/FC2.athaliana.ath_3.0 | Sort_pairs.pl | sort  -u | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_fc_lim"} {sign = $1 "###" $2;  edge[sign] = edge[sign] + $3;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign]; } }' > fc_lim_ath.withheader


# AARS2###ABAT    ABAT    catalysis-precedes      AARS2   KEGG            Aminoacyl-tRNA biosynthesis;Metabolic pathways  http://pathwaycommons.org/pc2/Catalysis_d23b661df082f2ea4893cba59456e028;http://pathwaycommons.org/pc2/BiochemicalReaction_6ec2abf3a80d4895a4cdf9e877e4e9bd;http://pathwaycommons.org/pc2/BiochemicalReaction_0737d51d51feca2730e7a8dce1fe4526;http://pathwaycommons.org/pc2/Catalysis_f0e4919cb94f762d034db71a6da5bd05

#cat /home/proj/func/DATA/PTMapper_kinome_Narushima2016/Narushima_et_al_SupTable.txt | sed '{s/\"//g}' | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; ki=4; su=1; } {gsub(" ", "", $0); gsub("\r", "", $0); split(toupper($ki), k, ";"); split(toupper($su), s, ";"); for (substrate in s) {for (kinase in k) {a[1] = k[kinase]; a[2] = s[substrate]; asort(a);  sign = a[1] "###" a[2];  edge[sign] = edge[sign] ";" k[kinase] "->" s[substrate] "(" $3 ")"; src[sign] = src[sign] ";" $6;}}} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign], src[sign]}}' |  gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_ptmapper"} {gsub("\t;", "\t", $0); print $1, $2, $3 "[" $4 "]" }' > ptmapper_hsa.withheader


 # cat /home/proj/func/DATA/InnateDB/all.mitab | grep -iv mouse | grep -i human| gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {id = ""; id2 = ""; for (i=5; i<=6; i++) {p1 = $(i); sub(/.*hgnc\:/, "", p1); sub(/\(.+/, "", p1); sub(/.+mgi\:/, "", p1); sub(/.+ensembl\:/, "", p1); if (i == 5) {id1 = p1} else {id2 = p1}} a[1] = id1; a[2] = id2; asort(a); sign = a[1] "###" a[2];  Int = $12; sub(/.+\(/, "", Int); edge[sign] = edge[sign] ";" Int; pm[sign] = pm[sign] ";" $9;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign],  pm[sign] } }' | gawk '{gsub("\t;", "\t", $0); gsub("pubmed:", "", $0);  gsub(")", "", $0);  print $0}' | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_innatedb"} {print $1, $2, $3 "[" $4 "]" }' > innatedb_hsa.withheader
 # cat /home/proj/func/DATA/InnateDB/all.mitab | grep -i mouse | grep -iv human| gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {id = ""; id2 = ""; for (i=5; i<=6; i++) {p1 = $(i); sub(/.*hgnc\:/, "", p1); sub(/\(.+/, "", p1); sub(/.+mgi\:/, "", p1); sub(/.+ensembl\:/, "", p1); if (i == 5) {id1 = p1} else {id2 = p1}} a[1] = id1; a[2] = id2; asort(a); sign = a[1] "###" a[2];  Int = $12; sub(/.+\(/, "", Int); edge[sign] = edge[sign] ";" Int; pm[sign] = pm[sign] ";" $9;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign],  pm[sign] } }' | gawk '{gsub("\t;", "\t", $0); gsub("pubmed:", "", $0);  gsub(")", "", $0);  print $0}' | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_innatedb"} {print $1, $2, $3 "[" $4 "]" }' > innatedb_mmu.withheader

# gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {id = ""; id2 = ""; for (i=5; i<=6; i++) {p1 = $(i); sub(/.+hgnc\:/, "", p1); sub(/\(.+/, "", p1); sub(/.+mgi\:/, "", p1); sub(/.+ensembl\:/, "", p1); if (i == 5) {id1 = p1} else {id2 = p1}} sign = id1 "###" id2; int = $12;  edge[sign] = edge[sign] ";" int; pm[sign] = pm[sign] ";" $9;} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign],  pm[sign] } }' /home/proj/func/DATA/InnateDB/all.mitab | m

# USING chemical WAS WRONG!!!  cat /home/proj/func/DATA/PathwayCommons/PWC8/PathwayCommons.8.All.EXTENDED_BINARY_SIF.hgnc.txt   | grep -iv -e eferenc -e chemical | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {if (1 == 1) {a[1] = $1; a[2] = $3; asort(a); sign = a[1] "###" a[2]; edge[sign] = edge[sign] ";" $1 "-" $2 "-" $3; src[sign] = src[sign] ";" $4; pm[sign] = pm[sign] ";" $5;} } END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign], src[sign],  pm[sign] } }' | gawk '{gsub("\t;", "\t", $0); print $0}' | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_pwc8"} {print $1, $2, $3 "(" $4 ")" "[" $5 "]" }'  > pwc8 

# cat /home/proj/func/DATA/PathwayCommons/PWC9/PathwayCommons9.All.hgnc.txt | grep -iv -e eferenc -e CHEBI | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {if (1 == 1) {a[1] = $1; a[2] = $3; asort(a); sign = a[1] "###" a[2]; edge[sign] = edge[sign] ";" $1 "-" $2 "-" $3; src[sign] = src[sign] ";" $4; pm[sign] = pm[sign] ";" $5;} } END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign], src[sign],  pm[sign] } }' | gawk '{gsub("\t;", "\t", $0); print $0}' | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_pwc9"} {print $1, $2, $3 "(" $4 ")" "[" $5 "]" }'  > pwc9_hsa.withheader

# cat /home/proj/func/DATA/PhosphoSite.org/Kinase_Substrate_Dataset |  gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; } {ev = ""; if ($4 == "mouse" && $4 == $9) { if ($3 == "") {kinase = $1; } else {kinase = $3;} if ($8 == "") {substrate = $5; } else {substrate = $8;} data = kinase "->" substrate "(" $10 ")"; a[1] = kinase; a[2] = substrate; asort(a); sign = a[1] "###" a[2]; if ($14 == "X") {ev  = ev ";" "in vivo";}  if ($15 == "X") {ev  = ev ";" "in vitro";} edge[sign] = edge[sign] ";" data;  evi[sign] = evi[sign] ";" ev  }} END {for (sign in edge) {pr = sign; sub("###", "\t", pr); print pr, edge[sign],  evi[sign] }}' | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; print "prot1", "prot2", "data_phosphosite"} {gsub(";;", ";", $0); gsub("\t;", "\t", $0);  print $1, $2, $3 "[" $4 "]" }' > phosphosite_mmu.withheader



 # gawk 'BEGIN {print "prot1\tprot2\tdata_kgml"}' > input_networks/kgml_hsa.withheader 
# FC.awk /var/www/html/research/andrej_alexeyenko/HyperSet/NW_web/hsa/kgml.ALL.HUGO  1 2 | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; data=1;} {print toupper($1 "\t" $2 "\t" data);}' | sort -u >> input_networks/kgml_hsa.withheader
# FC.awk /var/www/html/research/andrej_alexeyenko/HyperSet/NW_web/mmu/kgml.LNK.Genes 1 2 | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; data=1;} {print toupper($1 "\t" $2 "\t" data);}' | sort -u >> input_networks/kgml_mmu.withheader


# gawk 'BEGIN {print "prot1\tprot2\tdata_proteincomplex"}' > input_networks/proteincomplex_hsa.withheader 
# FC.awk /var/www/html/research/andrej_alexeyenko/HyperSet//NW_web/hsa/CORUM_and_KEGG_complexes.HUGO  1 2 | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"; data=1;} {if ($1 != $2) {print toupper($1 "\t" $2 "\t" data);}}' | sort -u >> input_networks/proteincomplex_hsa.withheader

# ./allocate_network.pl new hsa net_fc_hsa.withheader

#delete  from net_all_hsa where (data_fc_lim is null) and  (data_ptmapper is null) and   (data_innatedb is null)  and  (data_pwc8 is null) and data_kegg=1 and prot1 = prot2;
# delete from net_all_hsa where (data_fc_lim is null) and  (data_ptmapper is null) and   (data_innatedb is null)  and  (data_kegg is null) and  (data_pwc8 is null) and data_proteincomplex=1 and prot1 = prot2;

# cat /var/www/html/research/andrej_alexeyenko/HyperSet/db/input_networks/kegg_hsa.withheader | gawk '{if ($1 != $2) print}' > _m  
#mv _m /var/www/html/research/andrej_alexeyenko/HyperSet/db/input_networks/kegg_hsa.withheader

# create table stat_networks (network character varying(256), org character varying(32), nnodes integer,  nedges integer);

our $readHeader = 1;
our $sign_delimiter = '###';
our($nm, $pl, $columns);
my($org, $mode, $input, $spe, $nw);
our %datatypes = (
'sign' => 'varchar(256)',
'prot1' => 'varchar(64)', 
'prot2' => 'varchar(64)', 
'data_ptmapper' => 'text', 
'data_kinase_pwc8' => 'text', 
'data_innatedb' => 'text', 
'data_phosphosite' => 'text',
'data_pwc8' => 'text', 
'data_pwc9' => 'text', 
'data_i2d' => 'text', 
'data_biogrid' => 'text'
);
our %indices = (
'sign'  => 1, 
'prot1' => 1, 
'prot2' => 1 
);

if ($ARGV[0] =~ m/^new|add|all$/i) { 
$mode = lc($ARGV[0]);
} else {
if ($ARGV[0] eq 'stat' and $ARGV[1] =~ m/^ath|mmu|rno|hsa$/i) {
create_stat_networks('net_all_'.$ARGV[1], $ARGV[1]); exit;
} 
else {die "Mode not identified (1st parameter)...\n";}
}

if ($ARGV[1] =~ m/hsa|mmu|rno|ath/i) {
$org = lc($ARGV[1]);
} else {
die "Species not identified (2nd parameter)...\n";
}

if ($ARGV[2] and ($ARGV[2] =~ m/^[0-9A-Z\.\_\-]+$/i)) {
$input = $ARGV[2];
} else {
die "Input file not identified (3rd parameter).\nUse 1st parameter \'all\' in order to run the whole batch...\n" if ($mode ne 'all');
}

my ($header, $output);
our ($extraNets);
our $inputDir = "/var/www/html/research/HyperSet/db/input_networks/";
chdir $inputDir;
our $mainNet = 'net_all_'.$org;
if ($mode eq 'all') {
$input = 'fc_lim_'.$org.'.withheader';
$header = uploadToSQL(prepareTable('new', $org, $input, $mainNet, 1));
@{$extraNets->{hsa}} = (
'ptmapper_hsa.withheader', 
'innatedb_hsa.withheader',
'pwc9_hsa.withheader'
# 'phosphosite_hsa.withheader', 
);
@{$extraNets->{mmu}} = (
# 'fc_lim_mmu.withheader', 
'innatedb_mmu.withheader',
'phosphosite_mmu.withheader'
);
@{$extraNets->{rno}} = (
# 'fc_lim_rno.withheader', 
'phosphosite_rno.withheader'
);

@{$extraNets->{ath}} = (
# 'fc_lim_ath.withheader', 
);
for $spe(('hsa', 'mmu', 'rno', 'ath')) {
for $nw('biogrid', 'kegg',  'fc3', 'fc4', 'string105', 'genemania') {
# for $nw('biogrid', 'kegg',  'fc3', 'fc4', 'string105') {
push @{$extraNets->{$spe}}, $nw.'_'.$spe.'.withheader';
}}
for $spe(('hsa', 'mmu', 'rno')) {
for $nw('proteincomplex', 'i2d') {
# for $nw('proteincomplex') {
push @{$extraNets->{$spe}}, $nw.'_'.$spe.'.withheader';
}}


for $input(@{$extraNets->{$org}}) {
$output = $input; $output =~ s/\.withheader//; $output .= '.sql'; 
$header = uploadToSQL(prepareTable('add', $org, $input, $output, 1));
}
indexMain($header, $mainNet);
} else {
my $output = ($mode eq 'add') ? $input : $mainNet;
# my $output = $input; 
$output =~ s/\.withheader//; 
$output .= '.sql'; 
$header = uploadToSQL(prepareTable($mode, $org, $input, $output, 1));
# indexMain($header, $mainNet);
}
exit;

sub create_stat_networks {
my($mainNet, $org) = @_;
my $dbh = HS_SQL::dbh();
execStat("DELETE FROM stat_networks WHERE org = '$org';", $dbh);
for my $fld(@{listFields($mainNet, $dbh, 'onlynew')}) {
execStat("CREATE OR REPLACE TEMP VIEW  temp_list as select distinct(prot1) FROM $mainNet as c1 WHERE c1.$fld IS NOT NULL UNION SELECT distinct(prot2) AS prot1 FROM $mainNet AS c2 WHERE c2.$fld IS NOT NULL;", $dbh);
execStat("INSERT INTO  stat_networks (network, org) VALUES ('$fld', '$org');", $dbh);
execStat("UPDATE  stat_networks SET nnodes = (select count(*) FROM temp_list ) WHERE network = '$fld' AND org = '$org';", $dbh);
execStat("UPDATE  stat_networks SET nedges = (select count(*) FROM $mainNet WHERE $fld IS NOT NULL) WHERE network = '$fld' AND org = '$org';", $dbh);
}
execStat("ANALYZE stat_networks;", $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";

return undef;
}

sub indexMain {
my($header, $sqltable) = @_;
my($fl);
my $dbh = HS_SQL::dbh();
for $fl(@{$header}) {
if (defined($indices{$fl})) {
execStat("DROP  INDEX IF EXISTS $sqltable\_$fl ", $dbh); 
execStat("CREATE INDEX $sqltable\_$fl on $sqltable ($fl)", $dbh); 
execStat("DROP  INDEX IF EXISTS $sqltable\_$fl\_uc ", $dbh); 
execStat("CREATE INDEX $sqltable\_$fl\_uc on $sqltable (upper($fl))", $dbh);
}
}
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";
}

sub uploadToSQL {
my($mode, $org, $header, $table) = @_;
my(@fields, $meta, $stat, $fl);

my $sqltable = $table;
$sqltable =~ s/\.sql$//;
for $fl(@{$header}) {
push @fields, $fl . ' ' . (defined($datatypes{$fl}) ? $datatypes{$fl} : 'real');
}
print $sqltable."\n"; 
my $dbh = HS_SQL::dbh();
$dbh->do("DROP TABLE IF EXISTS $sqltable CASCADE");
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n"; 
#exit; 
execStat("CREATE TABLE $sqltable (".join(', ', @fields).")", $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";

my $conf_file = "HS_SQL.conf";
open(my $conf, $conf_file);
my $dsn  = <$conf>;
chomp $dsn;
my $user = <$conf>;
chomp $user;
my $ps   = <$conf>;
chomp $ps;
$meta = "PGPASSWORD=".$ps." psql -d ".$dsn." -U ".$user." -w -c \"\\copy $sqltable from \'"."$inputDir"."$table\'  delimiter as E\'\\t\' null as \'NULL\'\"";
print STDERR $meta."\n"; 
# print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n"; exit; 
print STDERR "Failed!..\n" if system($meta) < 0;
execStat("DROP  INDEX IF EXISTS $sqltable\_sign ", $dbh); 
execStat("CREATE INDEX $sqltable\_sign on $sqltable (sign)", $dbh); 
execStat("analyze $sqltable", $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";

if ($mode eq 'add') {
# execStat("ALTER TABLE $mainNet DROP COLUMN");
execStat("DROP TABLE IF EXISTS old_$mainNet", $dbh); 
my $newField = @{listFields($sqltable, $dbh, 'onlynew')}[0];

execStat("ALTER TABLE $mainNet DROP COLUMN $newField", $dbh) if grep(/$newField/, @{listFields($mainNet, $dbh, 'all')});
execStat("ALTER TABLE $mainNet RENAME TO old_$mainNet", $dbh);
execStat("CREATE TABLE $mainNet AS SELECT t2.sign as sign2, t1.".join(', t1.', @{listFields('old_'.$mainNet, $dbh, 'all')}).", t2.".join(', t2.', @{listFields($sqltable, $dbh, 'onlynew')})."  from old_$mainNet as t1 FULL OUTER JOIN $sqltable as t2 on t1.sign=t2.sign", $dbh); 
execStat("UPDATE $mainNet set sign=sign2 where sign is NULL", $dbh); 
execStat("ALTER TABLE $mainNet DROP COLUMN sign2", $dbh); 
execStat("UPDATE $mainNet SET prot1=upper(substring(sign from 1 for position('###' in sign)-1)) WHERE prot1 IS NULL", $dbh);
# print STDERR "-----------------2nd update\n";
execStat("UPDATE $mainNet SET prot2=upper(substring(sign from position('###' in sign)+3 for char_length(sign))) WHERE prot2 IS NULL", $dbh);

execStat("UPDATE $mainNet SET prot1=upper(prot1);", $dbh);
execStat("UPDATE $mainNet SET prot2=upper(prot2);", $dbh);

}  
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";
return($header);
}


sub execStat {
my($stat, $dbh) = @_;
print STDERR $stat."\n"; 
$dbh->do($stat) or die "Failed!..\n";
return undef;
}

sub listFields { 
my($mainNet, $dbh, $mode) = @_;
my $fields;
  my $vals = $dbh->selectall_arrayref(
      "SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = \'$mainNet\'",
      { Slice => {} }
  );
  foreach my $va ( @$vals ) {
  if (($mode ne 'onlynew') or (($va->{column_name} ne 'sign') and ($va->{column_name} ne 'prot1') and ($va->{column_name} ne 'prot2'))) {
push @{$fields}, $va->{column_name};
  }}
return $fields;
}

sub prepareTable {
my($mode, $org, $input, $output, $rewrite) = @_;
my($line, $i, @arr, $header);

open IN, $input or die "Cannot find $input ... \n";
print join(" ", ($mode, $org, $input, '=>', $output))."\n";
my $hd = <IN>;
readHeader($hd, $input) if $readHeader;
@{$header} = ('sign');
for $i(sort {$a <=> $b} keys(%{$nm->{$input}})) {
push @{$header}, $nm->{$input}->{$i};
}

if ($rewrite) {
open OUT, '> '.$output  or die "Cannot create $output ... \n";;
while ($line = <IN>) {
# last if $i++ >= 1000;
@arr = split("\t", $line);
print OUT pair_sign($arr[$pl->{$input}->{"prot1"}], $arr[$pl->{$input}->{"prot2"}])."\t".$line;
}
close OUT;
}
close IN;
return($mode, $org, $header, $output);
}

sub pair_sign {
my($p1, $p2) = @_;
return lc(join($sign_delimiter, sort {$a cmp $b} ($p1, $p2)));
}

sub readHeader ($$) {
my($head, $tbl) = @_;
my(@arr, $aa, $smp, $subset, @ind, $cp, $isRheader);
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

 