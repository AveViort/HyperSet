#!/usr/bin/perl -w

# my $q = new CGI; #new instance of the CGI object passed from the query page index.html
# use warnings;
use strict;
use CGI qw(-no_xhtml);
use DBI;
use Scalar::Util 'looks_like_number';
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi";
use HS_SQL;

# cd /var/www/html/research/andrej_alexeyenko/HyperSet/FG_web/

# sub(dir ".", "", lbl); sub("." dir, "", lbl);
# gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {if (FNR == 1) {file = FILENAME; split(file,  a, "/"); dir=a[1]; lbl = a[2];  }  if (file !~ "stats|gmt") {print $2, $3, lbl, dir}}' ???/*  | sort -u > fgs.sql

# allocate_gs.pl new fgs.sql


our $main = 'fgs_all';
#####################
create_stat_fgs($main);
 exit;
####################


our $readHeader = 1;
our $sign_delimiter = '###';
our($nm, $pl, $columns);
my($mode, $input);
our %datatypes = (
'prot' => 'varchar(1024)', 
'set' => 'varchar(1024)', 
'org_id' => 'varchar(64)', 
'source' => 'varchar(256)'
);
our %indices = (
'source'  => 1, 
'org_id'  => 1, 
'prot' => 1, 
'set' => 1 
);


if ($ARGV[0] =~ m/^new|add$/i) { 
$mode = lc($ARGV[0]);
} else {
die "Mode not identified (1st parameter)...\n";
}


if ($ARGV[1] =~ m/^[0-9A-Z\.\_\-]+$/i) {
$input = $ARGV[1];
} else {
die "Input file not identified (3rd parameter).\nUse 1st parameter \'all\' in order to run the whole batch...\n" if ($mode ne 'all');
}

our $inputDir = "/var/www/html/research/andrej_alexeyenko/HyperSet/FG_web/";
chdir $inputDir;

my $output = $main; #($mode eq 'add') ? $input : $main;
# my $output = $input; 
# $output =~ s/\.withheader//; 
# $output .= '.sql'; 
our $dbh = HS_SQL::connect2PG();
# uploadToSQL(prepareTable($mode, $input, $output, 1), $mode);
uploadToSQL($input, $mode);
indexMain($main) if 1 == 1;
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";

exit;

sub create_stat_fgs {
my($mainFGS) = @_;
my $dbh = HS_SQL::connect2PG();
execStat("DROP TABLE IF EXISTS stat_fgs;", $dbh);
execStat("CREATE TABLE stat_fgs AS SELECT org_id, source, set, count(distinct prot) from $mainFGS group by org_id, source, set;
", $dbh);
execStat("CREATE INDEX stat_fgs_org_id ON stat_fgs (org_id);", $dbh);
execStat("CREATE INDEX stat_fgs_set ON stat_fgs (set);", $dbh);
execStat("CREATE INDEX stat_fgs_source ON stat_fgs (source);", $dbh);
execStat("ANALYZE stat_fgs;", $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";
return undef;
}

sub indexMain {
my($sqltable) = @_;
my($fl);
# my $dbh = HS_SQL::connect2PG();
for $fl(keys(%indices)) {
execStat("CREATE INDEX $sqltable\_$fl on $sqltable ($fl)", $dbh); 
execStat("CREATE INDEX $sqltable\_$fl\_uc on $sqltable (upper($fl))", $dbh);
}
execStat("analyze $sqltable", $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
}

sub uploadToSQL {
my($table, $mode) = @_;
my(@fields, $meta, $stat, $fl);

my $sqltable = 'fgs_all'; # $table;
# $sqltable =~ s/\.sql$//;
for $fl(('prot', 'set', 'source', 'org_id')) {
push @fields, $fl . ' ' .$datatypes{$fl};
}
print $sqltable."\n"; 
# my $dbh = HS_SQL::connect2PG();
if ($mode eq 'new') {
$dbh->do("DROP TABLE IF EXISTS $sqltable CASCADE");
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n"; 
my $sm = "CREATE TABLE $sqltable (".join(', ', @fields).")";
print $sm."\n"; 
execStat($sm, $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
# exit;

$meta = "PGPASSWORD=\"SuperSet\" psql -d hyperset -U hyperset -w -c \"\\copy $sqltable from \'"."$inputDir"."$table\'  delimiter as E\'\\t\' null as \'\'\"";
print STDERR $meta."\n"; 
print STDERR "Failed!..\n" if system($meta) < 0;
}
elsif ($mode eq 'add') {
execStat("DROP TABLE IF EXISTS old_$main", $dbh); 
execStat("ALTER TABLE $main RENAME TO old_$main", $dbh); 
execStat("CREATE TABLE $main AS SELECT t2.sign as sign2, t1.".join(', t1.', @{listFields('old_'.$main, $dbh, 'all')}).", t2.".join(', t2.', @{listFields($sqltable, $dbh, 'onlynew')})."  from old_$main as t1 FULL OUTER JOIN $sqltable as t2 on t1.sign=t2.sign", $dbh); 
execStat("UPDATE $main set sign=sign2 where sign is NULL", $dbh); 
execStat("ALTER TABLE $main DROP COLUMN sign2", $dbh); 
}  
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
return undef;
}

sub execStat {
my($stat, $dbh) = @_;
print STDERR $stat."\n"; 
$dbh->do($stat) or die "Failed!..\n";
return undef;
}

sub listFields {
my($main, $dbh, $mode) = @_;
my $fields;
  my $vals = $dbh->selectall_arrayref(
      "SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = \'$main\'",
      { Slice => {} }
  );
  foreach my $va ( @$vals ) {
  if (($mode ne 'onlynew') or (($va->{column_name} ne 'sign') and ($va->{column_name} ne 'prot1') and ($va->{column_name} ne 'prot2'))) {
push @{$fields}, $va->{column_name};
  }}
return $fields;
}

sub prepareTable {
my($mode, $input, $output, $rewrite) = @_;
my($line, $i, @arr, $header);
return($input);

# open IN, $input or die "Cannot find $input ... \n";
# print join(" ", ($mode, $input, '=>', $output))."\n";
# my $hd = <IN>;
# readHeader($hd, $input) if $readHeader;
# @{$header} = ('sign');
# for $i(sort {$a <=> $b} keys(%{$nm->{$input}})) {
# push @{$header}, $nm->{$input}->{$i};
# }

# if ($rewrite) {
# open OUT, '> '.$output  or die "Cannot create $output ... \n";;
# while ($line = <IN>) {
###$$$$$$$$$$$$$$$$$  last if $i++ >= 1000;
# @arr = split("\t", $line);
# print OUT pair_sign($arr[$pl->{$input}->{"prot1"}], $arr[$pl->{$input}->{"prot2"}])."\t".$line;
# }
# close OUT;
# }
# close IN;
# return($mode, $header, $output);
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


# \timing
# CREATE TABLE net_all_hsa AS select * FROM net_fc_hsa;
# ALTER TABLE merged_hsa ADD COLUMN phosphosite boolean DEFAULT 'FALSE';
# CREATE INDEX merged_hsa_prot1 ON merged_hsa (prot1);
# CREATE INDEX merged_hsa_prot2 ON merged_hsa (prot2);

# CREATE TABLE temp_copy ( prot1 varchar(64), prot2 varchar(64));
# \copy temp_copy (prot1, prot2) FROM '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/Kinase_Substrate.2015.human.2col'
# CREATE INDEX temp_prot1 ON temp_copy (prot1);
# CREATE INDEX temp_prot2 ON temp_copy (prot2);
# ALTER TABLE temp_copy ADD COLUMN overlap boolean DEFAULT 'FALSE';

# UPDATE merged_hsa SET phosphosite='TRUE' FROM merged_hsa m, temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
# select count(*) from merged_hsa m, temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
# UPDATE merged_hsa m SET phosphosite='TRUE' FROM temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
# ALTER TABLE temp_copy ADD COLUMN overlap boolean;
# UPDATE temp_copy m SET overlap='TRUE' FROM temp_copy t  WHERE  (t.prot1 = m.prot1 AND t.prot2 = m.prot2);
 
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
# \copy optnames1 from '/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/optnames1.txt' delimiter as E'\t' null as ''



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

 
 
 
 