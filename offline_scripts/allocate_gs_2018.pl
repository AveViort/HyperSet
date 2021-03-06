#!/usr/bin/perl -w

# my $q = new CGI; #new instance of the CGI object passed from the query page index.html
# use warnings;
use strict;
use CGI qw(-no_xhtml);
use DBI;
use Scalar::Util 'looks_like_number';
use lib "/var/www/html/research/HyperSet/cgi/";
use HS_SQL;

# cd /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/db/input_files/
 # cat /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/db/FGS_update/*/*/rearr* | grep -vw -e wikipathways -e reactome -e kegg | gawk 'BEGIN {la = ""; FS="\t"; OFS = "\t"} {print $1, $2, tolower($3), $4, $6}}' | sort -u > fgs2018.sql
  # cat input_files/fgs2018.sql | sed "{s/[\']/_/g}" > input_files/fgs2018_noQW.sql


# cd /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/db/
# ./allocate_gs_2018.pl new fgs2018_noQW.sql
# ./allocate_gs_2018.pl  stat fgs2018_noQW.sql

our $main = 'fgs_current'; #the SQL table
#####################
####################

our $sign_delimiter = '###';
our($nm, $pl, $columns);
my($mode, $input);
# our %datatypes = (
# 'prot' => 'varchar(1024)', 
# 'set' => 'varchar(1024)', 
# 'org_id' => 'varchar(64)', 
# 'source' => 'varchar(256)',
# 'evidence' => 'varchar(64)'
# );
our @datatypes = (
'prot varchar(1024)', 
'set varchar(1024)', 
'source varchar(256)',
'org_id varchar(64)', 
'evidence varchar(64)'
);
our %indices = (
'source'  => 1, 
'org_id'  => 1, 
'prot' => 1, 
'evidence' => 1, 
'set' => 1 
);


if ($ARGV[0] =~ m/^new|add|stat$/i) { 
$mode = lc($ARGV[0]);
} else {
die "Mode not identified (1st parameter)...\n";
}

if ($ARGV[1] =~ m/^[0-9A-Z\.\_\-]+$/i) {
$input = $ARGV[1];
} else {
die "Input file not identified (3rd parameter).\nUse 1st parameter \'all\' in order to run the whole batch...\n" if ($mode ne 'all');
}

our $inputDir = "/var/www/html/research/HyperSet/db/input_files/";
chdir $inputDir;

my $output = $main; #($mode eq 'add') ? $input : $main;
# my $output = $input; 
# $output =~ s/\.withheader//; 
# $output .= '.sql'; 
our $dbh = dbh();

if ($mode eq 'new') { 
uploadToSQL($input, $mode, $output);
indexMain($main) if 1 == 1;
print STDERR "Disconnect.\n"; $dbh->disconnect or print STDERR "Failed!..\n";
exit;
} 
else {
create_stat_fgs($main);
 exit;
}

sub dbh {
my $conf_file = "/home/proj/func/FGS_update/HS_SQL.LOCAL.conf";

open(my $conf, $conf_file);

my $dsn  = <$conf>;
chomp $dsn;
my $user = <$conf>;
chomp $user;
my $ps   = <$conf>;
chomp $ps;
$dbh = DBI->connect( $dsn, $user, $ps ,  {
        RaiseError => 1, AutoCommit => 0
    }) || die "Failed to connect as $dsn, user $user.../n";
return $dbh;
}

sub create_stat_fgs {
my($mainFGS) = @_;

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
my($table, $mode, $output) = @_;
my(@fields, $meta, $stat, $fl);

my $sqltable = $output; # $table;
# $sqltable =~ s/\.sql$//;
for $fl((0..$#datatypes)) {
push @fields, $datatypes[$fl];
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

my $conf_file = "/home/proj/func/FGS_update/HS_SQL.LOCAL.conf";
open(my $conf, $conf_file);
my $dsn  = <$conf>;
chomp $dsn;
my $user = <$conf>;
chomp $user;
my $ps   = <$conf>;
chomp $ps;
$meta = "PGPASSWORD=".$ps." psql -d hyperset -U ".$user." -w -c \"\\copy $sqltable from \'"."$inputDir"."$table\'  delimiter as E\'\\t\' null as \'NULL\'\"";
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






