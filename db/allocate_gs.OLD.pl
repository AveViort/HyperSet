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
our $dbh = HS_SQL::dbh();
# uploadToSQL(prepareTable($mode, $input, $output, 1), $mode);
uploadToSQL($input, $mode);
indexMain($main) if 1 == 1;
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";

exit;

sub create_stat_fgs {
my($mainFGS) = @_;
my $dbh = HS_SQL::dbh();
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
if ($mode eq 'new') {
$dbh->do("DROP TABLE IF EXISTS $sqltable CASCADE");
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n"; 
my $sm = "CREATE TABLE $sqltable (".join(', ', @fields).")";
print $sm."\n"; 
execStat($sm, $dbh); 
print STDERR "Commit...\n"; $dbh->commit or print STDERR "Failed!..\n";
# exit;

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
 
 
 