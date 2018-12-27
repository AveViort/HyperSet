#!/usr/bin/perl -w

# my $q = new CGI; #new instance of the CGI object passed from the query page index.html
# use warnings;
use strict;
use CGI qw(-no_xhtml);
use DBI;
use Scalar::Util 'looks_like_number';
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi";
use HS_SQL;
#cat Best_features.Marcela.txt | sort -u > Best_features.ALL.txt & 

 # create table best_drug_corrs (dataset varchar(64), datatype varchar(64), platform varchar(64), screen varchar(64), drug varchar(64), feature varchar(1024), correlation real, pvalue float(48), fdr float(48), validn smallint);
# \copy best_drug_corrs from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/Best_features.ALL.txt' delimiter as E'\t' null as NA
# create index dataset_best on best_drug_corrs (dataset);
# create index platform_best on best_drug_corrs (platform);
# analyze best_drug_corrs;
# create index datatype_best on best_drug_corrs (datatype);
# create index screen_best on best_drug_corrs (screen);
# create index drug_best on best_drug_corrs (drug);
# create index feature_best on best_drug_corrs (feature);
# CREATE index total_best on best_drug_corrs (dataset, datatype, platform, screen);
# CREATE index validn_best on best_drug_corrs (validn);
# analyze best_drug_corrs;
#create table best_drug_corrs_counts ( dataset varchar(32), datatype varchar(32), platform varchar(1024), screen varchar(32), drug varchar(128), count smallint);
#insert into best_drug_corrs_counts SELECT  dataset, datatype, platform, screen, drug, count(*) from best_drug_corrs group by dataset, datatype, platform, screen, drug;
# create index dataset_counts on best_drug_corrs_counts (dataset);
# create index platform_counts on best_drug_corrs_counts (platform);
# create index datatype_counts on best_drug_corrs_counts (datatype);
# create index screen_counts on best_drug_corrs_counts (screen);
# create index drug_counts on best_drug_corrs_counts (drug);
# create index count_counts on best_drug_corrs_counts (drug);
# analyze best_drug_corrs_counts;
#############################################
# > df  /
# Filesystem                  1K-blocks      Used Available Use% Mounted on
# /dev/mapper/VGMain-lv_slash 542862056 358017476 157267712  70% /

our($nm, $pl, $columns);
#if (1 == 1) {.
my $i;
my $importAllDataTables = 0;
my $addTable = 1;
my $inputDir = "/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/";
#my $mask = "Temp_switch.2014.DE.SQL.v3.Limit.txt"; 
my $mask = "CTD.GNEA.*.txt";
#}
my $tableToAdd = '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/Kinase_Substrate.2015.human';

if ($importAllDataTables) {
chdir $inputDir;
open LS, "ls $mask | ";
while (my $file = <LS>) {
#print $file;
chomp $file;
next if $i++ < 9;
readLongTable($file, 0);
}
close LS;
}

sub readLongTable {
my($inputTable, $header) = @_;
my($i, $dbh, $stat, @indexOn, $sqltable, @nameSegments);
@nameSegments = split('\.', lc($inputTable));
pop(@nameSegments);
my $last = $#nameSegments;
$sqltable = $nameSegments[0].'_'.$nameSegments[1].'_'.join('', @nameSegments[2..$last]);
$sqltable = "temporal_switch";
print $sqltable."\n";
# return;
my $feature_length = ($sqltable =~ m/_nea_/) ? 1024 : 64;
$dbh = HS_SQL::connect2PG();
$dbh->do("DROP TABLE IF EXISTS $sqltable");
if ($inputTable eq "Temp_switch.2014.DE.SQL.v3.Limit.txt") {
@indexOn = ('condition1', 'condition2', 'gene');
$stat = "CREATE TABLE temporal_switch (condition1 varchar(512), condition2 varchar(512), gene varchar(64), fc real, p float(48), fdr float(48))";
} else {
@indexOn = ('feature','sample');
$stat = "CREATE TABLE $sqltable (feature varchar($feature_length), sample varchar(64), value float4)"; 
}
print STDERR $stat."\n";
$dbh->do($stat); 
$dbh->commit;
$dbh->disconnect;
system("PGPASSWORD=\"SuperSet\" psql -d hyperset -U hyperset -w -c \"\\copy $sqltable from \'"."$inputDir"."$inputTable\'  delimiter as E\'\\t\' null as NA\"");
$dbh = HS_SQL::connect2PG();
for my $field(@indexOn) {
my $index = join('_', ($field, $sqltable));
$stat = "CREATE INDEX $index ON $sqltable ($field);";
print STDERR $stat."\n";
$dbh->do($stat);
}
$stat = "CREATE INDEX pair_ts ON temporal_switch (condition1, condition2);";
print STDERR $stat."\n";
$dbh->do($stat);

$dbh->commit;
$stat = "ANALYZE $sqltable ;\n";
print STDERR $stat."\n";
$dbh->do($stat);

$dbh->disconnect;
print STDERR "disconnect\n";
#exit;
}


sub readWideTable {
my($table, $SQLtableName) = @_;

open  IN, $table or die "Could not open the input wide table $table ...\n"; 
my $head = <IN>;
readHeader($head, $table);
my($aa, $line, @ar, $VA, $COL, @flds, $SQL);
# if (!$isRheader) {@ind = 0..$#arr;} 
# else {@ind = 1..($#arr+1);}
my(%datatype, $i);
do {
$_ = <IN>;
$line = $_;
chomp;
@ar = split("\t", $_);
$i++;
for $aa(0..$#ar) {
$VA = $ar[$aa];
$COL = $nm->{$table}->{$aa};
push @{$columns->{$COL}}, $VA;
#if ($i < 100) {
$datatype{$COL} = looks_like_number($VA) ? $VA =~ /\D/ ? 'float4' : 'float4' : 'varchar(64)'
#}
}} while ($i < 100);
$SQL = 'CREATE TABLE '.$SQLtableName.' (';
for $COL(keys(%datatype)) {
push @flds, $COL.' '.$datatype{$COL} if $COL;
} 
$SQL .= join(', ', @flds).');';
my $dbh = connect2PG();
$dbh->do("DROP TABLE IF EXISTS ".$SQLtableName);
# $dbh->do(<<'SQL');
print $SQL;
$dbh->do($SQL); 
$dbh->commit;
$dbh->disconnect;

}

sub read_temporal_switch {
my($table, $header) = @_;
my($i);
# $dbh->do("DROP TABLE IF EXISTS temporal_switch");
# $dbh->do(<<'SQL');
my $dbh = connect2PG();
$dbh->do("CREATE OR REPLACE TABLE temporal_switch (gene varchar(64), fc float4, p float4, fdr float4)"); 
system('psql -d hyperset -U hyperset -c '."\copy temporal_switch from 'input_files/Temp_switch.2014.DE.SQL.txt' delimiter as E'\t'");
$dbh->commit;
$dbh->disconnect;

exit;# if ($i++ > 100);
my $sth = $dbh->prepare( q{
    INSERT INTO temporal_switch (gene, fc, p, fdr) VALUES (?, ?, ?, ?)
});
 
open FH, " < ".$ARGV[0] or die "Unable to open... $!";
$_ = <FH> if ($header);
while (<FH>) {
    chomp;
    my ($gene, $fc, $p, $fdr) = split /\t/;
    $sth->execute($gene, $fc, $p, $fdr);
}
close FH;
$dbh->commit;
$dbh->disconnect;
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

 \timing
 CREATE TABLE merged_hsa AS select * FROM net_fc_hsa;
 ALTER TABLE merged_hsa ADD COLUMN phosphosite boolean DEFAULT 'FALSE';
CREATE INDEX merged_hsa_prot1 ON merged_hsa (prot1);
CREATE INDEX merged_hsa_prot2 ON merged_hsa (prot2);

 CREATE TABLE temp_copy ( prot1 varchar(64), prot2 varchar(64));
 \copy temp_copy (prot1, prot2) FROM '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/Kinase_Substrate.2015.human.2col'
CREATE INDEX temp_prot1 ON temp_copy (prot1);
CREATE INDEX temp_prot2 ON temp_copy (prot2);
ALTER TABLE temp_copy ADD COLUMN overlap boolean DEFAULT 'FALSE';

 # UPDATE merged_hsa SET phosphosite='TRUE' FROM merged_hsa m, temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
# select count(*) from merged_hsa m, temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
UPDATE merged_hsa m SET phosphosite='TRUE' FROM temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
ALTER TABLE temp_copy ADD COLUMN overlap boolean;
UPDATE temp_copy m SET overlap='TRUE' FROM temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);


 
 
# > c ~/.psql_history
# > c ~/hyperset_db
# Database: hyperset
# Username: hyperset


# > psql -d hyperset -U hyperset
# http://www.postgresql.org/docs/8.4/static/libpq-pgpass.html

# >  cat  ~/.pgpass
# localhost:*:database:hyperset:SuperSet

# >  FC.awk /home/proj/func/NW/hsa/FC.2010.fc.joined 1 6 7 24 8-12 14-21 | grep -v FBS_max > /var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/net_fc_hsa.txt



 
# CREATE TABLE shownames1 (hsname varchar(64), description varchar(1024), org_id varchar(64));
# CREATE TABLE
# \copy shownames1 from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/shownames1.txt'

# CREATE TABLE optnames1 (hsname varchar(64), optname varchar(64), org_id varchar(64), source varchar(64));
# \copy optnames1 from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/optnames1.txt'



# DROP  TABLE net_fc_hsa; 
# CREATE TABLE net_fc_hsa (fbs float4, prot1 varchar(64), prot2 varchar(64), blast_score float4, hsa float4, mmu float4, rno float4, dme float4, cel float4, pearson float4, ppi float4, coloc float4, phylo float4, mirna float4, tf float4, hpa float4, domain float4);
# \copy net_fc_hsa from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/net_fc_hsa.txt' delimiter as E'\t' null as ''
# CREATE INDEX p1ind_hsa ON net_fc_hsa (prot1);
# CREATE INDEX
# CREATE INDEX p2ind_hsa ON net_fc_hsa (prot2);
# CREATE INDEX
# CREATE INDEX fbsind_hsa ON net_fc_hsa (fbs);


# CREATE TABLE net_fc_mmu (fbs float4, prot1 varchar(64), prot2 varchar(64), blast_score float4, hsa float4, mmu float4, rno float4, dme float4, cel float4, pearson float4, ppi float4, coloc float4, phylo float4, mirna float4, tf float4, hpa float4, domain float4);
# CREATE TABLE
# hyperset=> \copy net_fc_mmu from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/net_fc_mmu.txt' delimiter as E'\t' null as ''

# CREATE TABLE net_fc_rno (fbs float4, prot1 varchar(64), prot2 varchar(64), blast_score float4, hsa float4, mmu float4, rno float4, dme float4, cel float4, pearson float4, ppi float4, coloc float4, phylo float4, mirna float4, tf float4, hpa float4, domain float4);
 # \copy net_fc_rno from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/net_fc_rno.txt' delimiter as E'\t' null as ''

 
 
 
 