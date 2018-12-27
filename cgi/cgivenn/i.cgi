#!/usr/bin/perl -w
##################################################################################
## Latest changes -
# lines 1073 - 1075, 1093-1095, 1226-1229, 1236-1279 
# lines 1398 -1474 -- table header and stats for ags input file
# 887,929-940 - adding hrefs to nea-table fgs terms 












####################################################################################

use warnings;
# use strict;
use Net::SMTP;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use HStextProcessor;
use HSconfig;
use HS_html_gen;
use HS_bring_subnet;
use HS_cytoscapeJS_gen;
use HS_SQL;

#use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
#use lib "/var/www/html/research/andrej_alexeyenko/users_tmp";

use lib "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
use lib "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp";

use NET;
use venn_click_points;
use constant SPACE => ' ';

# check how long jobs can take and what happens when finished...
# checkAndSubmit?

#############################
# networks from SQL
# re-list uploaded files after a new upload 

# login for project protection but login is not required (?...)
# user accounts, log in /out, auto-registration
# universal file download/upload
# make selectable FGS members
# (users') error processing
# NEA matrix

# R syntax for creating the mouse file:
# P.matrix.NoModNodiff_wESC <- P.matrix[,colnames(P.matrix)[-grep("VMN|SMN|Rfx|TGF|4.5|5.6|6.5|7.5|10|Cycl|Alk|Fox|_SC", colnames(P.matrix), fixed=F, ignore.case=F)]]
# P.matrix.NoModNodiff_wESC <- P.matrix[,colnames(P.matrix)[-grep("VMN|SMN|Rfx|TGF|4.5|5.6|6.5|7.5|10|Cycl|Alk|Fox|_SC", colnames(P.matrix), fixed=F, ignore.case=F)]]
# write.table(P.matrix.NoModNodiff_wESC, file="P.matrix.NoModNodiff_wESC.txt", quote=F, sep="\t", col.names=T, row.names=T)
# my $nnn = 0;
no warnings;
my $debug = 0;
$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $conditions, $pl, $nm, $conditionPairs, $pre_NEAoptions, $itemFeatures, 
$savedFiles,  $fileUploadTag, $usersDir, $usersTMP, $sn, $URL);
our $NN = 0;
my $file_stat_ext = ".file_stat";
my($mode, @genes, $Genes, $type, $AGS, $FGS, $step, $NEAfile, @names, $mm, $callerNo, $AGSselected, $FGSselected, $NETselected);
my ($upload_err_stat, $upload_err_msg);
our $species;
our $restoreSpecial = 0; # see sub tmpFileName()
$fileUploadTag = "_table";
#return 0;
$dbh = HS_SQL::dbh();
our $q = new CGI;
# print system("rm -r /var/www/html/research/andrej_alexeyenko/users_tmp/*"); exit;
# print system("kill  19362"); print system("kill  19379"); print system("kill  18605"); print system("kill  17927"); print system("kill  17927"); exit;
# print system("rm  /var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/* "); exit;
# print  system("chmod a+w /var/www/html/research/andrej_alexeyenko/users_tmp/dmart/"); exit; 
## https://www.evinet.org/cgi/i.cgi?mode=standalone&request=information&source=pwc&prot1=RHOD 
@names = $q->param;
# HS_bring_subnet::bring_subnet($q->param("subNetURLbox"));
$species 	= $q->param("species");
#$species 	= '' if !defined($species);
#print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA<br>$species" if $debug;
print "Species: $species" if $debug; 
# use HS_html_gen;
 # print "Content-type: text/html\n\n"; 
 #################
 if ($q->param("jid") eq '578827557974') {$HSconfig::display->{nea}->{showcontextMenus} = 1; $HSconfig::display->{nea}->{showcontextMenus} = 1;}
 #################
 
if (($q->param("request") eq 'information') and ($q->param("source") eq 'pwc') and $q->param("mode") eq 'standalone') {
print "Content-type: text/html\n\n";
my $url = $q->query_string;
$url =~ s/mode\=standalone\;//;
$url = 'tab_id=analysis_type_ne;mode=begin';
my $cn;
# = $HS_html_gen::mainStart.' mmmmmmmmmmmmmmmmm'.$url.'<script  type="text/javascript">// $( "#main_nea" ).load( "cgi/i.cgi?'.$url.'");</script>'.$HS_html_gen::mainEnd;
my($node2, $evi, $co, $pair);
my $node1 = $q->param("prot1");
my $species = 'hsa';
my $Genes;
$Genes->{$node1} = 1;
 $HSconfig::network->{$species} = 'pwc8';
my $links = HS_bring_subnet::nea_links1($Genes, $species);
HS_bring_subnet::pubmed();
				
# print $node2.'<br>';
$cn .= '<table border=1>';
for $pair(keys(%{$links})) {
$cn .= '<tr>';
$evi = HS_html_gen::URLlist($links -> {$pair});

$cn .= '<td>'.join('</td><td>', (
$links -> {$pair}->{'prot1'},
$links -> {$pair}->{'interaction_type'},
$links -> {$pair}->{'prot2'},
'<span class=\'pubmed\'>'.'</span>'.$evi
)).'</td>';
$cn .= '</tr>'."\n";
}
$cn .= '</table>';
HS_html_gen::mainStart();
$HS_html_gen::mainStart =~ s/EviNet\:\snetwork\sanalysis\smade\sevident/Interactors/;
print  $HS_html_gen::mainStart.$cn.$HS_html_gen::mainEnd;
exit;
}




our $projectID = $q->param("project_id");
# $projectID 		= '' if !defined($projectID);
if ($projectID =~ /^\d+/){ $projectID="edited".$projectID;}
print $projectID;
our $GSEA_pvalue_coff = 0.01;
our $NEA_FDR_coff = $q->param("fdr") ? $q->param("fdr") : 0.35;
our $NEA_Nlinks_coff = $q->param("nlinks") eq "" ? 1 : $q->param("nlinks");
$HSconfig::printMemberGenes = $q->param("printMemberGenes");
$usersTMP = $HSconfig::usersTMP.$projectID.'/';
$usersDir = $HSconfig::usersDir.$projectID.'/';
system("mkdir $usersDir 1>/dev/null 2>/dev/null");
system("mkdir $usersTMP 1>/dev/null 2>/dev/null");
$step = '';
$mode 		= $q->param("analysis_type");
$type 		= $q->param("type");
$type 		= '' if !defined($type);
if (defined($q->param("tab_id"))) {
$step = 'mainTab';
}
if ($q->param("action") eq 'sbmRestore') {
$step = 'saved_nea';
} 
elsif ($q->param("action") eq 'display-archive') {$step = 'display-archive';} 
# https://www.evinet.org/cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout=arbor;showself=showself;project_id=stemcell;species=mmu;jid=883450573889
elsif ($q->param("action") eq 'sbmSubmit') {
$step = 'executeNEA';
} 
if (($q->param("action") =~  m/^subnet\-([0-9]+)$HS_html_gen::actionFieldDelimiter1([0-9A-Z_\:\.\-\(\)\=]+)$HS_html_gen::actionFieldDelimiter1([0-9A-Z_\:\.\-\(\)\=]+)$/) or ($q->param("action") =~  m/^subnet\-([0-9]+)$HS_html_gen::actionFieldDelimiter2([0-9A-Z_\-]+)$HS_html_gen::actionFieldDelimiter2([0-9A-Z_\-]+)/)) {
$step = 'shownet';
($callerNo, $AGS, $FGS) = ($1, $2, $3);
} 
elsif ($q->param("action") =~ m/vennsubmitbutton-table-ags-/) {$step = 'create_venn';} 
elsif ($q->param("action") eq 'updatebutton2-venn-ags-ele') { $step = 'update_venn';} 
elsif ($q->param("action") eq 'listbutton-table-ags-ele') {$step = 'list_ags_files';} 
elsif ($q->param("action") =~ m/deletebutton-table-ags-/) {$step = 'delete_ags_files';} 
elsif ($q->param("action") eq 'sbmSavedCy') {$step = 'saved_json';} 
elsif ($q->param("action") eq 'submit-save-cy-json3') {$step = 'save_json_into_project';} 
## gidconvert
#elsif ($q->param("action") =~ m/cidsubmitbutton-table-ags-/ ) {$step = 'convert_geneids';}
elsif ($q->param("action") eq 'cidSubmit' ) {$step = 'convert_geneids';}
elsif ($q->param("action") eq 'agsuploadbutton-table-ags-ele') {
for $mm(@names) {
if ($mm =~ m/$fileUploadTag$/i) {
#saveFiles($q->param($mm), $mm)  if ($mm eq "ags_table") and $q->param($mm);
#CGIVENN#
 ($upload_err_stat, $upload_err_msg) = saveFiles($q->param($mm), $mm)  if ($mm eq "ags_table") and $q->param($mm);
}}
$step = 'list_ags_files';
$step = 'wrong_upload_format' if ($upload_err_stat);
} 
$type = $step if ($step eq 'save_json_into_project')
 or ($step eq 'create_venn')
 or ($step eq 'update_venn')
 or ($step eq 'list_ags_files')
 or ($step eq 'delete_ags_files')
 or ($step eq 'wrong_upload_format')
 or ($step eq 'convert_geneids')
 or ($q->param("step") eq 'ags_select');
@{$AGSselected} = $q->param("AGSselector");
@{$FGSselected} = $q->param("FGSselector");
@{$NETselected} = $q->param('NETselector');
#CGIVENN#

my($pg, $lst);
for $lst('sgs_list', 'cpw_list') {
if ($q->param($lst)) {
$pg = HStextProcessor::parseGenes($q->param($lst), SPACE);
if (ref($pg) eq 'ARRAY') {
push @{$AGSselected}, @{$pg} if ($lst eq "sgs_list"); #parse the IDs in the AGS text  box
push @{$FGSselected}, @{$pg} if ($lst eq "cpw_list"); #parse the IDs in the FGS text  box
} 
else {
print HS_html_gen::errorDialog('error', $HSconfig::listName{$lst}, $q->param($lst).": this was invalid input.<br>Gene/protein IDs shall only contain letters, digits, dash, underscore, and dot", $HSconfig::listName{$lst}); exit;
#die;
}
}}
# push @{$FGSselected}, @{HStextProcessor::parseGenes($q->param('cpw_list'), SPACE)} if ($q->param("cpw_list")); #parse the IDs in the FGS text  box
	
my $fl;	
if ($q->param("use-venn")) {
for $fl($q->param("from-venn")) {
push @{$AGSselected}, $q->param("VennSelector_gene_list_".$1) if ($fl =~ m/^gene_list_([pm]+)$/i);
}}
our $delimiter;
	if (defined($q->param("gene_column_id"))) {
my $currentAGS = $usersDir.$savedFiles -> {data} -> {"ags_table"};
$pl->{$currentAGS}->{gene} = $q->param("gene_column_id")  - 1;
$pl->{$currentAGS}->{group} = $q->param("group_column_id") - 1;
$pl->{$currentAGS}->{delimiter} = $q->param("delimiter");
$delimiter = $pl->{$currentAGS}->{delimiter};
$delimiter = "\t" if lc($delimiter) eq 'tab';
$delimiter = ',' if lc($delimiter) eq 'comma';
$delimiter = ' ' if lc($delimiter) eq 'space';
$pl->{$usersDir.$q->param('selectradio-table-ags-ele')} = $pl->{$currentAGS};
			}
			
print "Content-type: text/html\n\n" if ($step ne 'shownet');
			
my $content = '';
# $content .=  $projectID.'<BR>MMMMMMMMMMMMMMMMMMMMM';
$content .= 'AGS input: <br>'.join('<br>', @{$AGSselected}) if $debug;			
print '<br>Submitted form values: <br>'.$q->query_string.'<br>'  if $debug; 
if ($step eq 'mainTab') {
$content .= '<br>Submitted tab_id: <br>'.$q->param("tab_id").'<br>' if $debug;
$content .= generateTabContent($q->param("tab_id"));
} 
else {
if ($step eq 'executeNEA') {
my $executed = executeNEA();
if ($executed =~ m/[A-Z\>\<]+/i) {
print $executed;
exit;
}
$content .= printNEA($executed, $projectID);
}
elsif (($step eq 'display-archive') and $projectID) {
$content .= printNEA('project', $projectID);
}
elsif ($step eq 'saved_nea') { #form_saved_nea
$content .= jobFromArchive($projectID, $q->param("jid"));  
# $content .= '<FORM id="form_ne"  action="cgi/i.cgi" method="POST" enctype="multipart/form-data" autocomplete="on" >'.printAccordion($q->param("jid")).'</FORM>';  
}
elsif ($step eq 'saved_json') {
$content .= restoreNodesAndEdges($usersTMP, $q->param("selectradio-table-cy-ele"));
open OUT, '> '.$main::usersTMP.'debug.table-cy-ele.html'; print OUT $content; close OUT;
}
elsif ($step eq 'shownet') {
$content .= "bsURL: ".$q->param("subNetURLbox") if $debug;
$content .=  printNet($q->param("subNetURLbox"), $callerNo, $AGS, $FGS); 
open OUT, '> '.$main::usersTMP.'debug_net.html'; print OUT $content; close OUT;
} 
else {
if ($type eq 'arc' and $q->param("job_to_remove")) {our $jobToRemove = $q->param("job_to_remove");}
$content .=  'Step: '.$step.' ... <br>'."\n".join(' --- ', ($type, $species, $mode)).'<br>' if $debug;
$content .= generateSubTabContent($type, $species, $mode); 
}
}
HS_html_gen::mainStart() if ($q->param("mode") eq 'standalone' or ($q->param("instance") eq 'new'));
my $newTitle = 'EviNet archive';
$HS_html_gen::mainStart =~ s/TLE\>(.+)\<\/TIT/TLE\>$newTitle<\/TIT/ if $step eq 'saved_nea';
$content = $HS_html_gen::mainStart.$content.$HS_html_gen::mainEnd if ($q->param("mode") eq 'standalone');

print $content; 
 if ($debug) {
 open OUT, '> /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/debug_output.html'; 
 print OUT $HS_html_gen::mainStart.$content; 
 close OUT;
 }

########################################################################################
########################################################################################
sub generateTabContent {
my($tab) = @_;
my @ar = split('_', $tab); my $main_type = $ar[2];
return 
 HS_html_gen::ajaxTabBegin($main_type).
 HS_html_gen::ajaxSubTabList($main_type).
$HS_html_gen::hiddenEl.
 HS_html_gen::ajaxJScode($main_type);
}

sub generateJID { return(sprintf("%u", rand(10**15))); }

sub executeNEA {
my($ags_table, $agsFile, $net, $fgs, $outFile, $filename, $jobParameters, $executeStatement, $email, $op);
my $jid = $q -> param("jid"); #generateJID();
$outFile = tmpFileName('NEA', $jid);
if ($q->param("use-venn")) {# print selected genes directly to the agsFile:
$ags_table = "#venn_lists";
} elsif ($q->param("sgs_list")) {# print selected genes directly to the agsFile:
$ags_table = "#sgs_list";
} elsif ($q->param("selectradio-table-ags-ele")) {
$ags_table = $usersDir.$q->param("selectradio-table-ags-ele");}
elsif ($q->param("ags_table")) {
$filename = $q->param("ags_table");
$filename =~ tr/ /_/;
$filename =~ s/[^$HStextProcessor::safe_filename_characters]//g;
$ags_table = $usersDir.$filename;
} 
else {
return HS_html_gen::errorDialog('error', "Input", 
'Altered gene set(s) not defined.<br>Use one of the alternative input options or run one of our Demos (see top of the page)', 
"Altered gene sets");
exit;
}

$jobParameters -> {jid} = $jid;
$jobParameters -> {rm} = $ENV{REMOTE_ADDR};
$jobParameters -> {projectid} = $projectID;
$jobParameters -> {species} = $species;
$jobParameters -> {sbm_selected_ags} = $AGSselected;
$jobParameters -> {sbm_selected_fgs} = $FGSselected;
$jobParameters -> {sbm_selected_net} = $NETselected;
$jobParameters -> {genewiseAGS} = $q->param("genewiseAGS") ? 'TRUE' : 'FALSE';
$jobParameters -> {genewiseFGS} = $q->param("genewiseFGS") ? 'TRUE' : 'FALSE';
$jobParameters -> {min_size} = $q->param("min_size") ? $q->param("min_size") : 'NULL';
$jobParameters -> {max_size} = $q->param("max_size") ? $q->param("max_size") : 'NULL';
$jobParameters -> {started} = 'LOCALTIMESTAMP';

my $thisURL = $HSconfig::BASE;
$jobParameters -> {url} = HS_html_gen::createPermURL($jobParameters);
# print('<br>sbm_selected_ags: '.join(' ', @{$jobParameters -> {sbm_selected_ags}})) if $debug;	
$agsFile = HStextProcessor::compileGS('ags', 
$jid, 
$ags_table, 
$jobParameters -> {sbm_selected_ags}, 
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}} -> {gene},
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}} -> {group},
$jobParameters -> {genewiseAGS},
$species, 
0);
return HS_html_gen::errorDialog('error', "Input", 
'Altered gene set input was not usable.<br>This might be caused by submitting incompatible gene/protein IDs.<br><span  class=\'clickable acceptedIDsOpener\' onclick=\'openDialog(\"acceptedIDs\");\'>Accepted IDs</span>', 
"Altered gene sets") if $agsFile eq 'empty';
# $agsFile = NET::compileAGS(
# $jid, 
# $ags_table, 
# $jobParameters -> {sbm_selected_ags}, 
# $pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}} -> {gene},
# $pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}} -> {group},
# $jobParameters -> {genewiseAGS},
# $species
# );

if ($HSconfig::nea_software =~ m/runNEAonEvinet/i) {
undef $net; undef $fgs;
if ($q->param("fgs-switch") eq "list") {
$fgs = join($HSconfig::fieldRdelimiter, @{$jobParameters -> {sbm_selected_fgs}});
} 
else {
for $op(@{$FGSselected}) {
# $fgs .= $HSconfig::RscriptParameterDelimiter.$HSconfig::fgsAlias->{$species}->{$op};
$fgs .= $HSconfig::RscriptParameterDelimiter.$op;
}
}
$net = $HSconfig::netfieldprefix.join($HSconfig::RscriptParameterDelimiter.$HSconfig::netfieldprefix, @{$NETselected});
# for $op(@{$NETselected}) {$net .= $HSconfig::RscriptParameterDelimiter.$HSconfig::netAlias->{$species}->{$op};}
$fgs =~ s/^$HSconfig::RscriptParameterDelimiter//;
$net =~ s/^$HSconfig::RscriptParameterDelimiter//;
# $agsFile = 'csnk2a1';
# my $org = 'hsa';
my(%SQL, %LST, %IND, %COL);
$LST{ags} = 'F'; #($ags_table eq "#sgs_list") ? 'T' : 'F';
$SQL{ags} = 'F';
$IND{ags} = ($jobParameters -> {genewiseAGS} eq 'TRUE') ? 'T' : 'F';
$COL{colgeneags} = 2;
$COL{colsetags} = 3;

# $LST{fgs} = ($q->param("fgs-switch") eq "list") ? 'T' : 'F';
$LST{fgs} = (!defined($q->param("FGSselector"))) ? 'T' : 'F';
$SQL{fgs} = ($LST{fgs} eq 'T') ? 'F' : 'T';
$IND{fgs} = ($jobParameters -> {genewiseFGS} eq 'TRUE') ? 'T' : 'F';
$COL{colgenefgs} = 2;
$COL{colsetfgs} = 3;

$executeStatement = "Rscript $HSconfig::nea_software --vanilla --args ntb=".$HSconfig::network->{$species}." fgs=$fgs net=".$net." ags=".$agsFile." out=".$outFile." org=".$species
." sqlags=".$SQL{ags}." lstags=".$LST{ags}." indags=".$IND{ags}
." sqlfgs=".$SQL{fgs}." lstfgs=".$LST{fgs}." indfgs=".$IND{fgs}
." colgeneags=".$COL{colgeneags}
." colsetags=".$COL{colsetags}
." colgenefgs=".$COL{colgenefgs}
." colsetfgs=".$COL{colsetfgs};
# print($executeStatement.'<br>');
} 
else {
# if ($q->param("fgs-switch") eq "list") {
if (!defined($q->param("FGSselector"))) {
# print('<br>'."cpw_listcpw_listcpw_listcpw_listcpw_listcpw_listcpw_list".'<br>');
$fgs = HStextProcessor::compileGS('fgs', 
$jid, 
'#cpw_list', 
$jobParameters -> {sbm_selected_fgs},
'', 
'',  
$jobParameters -> {genewiseAGS},
$species, 
0
);
return HS_html_gen::errorDialog('error', "Input", 
'Functional gene set input was not usable.<br>This might be caused by submitting incompatible gene/protein IDs.<br><span  class=\'clickable acceptedIDsOpener\' onclick=\'openDialog(\"acceptedIDs\");\'>Accepted IDs</span>', 
"Functional gene sets") if ($fgs eq 'empty');
} else {
$fgs = NET::compileFGS(
$jid, 
'files', 
$jobParameters -> {sbm_selected_fgs} ,
$q->param("genewiseFGS")
);
}
# print (join('<br>',  @{$jobParameters -> {sbm_selected_net}}));
$net = NET::compileNet ($jid, 'FunCoup LE'); 
# $net = NET::compileNet ($jid, @{$jobParameters -> {sbm_selected_net}});

$executeStatement = "$HSconfig::nea_software -fg $fgs -ag $agsFile -nw $net -nd 0 -do ".($q->param("indirect") ? 0 : 1)." -it ".((lc($q->param("netstat")) eq 'z') ? 10 : 0)." ".($q->param("fdr") ? ' -so '.$q->param("fdr") : 1)." -dd 1 -od ".$outFile." -ps ".($q->param("showself") ? 1 : 0).' -mi '.(($q->param("min_size") and ($q->param("min_size") ne 'NULL')) ? $q->param("min_size") : 0).' -ma '.(($q->param("max_size") and ($q->param("max_size") ne 'NULL')) ? $q->param("max_size") : 1000);

}
$jobParameters -> {commandline} = HS_html_gen::showCommandLine($executeStatement);
print '<br>'.$HSconfig::test.'<br>' if $debug;
print '<br>'.$executeStatement.'<br>' if $debug;
$email = $q->param('user-email') if ($q->param('user-email') =~ m/\@.+\./);

saveJob($jid, $jobParameters);
sendNotification ($jobParameters -> {projectid}, $q->param('user-email'), $jid, undef, $jobParameters -> {url}, 'running')  if $email;
if (!system($executeStatement)) {
confirmJob($jid); 
sendNotification ($jobParameters -> {projectid}, $email, $jid, undef, $jobParameters -> {url}, 'done') if $email;
# system("rm  ".tmpFileName('AGS', $jid).' '.tmpFileName('FGS', $jid).' '.tmpFileName('NET', $jid)) if !$debug;
} else {
$dbh->do("ROLLBACK;");
}
return ($jid);
}



# https://www.evinet.org/cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout=undefined;showself=showself;project_id=HYPERSET.ne;species=hsa;jid=154557948973

sub saveJob { #the SQL table can be re-created with $createSQLTabelStatement in HSconfig.pm
my($jid, $jobParameters) = @_;
my($fld, $va, $stat);

$stat = "INSERT INTO projectarchives (";
for $fld(sort {$a cmp $b} keys(%{$jobParameters})) {
$stat .= $fld.', '; #$jobParameters -> {$fld}
}
$stat =~ s/\,\s$/\)/;
$stat .= " VALUES ( ";
for $fld(sort {$a cmp $b} keys(%{$jobParameters})) {
if (defined($jobParameters -> {$fld})) {
# print $fld, $jobParameters -> {$fld}.'<br>';
$va = ($fld =~ m/^sbm_selected_.{1}gs$/) ? join($HS_html_gen::fieldURLdelimiter, @{$jobParameters -> {$fld}}) : $jobParameters -> {$fld};
if ($fld eq 'sbm_selected_net') {
$va = $HSconfig::netfieldprefix.join($HS_html_gen::fieldURLdelimiter.$HSconfig::netfieldprefix, @{$jobParameters -> {$fld}});
# print $va.'<br>';
}
if ($jobParameters -> {$fld} =~ m/LOCALTIMESTAMP|NULL/) {
$stat .= $va .', '; 
} else {
$stat .= "\'" . $va . "\', "; 
}
}}
$stat =~ s/\,\s$/\)\;/;

print $stat.'<br>' if $debug;
$dbh->do("BEGIN;");
$dbh->do($stat);
#$dbh->do("ROLLBACK;");
}

sub confirmJob {
my($jid) = @_;

my $outFile = tmpFileName('NEA', $jid);
open CNT, "wc $outFile | ";
my $li = <CNT>;
close CNT;
my $Nlines = $1 if $li =~ m/\s*([0-9]+)/;
 $dbh->do("COMMIT;");
 $dbh->do("BEGIN;");
 
my $stat = "UPDATE projectarchives SET status='done', finished=LOCALTIME, nlines=$Nlines  where jid=\'".$jid."\';";
print $stat.'<br>'  if $debug;
$dbh->do($stat);
$dbh->do("COMMIT;");
}

sub retrieveJobInfo {
my($jid, $fld) = @_;
my $rows;
# my $stat = "SELECT \* FROM projectarchives WHERE projectid=\'".$projectID."\' and jid!=''   order by started desc limit 1;";
my $stat = "SELECT \* FROM projectarchives WHERE jid=\'".$jid."\';";
 # print $stat ; #if $debug;
		my $sth = $dbh -> prepare_cached($stat) 
		  || die "Failed to prepare SELECT statement SELECT FROM projectarchives 2 ...\n";
		$sth->execute();
		while ( $rows = $sth->fetchrow_hashref ) {
			return $rows->{$fld};
			}
}

sub sendNotification {
my($proj, $to, $jid, $time, $url, $status) = @_;
my $smtp = Net::SMTP->new('localhost') or die $!;
    #print $smtp->domain,"\n";
    #$smtp->quit;
my $from = 'webmaster@evinet.org';
my $message;
if (lc($status) ne "done") {
$message = 'Your job '.$jid.' was submitted to evinet.org and is expected to be finished soon. 
You are going to be notified about that.
';
} else {
$message = 'Processing your job '.$jid.' at evinet.org has just finished. Please use the following URL to access the results: 
'.$url.'

Thank you for using EviNet.
';
}
my $subject = 'job execution on EviNet; project '.$proj;

$smtp->mail( $from );
$smtp->to( $to );
$smtp->data();
$smtp->datasend("To: $to\n");
$smtp->datasend("From: $from\n");
$smtp->datasend("Subject: $subject\n");
$smtp->datasend("\n"); # done with header
$smtp->datasend($message);
$smtp->dataend();
$smtp->quit(); # all done. message sent.
return undef;
}

sub tmpFileName {
my($type, $jid) = @_; 
if ($type eq 'NEArender') {
return($main::usersTMP.'_tmpNEA'.'.'.$jid.".RData");
} else {
return($main::usersTMP.'_tmp'.uc($type).'.'.$jid);
}
}
 
sub printNet {
my($bsURLstring, $callerNo, $AGS, $FGS) = @_;
my($data, $node);

print $bsURLstring."\n"   if $debug;
($data, $node) = HS_bring_subnet::bring_subnet($bsURLstring);
return('<div id="net_graph" style="width: '.$HSconfig::cy_size->{net}->{width}.'px; height: '.$HSconfig::cy_size->{net}->{height}.'px;">'.
HS_cytoscapeJS_gen::printNet_JSON($data, $node, $callerNo, $AGS, $FGS).'
		</div></div>');
}

sub readNEA {
my($table) = @_;
my($key, $i, @arr, $neaData);
my $current_usr_mask = $q->param('ags_mask');
my $current_fgs_mask = $q->param('fgs_mask');
# print "OPEN NEA FILE: $table".'<br>';
open NEA, $table or return("deleted");
print "OPEN NEA FILE: $table".'<br>' if $debug;
$_ = <NEA>;
HStextProcessor::readHeader($_, $table, "\t");
$i = 0;
while ($_ = <NEA>) {
chomp; 
@arr = split("\t", uc($_));
next if lc($arr[0]) ne 'prd';
next if ($current_usr_mask and $arr[$pl->{$table}->{'ags'}] !~ m/$current_usr_mask/i);
next if ($current_fgs_mask and $arr[$pl->{$table}->{'fgs'}] !~ m/$current_fgs_mask/i);
next if (($arr[$pl->{$table}->{$HSconfig::pivotal_nea_score}] < 0) or 
($arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] eq "") or 
$arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] > $NEA_FDR_coff or 
$arr[$pl->{$table}->{$HSconfig::nea_fdr}] > $HSconfig::min_nea_fdr or 
$arr[$pl->{$table}->{$HSconfig::nea_p}] > $HSconfig::min_nea_p );
next if ($arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}] < $NEA_Nlinks_coff);
$neaData->[$i]->{wholeLine} = $_;
for $key(keys(%HSconfig::neaHeader)) {
$neaData->[$i]->{$HSconfig::neaHeader{$key}} = $arr[$pl->{$table}->{lc($HSconfig::neaHeader{$key})}];
}
$i++;
}
close NEA;
if (1 == 2 or !$i) {
return("empty")
}
else {
return $neaData;
}
}

sub jobFromArchive {
my($proj, $job) = @_;

my $content = '<div id="nea_archive_tabs">
'.printJobTabs($proj, $job).'
</div>';

$content = '
<FORM id="form_ne" action="cgi/cgivenn/i.cgi" method="POST" enctype="multipart/form-data" autocomplete="on" >
<h3>Project: "'.$proj.'", analysis: #'.$job.'</h3>
'.
$content.'
</FORM>';
$content .= '<script type="text/javascript">
$(function() {
$("#nea_archive_tabs").tabs();
});
</script>';
}

sub printJobTabs {
my($proj, $job) = @_;
my $content = '
<ul>
<li><a href="cgi/cgivenn/i.cgi?project_id='.$proj.';jid='.$job.';type=csw;analysis_type=ne;">Graph</a></li>
<li><a href="cgi/cgivenn/i.cgi?project_id='.$proj.';jid='.$job.';type=tbl;analysis_type=ne;">Table</a></li>
<li><a href="cgi/cgivenn/i.cgi?project_id='.$proj.';type=arc;analysis_type=ne;">Archive</a></li>
</ul>';
return $content;
}

sub printAccordion {
my($jid) = @_;

my($table, $content, $key, $i, $neaData, $insert);
$table = tmpFileName('NEA', $jid);
$neaData = readNEA($table);
return HS_html_gen::errorDialog('error', "Project archive", 
$neaData eq 'deleted' ? 
"Job $jid:<br> this result is no longer stored in the Archive.<br>Try to reproduce it." : 
"Job $jid:<br> this output file does not contain lines indicating significant enrichment.<br>Try to re-run the analysis with different parameters.",
"Archive") if (ref($neaData) ne 'ARRAY');

# cgi/i.cgi?type=arc;species=hsa;analysis_type=ne;project_id=stemcell

my $subnet_url = prepareSubURL_and_Links($neaData, $pl, $table, $jid);
my($open, $close, $style);
$style = 'TAB';
$style = '';
if ($style eq 'UI') {
$open = '<h3><p>'; $close = '</p></h3>';
} elsif ($style eq 'TAB')  {
$open = ''; $close = '';
} else {
$open = '<div>'; $close = '</div>';
}
#"fillREST(
my $header = ($style eq 'TAB') ? '' : '<div id="acc_header_template" style="height: 30px; text-align: center;" onclick="toggleSection(\'template\')">NEA template<span id="acc_span_template"></span></div>';

$content .= '
<div id="net_up" >
<div id="ne-up-progressbar"></div>
</div>
<script   type="text/javascript"> 
$(function() {
$( "#ne-up-progressbar" ).progressbar({
value: false
});
$( "#ne-up-progressbar" ).css({"visibility": "hidden", "display": "none"});
});
</script> 

<div id="nea_acc" >';

if ($style eq 'TAB') {
}

###############################################
if ($style ne "TAB") { 
$insert = $header;
$insert =~ s/template/graph/g;
$content .= $open.$insert.'<div id="nea_graph" style="width: '.$HSconfig::cyPara->{size}->{nea}->{width}.'px; height: '.$HSconfig::cyPara->{size}->{nea}->{height}.'px">'.
printTabGraphics($neaData, $pl, $table, $subnet_url).'</div>'.$close if ($q->param("graphics"));

$insert = $header;
$insert =~ s/template/table/g;
$content .= $open.$insert.$HS_html_gen::hiddenEl.'<div id="nea_table" >
<input type="hidden"  name="neafile" id="neafile" value="default">
<input type="hidden"  name="subNetURLbox" id="subNetURLbox" value="">'
.printTabTable($neaData, $pl, $table, $subnet_url, $jid)
.'</div>'.$close if ($q->param("table"));

$insert = $header;
$insert =~ s/template/archive/g;
$insert =~ s/NEA/Project/g;
$content .= $open.$insert.'<div id="nea_archive" >'.HS_html_gen::printTabArchive($projectID).'</div>'.$close if ($q->param("archive"));
} else {
$content .= '<div id="nea_graph" style="width: '.$HSconfig::cyPara->{size}->{nea}->{width}.'px; height: '.$HSconfig::cyPara->{size}->{nea}->{height}.'px">
</div>' if ($q->param("graphics"));

$content .= '<div id="nea_table" >
<input type="hidden"  name="neafile" id="neafile" value="default">
<input type="hidden"  name="subNetURLbox" id="subNetURLbox" value="">
</div>' if ($q->param("table"));

$content .= '<div id="nea_archive" >
</div>' if ($q->param("archive"));
}

if ($style eq 'TAB') {
$content .= '<script type="text/javascript">
$(function() {
//urlfixtabs( "#test_ttt" );
//var Base = $("base").attr( "href" );
//$("base").attr( "href", "");
$("#nea_acc").tabs();
/* $( "#nea_acc" )
        .find( "ul li" ).
for () {
$("#nea_acc").tabs("load", i);
}
$("base").attr( "href", Base);*/

});
</script>';
} else {
$content .= '<script type="text/javascript"> '.
	'function toggleSection(tmpl) {
$("#nea_" + tmpl).toggleClass("hidden");
}'
.(($style eq 'UI') ? '$(function() {
$("#nea_acc").accordion();
$("#nea_tabs").addClass("ui-helper-clearfix");
});' : 
	'$(function() {
$("div[id^=\'acc_header_\']").addClass("ui-accordion-header ui-state-default ui-corner-all ui-accordion-icons");
$("#nea_archive").addClass("hidden");
$("#nea_table").addClass("hidden");

//$("div[id*=\'acc_header_\']").css("display: table-cell; height: 50px;");
//$("#acc_span_graph").addClass("ui-accordion-header-icon ui-icon ui-icon-triangle-1-e");
//$("#acc_span_graph").css("display: table-cell; ");
});')
.'</script>
' if 1==1;
}

# $content .= '<script type="text/javascript">$("#nea_matrix").tabs();</script>';

$content .= '</div>
';
return $content;
}

sub printNEA {
my($jid, $possibleProject) = @_;

$jid = retrieveJobInfo($possibleProject, 'jid') if ($jid eq 'project');
# print $jid.'<br>';
my($table, $content, $key, $i, $neaData);
$table = tmpFileName('NEA', $jid);
$neaData = readNEA($table);
return HS_html_gen::errorDialog('error', "Project archive", 
$neaData eq 'deleted' ? 
"Job $jid:<br> this result is no longer stored in the Archive.<br>Try to reproduce it." : 
"Job $jid:<br> this output file does not contain lines indicating significant enrichment.<br>Try to re-run the analysis with different parameters.",
"Check and submit") if (ref($neaData) ne 'ARRAY');
my $subnet_url = prepareSubURL_and_Links($neaData, $pl, $table, $jid);
 
# $content .= '<br><a href="'.$URL->{$jid}.'">Save URL to this analysis</a>';
$content .= '<br><div id="net_up" >
<div id="ne-up-progressbar"></div>
</div> 
Job #'.$jid.':
<div id="nea_tabs" >';
$useAjaxTabs = 1;
if ($useAjaxTabs) {
$content .= printJobTabs($possibleProject, $jid);
} else {
$content .= '<ul>';
$content .= '<li><a href="#nea_graph">Graph</a></li>' if ($q->param("graphics"));
$content .= '<li><a href="#nea_table">Table</a></li>' if ($q->param("table"));
# $content .= '<li><a href="#nea_archive">Archive</a></li>' if ($q->param("archive"));
$content .= '<li><a href="#nea_line">Command line syntax</a></li>' if ($q->param("commandline"));
$content .= '</ul>';
$content .= '
<script type="text/javascript"> 
$(function() {
urlfixtabs( "#nea_tabs" );
});
</script>';
if ($q->param("graphics")) {
$content .= '<div id="nea_graph" style="width: '.$HSconfig::cyPara->{size}->{nea}->{width}.'px; height: '.$HSconfig::cyPara->{size}->{nea}->{height}.'px;">'.
printTabGraphics($neaData, $pl, $table, $subnet_url).'</div>';
}
if (1 == 1 and $q->param("table")) { 
$content .= '<div id="nea_table">
<input type="hidden"  name="neafile" id="neafile" value="default">
<input type="hidden"  name="step" id="step" value="default">
<input type="hidden"  name="subNetURLbox" id="subNetURLbox" value="">';
$content .= printTabTable($neaData, $pl, $table, $subnet_url, $jid);
$content .= '</div>';
}
if (1 == 1 and $q->param("commandline")) { 
$content .= '<div id="nea_line">
<label for="commandline" title="Show command line and files for this analysis">
<!--span class="ui-icon ui-icon-info venn_box_control" id="commandlineButton" onclick="showCommandLine(\'commandline\');"></span-->
<div class="commandline" id="commandline">'.retrieveJobInfo($jid, 'commandline').'</div></label></div>'; 
}
}
$content .= '</div>';
$content .= '<script type="text/javascript"> 
$("#nea_tabs").tabs();
$("#nea_tabs").tabs().addClass("ui-helper-clearfix");
//$("#nea_tabs").draggable();
$("#nea_table").css("font-size",  "'.$HSconfig::font->{nea_table}->{size}.'px");
$("#nea_tabs").tabs({
beforeLoad: function( event, ui ) {
    if ( ui.tab.data( "loaded" ) ) {
      event.preventDefault();
      return;
    }
ui.jqXHR.error(function() {
	ui.panel.html("Could not load this tab. We\'ll try to fix this as soon as possible. Please inform <a href=\"mailto:andrej.alekseenko@scilifelab.se?subject=HyperSet website bug\">andrej.alekseenko@scilifelab.se</a>...");
});
	ui.jqXHR.success(function() {
    ui.tab.data( "loaded", true );
});
}});
$( "#ne-up-progressbar" ).progressbar({value: false});
$( "#ne-up-progressbar" ).css({"visibility": "hidden", "display": "none"});
</script>
';

}

sub prepareSubURL_and_Links {
my($neaData, $pl, $table, $jid) = @_;
my $species = retrieveJobInfo($jid, 'species');
my $networks = retrieveJobInfo($jid, 'sbm_selected_net');

my $su = HStextProcessor::subnet_urls($neaData, $pl, $table, $species, $networks);
#  print  $species.'<br>' if $debug;
return($su);
}

sub printTabPlot {
my($neaData, $pl, $table, $subnet_url) = @_;
#nea_link_url();
return '<iframe id="heatmap-iframe" src="pics/ttb.pairwise_correlations.156proteins.v3.html" style="width:100%; height:100%;"></iframe>';
# HS_cytoscapeJS_gen::printNEA_JSON($neaData, $pl->{$table}, $subnet_url);
}

sub tabByURL {
my($jid, $ty) = @_;

my($table, $content, $key, $i, $neaData, $insert);
$table = tmpFileName('NEA', $jid);
$neaData = readNEA($table);
return HS_html_gen::errorDialog('error', "Project archive", 
$neaData eq 'deleted' ? 
"Job $jid:<br> this result is no longer stored in the Archive.<br>Try to reproduce it." : 
"Job $jid:<br> this output file does not contain lines indicating significant enrichment.<br>Try to re-run the analysis with different parameters.",
"Archive") if (ref($neaData) ne 'ARRAY');
my $subnet_url = prepareSubURL_and_Links($neaData, $pl, $table, $jid);
if ($ty eq 'csw') {
return(printTabGraphics($neaData, $pl, $table, $subnet_url));
} 
elsif ($ty eq 'tbl') {
return(printTabTable($neaData, $pl, $table, $subnet_url, $jid));
} else {
return("<br>Unknown tab type...<br>\n");
}
}


sub printTabGraphics {
my($neaData, $pl, $table, $subnet_url) = @_;
#nea_link_url();
return HS_cytoscapeJS_gen::printNEA_JSON(
		$neaData, $pl->{$table}, $subnet_url);
}
# return undef; 

sub printTabTable {
my($neaData, $pl, $table, $subnet_url, $jid) = @_;
my($i,$genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $text, $ol, $signGSEA, $key, @arr, $AGS, $FGS);

my $content = '<div id="nea_matrix">'.insertMatrixURLs($jid).'</div>';
#CGIVENN#
my $species = retrieveJobInfo($jid, 'species');
print  'Selected Species:'.$species.'<br>' if $debug;
#CGIVENN#
my $tableID = 'nea_datatable';
$content .= '<table id="'.$tableID.'"  class="display" cellspacing="0" width="100%"><thead>'; 
for $key(@HSconfig::NEAshownHeader) {
	$content .= '<th ';
	$content .= 'class="'.$HSconfig::NEAheaderCSS{$key}.'"' if $HSconfig::NEAheaderCSS{$key}; 
	$content .= '>'; 
	$content .= $HS_html_gen::OLbox1.$HSconfig::NEAheaderTooltip{$key}.$HS_html_gen::OLbox2 if $HSconfig::NEAheaderTooltip{$key};

	$content .= $key.''; #</th></tr>    </a><br>
	$content .= '</th>';
	}
	$content =~ s/qtip-content/qtip-justtext/g;
	$content .= '</tr></thead>';

	for $i(0..$#{$neaData}) { 
	@arr = split("\t", uc($neaData->[$i]->{wholeLine})); 
	# $genesAGS = $arr[$pl->{$table}->{ags_genes2}]; 
	# $genesFGS = $arr[$pl->{$table}->{fgs_genes2}]; 
	$genesAGS = $arr[$pl->{$table}->{ags_genes1}]; 
	$genesFGS = $arr[$pl->{$table}->{fgs_genes1}]; 
	$text = $arr[$pl->{$table}->{ags}];
	$text = substr($text, 0, 40);
	$ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{ags}].$HS_html_gen::OLbox2 if length($arr[$pl->{$table}->{ags}]) > 41;
	$content .= "\n".'<tr><td name="firstcol" class="AGSout">'.$ol.$text.'</a>'.'</td>';
	$content .= "\n".'<td class="AGSout">'.
	$HS_html_gen::OLbox1.
	# '<b>AGS genes that contributed to the relation</b><br>(followed with and sorted by the number of links):<br>'.
	'<b>AGS genes that contributed to the relation</b>:<br>'.
	$genesAGS.
	$HS_html_gen::OLbox2.
	$arr[$pl->{$table}->{n_genes_ags}].'</a>'.'</td>';
	$content .= "\n".'<td class="AGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_AGS')}].'</td>';
	$text = $arr[$pl->{$table}->{fgs}];
	$text = substr($text, 0, 40);

	#CGIVENN#
	if (length($arr[$pl->{$table}->{fgs}]) > 41) {
		$ol2 = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2;
	}
	else{
		$ol2 = "\<a\>";
	}
	if ($text =~ /^KEGG_([0-9]*)[^0-9].*$/){ # && $ol =~ /^[^\s*]$/ && $species ne 'ath'){
		my $kid = $1;
		my $sp = $species;
		my $khref = "href\=\"$HS_html_gen::kegg_url$sp$kid\" class\=\"clickable\"";
		$ol2 =~ s/(\<a)/\1 $khref/;
		
	}

	$content .= "\n".'<td class="FGSout">'.$ol2.$text.'</a>'.'</td>';
	#CGIVENN#

	$content .= "\n".'<td class="FGSout">'.$HS_html_gen::OLbox1.
	# '<b>FGS genes that contributed to the relation</b><br>(followed with and sorted by the number of links):<br>'.
	'<b>FGS genes that contributed to the relation</b>:<br>'.
	$genesFGS.$HS_html_gen::OLbox2.$arr[$pl->{$table}->{'n_genes_fgs'}].'</a>'.'</td>';
	$content .= "\n".'<td class="FGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_FGS')}].'</td>';
	$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}].'</td>';
	$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc($HSconfig::pivotal_nea_score)}].'</td>';
	$content .= "\n".'<td>'.$arr[$pl->{$table}->{$HSconfig::pivotal_confidence}].'</td>';
	$signGSEA = (
	($arr[$pl->{$table}->{lc('GSEA_p-value')}] =~ m/[0-9e\.\-\+]+/i) and ($arr[$pl->{$table}->{lc('GSEA_p-value')}] < $GSEA_pvalue_coff)
	) ? 
	$HS_html_gen::OLbox1.$arr[$pl->{$table}->{lc('GSEA_overlap')}].' genes shared between AGS and FGS, significant at p<'.sprintf("%.9f", 0.000000001+$arr[$pl->{$table}->{lc('GSEA_p-value')}]).
	$HS_html_gen::OLbox2.'*</a>' : 
	'';
	$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc('GSEA_overlap')}].$signGSEA.'</td>';

	$AGS = $arr[$pl->{$table}->{ags}];
	$FGS = $arr[$pl->{$table}->{fgs}];

	my $id = join($HS_html_gen::actionFieldDelimiter1, ('subnet-'.++$sn, $AGS, $FGS));
	$content .= "\n".'<td>'. #????????????????????????????????????????????
	((1 == 1) ? '<button type="submit" id="'.$id
	.'" style="visibility: visible;" formmethod="get" onclick="fillREST(\'subNetURLbox\', \''.$subnet_url->{$AGS}->{$FGS}.'\', \''.$id .'\')" class=\'cs_subnet\'>Sub-network</button>' : '') .'</td>' ; 

	$content .= '</tr>';
	}
	$content .="\n".'</table>
	<script   type="text/javascript">HSonReady();
	 var table = $("#'.$tableID.'").DataTable('.HS_html_gen::DTparameters(1).');
	table.buttons().container().appendTo( $("#'.$tableID.'_wrapper").children()[0], table.table().container() ) ; 
	table.buttons().container().prependTo($($("#'.$tableID.'_wrapper").children()[0]) ) ; 
	 $("a[qtip-content]").qtip({
	     show: "mousedown",
	     hide: "unfocus",
	     content: {
		text: function(event, api) {
		    return $(this).attr("qtip-content");
		}
	    }
	});
	 $("a[qtip-justtext]").qtip({
	     show: "mouseover",
	     hide: "mouseout",
	     content: {
		text: function(event, api) {
		    return $(this).attr("qtip-justtext");
		}
	    }
	});
	</script>';
	return ($content);
	}

	sub insertMatrixURLs {
	my($jid) = @_;
	my($tableID, $i, $cnt);
	my @lst = @{$HSconfig::matrixTab->{displayList}}; 
$executeStatement = "Rscript $HSconfig::nea_reader  --vanilla --args nea=".
	tmpFileName('NEArender', $jid).
	" tables=".join($HSconfig::RscriptParameterDelimiter , @lst).
	" htmlmask=".$main::usersTMP.$HSconfig::matrixHTML.'.'.$jid;
	# print $executeStatement.'<br>';
system($executeStatement); #
$cnt = '<div style="width:100%; text-align: right; ">
<span style="vertical-align: middle; padding-bottom: 20px;">Open rectangular matrix: </span><select name="matrix_select" id="matrix_select">';
	for $i(0..$#lst) {
	$tableID = $HSconfig::tmpVennHTML.$projectID.'/'.$HSconfig::matrixHTML.'.'.$jid.'.'.$lst[$i].'.html';
	$cnt .= '<option class="clickable" value="'.$tableID.'">'. $HSconfig::matrixTab -> {caption} -> {$lst[$i]} .'</option>';
}
$cnt .= '</select>
</div>';

$cnt .= '<script type="text/javascript"> 
$( "#matrix_select" ).selectmenu({
		width: 350,
		select: function( event, data ) {
			window.open(data.item.value, "_blank");
			}
});

</script>';
return ($cnt);
}

sub generateSubTabContent {
my($type, $species, $mode) = @_;
# print join(' +++ ', ($type, $species, $mode)).'<br>' if $debug;
my($field, $tbl, $cond1, $cond2, $content, $ID, $table, $fl, $criteria, $cr, $cntr, $fld, $order);
#################
#################
if ($type =~ m/^csw|tbl$/) {
$content = tabByURL($q->param("jid"), $q->param("type"));
# cgi/i.cgi?type=arc;species=hsa;analysis_type=ne;project_id=stemcell
}
elsif ($type eq 'update_venn') {
my $vennFile  = $usersDir.$q->param("selected-table-venn"); #$HSconfig::usersDir.'venn/P.matrix.NoModNodiff.2.txt'; ####
#print $vennFile;

if (system("chmod g+rwx $usersTMP")==0){ #on success system returns 0
#$content .= "<p style=\"color: red;\">$vennFile</p>";
system("rm venn*.png vennGenes*.pm");}
for $fl($q->param) {
# $content .= $fl.': <br>';$fl =~ m/^venn-hidden-([0-9]-[0-9])-([0-9a-z\_]+)\-([a-z]+)$/i
# print $q->param('venn-hidden-3-2-wt_nondiff_3_control_vs_wt_nondiff_2_control-fdr').'<br>';

if ($fl =~ m/^venn-hidden-[0-9]-[0-9]/i) {
if ($q->param($fl)) {
if ($fl =~ m/\-fc$/i) {

($order, $cntr, $fld) = ($1 - 1, $3, $3.'-'.$4.'-'.$2) if $fl =~ m/^venn-hidden-([0-9])-[0-9]-([LR])-([0-9a-z\_]+)\-([a-z]+)$/i;
$criteria->{$cntr}->{$fld} = $q->param($fl);
$criteria->{order}->[$order] = $cntr;
} else {
($order, $cntr, $fld) = ($1 - 1, $2, $2.'-'.$3) if $fl =~ m/^venn-hidden-([0-9])-[0-9]-([0-9a-z\_]+)\-([a-z]+)$/i;
$criteria->{$cntr}->{$fld} = $q->param($fl);
 # print $fl.' '.$criteria->{$cntr}->{$fld}.'<br>';
$criteria->{order}->[$order] = $cntr;
}}}}
# my $pval = $q->param("pvalue1");
# my $fval = $q->param("fc1");
my $comp = scalar(keys(%{$criteria})) - 1;
my $tm = generateJID();
my $venName = "venn".$tm.".png";
my $gTable = "vennGenes".$tm.".pm";
#my $new_venPath = $usersTMP.$venName;
my $new_venPath = $HSconfig::usersPNG.$venName;
my $gene_listPath = $usersTMP.$gTable;
my $parametersFile = join('.', $usersTMP.$HSconfig::parameters4vennGen, $tm, 'r');
HStextProcessor::writeParameters4vennGen($parametersFile, $vennFile, $criteria, $new_venPath, $gene_listPath, $q->param('venn-hidden-genecolumn'));
my $cmd = "Rscript /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/cgivenn/vennGen.AA.r $parametersFile";
system($cmd);

if (-e $new_venPath && -e $gene_listPath) {
	#print "ref:".ref(\$projectID)."\n"
	#my $modulepath=$usersTMP.$projectID;
	#BEGIN { push @INC, $modulepath };
	#use lib $modulepath;
	print $projectID"\n";	
	require $projectID.'/'.$gTable;
	import $projectID.'/'.$gTable;
#	require $gTable;
#	import $gTable;	
	#use GeneList qw($gList $contrasts);
$content = HS_html_gen::make_gene_list($GeneList::gList, $GeneList::contrasts, $criteria, $species);
#$content = HS_html_gen::make_gene_list($gList, $contrasts, $criteria, $species);
#$content .= "\n<img src=\"$HSconfig::tmpVennPNG/$projectID/$venName\" id=\"map-venn\" usemap=\"#for-venn-".$comp."\">\n";
$content .= "\n<img src=\"$HSconfig::tmpVennPNG/$venName\" id=\"map-venn\" usemap=\"#for-venn-".$comp."\">\n";
$content .= HS_html_gen::get_map_html(\%{$venn_click_points::venn_coord},$comp);
$content .= "\n<script type=\"text/javascript\">
                        (function (){
                                  jq_mp(\"#map-venn\").mapster({
				        mapKey: \"data-key\",
                                        isSelectable: true,
                                        fill : true,
                                        fillOpacity : 0.3,
                                        fillColor : \"a4a4a4\"
                                        });})(jQuery);
                        </script>\n";
print $content.'<br>';
}
#CGIVENN#
else {
$content .= HS_html_gen::errorDialog('error', "Cutoffs are stringent","No genes meet the choosen cutoff requirements. Lower your stringency and Generate Venn diagram" );
}
#CGIVENN#
}
elsif ($type eq 'create_venn') {
my $vennFile  = $usersDir.$q->param("selectradio-table-ags-ele"); #$HSconfig::usersDir.'venn/P.matrix.NoModNodiff.2.txt'; ####

my $vennData =  HStextProcessor::vennInput($vennFile, "\t", 200000);
if (ref($vennData) ne 'HASH') {
print $vennData;
exit;
}
#CGIVENN#
$content .= HS_html_gen::errorDialog("error", "Message", "Please select number of comparsions for venn-diagrams (1,2,3,4) <br> The possible contrasts from the header line of input file will appear as dropdown menu <br> ");
#CGIVENN#
$content .=  HS_html_gen::vennControls(HStextProcessor::vennHeader($vennFile, "\t"), $vennData);
$content .=  '<script type="text/javascript">
$(\'[name="selected-table-venn"]\').val("'.$q->param("selectradio-table-ags-ele").'");
</script>';
}

elsif ($type eq 'convert_geneids'){
#my $cidFile =  $usersDir.$q->param("selectradio-table-ags-ele");
my $cidFile = $HSconfig::usersDir.'gidconv/sample.CIDs.txt';
my $input_gid= $q->param("gid_ip") ;
my $output_gid= $q->param("gid_op");
my $tm1 = generateJID();
my $cidTable = "convID".$tm1.".pm";
my $cid_listPath = $usersTMP.$cidTable;
my $parametersFile4cid = join('.', $usersTMP.$HSconfig::parameters4convID, $tm1, 'r');
HStextProcessor::parameters4convID($parametersFile4cid, $cidFile, $input_gid, $output_gid, $cid_listPath);
print $cid_listPath if debug;
#my $rcmd = "Rscript /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/cgivenn/geneID_convHTML.r $parametersFile4cid"; 
#$cidFile $input_gid $output_gid"; 
my $rcmd = "Rscript /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/cgivenn/geneID_conv.r";
print $rcmd if debug;
system($rcmd);
}

#my $cid_file =  $usersDir.$q->param("selectradio-table-ags-ele"); 
#my $cid_file = $HSconfig::usersDir.'gidconv/sample.CIDs.txt';
#my $cid_data = HStextProcessor::cidInput($cid_file,"\t");
#$content .= HS_html_gen::cidInput($cid_file);
#$content .= '<script type="text/javascript">
#$(\'[name="selected-table-cid"]\').val("'.$q->param("selectradio-table-ags-ele").'");
#</script>'

#$content .= '<script type="text/javascript">
#$(\'#vertAGStabs\').tabs({active:3});
#</script>'
#
#;

#}
elsif ($type eq 'list_ags_files') {
$content .= HS_html_gen::wrapColl(listFiles($usersDir, ''), $type, $species, $mode);
}
#CGIVENN#
elsif ($type eq 'wrong_upload_format'){
$content .= HS_html_gen::errorDialog("error", "File upload error", $upload_err_msg); # exit;
}
#CGIVENN#
elsif ($type eq 'delete_ags_files') {
deleteFiles($usersDir, $q->param("selectradio-table-ags-ele"));
$content .= HS_html_gen::wrapColl(listFiles($usersDir, ''), $type, $species, $mode);
}
elsif ($type eq 'save_json_into_project') {
my $manipulated_graph = $q->param("json3_content");
$manipulated_graph =~ s/^\{//;
$manipulated_graph =~ s/\}$//;
$manipulated_graph .= ', ready: function(';
my $nea_div = $q->param("json3_script");
my $empty = 'name="json3_content" value=""';
$nea_div =~ s/name\=\"json3_content\".+value\=\".+\}\}\"/$empty/s;
$nea_div =~ s/\)\.cytoscape\(\{.+\,\s+\"elements\"\:/\)\.cytoscape\(\{\"elements\"\:/s;
$nea_div =~ s/\"elements\"\:.+\}\,\s*ready\:\s+function\(/$manipulated_graph/s;
$nea_div =~ s/\"layout\"\:\s*\{.+?\}\,//s;

$content .= saveIntoProject($usersTMP, $q->param("input-save-cy-json3"), $HSconfig::users_file_extension{'JSON'}, $nea_div); 
$content .= HS_html_gen::wrapColl(listFiles($usersTMP, $HSconfig::users_file_extension{'JSON'}), $type, $species, $mode);
#'print-save-cy-json3'
}
elsif (($type eq 'sgs')  or ($type eq  "ags" )) {
our %AGS; #
# print  "Type: ".$type if $debug;
my $file = $q->param('selectradio-table-ags-ele') ? $q->param('selectradio-table-ags-ele') : $savedFiles -> {data} -> {$type."_table"}; #
$table = $usersDir.$file; #
 print $type.' table '.$table.'<br>' if $debug;
#  
 $AGS{readin} = NET::read_group_list($table, 0, $pl->{$table}->{gene}, $pl->{$table}->{group}, $delimiter, '_AGS', ($q->param("useCR") ? 1 : 0)); #
$pre_NEAoptions -> {$type} -> {$species} -> {ne} =  
	HS_html_gen::makeDraggable('ags', 
	HS_html_gen::listAGS(
	$AGS{readin}, 
	'AGS', 
	(($type ne 'sgs') ? 1 : 0), 
	$file, 
	$usersDir)); #
$content .=  HS_html_gen::pre_selectJQ('ags'); #
$content .=  '<input type="hidden" name="analysis_type" value="'.$mode.'"> '; #
# $content .=  '<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Specify table format and columns that contain gene/protein IDs and group IDs. The groups are meant to represent multiple s.c. altered gene sets (AGS) which you want to characterize">[?]</div>';
# $content .=  'Gene/protein groups contained in '.$file.': ';
$content .= '<br>'.$pre_NEAoptions -> {$type} -> {$species} -> {ne}.'<br>';
# $content .=  HS_html_gen::pre_selectJQ('input');
# $content .= '<div id="">'.HS_html_gen::textTable2dataTables_JS($file, $usersDir, 'input_'.$file, 0).'<div>';

}
elsif (
($type eq 'arc') or 
($type eq 'hlp') or 
($type eq 'res') or 
($type eq 'usr') or 
($type eq 'net') or 
($type eq 'fgs') or 
($type eq 'sbm')) {
if (($type eq 'net') or ($type eq 'fgs')) {
my ($spe, $stat, %statfile, @fields, $fi, @ar, $i);
for $spe('hsa', 'mmu', 'ath', 'rno') {
%statfile = (
"NET" => $HSconfig::netDir.'/'.$spe.'/'.'NW.stats.txt', 
"FGS" => $HSconfig::fgsDir.'/'.$spe.'/'.'FG.stats.txt'
);
for $stat(("FGS", "NET")) {
if ($stat eq "FGS") {
@fields = ('ngenes', 'ngroups');
$pl->{$statfile{$stat}}->{'filename'} = 1;
$pl->{$statfile{$stat}}->{'ngenes'} = 2;
$pl->{$statfile{$stat}}->{'ngroups'} = 3;
$i = 0;
 open  IN, $statfile{$stat} or die "Could not re-open $statfile{$stat} ...\n";
 while ($_ = <IN>) {
 next if ++$i == 1 ;
chomp;
@ar = split("\t", $_);
for $fi(@fields) {
# $content .= $HSconfig::fgsAlias -> {$spe}->{'BioCarta'}.'<br>' if $debug;
# $content .= $ar[$pl->{$statfile{$stat}}->{$fi}].'<br>' if $debug;
$HSconfig::fgsDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = 
$ar[$pl->{$statfile{$stat}}->{$fi}];
 }}
 close IN;
}

if ($stat eq "NET") {
@fields = ('ngenes', 'nlinks');
$pl->{$statfile{$stat}}->{'filename'} = 1;
$pl->{$statfile{$stat}}->{'ngenes'} = 3;
$pl->{$statfile{$stat}}->{'nlinks'} = 2;
$i = 0;
 open  IN, $statfile{$stat} or die "Could not re-open $statfile{$stat} ...\n";
 while ($_ = <IN>) {
 next if ++$i == 1 ;
chomp;
@ar = split("\t", $_);
# print join("&npsp;", @ar)."<br>\n" if $main::debug;
for $fi(@fields) {
# $content .= $HSconfig::fgsAlias -> {$spe}->{'BioCarta'}.'<br>' if $debug;
# $content .= $ar[$pl->{$statfile{$stat}}->{$fi}].'<br>' if $debug;
$HSconfig::netDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = 
		$ar[$pl->{$statfile{$stat}}->{$fi}];
 }}
  close IN;
 }}}}

$content .= 
	HS_html_gen::ajaxSubTab($type, $species, $mode).
	HS_html_gen::ajaxJScode($type);
} 
else {
print "No such job defined...".'<br>'."\n";
exit;
}
return $content;
}
# https://www.evinet.org/cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout=undefined;showself=showself;project_id=HYPERSET.ne;species=hsa;jid=725068915901

sub saveFiles { #save primary user-uploaded files
my($filename, $type) = @_; 
my($name, $path, $extension ) = fileparse ($filename, '\..*');
$filename = $name.$extension;
$filename =~ tr/ /_/;
$filename =~ s/[^$HStextProcessor::safe_filename_characters]//g;
my $upload_filehandle = $q->upload($type);
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>' ;# if $debug;
open ( UPLOADFILE, "> $usersDir/$filename" ) or print STDERR "Did not open filehandle... $!";
binmode UPLOADFILE;
while ( <$upload_filehandle> )
{
print UPLOADFILE;
}
print "checking filename:$filename"."<br>" if $debug;
close UPLOADFILE;
#CGIVENN#
my ($fail_status, $fail_msg) = checkAgsFile("$usersDir/$filename");
if ($fail_status){
    return($fail_status, $fail_msg);
}
#CGIVENN#
$savedFiles -> {data} -> {$type} = $filename;
#print $savedFiles -> {data} -> {$type}."<br>" if $debug;
print "input file type: ".$type.'<br>' if $debug;
return();
}

#CGIVENN#
sub checkAgsFile {
 my $fl_name = $_[0];
 my $line_num = 1;
 my $err_status = 0;
 my $err_message = 0;
 my ($header, @head_val);
 my $pat = $HSconfig::vennFieldTypeMask;
 if ($fl_name !~ m/\.VENN|\.groups|\.CIDs/i) {
  $err_status = 1;
  $err_message = "For Differential expression analysis: filename should contain the keyword '.VENN'(or '.venn') <br>Example: test.venn.txt , test.VENN.txt <br><br> For AGS file, filename should contain the keyword '.groups' as an extension <br>Example: example.groups <br><br> For converting geneids into other formats, filename should contain the keyword '.CIDs' in its filename.Example:sample.CIDs.txt<br>";
} elsif ($fl_name =~ m/.VENN/i){
 open(my $fl, $fl_name);
 $header = <$fl>;
 @head_val = split(/\t/, $header); 
#my $pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-[FC|FDR|p]";
 if (! grep(/$pat/i, $header) ) {
  $err_status = 1;
  $err_message = "File doesnot contain the DE columns<br>Please ensure that the first line in the file should contain the pattern $pat<br><br>Example: A_vs_B-FC, A_vs_B-p, A_vs_B-FDR";
} else {
 my $p_pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-P";
 my $fc_pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-FC";
 my $fdr_pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-FDR";
 my @checked_pair;
 my @matches_p = $ln =~ m/$p_pat/gi;
 my @matches_fc = $ln =~ m/$fc_pat/gi;
 my @matches_fdr = $ln =~ m/$fdr_pat/gi;
 my @matches_all = (@matches_p, @matches_fc, @matches_fdr);

 for my $m(@matches_all){
     if ( grep(/$m/, @checked_pair) ){next;}
     my @missing_cat;
     if ( ! grep(/$m/, @matches_p) ) {$err_status = 1; push(@missing_cat, "P-val");}
     if ( ! grep(/$m/, @matches_fc) ) {$err_status = 1; push(@missing_cat, "FC-val");}
     if ( ! grep(/$m/, @matches_fdr) ) {$err_status = 1; push(@missing_cat, "FDR-val");}
     if ($err_status){
         $err_message = "Contrasts ".$m." is missing ".join(",", @missing_cat) ."<br>Requires all three columns for each contrast. <br> Example: (A_vs_B-P,A_vs_B-FC,A_vs_B-FDR). <br> Please modify accordingly and submit the file again.";
     }
     push(@checked_pair, $m);
 }}
 if(!$err_status) {
 my %duplicates;
 my @gene_ind = grep { $head_val[$_] =~ /gene/i } 0..$#head_val;
 while (my $fln = <$fl>) {
     $line_num++;
     my @col_val = split(/\t/, $fln);
     my $thegene = $col_val[$gene_ind[0]];
     if ($fln =~ m/\t\s*\t/){
         $err_status = 1;
         $err_message = "Line ".$line_num." contains missing columns.";
    } elsif ($thegene =~ m/[A-Z0-9_\.][\s\&\@][A-Z0-9_\.]/i){
         $err_status = 1;
         $err_message = "Wrong gene symbol format in AGS file, Invalid ID:<br> ".$thegene." submitted at line ".$line_num." in <br>".$fl_name." contains an invalid gene name"
    } elsif (defined ($duplicates{$fln}) ) {
	$err_status = 1;
	$err_message = "File contains duplicate lines. Check line:".$line_num."<br>Please make sure duplicate lines does not exist in the file";	
     }
 $duplicates{$fln}++;
 }
 if ($line_num < 10) {
	my $n_genes = $line_num -1;
 	$err_status = 1;
        $err_message = "Low number of genes <br> File contains ".$n_genes." genes, required file with more than 10 genes";
     }
 close $fl;
 }}
 if ($err_status){
   deleteFiles('', $fl_name);
 }
 elsif ($fl_name =~ m/.VENN/i){
 my @hd_contrasts = ();
 foreach my $hd_val(@head_val){
  if ($hd_val =~ /^([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-[FC|FDR|p]$/){	
  	push (@hd_contrasts, $1);
  	}	
 }
 my $file_stat = "Number of rows: $line_num\nNumber of columns: $#head_val\n<br>The  ".scalar @hd_contrasts." sample contrasts provided in the header which contains -FC,-p, -FDR extensions are :\n<br>".join("\n", map { " - ".$_ } @hd_contrasts)."\n"; my($name, $path, $extension ) = fileparse ($fl_name, '\..*');
 $op_nm = $name.$file_stat_ext;
 $op_nm =~ tr/ /_/;
 $op_nm =~ s/[^$HStextProcessor::safe_filename_characters]//g;
 open (my $ifl, "> $usersDir/$op_nm");
 print $ifl $file_stat;
 close $ifl;
 } 
return($err_status, $err_message);
}
#CGIVENN#

sub deleteFiles {
my ($location, $filename) = @_;
my($name, $path, $extension ) = fileparse ($filename, '\..*'); 
system ( 'rm '.$location.$filename) and print "Could not remove files... $!";
#CGIVENN#
system ( 'rm '.$location.$name.$file_stat_ext) and print "Could not remove stat file... $!";
}

sub saveIntoProject { #save user-created intermediate/final files
my($location, $filename, $ext, $content) = @_;
my ($fi); 
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>'  if $debug;
open ( SAVE, ' > '.$location.$filename.'.'.$ext ) or return "Did not open filehandle... $!";
print SAVE '"'.$content.'"';
close SAVE;
return undef;
}

sub listFiles {
my($location, $type) = @_;
my ($filename, @ar, @a2, $content, $buttons, $ac, $head, $name); 
my @actions = ('Delete', 'Display AGS', 'Venn diagram', 'Convert ID');
chdir($location);
 #$content .= 'ls -hl *.'.$type.' | ';
open ( LS, 'ls -hl *'.(($type) ? '.'.$type : '').' | grep -v "'.$file_stat_ext.'" | ') or print "Could not list files... $!";
$content .= '<table id="listFiles" class="ui-state-default ui-corner-all">';
for $ac(@actions) {
$head .= '<th title="'.$ac.'"></th>';
} #<th>Select</th>
$content .=  '<thead><tr><th>Filename</th><th>Date</th><th>Size</th>'.$head.'</tr></thead>'."\n";
my $tag = 'ags';
$tag = 'cy' if $type eq $HSconfig::users_file_extension{'JSON'};
while ($filename = <LS> ) {
@ar = split($HSconfig::userGroupID, $filename);
@a2 = split(/\s+/, $ar[1]);
$name = $a2[5];
#print "array: $ar[1]".'<br>' if $debug;
#print "filename: $a2[0]".'<br>' if $debug;
if ($a2[1]) {
#CGIVENN# 
my $stat_info_txt = '';
my($stname, $stpath, $stext) = fileparse ($name, '\..*');
my $stfile = $location.$stname.$file_stat_ext;
if (-e $stfile){
open (my $ifh, '<' , $stfile ) or die "Cant open file";
$content .= '<div id="flstat-'.$stname.'" class="vennhdline"><p>';
while (<$ifh>) {
chomp $_;
$content .= '<b>'.$_.'</b><br>';
}
$content .= '</p></div>';
$stat_info_txt = '<span style="color:#E87009" class="clickable vennhdlineOpener" onclick="openDialog(\'flstat-'.$stname.'\');"> &#9432 </span>';
close $ifh;
}
$content .= '<tr><td>'.$name.$stat_info_txt.'</td><td>'.join(' ', ($a2[2], $a2[3], $a2[4])).'</td><td>'.$a2[1].'</td>';
#$content .= '<td><input type="radio" name="selectradio-table-'.$tag.'-ele" id="selectradio-table-'.$tag.'-ele" value="'.$a2[5].'"/></td>';
undef $buttons; # 
for $ac(@actions) {
$buttons .= '<td>'.
(($name =~ m/${$HSconfig::uploadedFile->{$ac}}{mask}/i and $name =~ m/${$HSconfig::uploadedFile->{$ac}}{keyword}/i) ? '<button type="submit" name="selectradio-table-ags-ele" value="'.$name.'" id="'.${$HSconfig::uploadedFile->{$ac}}{button}.$name.'" class="sbm-ags-controls ui-widget-header ui-corner-all qtip-transient" title="'.${$HSconfig::uploadedFile->{$ac}}{title}.'">'.$ac.'</button>' : '<span title="'.${$HSconfig::uploadedFile->{$ac}}{empty}.'">&nbsp;&nbsp;&nbsp;</span>')
.'</td>';
}
$content .= ''.$buttons.''.'</tr>'."\n";
}}
$content .= '</table>	
<script   type="text/javascript">
//writeHref();
$(function() {
    $( ".vennhdline" ).dialog({
        resizable: false,
        modal: true,
        title: "User file information",
        width:  ' . $HSconfig::img_size->{roc}->{width}. ',
        height: "auto",
        position: {my: "center", at: "center", of: window},
        autoOpen: false,
        show: {effect: "blind", duration: 380},
        hide: {effect: "explode", duration: 400}
        });
    });
HSonReady();
updatechecksbmAll();
$("#listFiles").DataTable('.HS_html_gen::DTparameters(undef).');
$(\'[class*="sbm-ags-controls"]\').qtip({
    show: "mouseover",
    hide: "mouseout",
    content: {
    text: function(event, api) {
    return $(this).attr("title");
       }
    }, 
    position: {
    my: "top left",
    at: "bottom center",
        adjust: {
            screen: true,
            method: "shift flip"
            }
        },
     style: {
          classes: "qtip-bootstrap",
          tip: {
               width: 16,
               height: 8
               }}
     });
$(\'[class*="-ags-controls"]\').css("visibility", "visible");
showSubmit();
</script>';
close LS;
return($content);
}
#CGIVENN#


sub restoreNodesAndEdges  {
my($location, $file) = @_;
my($content);
open IN, $location.$file or die "Cannot open JSON file $file...\n";
while ($_ = <IN>) {
$content .= $_;
}
close IN;
 $content =~ s/^\"//;
 $content =~ s/\"$//; 
return($content);
}
use warnings;

