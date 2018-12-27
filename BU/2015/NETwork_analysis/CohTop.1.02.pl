#!/usr/bin/perl
use strict vars;

## CohTop version 1.01: a network clustering program employing Kullback-Leibler divergence metric ###
## Copyright Andrey Alexeyenko, 2009 ################################################################

#changes since v. 1.00 : memory consumption reduced

#The program is run via a unix/linux command line with desirable parameters. If parameters are not
# specified, then they may take on values in the next 15 lines. 
#Most importantly, the header (1st line) of the input network table (must be TAB-delimited) should
# contain protein name columns as 'PROTEIN1', 'PROTEIN2' and, optionally, edge cutoff 
#(must be stored in the column defined by $scorecol variable - see below) to reduce the network size 
#by selecting the most confident subset of network edges, or another numerically defined subset.
#Another way to select a subset of edges is to define parameter '-type'.
#E.g. '-type dioxin -sort p' would select only links with label "P" in the column "DIOXIN".
#Thus for example, a command line statement:
#> ./CohTop.pl -file network_file.txt -coff 0.5 -type dioxin -sort p > clusters.output
#will take network edges defined at conifdence >0.50 in "network_file.txt" and write
#the clusters to "clusters.output"
#Processing a network of ~2000 nodes and ~20000 edges takes about an hour on a modern desktop.

#The output table is TAB-delimited:
#CLUSTER_ID	NO_OF_NODES_IN_THE_CLUSTER	CLUSTER_MEMBERS
#Clusters members in the column 3 are space-delimited
##################################################################################################

our($delta, $pms, $net, $smallSampleFraction, $makeSmallSample, $scorecol, %LLRpl, %LLRnm, %SRCpl, %SRCnm, %pl, @hubs, @closest, %Ntot, $debug, %outd, $e, $workdir, $scorecutoff, $Ncutoff, $Nin, $printSteps, $printClusters, $energyMode, $pms, %sorts, $output, $MINdist);

######SETTINGS: ###############################
$printSteps = 1; #debug mode - turning on means too much output
$printClusters = 1; #print output
$e = 2.718282;
$Ncutoff = 10000;
$delta = 0.000001;
$MINdist = -1000;
$pms = parseParameters(join(' ', @ARGV));
$scorecol = 'fbs_max';
$scorecol = $pms->{'scol'} if defined($pms->{'scol'});     #column for quantitative cutoff to select (the most confident) part of the network
#$scorecol = 'confidence';
#$pms->{'sort'} = 'p' if !$pms->{'sort'}; #a particular type (sort) of link to load and cluster
#$pms->{'type'} = 'dioxin' if !$pms->{'type'}; #the column header where labels of the above 'link sort' are stored
$sorts{lc($pms->{'sort'})} = $sorts{uc($pms->{'sort'})} = 1 if defined($pms->{'sort'});
$pms->{'coff'} = 0 if !$pms->{'coff'}; #network edge quantitative cutoff
$scorecutoff = $pms->{'coff'};
#$pms->{'file'} = '' if !$pms->{'file'}; #a stable file name can be put here
$energyMode = 'KullbackLeibler';
my($pp, @nameline, $spec);
$spec = 'hsa' if $pms->{'file'} =~ m/human|hsa\./i;
$spec = 'sce' if $pms->{'file'} =~ m/yeast|sce\./i;

for $pp('CohTop', 'clusters', $spec, $scorecol, $pms->{'coff'}, $pms->{'sort'}, $$, 'list') {
  push @nameline, $pp if $pp;
  }
$output = join('.', @nameline);
#####END OF SETTINGS################################

readWholeNetwork($pms->{'file'});
if (defined($output)) {
open OUT, '> '.$output or die "Could not open output file $output...\n";
print "The list of clusters is going to be written to $output ... \n";
}
else  {print "The list of clusters is going to be sent to STandard OUTput... \n";}
initialize_net();
shared_network_context();
cluster_by();
printClusters() if $printClusters;

sub printClusters {
my($cc, $outline);
for $cc(sort {scalar(keys(%{$net->{'cluster_members'}->{$b}})) <=> scalar(keys(%{$net->{'cluster_members'}->{$a}}))} keys(%{$net->{'cluster_members'}})) {
if (scalar(keys(%{$net->{'cluster_members'}->{$cc}})) > 1) {
$outline = $cc."\t".scalar(keys(%{$net->{'cluster_members'}->{$cc}}))."\t".join(' ', keys(%{$net->{'cluster_members'}->{$cc}}))."\n";
if      (defined($output)) {    print OUT $outline;}
else {                          print $outline;}
}}
print "Finished. The list of clusters can be found in $output... \n";
}

sub cluster_by {
my($c1, $c2, $ci, $cj, $cc, $gg, $d, $dd, $dist, $max, @closest, $i, $j, $k, $done, $current_affinities, %alreadyMerged);

while ($i++ < 100 and !$done) {
undef $current_affinities; $d = 0; $j = 0; undef %alreadyMerged;
for $c1(sort {$a cmp $b} keys(%{$net->{'cluster_members'}})) {
for $c2(sort {$a cmp $b} keys(%{$net->{'cluster_members'}})) {
last if $c1 eq $c2;
$dist = IClocal($c1, $c2);
next if $dist <= $MINdist;
$current_affinities->[$d]->{'dist'} = $dist;
$current_affinities->[$d]->{'nin'} = $Nin;
$current_affinities->[$d]->{'c1'} = $c1;
$current_affinities->[$d]->{'c2'} = $c2;
$d++;
}}
@{$current_affinities} = sort {$b->{'dist'} <=> $a->{'dist'}} @{$current_affinities};
undef $k;
for $dd(@{$current_affinities}) {
last if $j++ > 1000;
print OUT join("\t", ($dd->{'c1'}, $dd->{'c2'}, $dd->{'dist'}, $dd->{'nin'}))."\n" if 1 == 1;
next if $alreadyMerged{$dd->{'c1'}} or $alreadyMerged{$dd->{'c2'}};
last if $dd->{'dist'} < $delta;
$alreadyMerged{$dd->{'c1'}} = $alreadyMerged{$dd->{'c2'}} = 1;
if ($printSteps) {
print join("\t", ($i, $j, $dd->{'dist'}, 'Nin:'.$dd->{'nin'}, $dd->{'c1'}, scalar(keys(%{$net->{'cluster_members'}->{$dd->{'c1'}}})), $dd->{'c2'}, scalar(keys(%{$net->{'cluster_members'}->{$dd->{'c2'}}}))))."\t";
for $cc('c1', 'c2') {
for $gg(keys(%{$net->{'cluster_members'}->{$dd->{$cc}}})) {
print "\t".$gg.' '.scalar(keys(%{$net->{'neighbors'}->{$gg}}));
}
print "\t".'VVVVV'."\t";
}
print "\n_______________\n";
}
mergeClusters($dd->{'c1'}, $dd->{'c2'});
$k++;
}
$done = 1 if $k < 2;
}
return undef;
}

sub IClocal { #quantifies information shared  by the two clusters
my($c1, $c2) = @_;
my($BIC1, $BIC2);

return($MINdist) if !crossCheck($c1, $c2);
undef $Nin; $BIC1 = inOutEdgesEnergy($c1);
undef $Nin; $BIC2 = inOutEdgesEnergy($c2);
undef $Nin; return($BIC1 + $BIC2 - inOutEdgesEnergy($c1, $c2));
return undef;
}

sub crossCheck {
my($c1, $c2) = @_;
my($gi, $gj);

for $gi(keys(%{$net->{'cluster_members'}->{$c1}})) {
for $gj(keys(%{$net->{'cluster_members'}->{$c2}})) {
return 1 if (defined($net->{'neighbors'}->{$gj}) and defined($net->{'neighbors'}->{$gj}->{$gi}));
}}
return undef;
}

sub inOutEdgesEnergy {
my(@cList) = @_;
my($all, $c, $nModel, $gi, $gj, $gn, $Ntotal, $Nclus, $Nshared, $distFBS);

for $c(@cList) {
for $gi(keys(%{$net->{'cluster_members'}->{$c}})) {
$all->{$gi} = 1;
}} 
$nModel = scalar(keys(%{$all}));
for $gi(sort {$a cmp $b} keys(%{$all})) {
$Ntotal += scalar(keys(%{$net->{'neighbors'}->{$gi}})); ###
for $gj(sort {$a cmp $b} keys(%{$all})) {
last if $gj eq $gi;
$Nin++ if (defined($net->{'neighbors'}->{$gj}) and defined($net->{'neighbors'}->{$gj}->{$gi}));
$Nin += sqrt($net->{'shared_network_context'}->{pair_sign($gi, $gj)}->{n});
$Nshared += sqrt($net->{'shared_network_context'}->{pair_sign($gi, $gj)}->{n});
}}
$Ntotal = $Ntotal / $nModel ** 2; 
$Nin = $Nin / $nModel ** 2;
$Nclus = $Nin + $Nshared / $nModel ** 2;
$net->{'cluster_status'}->{$c} = $cList[0] if ($#cList < 1) and ($Ntotal == $Nin);
return sprintf("%.3f", ($Ntotal * log(($Ntotal + 0.1) / ($Nin + 0.1))));
}

sub clusterAffinity {
my($c1, $c2) = @_;
my($gi, $gj, $ci, $cj, $distN, $distFBS);
($ci, $cj) = 
(scalar(keys(%{$net->{'cluster_members'}->{$c1}})) > scalar(keys(%{$net->{'cluster_members'}->{$c2}})))
? ($c2, $c1) : ($c1, $c2);
 
for $gi(keys(%{$net->{'cluster_members'}->{$ci}})) {
for $gj(keys(%{$net->{'cluster_members'}->{$cj}})) {
if (defined($net->{'neighbors'}->{$gj} ) and defined($net->{'neighbors'}->{$gj}->{$gi})) {
$distN++;
$distFBS += $net->{'pairs'}->{$gi}->{$gj}->{'fbs'};
}}}
return $distN / scalar(keys(%{$net->{'cluster_members'}->{$ci}}));
return undef;
}


sub mergeClusters {
my($c1, $c2) = @_;
my($g2, $ID);

for $g2(keys(%{$net->{'cluster_members'}->{$c2}})) {
$net->{'cluster_numbers'}->{$g2} = $c1;
$net->{'cluster_members'}->{$c1}->{$g2} = 1;
}
delete $net->{'cluster_members'}->{$c2};
return undef;
} 

sub shared_network_context {
my($g1, $g2, $gi, $gj, $ni, $nj, $pair );

for $g1(sort {$a cmp $b} keys(%{$net->{'neighbors'}})) {
for $g2(sort {$a cmp $b} keys(%{$net->{'neighbors'}})) {
last if $g1 eq $g2;
$pair = pair_sign($g1, $g2);
($gi, $gj) =
(scalar(keys(%{$net->{'neighbors'}->{$g1}})) > scalar(keys(%{$net->{'neighbors'}->{$g2}})))
? ($g2, $g1) : ($g1, $g2);

for $ni(keys(%{$net->{'neighbors'}->{$gi}})) {
if (defined($net->{'neighbors'}->{$gj}) and defined($net->{'neighbors'}->{$gj}->{$ni})) {
$net->{'shared_network_context'}->{$pair}->{n}++;
$net->{'shared_network_context'}->{$pair}->{sFBS} += $net->{'pairs'}->{$g1}->{$g2}->{'fbs'};
}}}}
return undef;
}

sub pair_sign {return join('=', (sort {$a cmp $b} @_));}

sub pair_unsign {shift @_; return split('=');}

sub initialize_net {
my($i, $j, $g1, $g2, $pair, $ID);
print scalar(keys(%{$net->{'unique'}}))." edges\n";
print scalar(keys(%{$net->{'pairs'}}))." nodes\n";
for $g1(sort {$a cmp $b} keys(%{$net->{'edges_by_type'}})) {
$net->{'cluster_members'}->{++$ID}->{$g1} = 1;
$net->{'cluster_numbers'}->{$g1} = $ID;

for $g2(sort {$a cmp $b} keys(%{$net->{'edges_by_type'}})) {
last if $g1 eq $g2;
$net->{'neighbors'}->{$g1}->{$g2}->{'fbs'} =  
$net->{'neighbors'}->{$g2}->{$g1}->{'fbs'} =
$net->{'pairs'}->{$g1}->{$g2}->{'fbs'}
if (
defined($net->{'pairs'}->{$g1}) and
defined($net->{'pairs'}->{$g1}->{$g2})
and $net->{'pairs'}->{$g1}->{$g2}->{'fbs'}
);
}}
return undef;
}

sub readWholeNetwork {
my($table) = @_;
my(@arr, $N);
open NET, $table or die "Cannot open NET from table $table ...\n";

$_ = <NET>;
readHeader($_);
$pl{'protein1'} = $pl{'gene1'} if defined($pl{'gene1'});
$pl{'protein2'} = $pl{'gene2'} if defined($pl{'gene2'});

die "Cannot find column PROTEIN1 in the table $table.\nPlease define the header ...\n" if !defined($pl{'protein1'});
die "Cannot find column PROTEIN2 in the table $table.\nPlease define the header ...\n" if !defined($pl{'protein2'});
if ($pms->{'coff'}) {
die "Cannot find column $scorecol in the table $table.\nPlease define the header ...\n" if defined($scorecutoff) and !defined($pl{$scorecol});
}
while (<NET>) {
#last if $N++ > $Ncutoff; ##########################
chomp; @arr = split("\t", $_);
next if $arr[$pl{$scorecol}] < $scorecutoff;
next if ($pms->{'sort'} and !defined($sorts{$arr[$pl{$pms->{'type'}}]}));
%{$net->{'pairs'}->{$arr[$pl{'protein2'}]}->{$arr[$pl{'protein1'}]}} = 
%{$net->{'pairs'}->{$arr[$pl{'protein1'}]}->{$arr[$pl{'protein2'}]}} = 
%{$net->{'unique'}->{pair_sign($arr[$pl{'protein1'}], $arr[$pl{'protein2'}])}} = 
(
$pms->{'type'} => $arr[$pl{$pms->{'type'}}],
'fbs' => $arr[$pl{$scorecol}]
);
%{$net->{'edges_by_type'}->{$arr[$pl{'protein1'}]}->{'dioxin'}->{$arr[$pl{'protein2'}]}} =
%{$net->{'edges_by_type'}->{$arr[$pl{'protein2'}]}->{'dioxin'}->{$arr[$pl{'protein1'}]}} = $arr[$pms->{'type'}];
}
close NET;
return undef;
}

sub readHeader {

    my($head) = @_;
    my(@arr, $aa);
chomp($head);
@arr = split("\t", $head);

for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$pl{lc($arr[$aa])} = $pl{$arr[$aa]} = $aa; #column number (index) to find respective data
if ($arr[$aa] =~  m/^LLR_[a-z]{3}_/) {
$arr[$aa] =~  s/^LLR_//i;
$LLRpl{$arr[$aa]} = $aa;
$LLRnm{$aa} = $arr[$aa];
}
else {
  if ($arr[$aa] =~  m/colocali/i or $arr[$aa] =~  m/_ppi_/i or $arr[$aa] =~  m/pearso/i or $arr[$aa] =~  m/phylo/i) {
$SRCpl{$arr[$aa]} = $aa;
$SRCnm{$aa} = $arr[$aa];
}}}
    $pl{protein1} = $pl{gene1} if defined($pl{gene1}) and !defined($pl{protein1});
    $pl{protein2} = $pl{gene2} if defined($pl{gene2}) and !defined($pl{protein2});

#ATTENTION: if you do not have correct header in the input network file,
# then please redefine it in the end of this subprogram!!!
#For example, uncomment these:
# $pl{'protein1'} = 0;
# $pl{'protein2'} = 1;
# $pl{'confidence'} = 2;
return undef;
}
 
sub parseParameters ($) {
my($parameters) = @_;
my($_1, $_2, $prms);

print "$parameters\n";
$_ = $parameters;
while (m/\-(\w+)\s+([A-Za-z0-9.-_+]+)/g) {
$_1 = $1;
$_2 = $2;
if ($_2 =~ /\+/) {push @{substr(lc($_1), 0, 4)}, split(/\+/, lc($_2));}
else {$prms->{substr(lc($_1), 0, 4)} = $_2;}
}
die "\nNot enough parameters! Please specify:\n
-file :	input network file name (TAB-delimited, with columns 'PROTEIN1', 'PROTEIN2' and, optionally, edge cutoff - must be stored in the column defined by \$scorecol variable - see the header of the script)\n
\tIf your input table does not have a header, then find the subprogram readHeader in this script and manually add necessary column places (hash \%pl)!!!
-coff : sets a numeric cutoff for edges to be loaded and considered as part of the network\n
-type : sets a name of the column where additional qualitative labels are stored. Optional. If set, then \'sort\' must be given as well\n
-sort :	if type has been given, sets a particular qualitative label to select. Optional. If set, then \'type\' must be given as well\n
-scol :	'score column' - a name of the column with quantitative (continuous or discrete) score which '-coff' is applied to. Optional (if not set, then it is column name set by variable \$scorecol). \n\n" if (scalar( keys( %{$prms} ) ) < 1) or ($prms->{'type'} and !defined($prms->{'sort'}))  or (!$prms->{'type'} and defined($prms->{'sort'}));
return $prms;
}

