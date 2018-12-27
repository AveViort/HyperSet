#!/usr/bin/perl
use strict vars;
#replaceable project-specific WD modules that define data and important specific details
#use m8::WIR::WD;
use mou3::Projects::NETwork_analysis::NET;

my($doRandomization, $Niter, $Ntestlines, $debug, $id);
our(@mtr, $borders, $value_index, $pms, $debug);
parseParameters(join(' ', @ARGV));

srand();
$debug = 1; #############

#$methWD::data = 0;
define_data('hsa');
compareNets($net1, $net2);

sub compareNets {
my($net1, $net2);

return();
}


sub define_data {
#our();

$spe = 'hsa';
$table->{refnet}->{'hsa'} = 'm14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new';
$table->{expression}->{'hsa'} = '/afs/pdc.kth.se/home/a/andale/m15/RAW/chemores.Agi41000.txt';
$table->{'en2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/Name_2_name/SANGER47.externalGeneID_2_ENS_2_DE.Labels.New.human.txt'; $pl->{'en2sym_hsa'}->{'id'} = 0; $pl->{'en2sym_hsa'}->{'sym'} = 4;
#$table->{'cg2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CANCER/TCGA/Methyl/METADATA/JHU_USC__IlluminaDNAMethylation_OMA003_CPI/jhu-usc.edu_GBM.IlluminaDNAMethylation_OMA003_CPI.1.adf.txt'; $pl->{'cg2sym_hsa'}->{'id'} = 0; $pl->{'cg2sym_hsa'}->{'sym'} = 2;
$table->{'ma2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/Name_2_name/ENS_RefSeq_Agi.human.txt'; $pl->{'ma2sym_hsa'}->{'id'} = 5; $pl->{'ma2sym_hsa'}->{'sym'} = 3;



%coff = ( #various cutoffs
'fbs_max' => 3, 
'hsa' => 0,
'mmu' => 0,
'ppi' => 0, 
'pearson' => 0.001,
'mut-mut' => 0.001,
'mut-exp' => 0.001,
'mut-met' => 0.001,
'exp-mut' => 0.001,
'met-mut' => 0.001,
'exp-met' => 0.35,
'met-exp' => 0.35,
'met-met' => 0.35, 
'exp-exp' => 0
);
$sign_cutoff{'Fratio'} = 4;
$coff{'partial'} = 0.3;
@{$link_fields->{'primary'}} = ('exp-exp'); #, 'exp-met', 'met-exp', 'met-met', 'mut-exp', 'mut-met', 'exp-mut', 'met-mut', 'mut-mut');
@{$link_fields->{'refnet'}} = ('fbs_max', 'hsa', 'mmu', 'rno', 'ppi', 'pearson');
$filedir = '/afs/pdc.kth.se/home/a/andale/m15/NET/';

$table->{primary}->{$spe} = 'm15/NET/Primary..WIR'; #'m8/PrimaryPAIRS..at_9755.WIR'; #
}
