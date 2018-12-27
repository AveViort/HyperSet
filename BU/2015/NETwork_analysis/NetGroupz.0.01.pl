#!/usr/bin/perl

#use strict vars;
$ENV{'PERL5LIB'} = '/afs/pdc.kth.se/home/a/andale/perl-from-cpan/lib/perl5/site_perl/';
use Statistics::Distributions;
#####################################################################################################
# The script randomizes funcoup networks and checks whether different gene groups (e.g. 
# kegg pathways or other gene groups) are more connected to each other than expected.
#
# Input: the script requires two files to be defined within the script:
#  1) The protein network, $fc{'species'} for your species in the script
#  2) The gene groups, $GOtable.  The format of this file is species-dependent(!) and governed
#     by the $pl{} array.
#           For Human (hsa), it is:
#           <Gene_ID> <Group_ID> <Species> <Type_of_group> <Group_annotation>
#  3) A file with the gene symbol / identifier mappings, $symtable{'species'}
#
#
# As column positions in both files are hard coded in the script double check them!
#
# Output: the script produces two ouput files:
# -> the first file includes statistics about the number of connections
# -> the second file can be used as an input for cytoscape
#
# Parameters:
#  -sp  Species
#  -ki  Kind of group, e.g. MET or SIG
#  -co  Cutoff for Function link strength
#  -sc  Score column to use in FunCoup network
#####################################################################################################


#FILES WITH THE NETWORKS:
$fc{'hsa'} = '/afs/pdc.kth.se/home/a/andale/mshared7/Networks/human/Human.Version_1.00.4classes.fc.joined.new';
#$fc{'hsa'} = 'Human_net.all';
$fc{'mmu'} = '/afs/pdc.kth.se/home/a/andale/mshared7/Networks/mouse/Mouse.Version_1.00.3classes.fc.joined';
$fc{'cin'} = 'm14/SQL_FunCoup/Networks/Ciona.Version_1.00.2classes.fc.joined';
$fc{'ath'} = 'm14/SQL_FunCoup/Networks/Thaliana.Version_1.00.2classes.fc.joined';
$fc{'dme'} = 'm14/SQL_FunCoup/Networks/Fly.Version_1.00.3classes.fc.joined';
$fc{'cel'} = 'm14/SQL_FunCoup/Networks/Worm.Version_1.00.3classes.fc.joined';
$fc{'sce'} = 'm14/SQL_FunCoup/Networks/Yeast.Version_1.00.4classes.fc.joined';
$fc{'dre'} = 'm14/SQL_FunCoup/Networks/Zfish.Version_X.1class.fc.joined';
$fc{'rno'} = 'm14/SQL_FunCoup/Networks/Rat.Version_1.00.2classes.fc.joined';
$fc{'gga'} = '/afs/pdc.kth.se/home/o/olifri/Private/vol00/funcoup_bn04/GGA.Version04.3classes.fc.joined';

#CROSS-REFERENCES BETWEEN ENSEMBL GENES AND GENE SYMBOLS:
$symtable{'hsa'} = '/afs/pdc.kth.se/home/a/andale/mou0/Name_2_name/geneID_2_ENSG_2_DE.Labels.New.human.txt';
$symtable{'mmu'} = '/afs/pdc.kth.se/home/a/andale/mou0/Name_2_name/geneID_2_ENSG_2_DE.Labels.New.mouse.txt';
$symtable{'rno'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.rat.txt';
$symtable{'dme'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.fly.txt';
$symtable{'cel'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.worm.txt';
$symtable{'sce'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.yeast.txt';
$symtable{'dre'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.zfish.txt';
$fc{'gga'} = '/afs/pdc.kth.se/home/o/olifri/Private/vol00/funcoup_bn04/GGA.Version04.3classes.fc.joined';

#IDs of FUNCTIONAL GROUPS FOR NETWORK GENES:
$GOtable = '/afs/pdc.kth.se/home/a/andale/mou1/data/KEGG/ENSEMBL.KEGGwithLevels.met_and_sig.anno';
#$GOtable = 'input.random4';
$GOtable = 'crosstalk/input.hsa';
parseParameters(join(' ', @ARGV));
srand();

#DEFINE COLUMN NUMBERS IN THE INPUT FILES TO PROPERLY READ DATA IN:
#NETWORK FILE
$pl{fbs} = 0; $pl{prot1} = 1; $pl{prot2} = 2;
#GENE SYMBOL FILE:
$pl{gene2sym} = 1; $pl{sym} = 0; $pl{descr} = 2;
#FUNCTIONAL GROUP FILE:
$pl{gene} = 0; $pl{GO} = 1; $pl{level} = 2; $pl{kind} = 3; $pl{spec} = 2; $pl{title} = 4;
###################
    $spe = 		$pms->{'sp'} ? $pms->{'sp'} : 'hsa'; #SPECIES ID
    $GOkind = 		$pms->{'ki'} ? $pms->{'ki'}  :'all';
    $FBScutoff = 	$pms->{'co'} ? $pms->{'co'} : 7;
    $Niter = 		$pms->{'it'} ? $pms->{'it'} : 10; #NUMBER OF RANDOMIZATIONS IN THE INPUT NETWORK
    $filenames = join('_', $spe, $GOkind, "FBS", $FBScutoff, 'Nreal', $minRealLinksForPvalue, 'Nexp', $minExpLinksForPvalue);
######################################################################
$considerAllLinks = 1;
$minRealLinksForPvalue = 3;
$minExpLinksForPvalue = 0.3;
$Ntestlines = 100000; #TAKE FIRST Ntestlines LINES IN THE NETWORK FILE (TEST MODE)
$debug = 1;
$join =  '_vs_';

print STDERR "\nReading in functional groups from \n $GOtable ...\n";
readGO($GOtable);

print STDERR "Reading in gene symbols from \n ".$symtable{$spe}." ...\n";
readSymbols($symtable{$spe}) if defined($symtable{$spe});

print STDERR "Reading in network from \n $fc{$spe} ...\n";
readLinks($fc{$spe});

#######################################################################
    for $i(0..($Niter - 1)) {
	print STDERR "Doing iteration ".($i+1)." out of $Niter ... \n";
	count_in_groups(randomizeNetwork(), $i);
	undef $p; undef $pdiff; undef $startdir; undef $enddir;
    }
    $co = 0;
    count_in_groups($link, 'real');
calculateConn();  exit;
#######################################################################

sub calculateConn {
    open OUT0, '> '.$filenames.'.ATTR'; #PRINT INFORMATIONAL FILE WITH go ATTRIBUTES
    print OUT0 join("\t", (
			   'ID'.$daylabel,
			   'IDtitle'.$daylabel,
			   'Ngenes'.$daylabel,
			   'NlinksTotal'.$daylabel,
			   'NlinksOut'.$daylabel,
			   'NlinksIn'.$daylabel,
			   'Genes'.$daylabel))."\n";
    for $go1(keys(%{$p})) {	# $p IS THE GENERAL POINTER TO ALL go, BOTH SINGLETONS AND PAIRS
	if ($go1 !~ m/$join/i) {
	    print OUT0 join("\t", (
				   $go1,
				   $GOtitle->{$go1},
				   scalar(keys(%{$GOmembers->{$go1}})), 
				   $p->{$go1}, 
				   $startdir->{$go1}, #THESE TWO COLUMNS SIMPLY INFORM ON WHICH COLUMN (prot1 OR prot2) CONTAINED RESPECTIVE GENES - CAN BE IGNORED
				   $enddir->{$go1}, #
	    join('|', (sort {$a cmp $b} keys(%{$genelist->{total}->{$go1}})))))."\n";
	}
    }
    close OUT0;
    print $filenames.'.ATTR'." now contains gene group attributes\n";
    open OUT1, '> '.$filenames.'.NET'; #PRINT MAIN FILE WITH go-go PAIR SCORES
    print OUT1 join("\t", ('PAIR', 'label', 'label2', 'ID1', 'ID2', 'NlinksExp', 'NlinksObs', 'Zscore_1-2', 'p-value', 'pFDR', 'Zscore_1-1', 'Zscore_2-2'))."\n";
    $Ntot = $co;

    calculateStats();
    for $go1(sort {$b cmp $a} keys(%{$p})) { # $p IS THE GENERAL POINTER TO ALL go, BOTH SINGLETONS AND PAIRS
	next if ($go1 =~ m/$join/i);
	for $go2(sort {$b cmp $a} keys(%{$p})) {
	    next if ($go2 =~ m/$join/i);
	    $gg = join($join, (sort {$a cmp $b} ($go1, $go2)));
	    $type = ($go1 eq $go2) ? 'same' : 'diff'; # : 'total';

	    undef @line; undef %Ngg; undef $Nggexp;
	    if ($type eq 'same') {
		$Ngg{$gg} = $p->{$gg};
		($Ngg{$go1}, $Ngg{$go2}) = ($p->{$go1}, $p->{$go2});
	    } elsif ($type eq 'diff') {
		$Ngg{$gg} = $pdiff->{$gg};
		($Ngg{$go1}, $Ngg{$go2}, $Ngg{$gg}) = ($p->{$go1}, $p->{$go2}, $pdiff->{$gg});
	    }
	    undef $shareMemb;
	    for $p1(keys(%{$GOmembers->{$go1}})) {
		$shareMemb++ if defined($GOmembers->{$go2}->{$p1}); #COUNT GENES SHARED BY GO1 AND GO2
	    }

@STAT = defined($stats_by_pair->{$gg}->{zsc}) 
      ? (
sprintf("%.3f", $stats_by_pair->{$gg}->{zsc}),
sprintf("%.10f", $stats_by_pair->{$gg}->{pval}),
sprintf("%.6f", $stats_by_pair->{$gg}->{pfdr}))
	:
('NA', 'NA', 'NA');
$SELF1 = defined($stats_by_pair->{join($join, ($go1, $go1))}->{zsc}) ?
sprintf("%.3f", $stats_by_pair->{join($join, ($go1, $go1))}->{zsc}) : 'NA';
$SELF2 = defined($stats_by_pair->{join($join, ($go2, $go2))}->{zsc}) ?
sprintf("%.3f", $stats_by_pair->{join($join, ($go2, $go2))}->{zsc}) : 'NA';
	    @line = (
		     $gg,
		     join('-', (sort {$a cmp $b} ($GOkind->{$go1}, $GOkind->{$go2}))),
		     $type,
		     $go1,
		     $go2, 
		     sprintf("%.3f", $mean{$gg}),
		     ($Ngg{$gg} ? $Ngg{$gg} : '0'),
		     @STAT,
		     $SELF1,
		     $SELF2
		    );
	    print OUT1 join("\t", @line)."\n";
	    last if ($go1 eq $go2);
	}
    }
    close OUT1;
    print $filenames.'.NET'." now contains pairwise gene group statistics\n";
}


sub calculateStats { #STANDARD DEVIATION
my $G;
    undef %mean; undef %SD;
    for $go1(sort {$b cmp $a} keys(%{$p})) {
	next if ($go1 =~ m/\_vs\_/i);
	for $go2(sort {$b cmp $a} keys(%{$p})) {
	    next if ($go2 =~ m/\_vs\_/i);
	    $gg = join($join, (sort {$a cmp $b} ($go1, $go2)));
	    $type = ($go1 eq $go2) ? 'same' : 'diff';

	    $pp = ($type eq 'same') ? $pRandom->{$gg} : $pdiffRandom->{$gg};
	    for $ppR(0..($Niter - 1)) {
		$mean{$gg} += $pp->[$ppR];
	    }
	    $mean{$gg} /= $Niter;
	    for $ppR(0..($Niter - 1)) {
		$SD{$gg} += ($pp->[$ppR] - $mean{$gg}) ** 2;
	    }
	    $SD{$gg} /= ($Niter - 1);
	    $SD{$gg} = sqrt($SD{$gg});
$Nreal = ($go1 eq $go2) ? $p->{$gg} : $pdiff->{$gg};
if (analyzeThis(
$Nreal,
$mean{$gg}
)) {
$stats->[$G]->{pair} = $gg;
$stats->[$G]->{zsc} = zscore(
$Nreal,
$mean{$gg},
$SD{$gg}
);
$stats->[$G]->{pval} = 2 * Statistics::Distributions::uprob(abs($stats->[$G]->{zsc}));
$stats->[$G]->{pval} = 0.000000000000000000000001 if $stats->[$G]->{pval} == 0;
$G++ if defined($stats->[$G]->{zsc}) and defined($stats->[$G]->{pval});
	}}}
$stats = p_adjust($stats);
for $G(0..$#{$stats}) {
$gg = $stats->[$G]->{pair};
$stats_by_pair->{$gg}->{zsc} = $stats->[$G]->{zsc};
$stats_by_pair->{$gg}->{pval} = $stats->[$G]->{pval};
$stats_by_pair->{$gg}->{pfdr} = $stats->[$G]->{pfdr};
}
	}

sub analyzeThis {
my($Nreal, $Nexp) = @_;

return(0) if ($Nreal < $minRealLinksForPvalue) and ($Nexp < $minExpLinksForPvalue);
return(1);
}

sub zscore {
    my($Nreal, $Nexp, $sd) = @_;
    return undef if !$sd;
    return ($Nreal - $Nexp) / $sd;
}

sub p_adjust { #method = FDR (Benjamini & Hochberg, 1995)
my(@pvalues) = @_;

@{$stats} = sort {$a->{pval} <=> $b->{pval}} @{$stats};
$M = scalar(@{$stats});
$stats->[$#{$stats}]->{pfdr} = $stats->[$#{$stats}]->{pval};
for $i(1..($#{$stats} - 1)) {
$stats->[$i]->{pfdr} = $stats->[$i]->{pval} * ($M / ($#{$stats} - $i));
$stats->[$i]->{pfdr} = 1.0000000000 if $stats->[$i]->{pfdr} > 1;
}
return($stats);
}

sub count_in_groups {
    my($_link, $i) = @_;
    for $Astart(keys(%{$_link})) {
	for $Aend(keys(%{$_link->{$Astart}})) {
	    $a[$pl{prot1}] = $Astart; $a[$pl{prot2}] = $Aend;
	    $a[$pl{fbs}] = $_link->{$Astart}->{$Aend};
	    processLink(\@a);
	}
    }
    return if $i =~ /[a-z]/i;
    for $pR(keys(%{$p})) {
	next if $pR !~ m/_vs_/i;
	$pRandom->{$pR}->[$i] = $p->{$pR};
	$pdiffRandom->{$pR}->[$i] = $pdiff->{$pR};
    }
}

sub processLink {
    my($array) = @_;

    my @a = @{$array};

    ($p1, $p2) = ($a[$pl{prot1}], $a[$pl{prot2}]);
    next if !defined($p1);
    $co++;
    for $go1(keys(%{$GO->{$p1}})) {
	$p->{$go1}++; # $p IS THE GENERAL POINTER TO ALL go, BOTH SINGLETONS AND PAIRS
	$startdir->{$go1}++; 
	$genelist->{start}->{$go1}->{uc($sym->{lc($p1)})} = 1;
	$genelist->{total}->{$go1}->{uc($sym->{lc($p1)})} = 1;
    }
    for $go2(keys(%{$GO->{$p2}})) {
	$p->{$go2}++;
	$enddir->{$go2}++;
	$genelist->{end}->{$go2}->{uc($sym->{lc($p2)})} = 1;
	$genelist->{total}->{$go2}->{uc($sym->{lc($p2)})} = 1;
    }
    for $go1(sort {$a cmp $b} keys(%{$GO->{$p1}})) {
	for $go2(sort {$a cmp $b} keys(%{$GO->{$p2}})) {
	    $co_all_pw++;
	    $tag = join($join, (sort {$a cmp $b} ($go1, $go2)));
	    $p->{$tag}++;
	    if ((defined($GO->{lc($p1)}->{$go1}) and defined($GO->{lc($p2)}->{$go1}))
		or 
		(defined($GO->{lc($p1)}->{$go2}) and defined($GO->{lc($p2)}->{$go2}))) {
		#$pshare->{$tag}++; 
	    } 
	    else {
		$pdiff->{$tag}++;
	    }
	}
    }
}

sub randomizeNetwork {
#THE PROCEDURE IS IMPLEMENTED ACCORDING TO Maslov&Sneppen(2002) PMID: 11988575
#my($link) = @_;

my($swaps, $nlinks, $Rlink, $Astart, $Aend, @Astarts, $Bstart, $Bend, @endsBstart, @Bstarts, $Ascore, $Bscore, $tt, @test, $time, %nodeCnt, $signature, %copied_edge);

$time = time();
undef %nodeCnt;
for $Astart(keys(%{$link})) {
for $Aend(keys(%{$link->{$Astart}})) {
$signature = join('-#-#-#-', sort {$a cmp $b} ($Astart, $Aend)); #protects against importing duplicated edges
next if defined($copied_edge{$signature});
$Rlink->{$Astart}->{$Aend} = $link->{$Astart}->{$Aend};
$copied_edge{$signature} = 1;
$nlinks++;
$nodeCnt{$Astart} = $nodeCnt{$Aend} = 1;
}}
print STDERR "Before randomization: \n $nlinks links, ".scalar(keys(%{$link}))." primary (outgoing)  nodes  \n".scalar(keys(%nodeCnt))." total nodes\n" if $main::debug;

@Astarts = keys(%{$Rlink});
while ($Astart = splice(@Astarts, rand($#Astarts + 1), 1)) {
@Bstarts = keys(%{$Rlink});
next if !$Astart;
for $Aend(keys(%{$Rlink->{$Astart}})) {
next if !$Aend or
!defined($Rlink->{$Astart}->{$Aend});

while ($Bstart = splice(@Bstarts, rand($#Bstarts + 1), 1)) {
next if (!$Bstart or
($Bstart eq $Astart) or ($Bstart eq $Aend) or
defined($Rlink->{$Bstart}->{$Aend}));

@endsBstart = keys(%{$Rlink->{$Bstart}});
while ($Bend = splice(@endsBstart, rand($#endsBstart + 1), 1)) {
next if (
!$Bend or
($Astart eq $Bend) or
!defined($Rlink->{$Bstart}->{$Bend}) or
defined($Rlink->{$Astart}->{$Bend}));

$Ascore = $Rlink->{$Astart}->{$Aend};
$Bscore = $Rlink->{$Bstart}->{$Bend};
delete $Rlink->{$Astart}->{$Aend};
delete $Rlink->{$Bstart}->{$Bend};
$Rlink->{$Astart}->{$Bend} = $Ascore;
$Rlink->{$Bstart}->{$Aend} = $Bscore;
$swaps++;
last;
}
last;
}}}
print STDERR "After randomization: ".scalar(keys(%{$Rlink}))." primary nodes, ".$swaps." swaps done in ".(time() - $time)." s\n" if $main::debug;
$time = time();
return $Rlink;
}

sub readLinks {
    my($table) = @_;
    my(@a, $thescore);
    open IN, $table or die "Could not open $table\n";
    while ($_ = <IN>) {
if ($Ntotal++ < 1) {
    readHeader($_) if m/prot/i or m/gene/i;
    my $scorecol = $pl{fbs};
    $scorecol = $pl{$pms->{'sc'}} if defined($pms->{'sc'});
}
	last if $Ntotal > $Ntestlines;
	chomp;
	@a = split("\t", $_);
	$thescore = $a[$scorecol];
	$thescore = ($a[$pl{'fbs_max'}] - $a[$pl{'ppi'}]) if ($pms->{'sc'} eq 'wppi'); #CAN TAKE A SUM OF COLUMNS AS A SCORE
	$thescore = ($a[$pl{'hsa'}] + $a[$pl{'mmu'}] + $a[$pl{'rno'}]) if ($pms->{'sc'} eq 'mammal');
	next if $thescore < $FBScutoff;
	$a[$pl{prot1}] = lc($a[$pl{prot1}]); $a[$pl{prot2}] = lc($a[$pl{prot2}]);
	next if !$a[$pl{prot1}] or !$a[$pl{prot2}];
	next if !$considerAllLinks and (!defined($GO->{$a[$pl{prot1}]}) or !defined($GO->{$a[$pl{prot2}]}));
	    $link->{lc($a[$pl{prot1}])}->{lc($a[$pl{prot2}])} = $a[$pl{fbs}];
    }
    close IN;
}

sub readSymbols {
    my($table) = @_;
    open IN, $table or die "Could not open $table\n";
    while (<IN>) {
	chomp;
	@a = split("\t", $_);
	$sym->{lc($a[$pl{gene2sym}])} = $a[$pl{sym}];
	$descr->{lc($a[$pl{gene2sym}])} = $a[$pl{descr}];
    }
    close IN;
}

sub readGO {
    my($table) = @_;
    open IN, $table or die "Could not open $table\n";
    while (<IN>) {
	chomp;
	@a = split("\t", $_);
	next if ((defined($pl{spec})) &&  lc($a[$pl{spec}]) ne lc($spe));
	$GOmembers->{$a[$pl{GO}]}->{lc($a[$pl{gene}])} = 1;
	$GOlist->{lc($a[$pl{gene}])} = 1;
	next if (lc($GOkind) ne 'all') and (lc($a[$pl{kind}]) ne lc($GOkind));
	next if (defined(%allowedGOLevel) and !defined($allowedGOLevel{lc($a[$pl{level}])}));
	next if !$a[$pl{gene}] or !$a[$pl{GO}];
	$GO->{lc($a[$pl{gene}])}->{$a[$pl{GO}]} = 1;
	$sym->{lc($a[$pl{gene}])} = lc($a[$pl{gene}]);
	$sym->{lc($a[$pl{gene}])} = $a[$pl{sym}]  if $filterDE2;
	$GOtitle->{$a[$pl{GO}]} = $a[$pl{title}];
	$GOkind->{$a[$pl{GO}]} = $a[$pl{kind}];
    }
    close IN;
}

sub parseParameters ($) {
    my($parameters) = @_;
    my($_1, $_2);

#print "$parameters\n";
    $_ = $parameters;
    while (m/\-(\w+)\s+([A-Za-z0-9.-_+]+)/g) {
	$_1 = $1;
	$_2 = $2;
	if ($_2 =~ /\+/) {push @{substr(lc($_1), 0, 4)}, split(/\+/, lc($_2));}
	else {$pms->{substr(lc($_1), 0, 4)} = $_2;}
    }
    if (defined($pms->{'sort'})) {
	while ($pms->{'sort'} =~ m/([a-z0-9]){1}/sig) {
	    $sorts{lc($1)} = 1; 
	    $sorts{uc($1)} = 1;
	}
    }
if (!defined($_1)) {
die "Input: the script requires 2 files to be defined within the script:
  1) The protein network, \$fc\{species\} for your species in the script\n
  2) The gene groups, \$GOtable.  The format of this file is species-dependent(!) and governed
     by the \$pl\{\} array.\n
           For Human (hsa), it is:\n
           \<Gene_ID\> \<Group_ID\> \<Species\> \<Type_of_group\> \<Group_annotation\>\n
  3) A file with the gene symbol \/ identifier mappings, \$symtable\{species\}\n

 As column positions in both files are hard coded in the script double check them\!\n

 Output: the script produces two ouput files:\n
 -\> the first file includes statistics about the number of connections\n
 -\> the second file can be used as an input for cytoscape\n

 Parameters:\n
  -sp  Species\n
  -ki  Kind of group, e.g. MET or SIG\n
  -co  Cutoff for Function link strength\n
  -sc  Score column to use in FunCoup network\n\n";
}
return undef;
}

sub readHeader {
    my($head) = @_;
    chomp($head);
    @arr = split("\t", $head);

    for $aa(0..$#arr) {
	$arr[$aa] =~  s/^[0-9]+\://i;	$arr[$aa] =~  s/^llr_//i;
	$pl{lc($arr[$aa])} = $aa;
    }
    $pl{prot1} = $pl{protein1} if defined($pl{protein1});
    $pl{prot2} = $pl{protein2} if defined($pl{protein2});
    $pl{prot1} = $pl{gene1} if defined($pl{gene1}) and !defined($pl{protein1});
    $pl{prot2} = $pl{gene2} if defined($pl{gene2}) and !defined($pl{protein2});

    return undef;
}



