#!/usr/bin/speedy -w
# use warnings;

# script for retrieving drug list for each source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $stat);

my $query = new CGI;
my($sqltable, $order ) = ('best_drug_corrs', ' abs(correlation) DESC ');
my $condition = "  dataset=\'CTD\' ";
$condition .=  " AND screen=\'".$query->param("screenList")."\'" if $query->param("screenList") ne 'all'; 
$condition .=  " AND platform=\'".$query->param("corrTabList")."\'" if $query->param("corrTabList") ne 'all';
my $selectedDrug = $query->param("drugList"); 
#my $selectedDrug = $query->param("drugList_".$query->param("screenList")) if $query->param("screenList") ne 'all';
$condition .=  " AND drug=\'".$selectedDrug."\'" if $selectedDrug ne 'all'; 
my( $row , $rows, @r, $col, $tbl, $pl, $gene);
$dbh = HS_SQL::dbh();
my $stat = "select * from $sqltable where $condition order by  $order limit 10000;";
print "Content-type: text/html\n\n";
print $stat."<br>";

for $col(@{$Aconfig::cols}) { 
$tbl .= '<th>'.$Aconfig::colTitles{$col}.'</th>';
}
$tbl .= '</tr></thead>';
$rows = $dbh->selectall_arrayref($stat);

for  $row (@{$rows}) { #id="submit-'.join('-', @{$row}[0..5]).'" 
$pl = $row->[2];
$pl =~ s/\.//g;
$pl =~ s/pwnea//g;
$gene = $row->[5];
$gene =~ s/-/@@@/g;
print $pl." ".$gene."<br>";
}

$dbh->disconnect;