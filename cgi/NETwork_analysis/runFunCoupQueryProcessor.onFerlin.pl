#!/usr/bin/perl
#use strict vars;
use FileHandle;

#exit;
$glob_pms = parseParameters(join(' ', @ARGV));
$prog = 'FunCoup_software/FunCoupQueryProcessor.pl';
#$CAC = '005-06-32';
$workdir = $ENV{HOME}.'/mou0/';
$coff = $glob_pms->{'coff'} ? $glob_pms->{'coff'} : 4;
$spe = $glob_pms->{'spec'};
$dire = $glob_pms->{'dire'} ? $glob_pms->{'dire'} : 'New';
#$data = defined($glob_pms->{'data'}) ? $glob_pms->{'data'} : 1;
#####
#$spe = 'mouse' if ($glob_pms->{'spec'} eq 'mouse');
$viet = 1;
$nodesList = '_nodes';
$nodesList = $ENV{SP_HOSTFILE};
#$nodesList = '/var/easy/f-pop/user/hostlist/andale/SPnodes.030421185524';
print $ENV{SP_HOSTFILE}."\n";
print $ENV{SP_NODES}."\n";
$ifGOfc = ' -gofc 1 ' if $glob_pms->{'gofc'};
chdir $workdir;

defineData($spe);
#$input->{'zfish'}->{'allNamesFile'} = 'FunCoup_resources/Genes.zfish.ZfinID';
#$input->{'dre'}->{'allNamesFile'} = 'FunCoup_resources/Genes.zfish.ZfinID';
#$input->{'zfish'}->{'allNamesFile'} = 'FunCoup_resources/Genes.zfish.notInTheNewOrthoMaps';
#$input->{'dre'}->{'allNamesFile'} = 'FunCoup_resources/Genes.zfish.notInTheNewOrthoMaps';
if (lc($glob_pms->{'mode'}) eq 'test') {
$spe = 'human' if !$glob_pms->{'spec'};
$dire = $glob_pms->{'dire'} ? $glob_pms->{'dire'} : 'NEw';
}

$file = 	$input->{$species{$spe}}->{'allNamesFile'};
$preyfile = 	$input->{$species{$spe}}->{'allNamesFile'};
$preyfile = $input->{'resource_dir'}.'Genes.human.GO' if $glob_pms->{'gofc'};
open IN, 'wc '.$nodesList.' | ';
$_ = <IN>;
@b = split();
$nparts = $b[0];
close IN;
open IN, 'wc '.$file.' | ';
$_ = <IN>;
@a = split();
close IN;
$length = $a[0];
$S = $length ** 2 / (2 * $nparts);
open NODES, $nodesList;
while ($node = <NODES>) {
chomp $node;
#for $x(1..$nparts) {
$x++;
$a = 0.5;
$b = $w - 0.5;
$c = -$S;
$D = ($b**2 - 4*$a*$c) / (4*$a**2);
$height = (-$b + sqrt($D)) / (2*$a);
#sqrt($length**2 / (2*$nparts*($x -  0.5)));
#die if (int($length**2 / (2 * $nparts)) != int((($x - 1) * $height**2) + ($height**2 / 2)));
$baits[$x] = $spe.'.Baits.'.$$.'.'.$x;
print "Creating sublist $baits[$x]\t".(int($w + $height) + 1)."\t".int($w)."\t".(int($height))."\n";
system("head -n ".(int($w + $height) + 1)." $file | tail -n ".(int($height) + 1)." >  ".$baits[$x]);
$w += $height;
#-coff $coff
$comm = " /usr/heimdal/bin/rsh -F -e -l andale $node 'cd $workdir; $prog -spec $spe -mode onfly -list cross -data 1 -prey $preyfile -bait ".$baits[$x]." -viet $viet -dire $dire -outd $outd{$spe} -out_ $spe.$node.$$.Bait$x.fc.out -coff $coff ".$ifGOfc."; module add easy; sprelease;' &";
print($comm."\n");
system($comm);
}

sub defineData {
my($spe) = @_;
#my($class);
$outd{'human'} = 	'm8';
$outd{'mouse'} = 	'm9';
$outd{'rat'} = 		'm10';
$outd{'fly'} = 		'm11';
$outd{'worm'} = 	'm12';
$outd{'yeast'} = 	'm13';
$outd{'thaliana'} = 	'm14';
$outd{'ciona'} = 	'm15';
$outd{'zfish'} = 	'm11';

$TSScript = 'FunCoup_software/buildAnFCTrainingSet.awk';
$NScript = 'FunCoup_software/buildAnFCNodeFile.awk';
$RealScript = 'FunCoup_software/buildAnFCRealFile.awk';
$species{'zfish'} = 'dre';
$species{'ciona'} = 'cin';
$species{'human'} = 'hsa';
$species{'mouse'} = 'mmu';
$species{'rat'} = 'rno';
$species{'fly'} = 'dme';
$species{'worm'} = 'cel';
$species{'yeast'} = 'sce';
$species{'thaliana'} = 'ath';
$org{'dre'} = 'zfish';
$org{'cin'} = 'ciona';
$org{'hsa'} = 'human';
$org{'mmu'} = 'mouse';
$org{'rno'} = 'rat';
$org{'dme'} = 'fly';
$org{'cel'} = 'worm';
$org{'sce'} = 'yeast';
$org{'ath'} = 'thaliana';

$input->{'resource_dir'} = 'FunCoup_resources/';
$spe = $species{$spe} if $species{$spe};

undef $evidenceHeader;
$fcExt = '.fc';
$nodesExt = '.nodes';
$pms->{'species'} = $spe;

$input->{$spe}->{'infile'}->{'random'} = '';
for $class(@{$input->{$spe}->{'classes'}}) {
$input->{$spe}->{'outfile'}->{$class} = $input->{'temp_dir'}.$org{$spe}.'.'.uc($class);
}
$input->{$spe}->{'allNamesFile'} = $input->{'resource_dir'}.'Genes.'.$org{$spe};
#$input->{'hsa'}->{'allNamesFile'} = $input->{'resource_dir'}.'Genes.human.250';
#$input->{'dme'}->{'allNamesFile'} = $input->{'resource_dir'}.'Genes.fly_300';
#$input->{'sce'}->{'allNamesFile'} = $input->{'resource_dir'}.'Genes.yeast.1000';
#$input->{'cel'}->{'allNamesFile'} = $input->{'resource_dir'}.'Genes.worm_300';
$input->{$spe}->{'series'} = $org{$spe}.'.'.uc(join('_', @{$input->{$spe}->{'classes'}}));
$input->{$spe}->{'sleepingBN'} = $org{$spe}.'.'.uc(join('_', @{$input->{$spe}->{'classes'}})).'.sleepingBN';
$input->{$spe}->{'novelset'} = join('_', ($pms->{'species'}, @{$pms->{'counterpart'}}, $glob_pms->{'bait'}, 'vs', $glob_pms->{'prey'})).'.fc';
return($pms, $input, $spe);
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
\n\n" if scalar(keys(%{$pms})) < 1;
$pms->{'spec'} = 'human' if !$pms->{'spec'};
#$pms->{'clas'} = 'kegg' if !$pms->{'clas'};
$pms->{'mode'} = 'train' if !$pms->{'mode'};
#$pms->{'coff'} = -10 if !defined($pms->{'coff'});

return $pms;
}

