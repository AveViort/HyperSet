#!/usr/bin/perl -w
use warnings;
use strict;
use CGI qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use DBI;
use HStextProcessor;

$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our $safe_filename_characters = "a-zA-Z0-9_.-";
our ($dbh, $pl, $nm, 
$conditions, 
$conditionPairs, 
$savedFiles, 
$node_features, $nodeList, $Genes, $NlinksTotal, $conn_class_members, $network_links, %AGS_mem, %conn,  $filterList);
our $NN = 0;
my $NEAfile = '/var/www/html/research/andrej_alexeyenko/HyperSet/DATA/GO.BP_KEGG.mmu.5x4plus_minus.Mouse.merged4_and_tf.co7.prd';
our $q = new CGI;
#saveFiles(); our $mode = $q->param("specify");
our $mode = $q->param('specify');
#our $mode = $q->param('contrastSelector'};

$savedFiles -> {data} -> {"detable"} = 'DE12.test';
$savedFiles -> {data} -> {"detable"} = $q->param('detable'); 
print "Content-type: text/html\n\n";

our ($content, $itemFeatures);
our $Filter = parseContrastSelector($q->param('contrastSelector'));
our $lists  = filterTable($Filter);
our $listsTable = listTable($lists);
$content .= $listsTable;
printContent($content);

sub listTable {
my($list) = @_;

my($contrast, $cnt, $item); 
$cnt = '<table >'."\n";

for $contrast(keys(%{$list})) {
for $item(@{$list->{$contrast}}) {
$cnt .= '<tr><td>'.$contrast.'</td><td>'.$item.'</td><td>'.$itemFeatures -> {$item} -> {$contrast} -> {fc}.'</td><td>'.$itemFeatures -> {$item} -> {description}.'</td></tr>'."\n";
}}
$cnt .= '</table>';

return($cnt);
}

sub filterTable {
my($filterList) = @_;

my($contrast, $title, $value, $direction, %rejected, $line, $skip, $item, $list);
my $table = $HStextProcessor::usersDir.$savedFiles -> {data} -> {"detable"};
open IN, $table;
my $header = <IN>;
HStextProcessor::readHeader($header, $table);

while ($line = <IN>) {
#$content .= '<br>&nbsp;&nbsp;&nbsp;Gene&nbsp;&nbsp;'.scalar(keys(%{$pl->{$table}})).'&nbsp;&nbsp;'.$pl->{$table}->{'gene'};

my(@arr, $aa);
chomp($line);
@arr = split("\t", $line);
undef %rejected;
$item = $arr[$pl->{$table}->{'gene symbol'}];

for $contrast  (keys(%{$filterList})) {
#$content .= '<br>&nbsp;&nbsp;&nbsp;Keys&nbsp;&nbsp;'.$contrast.':::'.join('&nbsp;&nbsp;_AND_&nbsp;', keys(%{$filterList->{$contrast}})).'&nbsp;&nbsp;';
for $title     (keys(%{$filterList->{$contrast}})) {
for $direction (keys(%{$filterList->{$contrast}->{$title}})) {
$value = $arr[$pl->{$table}->{$title}];
if (($value ne '') and ($value ne 'NA')) {
if ((($direction eq 'down') and ($value > $filterList->{$contrast}->{$title}->{down})) 
or  (($direction eq   'up') and ($value < $filterList->{$contrast}->{$title}->{up})))  {
$rejected{$title}++;
}
else {
$itemFeatures -> {$item} -> {$contrast} -> {fc} = $arr [ $pl -> {$table} -> {'x6_wt_sb_d3_5s_x10_wt_sb_d5_5s_fpkm_log2fc'} ];
# $content .= '<br>&nbsp;&nbsp;&nbsp;Keys&nbsp;&nbsp;'.$contrast.':::'.join('&nbsp;&nbsp;_AND_&nbsp;', keys(%{$filterList->{$contrast}})).'&nbsp;&nbsp;';
}}}}
$skip = 0;
for $title(keys(%rejected)) {
if (defined($filterList->{$contrast}->{$title})) {
if (
((scalar(keys(%{$filterList->{$contrast}->{$title}})) >  1) and ($rejected{$title}  > 1)) #for fold change either up or down
 or 
((scalar(keys(%{$filterList->{$contrast}->{$title}})) == 1) and ($rejected{$title}  > 0)) #for fdr
) {
$skip = 1;
}
}
}
if (!$skip) {
$itemFeatures -> {$item} -> {description} = $arr[$pl->{$table}->{'gene description'}];
push @{$list->{$contrast}}, $item;
#$content .= '<br>&nbsp;&nbsp;&nbsp;'.$contrast.'&nbsp;'.$item;
}
}
}
close IN;
return $list;
}

sub parseContrastSelector { #contrastSelector
my(@pars) = @_;
my($field, $tbl, $cond1, $cond2,  $ID, $contrast, $filter, $title);
my $ff; 
for $ID(@pars) {
$content .= '<br>'.$ID;
	for $ff(keys(%HStextProcessor::filterList)) {
$title = HStextProcessor::id2title($ID, $HStextProcessor::postfix{$ff});
if ($q->param($ID.'_'.$ff)) {

if (lc($ff) eq 'fcdn') {$filter->{$ID}->{$title}->{down} = -$q->param($ID.'_'.$ff);}
if (lc($ff) eq 'fcup') {$filter->{$ID}->{$title}->{up}   =  $q->param($ID.'_'.$ff);}
if (lc($ff) eq 'fdr')  {$filter->{$ID}->{$title}->{down} =  $q->param($ID.'_'.$ff);}
	}
#$content .= '<br>&nbsp;&nbsp;&nbsp;'.$ID.'&nbsp;'.$title;
#$content .= '<br>&nbsp;&nbsp;&nbsp;'.$title.'&nbsp;'.$q->param($ID.'_'.$ff);
	}
}
return $filter;

}

sub printContent {
my($cc) = @_;
#print printStart();
print "$cc<br>\n";
#print printEnd();
}

