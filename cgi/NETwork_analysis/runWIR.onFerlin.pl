#!/usr/bin/perl
#use strict vars;
use FileHandle;

#exit;
$pms = parseParameters(join(' ', @ARGV));
$prog = 'pl/wir.pl';
$prog = 'pl/WiringViaPartCorr.pl';
#$prog = 'WiringViaPartCorr.pl';
$metr = $pms->{'metr'};
$data = $pms->{'data'};

$workdir = $ENV{HOME};
#$workdir = '/afs/pdc.kth.se/home/a/andale/pl/';
#$workdir = '/afs/pdc.kth.se/home/a/andale/m11/TCGAfresh/'; $viet = 1;
$cancer_type = 'OV';
#$cancer_type = 'GBM';
$nodesList = '_nodes';

$nodesList = $ENV{SP_HOSTFILE};
print $ENV{SP_HOSTFILE}."\n";
print $ENV{SP_NODES}."\n";
chdir $workdir;
#defineData($spe);
open IN, 'wc '.$nodesList.' | ';
$_ = <IN>;
@b = split();
###$nparts = 4;
$nparts = $b[0];
close IN;
#>>>>>>>>#SET THIS VALUE:

$length = 13500; # TCGA Affy
$length = 18500;
$length = 18500 if ($pms->{'data'} =~ m/Agi/i);
$length = 21000 if ($pms->{'data'} =~ m/_/);
$length = 16500 ; # for vanAgthoven2009.GSE14513
$length = 25030 ; # for mouse
$length = 18500 ; #cd4plus
$length = 16500 ; # TCGA fresh

#>>>>>>>>>>>>>>>>>>>>>>>>>>>

$S = $length ** 2 / (2 * $nparts);
open NODES, $nodesList;
while ($node = <NODES>) {
###for $node(1..$nparts) {
chomp $node;
$x++;
$a = 0.5;
$b = $w - 0.5;
$c = -$S;
$D = ($b**2 - 4*$a*$c) / (4*$a**2);
$height = (-$b + sqrt($D)) / (2*$a);
$start = (int($height) + 1);
$end = (int($w + $height) + 1) - $start;

#$length = (int($height) + 1);
$end = (int($w + $height) + 1);
$start = (int($w + $height) + 1) - (int($height) + 1);

$w += $height;

#$comm = " /usr/heimdal/bin/rsh -F -e -l andale $node 'cd $workdir; $prog -mode prim -star $start -end_ $end -metr $metr -data $data ; module add easy; sprelease;' &";
$comm = " /usr/heimdal/bin/rsh -F -e -l andale $node 'cd $workdir; $prog -mode prim -type $cancer_type -star $start -end_ $end ; module add easy; sprelease;' &";
print($comm."\n");
system($comm);
}

sub parseParameters ($) {
my($parameters) = @_;
my($key, $found, %found, $_1, $_2, $pms);

print "$parameters\n";
$_ = $parameters;
while (m/\-(\w+)\s+([A-Za-z0-9.-_+]+)/g) {
$_1 = $1;
$_2 = $2;
if ($_2 =~ /\+/) {push @{substr(lc($_1), 0, 4)}, split(/\+/, lc($_2));}
else {$pms->{substr(lc($_1), 0, 4)} = $_2;}
}
die "\nNot enough parameters! Please specify:\n
-mode :	one of {collect, train, classify, onfly, post}. Maybe, you should use 'jobList' procedure instead\n
-spec :  organism, one of {".keys(%org)."} species (default: human)\n
-clas :  the class of functional coupling, one of ".(($pms->{'spec'}) ? 'specify organism' : join(', ', @{$input->{$pms->{'spec'}}->{'classes'}}))." (default: KEGG)\n
-out_ : an output file name (default: STDOUT)
\tOptional:
-list : which procedure to use to generate protein pairs for the analysis on-fly\n\tOne of: readin , movwin , allrand , cross - the latter needs also 'prey' and 'bait' with protein names; the 'readin' needs a list of ready pairs as 'bait'Calcyon/All_related.mouse
-coff :  set a cutoff for the final Bayesian score for filteing the output, (default: no filtering)\n
-data : if to attach raw data to the output lines\n
-bait :	file with genes to find FC links to (can be omitted if mode=train OR list != cross)\n
-prey : file with genes to find FC links from  (can be omitted if mode=train OR list != cross). Can be set to 'ALL', then 'viet' should be TRUE\n
-viet : if to apply parallelization procedure by Viet theorem: assumes computing only lower triangle of ALL x ALL matrix\n
-file : file with previously generated output. This neede for post-processin (set with '-mode post')\n
-dire : an alternative directory with training sets, located at m5 disk\n
-set_ : 'onlyppi' if only PPI data should be used\n
-debu : debug (1...3)
\n\n" if 1 == 2 and scalar(keys(%{$pms})) < 1;
$pms->{'spec'} = 'human' if !$pms->{'spec'};
#$pms->{'clas'} = 'kegg' if !$pms->{'clas'};
$pms->{'mode'} = 'train' if !$pms->{'mode'};
#$pms->{'coff'} = -10 if !defined($pms->{'coff'});

return $pms;
}
