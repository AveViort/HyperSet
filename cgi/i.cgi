#!/usr/bin/perl -w
use warnings;
use strict;
use Net::SMTP;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use HStextProcessor;
use HSconfig;
use HS_SQL; 

use HS_html_gen;
use HS_bring_subnet;
use HS_cytoscapeJS_gen;
use Proc::Background;

use lib "/var/www/html/research/HyperSet/cgi/NETwork_analysis";
use lib "/var/www/html/research/users_tmp";
use NET;
use venn_click_points;
use constant SPACE => ' ';
no warnings;


our $dbh = HS_SQL::dbh('hyperset');
$CGI::POST_MAX=102400000;
our $q = new CGI;
our $species = $q->param("species") ? $q->param("species") : '';
our $action = $q->param("action");
# print STDERR '###########Species: '.$species .'<br>';
# system('');
# system('rm /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/offline/*');
# system('rm /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/offline_results/offline/*');
# system('cp /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/_tmpNEA* /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/offline/');
# system('cp /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/_tmpNEA* /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/offline_results/offline/');
# exit;
my $debug = 0;
$ENV{'PATH'} = '/bin:/usr/bin:';
# $ENV{'PATH'} = '/bin:/usr/bin:';
our ($conditions, $pl, $nm, $conditionPairs, $pre_NEAoptions, $itemFeatures, 
$savedFiles,  $fileUploadTag, $usersDir, $usersTMP, $sn, $URL);
our $NN = 0;
my(@genes, 
# $Genes, 
$type, $step, $NEAfile, $mm, $quasyURL, $callerNo, $AGS, $FGS);
our($AGSselected, $FGSselected, $FGScollected, $NETselected);
my @names = $q->param;
our $restoreSpecial = 0; # see sub tmpFileName()
$fileUploadTag = "_table";
#return 0;

# my $parname;
# my $pcont = '';
# my @parnames = $q->param;
# foreach $parname ( @parnames ) {$pcont =  $pcont.$parname."=".$q->param($parname).";\n";}  
# my $debug_filename = "/var/www/html/research/users_tmp/myveryfirstproject/subnet-2.txt";
# open(my $fh, '>', $debug_filename);
# print $fh "Params: ".$pcont."\n";
# close $fh;
if ($q->param('action')  eq  "subnet-ags") {
		$HS_bring_subnet::keep_query                         = 	$q->param('keep_query');
		$HS_bring_subnet::submitted_coff                     = 	$q->param('coff'); 
		$HS_bring_subnet::order                              =	$q->param('order'); #network order
		$HS_bring_subnet::reduce  =  'yes' if defined($q->param('reduce_by')); 
		if ($HS_bring_subnet::reduce) {#choice of algorithm to reduce too large networks
			$HS_bring_subnet::reduce_by           = $q->param('reduce_by');
			$HS_bring_subnet::desired_links_total = $q->param('no_of_links');
			$HS_bring_subnet::qvotering           = $q->param('qvotering');
		}
		# else {$HS_bring_subnet::desired_links_total = 1000000;}
	 }
our $uname = $q->param("username");
$uname = 'Anonymous' if ((!defined($uname)) || ($uname eq ''));
our $sign = $q->param("signature");
$sign = '' if !defined($sign);
our $sid = $q->param("sid");
$sid = '' if !defined($sid);
our $projectID = $q->param("project_id");
my $shared = $q->param("shared");
# check if link was a shareable one
my $stat;
if ((defined($shared)) && ($shared ne "")) {
	$stat = qq/SELECT jid FROM projectarchives WHERE share_hash LIKE \'$shared'\ /;
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $control_jid = $sth->fetchrow_array;
	$sth->finish;
	# empty jid is a mark of broken link
	if (($control_jid ne $q->param("jid")) || ($control_jid eq "")) {
		print "Content-type: text/html\n\n";
		print "Permission through shared link denied. JID: ".$q->param("jid")." Control jid: ".$control_jid;
		exit 0;}
	}

# check permission
else {
if ((defined($projectID)) && ($projectID ne "")) {
	$stat = qq/SELECT session_valid(\'$uname'\, \'$sign'\, \'$sid'\)/;
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $sessionstat = $sth->fetchrow_array;
	$stat = qq/SELECT is_owner(\'$uname'\, \'$projectID'\)/;
	$sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	my $ownership = $sth->fetchrow_array;
	$sth->finish;
	# if no ownership rights or session is not valid - terminate i.cgi
	if (not($sessionstat) or not($ownership)) {
		print "Content-type: text/html\n\n";
		if (not ($sessionstat) and ($ownership)) {
			print '<script>
				usetCookie("project_id", "'.$projectID.'", 168);
				prepare_relogin();
				showLoginForm();</script>';
		}
		print "Permission denied. Project: ".$projectID." User: ".$uname." Signature: ".$sign." SID: ".$sid." Session status: ".$sessionstat." Ownership status: ".$ownership;
		exit 0;}
		
		}
}
my ($err_stat, $err_msg);
our $GSEA_pvalue_coff = 0.01;

$HSconfig::printMemberGenes = $q->param("printMemberGenes");
if ((defined($projectID)) && ($projectID ne "")) {
$usersTMP = $HSconfig::usersTMP.$projectID.'/';
$usersDir = $HSconfig::usersDir.$projectID.'/';
system("mkdir $usersDir 1>/dev/null 2>/dev/null");
system("mkdir $usersTMP 1>/dev/null 2>/dev/null");
}
$step = '';
# $mode 		= $q->param("analysis_type");
$type 		= $q->param("type"); # if this parameter is not defined, then $type will be set downstream.
# $type 		= '' if !defined($type);
if ($q->param("mode") eq 'begin') {
$step = 'mainTab';
}
if ($q->param("mode") eq 'fill_menu') {
$step = 'fillMenu';
}



##################################################
@{$AGSselected} = $q->param("AGSselector") if $q->param("AGSselector");
@{$FGSselected} = $q->param("FGSselector") if $q->param("FGSselector");
@{$FGScollected} = ($q->param("FGScollection")) if $q->param("FGScollection");
@{$NETselected} = $q->param('NETselector') if $q->param('NETselector');
# print STDERR "NETselected: ". $NETselected ;
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
}
}}
##################################################



if ($q->param("action") eq 'sbmRestore') {
$step = 'saved_nea';
} 
elsif ($q->param("action") eq 'display-archive') {$step = 'display-archive';} # <= a display of one archived jobs in a separate window. not the same as 'arc' requested via function displayProjectTable  from HS.js
elsif ($q->param("action") eq 'display-file') {$step = 'display-file';} 
elsif ($q->param("action") eq 'sbmSubmit') {$step = 'executeNEA';} 
if (($q->param("action") =~  m/^subnet\-([0-9]+)$HS_html_gen::actionFieldDelimiter1([0-9A-Z_\;\:\.\-\(\)\=]+)$HS_html_gen::actionFieldDelimiter1([0-9A-Z_\;\:\.\-\(\)\=]+)$/) or ($q->param("action") =~  m/^subnet\-([0-9]+)$HS_html_gen::actionFieldDelimiter2([0-9A-Z_\-]+)$HS_html_gen::actionFieldDelimiter2([0-9A-Z_\-]+)/)) {
$step = 'shownet';
($quasyURL, $callerNo, $AGS, $FGS) = ($q->param("subneturlbox"), $1, $2, $3);
# my $debug_filename = "/var/www/html/research/users_tmp/myveryfirstproject/subnet.txt";
# open(my $fh, '>', $debug_filename);
# print $fh "subneturlbox=".$quasyURL."\n";
# close $fh;
} 
if ($q->param("action") eq  "subnet-ags") {
$step = 'shownet';
($quasyURL, $callerNo, $AGS, $FGS) = (
	HStextProcessor::subnetURL(
		$AGSselected, 
		$AGSselected, 
		$species, 
		$HSconfig::netfieldprefix.join($HS_html_gen::fieldURLdelimiter.$HSconfig::netfieldprefix, $q->param('NETselector')),
		$q->param("nlinks") ? $q->param("nlinks") : 1000,
		$q->param("order") ? $q->param("order") : 0, 
		1), 
undef, undef, undef);
# my $debug_filename = "/var/www/html/research/users_tmp/myveryfirstproject/subnet.txt";
# open(my $fh, '>', $debug_filename);
# print $fh "not.subneturlbox=".$quasyURL."\n";
# close $fh;
} 
elsif ($q->param("action") =~ m/vennsubmitbutton-table-ags-/i) {$step = 'create_venn';} 
elsif ($q->param("action") eq 'updatebutton2-venn-ags-ele') { $step = 'update_venn';} 
elsif ($q->param("action") eq 'genes-available') {$step = 'genes-available';} 
elsif ($q->param("action") eq 'fgs-available') {$step = 'fgs-available';} 
elsif ($q->param("action") =~ m/run-exploratory-/) {$step = 'executeExploratory';} 
elsif ($q->param("action") =~ m/listbutton-table-([a-z]+)-ele/i) {$step = 'list_'.$1.'_files';} 
elsif ($q->param("action") =~ m/deletebutton-table-([a-z]+)-/i) {$step = 'delete_'.$1.'_files';} 
elsif ($q->param("action") eq 'sbmSavedCy') {$step = 'saved_json';} 
elsif ($q->param("action") eq 'submit-save-cy-json3') {$step = 'save_json_into_project';} 
elsif ($q->param("action") =~ m/uploadbutton-table-([a-z]+)-ele/i) {
for $mm(@names) {
if ($mm =~ m/$fileUploadTag$/i) {
($err_stat, $err_msg) = saveFiles($q->param($mm), $mm)  if ($mm =~ m/_table/) and $q->param($mm);
}}
$step = 'list_'.$1.'_files';
$step = 'wrong_upload_format' if ($err_stat);
} 
$type = $step if ($step eq 'save_json_into_project')
 or ($step eq 'display-file')
 or ($step eq 'create_venn')
 or ($step eq 'update_venn')
 or ($step =~ m/list_([a-z]+)_files/i) # eq 'list_ags_files')
 or ($step =~ m/delete_([a-z]+)_files/i) # eq 'delete_ags_files')
 or ($step eq 'wrong_upload_format')
 or ($q->param("step") =~ m/ags_select|fgs_select|net_select/i); # eq 'ags_select')

my $fl;	
if ($q->param("use-venn")) {
for $fl($q->param("from-venn")) {
push @{$AGSselected}, $q->param("VennSelector_gene_list_".$1) if ($fl =~ m/^gene_list_([pm]+)$/i);
}}
our $delimiter;
	if (defined($q->param("gene_column_id_ags"))) {
my $currentAGS = $usersDir.$savedFiles -> {data} -> {"ags_table"};
$pl->{$currentAGS}->{gene} = $q->param("gene_column_id_ags")  - 1;
$pl->{$currentAGS}->{group} = $q->param("group_column_id_ags") - 1;
$pl->{$currentAGS}->{score} = $q->param("score_column_id_ags") - 1;
$pl->{$currentAGS}->{subset} = $q->param("subset_column_id_ags") - 1;
$pl->{$currentAGS}->{delimiter} = $q->param("delimiter_ags");
$delimiter = $pl->{$currentAGS}->{delimiter};
$delimiter = "\t" if lc($delimiter) eq 'tab';
$delimiter = ',' if lc($delimiter) eq 'comma';
$delimiter = ' ' if lc($delimiter) eq 'space';
$pl->{$usersDir.$q->param('selectradio-table-ags-ele')} = $pl->{$currentAGS};
			}
			
print "Content-type: text/html\n\n"  if ($step ne 'shownet');
			
my $content = '';
# print STDERR '<br>Submitted form values: <br>'.$q->query_string.'<br>'  if $debug; 
print STDERR '###########STEP: '.$step  if $debug; 
if ($step eq 'mainTab') {
$content .= '<br>Submitted tab_id: <br>'.$q->param("tab_id").'<br>' if $debug;
$content .= generateTabContent('analysis_type_ne');
} 
elsif ($step eq 'fillMenu') {
$content .= generateMenuContent();
} 
else {
if ($step eq 'executeNEA') {
	my $executed = executeNEA();
	if (!$executed or ($executed =~ m/[A-Z\>\<]+/i)) {
	print $executed;
	exit;
} 
$content .= printNEA($executed, $projectID);
}
elsif (($step eq 'display-archive') and $projectID) {
$content .= printNEA('project', $projectID);
}
elsif ($step eq 'genes-available') {
$content .= join(';', (sort {$a cmp $b} HS_SQL::genes_available($species, undef))) if $species;
}
elsif ($step eq 'fgs-available') {
$content .= join(';', (sort {$a cmp $b} HS_SQL::fgs_available($species, undef))) if $species;
}
elsif ($step eq 'executeExploratory') {
$content .= executeExploratory($1) if $q->param("action") =~ m/run-exploratory-([0-9A-Z]+)$/i;
}
elsif ($step eq 'saved_nea') { 
$content .= jobFromArchive($projectID, $q->param("jid"));  
}
elsif ($step eq 'saved_json') {
if (defined($usersTMP)) {
$content .= restoreNodesAndEdges($usersTMP, $q->param("selectradio-table-cy-ele"));
open OUT, '> '.$main::usersTMP.'debug.table-cy-ele.html'; print OUT $content; close OUT;
}}

elsif ($step eq 'shownet') {
# print STDERR "bsURL: ".$q->param("subneturlbox") if $debug;
$content .=  printNet($quasyURL, $callerNo, $AGS, $FGS); 
# open OUT, '> '.$main::usersTMP.'debug_net.html'; print OUT $content; close OUT;
} 
else {
if ($type eq 'arc') {	
	our $jobToRemove; 
	$jobToRemove = $q->param("job_to_remove") if $q->param("job_to_remove");
	$content .= HS_html_gen::printTabArchive($projectID, $jobToRemove);
	} else {
$content .= generateSubTabContent($type, $species); 
}
}
}
HS_html_gen::mainStart() if ($q->param("mode") eq 'standalone' or ($q->param("instance") eq 'new'));
my $newTitle = 'EviNet archive';
$HS_html_gen::mainStart =~ s/TLE\>(.+)\<\/TIT/TLE\>$newTitle<\/TIT/ if $step eq 'saved_nea';
$content = $HS_html_gen::mainStart.$content.$HS_html_gen::mainEnd if ($q->param("mode") eq 'standalone');
print $content; 
# print STDERR "-----------------mainStart"."\n";
# open OUT, '> '.$main::usersTMP.'debug.'.join('.', ($step, $type)).'.html'; print OUT $content; close OUT;
$dbh->disconnect;

sub generateTabContent {
my($tab) = @_;
my @ar = split('_', $tab); my $main_type = $ar[2];
my $content = 
'<div id="analysis_type_'.$main_type.'"  class="main_ajax_menu form '.$main_type.'" >'.
HS_html_gen::ajaxSubTabList($main_type).
HS_html_gen::ajaxJScode($main_type, $species);
return($content);
}

sub generateMenuContent {
return(HS_html_gen::ajaxMenu('menu'));
}


sub executeExploratory {
my($mode) = @_;
my($content, $outfile);

if ($mode eq 'pca') {
$outfile = 'pca'.HStextProcessor::generateJID().'.html';
system("Rscript ../R/runExploratory.r --vanilla --args mode=$mode table=".$usersDir.$q->param('table')." colnames=".$q->param('colnames')." rownames=".$q->param('rownames')." out=$outfile delimiter=TAB"); # start=4 end=11 
$content = '<a href="'.$HSconfig::Rplots->{dir}.$outfile.'" target="_blank" class="clickable">3D PCA plot</a>';
} elsif ($mode eq 'hea') {
$outfile = 'heatmap'.HStextProcessor::generateJID().'.html';
my($pg, $lst);

my($rnms);
push @{$rnms}, @{HStextProcessor::parseGenes($q->param('sgs_list'), SPACE)};
system("Rscript ../R/runExploratory.r --vanilla --args mode=$mode table=".$usersDir.$q->param('table')." colnames=".$q->param('colnames')." rownames=".$q->param('rownames')." out=$outfile delimiter=TAB  normalize=".$q->param('normalize')." hclust_method=".$q->param('hclust_method')); 
$content = '<a href="'.$HSconfig::Rplots->{dir}.$outfile.'" target="_blank" class="clickable">Heatmap</a>';
} 
return $content;
}

sub executeNEA {
my($ags, $agsSource, $fgs, $fgsSource, $netSource, $outFile, $filename, $jobParameters, $executeStatement, $email, $op);
my $jid = $q -> param("jid"); #generateJID();
# check if the job is already executing (see Evinet.todo to learn more about double-run bug)
# my $stat = qq/SELECT started FROM projectarchives WHERE jid LIKE \'$jid'\ /;
# my $sth = $dbh->prepare($stat) or die $dbh->errstr;
# $sth->execute( ) or die $sth->errstr;
# my $control = $sth->fetchrow_array;
	##print("Control: ".$control." <br>");
# $sth->finish;
# if ($control eq "") {
	$outFile = tmpFileName('NEA', $jid);
	$jobParameters -> {jid} = $jid;
	$jobParameters -> {rm} = $ENV{REMOTE_ADDR};
	$jobParameters -> {projectid} = $projectID;
	$jobParameters -> {species} = $species;
	$jobParameters -> {sbm_selected_ags} = $AGSselected;
	$jobParameters -> {sbm_selected_fgs} = defined($FGScollected)? $FGScollected : $FGSselected;
	$jobParameters -> {sbm_selected_net} = $NETselected;
	$jobParameters -> {genewiseAGS} = $q->param("genewiseAGS") ? 'TRUE' : 'FALSE';
	$jobParameters -> {genewiseFGS} = $q->param("genewiseFGS") ? 'TRUE' : 'FALSE';
	$jobParameters -> {min_size} = $q->param("min_size") ? $q->param("min_size") : 'NULL';
	$jobParameters -> {max_size} = $q->param("max_size") ? $q->param("max_size") : 'NULL';
	$jobParameters -> {started} = 'LOCALTIMESTAMP';

	my $thisURL = $HSconfig::BASE;
	$jobParameters -> {url} = HS_html_gen::createPermURL($jobParameters);

	if ($q->param("use-venn")) {# print selected genes directly to the agsFile:
		$ags = "#venn_lists";
	} elsif ($q->param("sgs_list")) {# print selected genes directly to the agsFile:
		$ags = "#sgs_list";
	} elsif ($q->param("AGSselector")) {
	$ags = $usersDir.$q->param("selectradio-table-ags-ele");
	}
	else {
	return HS_html_gen::errorDialog('error', "Input", 
	'Altered gene set(s) not defined.<br>Use one of the alternative input options or run one of our Demos.', 
	"Altered gene sets");
	}
	
	my($textFileFields);
%{$textFileFields} = (
	 'group'  => $q->param('group_column_id_ags') - 1,
	 'id'  => $q->param('gene_column_id_ags') - 1,
	 'score'  => ($q->param('score_column_id_ags') ? $q->param('score_column_id_ags') - 1 : undef),
	 'subset'  => ($q->param('score_column_id_ags') ? $q->param('subset_column_id_ags') - 1 : undef)
 );
 
	print STDERR 'sbm_selected_ags: '.join(' ', @{$jobParameters -> {sbm_selected_ags}})."\n" if $debug;	
	$agsSource = HStextProcessor::compileGS2('ags', 
	$jid, 
	$ags, 
	$jobParameters -> {sbm_selected_ags}, 
	$textFileFields,
	$jobParameters -> {genewiseAGS},
	$species, 
	0);
	# return HS_html_gen::errorDialog('error', "Input", $agsSource);
	return HS_html_gen::errorDialog('error', "Input", 
	'Altered gene set input was not usable.<br>This might be caused by submitting incompatible gene/protein IDs <br>or using irrelevant input category (File/Text box/Venn diagram).<span  class=\'clickable dialogOpener\' onclick=\'openDialog(\"acceptedIDs\");\'>Accepted IDs</span>', 
	"Altered gene sets") if $agsSource eq 'empty';

	print  STDERR '+++AGS: '.(defined($ags) ? $ags : '---')."\n" if $debug;
	print  STDERR '+++AGSselected: '.join(' ', @{$AGSselected})."\n" if $debug;	
	print  STDERR '+++AGSSource: '.$agsSource."\n" if $debug;	

	if ($q->param("cpw_list")) {# print selected genes directly to the FGS source file:
	$fgs = "#cpw_list";
	} elsif ($q->param("FGSselector")) {
	$fgs = $usersDir.$q->param("selectradio-table-fgs-ele");
	}
	elsif ($q->param("FGScollection")) {
	$fgsSource = join($HSconfig::RscriptParameterDelimiter, @{$FGScollected});
	} else {
	return HS_html_gen::errorDialog('error', "Input", 
	'Functional gene set(s) not defined.<br>Use one of the alternative input options or run one of our Demos (see the top menu)', 
	"Functional gene sets") ;
	} 

	if (defined($fgs))  {
%{$textFileFields} = (
	 'group'  => $q->param('group_column_id_fgs') - 1,
	 'id'  => $q->param('gene_column_id_fgs') - 1,
	 'score'  => ($q->param('score_column_id_fgs') ? $q->param('score_column_id_fgs') - 1 : undef),
	 'subset'  => ($q->param('score_column_id_fgs') ? $q->param('subset_column_id_fgs') - 1 : undef)
 );	
 $fgsSource = HStextProcessor::compileGS2('fgs', 
	$jid, 
	$fgs, 
	$jobParameters -> {sbm_selected_fgs}, 
	$textFileFields,
	$jobParameters -> {genewiseFGS},
	$species, 
	0);
	}
	 
	# print STDERR '---FGS: '.(defined($fgs) ? $fgs : '---')."\n" if $debug;
	# print STDERR '---FGSselected: '.(defined($FGSselected) ? join(' ', @{$FGSselected}) : '---')."\n" if $debug;	
	# print STDERR '---FGScollected: '.(defined($FGScollected)? join('; ', @{$FGScollected}) : '---')."\n"; #if $debug;	
	# print STDERR '---FGSSource: '. $fgsSource." #FFFFFFF\n";
if ($#{$NETselected} >= 0) {
	$netSource = $HSconfig::netfieldprefix.join($HSconfig::RscriptParameterDelimiter.$HSconfig::netfieldprefix, @{$NETselected});
	$netSource =~ s/^$HSconfig::RscriptParameterDelimiter//;
	} else {
	return HS_html_gen::errorDialog('error', "Input", 
	'Nework version(s) not defined.<br>Use one of the alternative input options or run one of our Demos (see the top menu)', 
	"Network") ;
	} 


	my(%SQL, %LST, %IND, %COL);
	$LST{ags} = 'F'; 
	$SQL{ags} = 'F';
	$IND{ags} = ($jobParameters -> {genewiseAGS} eq 'TRUE') ? 'T' : 'F';
	$COL{colgeneags} = 2;
	$COL{colsetags} = 3;
	$COL{colscoreags} = 4;
	$COL{colsubsetags} = 5;

	$LST{fgs} = 'F'; 
	$SQL{fgs} = (defined($FGScollected)) ? 'T' : 'F'; 
	$IND{fgs} = ($jobParameters -> {genewiseFGS} eq 'TRUE') ? 'T' : 'F';
	$COL{colgenefgs} = 2;
	$COL{colsetfgs} = 3;
	$COL{colscorefgs} = 4;
	$COL{colsubsetfgs} = 5;
	
	$executeStatement = "Rscript $HSconfig::nea_software --vanilla --args ntb=".$HSconfig::network->{$species}." fgs=".$fgsSource." net=".$netSource." ags=".$agsSource." out=".$outFile." org=".$species
	." sqlags=".$SQL{ags}." lstags=".$LST{ags}." indags=".$IND{ags}
	." sqlfgs=".$SQL{fgs}." lstfgs=".$LST{fgs}." indfgs=".$IND{fgs}
	." colgeneags=".$COL{colgeneags}
	." colsetags=".$COL{colsetags}
	." colscoreags=".$COL{colscoreags}
	." colsubsetags=".$COL{colsubsetags}
	." colgenefgs=".$COL{colgenefgs}
	." colsetfgs=".$COL{colsetfgs}
	." colscorefgs=".$COL{colscorefgs}
	." colsubsetfgs=".$COL{colsubsetfgs};
	# print($executeStatement."\n");

	$jobParameters -> {commandline} = HS_html_gen::showCommandLine($executeStatement);
	# print STDERR '<br>'.$HSconfig::test.'<br>' if $debug;
	print STDERR '<br>'.$executeStatement.'<br>'; # if $debug;
	$email = $q->param('user-email') if ($q->param('user-email') =~ m/\@.+\./);
	print STDERR 'saveJob';
	saveJob($jid, $jobParameters);
	
sendNotification ($jobParameters -> {projectid}, $q->param('user-email'), $jid, undef, $jobParameters -> {url}, 'running')  if $email; # DISABLED IN HS_html_gen.pm: <INPUT type="text" name="user-email" id="user-email"...>
	# my $returnCode = ;
	print '<br>Start runNEAonEvinet.r...<br>'."\n" if $debug;
	#my $debug_filename = "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/debug.txt";
	#open(my $fh, '>', $debug_filename);
	#print $fh "Debug report executeNEA, JID: ".$jid." self PID: ".$$."\n";
	my $proc=Proc::Background->new($executeStatement);
	my $alive=$proc->alive;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	print "Job started: ".$hour.":".$min.":".$sec." <br>";
	#print $fh "Job started: ".$hour.":".$min.":".$sec." \n";
	while ($alive) {
		$alive=$proc->alive;
		sleep 1;
		system("echo 1 > /dev/null");
		($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
		#print "Job running: ".$hour.":".$min.":".$sec." PID: ".$proc->pid." SELF: ".$$."<br>";
		#print $fh "Job running: ".$hour.":".$min.":".$sec." PID: ".$proc->pid." SELF: ".$$."\n";
	}
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	print "Job finished: ".$hour.":".$min.":".$sec." <br>";
	#print $fh "Job finished: ".$hour.":".$min.":".$sec." \n";
	#if (!system($executeStatement)) {
	print STDERR 'confirmJob';
	#print $fh "Execution completed. Trying to confirm job...\n";
	#close $fh;
	confirmJob($jid); 
	sendNotification ($jobParameters -> {projectid}, $email, $jid, undef, $jobParameters -> {url}, 'done') if $email;
	# system("rm  ".tmpFileName('AGS', $jid).' '.tmpFileName('FGS', $jid).' '.tmpFileName('NET', $jid)) if !$debug;
	# } else {
	# $dbh->do("ROLLBACK;");
	#}
	return ($jid);
	# }
# else {
	# return undef; #("Double_run");
	# }
}

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
$dbh->do("COMMIT;");
return undef;
}

sub confirmJob {
my($jid) = @_;
my($stat);
#my $debug_filename = "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/debug.txt";
#open(my $fh, '>', $debug_filename);
#print $fh "Debug report from sub confirmJob\nJID: ".$jid."\n";
my $debug_filename = "/var/www/html/research/users_tmp/debug.txt";
open(my $fh, '>', $debug_filename);
print $fh "Debug report from sub confirmJob\nJID: ".$jid."\n";
my $outFile = tmpFileName('NEA', $jid);
print $fh "outFile: ".$outFile."\n";
open CNT, "wc $outFile | ";
my $li = <CNT>;
print $fh "li: ".$li."\n";
close CNT;
my $Nlines = 0;
print $fh "Nlines: ".$Nlines."\n";
$Nlines = $1 if $li =~ m/\s*([0-9]+)/;
 $dbh->do("COMMIT;");
 $dbh->do("BEGIN;");

#print $fh "STAT: ".$stat."\n";
my $stat = "UPDATE projectarchives SET status='done', finished=LOCALTIME, nlines=$Nlines where jid=\'".$jid."\';";
print $stat.'<br>'  if $debug;
print $fh "stat: ".$stat."\n";
$dbh->do($stat);
$dbh->do("COMMIT;");
print $fh "Done.";
close $fh;
return undef;
}

sub retrieveJobInfo {
my($jid, $fld) = @_;
my($rows, $fieldValue);
my $stat = "SELECT \* FROM projectarchives WHERE jid=\'".$jid."\';";
		my $sth = $dbh -> prepare_cached($stat) || die "Failed to prepare SELECT statement SELECT FROM projectarchives 2 ...\n";
		$sth->execute();
		while ( $rows = $sth->fetchrow_hashref ) {
			$fieldValue = $rows->{$fld};
			last; #single value return - even if there were multiple rows
			}
			$sth->finish;
			return $fieldValue;
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
my $filename;
return undef if (!defined($usersTMP));
if ($type eq 'NEArender') {
$filename = $main::usersTMP.'_tmpNEA'.'.'.$jid.".RData";
} else {
$filename = $main::usersTMP.'_tmp'.uc($type).'.'.$jid;
}
return($filename);
}
 
sub printNet {
my($bsURLstring, $callerNo, $AGS, $FGS) = @_;
my($data, $node);

print $bsURLstring."\n" if $debug;
($data, $node) = HS_bring_subnet::bring_subnet($bsURLstring);
my $parname;
my $pcont = '';
my @parnames = $q->param;
foreach $parname ( @parnames ) {$pcont =  $pcont.$parname."=".$q->param($parname).";";}  
# customfield='.$bsURLstring.' 
return(	
	'<div id="net_graph" style="width: '.
		$HSconfig::cy_size->{net}->{width}.'px; height: '.$HSconfig::cy_size->{net}->{height}.'px;">'.
		HS_cytoscapeJS_gen::printNet_JSON($data, $node, $callerNo, $AGS, $FGS).
	'</div><!--/div-->');
}

sub readNEA {
my($table) = @_;
my($key, $i, @arr, $neaData);
print "OPEN NEA FILE: $table".'<br>' if $debug;
open NEA, $table or return("deleted");
$_ = <NEA>;
HStextProcessor::readHeader($_, $table, "\t");
$i = 0;
while ($_ = <NEA>) {
chomp; 
@arr = split("\t", uc($_));
next if lc($arr[0]) ne 'prd';
next if ($arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}] < 1);
next if (($arr[$pl->{$table}->{$HSconfig::pivotal_nea_score}] < $HSconfig::min_pivotal_nea_score) or 
($arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] eq "") or 
$arr[$pl->{$table}->{$HSconfig::nea_fdr}] > $HSconfig::min_nea_fdr or 
$arr[$pl->{$table}->{$HSconfig::nea_p}] > $HSconfig::min_nea_p );
$neaData->[$i]->{wholeLine} = $_;
for $key(keys(%HSconfig::neaHeader)) {
$neaData->[$i]->{$HSconfig::neaHeader{$key}} = $arr[$pl->{$table}->{lc($HSconfig::neaHeader{$key})}];
}
$i++;
}
close NEA;
return("empty") if !$i;
return($neaData);
}

sub jobFromArchive {
my($proj, $job) = @_;
my $content = '
<div id="net_message" ></div>
<div id="net_up" ></div>
<div id="ne-up-progressbar"></div>
<script   type="text/javascript"> 
$(function() {
$( "#ne-up-progressbar" ).progressbar({
value: false
});
$( "#ne-up-progressbar" ).css({"visibility": "hidden", "display": "none"});
});
</script> 
<div id="nea_archive_tabs">
'.printJobTabs($proj, $job).'
</div>';
$content = '
<FORM id="form_ne" action="cgi/i.cgi" method="POST" enctype="multipart/form-data" autocomplete="on" >
<input type="hidden" name="selectradio-table-ags-ele" id="selectradio-table-ags-ele"  value="">	 <!-- name of file selected via AGS tab -->
<input type="hidden" name="selectradio-table-fgs-ele" id="selectradio-table-fgs-ele"  value="">	 <!-- name of file selected via FGS tab -->
<input type="hidden" name="selectradio-table-net-ele" id="selectradio-table-net-ele"  value="">	 <!-- name of file selected via Network tab -->
<input type="hidden" id="username" name="username" value="">
<input type="hidden" id="sid" name="sid" value="">
<input type="hidden" id="signature" name="signature" value="">
<input type="hidden" name="neafile" id="neafile" value="default">
<input type="hidden" name="step" id="step" value="default">
<input type="hidden" name="subneturlbox" id="subneturlbox" value="">
<input type="hidden" name="action" id="action"  value="default">	
<h3>Project: "'.$proj.'", analysis: #'.$job.'</h3>'.$content.'</FORM>';
$content .= '<script type="text/javascript">
$(function() {
$("#nea_archive_tabs").tabs();
});
</script>';
return($content);
}

sub printJobTabs {
my($proj, $job) = @_;
my $content = '
<!--input type="hidden"  name="neafile" id="neafile" value="default">
<input type="hidden"  name="step" id="step" value="default">
<input type="hidden"  name="subneturlbox" id="subneturlbox" value=""-->

<ul>
<li><a href="cgi/i.cgi?username='.$uname.';signature='.$sign.';sid='.$sid.';project_id='.$proj.';jid='.$job.';type=csw;analysis_type=ne;shared='.$shared.';">Graph</a></li>
<li><a href="cgi/i.cgi?username='.$uname.';signature='.$sign.';sid='.$sid.';project_id='.$proj.';jid='.$job.';type=tbl;analysis_type=ne;shared='.$shared.';">Table</a></li>
<!--li><a href="cgi/i.cgi?username='.$uname.';signature='.$sign.';sid='.$sid.';project_id='.$proj.';type=arc;analysis_type=ne;jid='.$job.';shared='.$shared.'">Archive</a></li-->
</ul>';
return($content);
}

sub printNEA {
my($jid, $possibleProject) = @_;

$jid = retrieveJobInfo($possibleProject, 'jid') if ($jid eq 'project');
# print $jid.'<br>';
my $content = '';
my($table, $key, $i, $neaData);
$table = tmpFileName('NEA', $jid);
$neaData = readNEA($table);
return HS_html_gen::errorDialog('error', "Project archive", 
$neaData eq 'deleted' ? 
"Job $jid:<br> this result is no longer stored in the Archive.<br>Try to reproduce it." : 
"Job $jid:<br> this output file does not contain lines indicating significant enrichment.<br>Try to re-run the analysis with different parameters.",
"Check and submit") if (ref($neaData) ne 'ARRAY');
my $subnet_url = prepareSubURL_and_Links($neaData, $pl, $table, $jid);

# $content .= '<br><a href="'.$URL->{$jid}.'">Save URL to this analysis</a>';
$content = '<!--br><div id="net_up" >
<div id="ne-up-progressbar"></div>
</div-->
Job #'.$jid.':
<div id="nea_tabs" >';
my $useAjaxTabs = 1;
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
urlfixtabs("#nea_tabs");
});
</script>';
if ($q->param("graphics")) {
$content .= '<div id="nea_graph" style="width: '.$HSconfig::cyPara->{size}->{nea}->{width}.'px; height: '.$HSconfig::cyPara->{size}->{nea}->{height}.'px;">'.
printTabGraphics($neaData, $pl, $table, $subnet_url).'</div>';
}
if ($q->param("table")) { 
$content .= '<div id="nea_table">';
$content .= printTabTable($neaData, $pl, $table, $subnet_url, $jid);
$content .= '</div>';
}
if ($q->param("commandline")) { 
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
			/*console.log("i.cgi, ID: " + ui.panel.attr("id"))
			ui.panel.html(\'<span class="\' + loadingClasses + \'"></span>\');*/

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
}, 
load: function( event, ui ) {
	//console.log(ui.tab.data("loaded"));
	//console.log(ui.panel);	
}
});
$( "#ne-up-progressbar" ).progressbar({value: false});
$( "#ne-up-progressbar" ).css({"visibility": "hidden", "display": "none"});
</script>
';
return($content);
}

sub prepareSubURL_and_Links {
my($neaData, $pl, $table, $jid) = @_;
my $species = retrieveJobInfo($jid, 'species');
my $networks = retrieveJobInfo($jid, 'sbm_selected_net');

my $su = HStextProcessor::subnet_urls($neaData, $pl, $table, $species, $networks);
return($su);
}

sub tabByURL {
my($jid, $ty) = @_;

my $content = '';
my($table, $key, $i, $neaData, $insert);
$table = tmpFileName('NEA', $jid);
$neaData = readNEA($table);
return HS_html_gen::errorDialog('error', "Project archive", 
$neaData eq 'deleted' ? 
"Job $jid:<br> this result is no longer stored in the Archive.<br>Try to reproduce it." : 
"Job $jid:<br> this output file does not contain lines indicating significant enrichment.<br>Try to re-run the analysis with different parameters.",
"Archive") if (ref($neaData) ne 'ARRAY');
my $subnet_url = prepareSubURL_and_Links($neaData, $pl, $table, $jid);
if ($ty eq 'csw') {
$content = printTabGraphics($neaData, $pl, $table, $subnet_url);
} 
elsif ($ty eq 'tbl') {
$content = printTabTable($neaData, $pl, $table, $subnet_url, $jid);
} else {
$content = '<br>Unknown tab type...<br>';
}
return($content);
}

sub printTabGraphics {
my($neaData, $pl, $table, $subnet_url) = @_;

return (HS_cytoscapeJS_gen::printNEA_JSON($neaData, $pl->{$table}, $subnet_url));
}

sub printTabTable {
my($neaData, $pl, $table, $subnet_url, $jid) = @_;
my($i,$genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $text, $ol, $ol2, $signGSEA, $key, @arr, @a2, $AGS, $FGS, $pwKey, $pwID, $pwt, $pwh);

my $content = '<div id="nea_matrix">'.insertMatrixURLs($jid).'</div>';
my $species = retrieveJobInfo($jid, 'species');
my $tableID = 'nea_datatable';
$content .= '<table id="'.$tableID.'"  class="display" cellspacing="0" style="font-size: '.$HSconfig::font->{project}->{size}.'px; width: 97%; border-spacing: 1px; border-collapse: separate;"><thead>'; 
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
# $text = substr($text, 0, 40);
$ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{ags}].$HS_html_gen::OLbox2 if length($arr[$pl->{$table}->{ags}]) > 41;
$content .= "\n".'<tr><td name="firstcol" class="AGSout">'.$ol.$text.'</a>'.'</td>';
 
@a2 = split(",", $genesAGS);
$content .= "\n".'<td class="AGSout">'.
$HS_html_gen::OLbox1.
# '<b>AGS genes that contributed to the relation</b><br>(followed with and sorted by the number of links):<br>'.
'<b>АGS genes behind the relation ('.($#a2 + 1).' out of '.$arr[$pl->{$table}->{n_genes_ags}].')</b>:<br>'.
$genesAGS.
$HS_html_gen::OLbox2.
$arr[$pl->{$table}->{n_genes_ags}].'</a>'.'</td>';
$content .= "\n".'<td class="AGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_AGS')}].'</td>';
$text = $arr[$pl->{$table}->{fgs}];
# $text = substr($text, 0, 40);
# $ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2 if length($arr[$pl->{$table}->{fgs}]) > 41;

# $content .= "\n".'<td class="FGSout">'.$ol.$text.'</a>'.'</td>';
$pwKey = substr(uc($arr[$pl->{$table}->{fgs}]), 0, 3);
$pwID = $1 if uc($arr[$pl->{$table}->{fgs}]) =~ m/^(.+)\:/ or uc($arr[$pl->{$table}->{fgs}]) =~ m/^(.+)$/;
if (defined($HS_html_gen::pwURLhead{$pwKey})) {
$pwh = $HS_html_gen::pwURLhead{$pwKey}.$pwID.'" target="_blank", class="clickable">';
$pwt = '</a>';
} 
else {
$pwh = '';
$pwt = '';
}
#CGIVENN#
# if (length($arr[$pl->{$table}->{fgs}]) > 41) {
# $ol2 = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2;
# }
# else{
	$ol2 = "\<a\>";
# }
# if ($text =~ /^KEGG_([0-9]*)[^0-9].*$/){ # && $ol =~ /^[^\s*]$/ && $species ne 'ath'){
	# my $kid = $1;
	# my $khref = "href\=\"$HS_html_gen::kegg_url$species$kid\" class\=\"clickable\"";
	# $ol2 =~ s/(\<a)/\1 $khref/;
	
# }

$content .= "\n".'<td class="FGSout" style="word-wrap: break-word;">'.$ol2.$pwh.$text.$pwt.'</a>'.'</td>';
#CGIVENN#
@a2 = split(",", $genesFGS);
$content .= "\n".'<td class="FGSout">'.$HS_html_gen::OLbox1.
# '<b>FGS genes that contributed to the relation</b><br>(followed with and sorted by the number of links):<br>'.
'<b>FGS genes behind the relation ('.($#a2 + 1).' out of '.$arr[$pl->{$table}->{n_genes_fgs}].')</b>:<br>'.
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
.'" style="visibility: visible;" formmethod="get" onclick="fillREST(\'subneturlbox\', \''.$subnet_url->{$AGS}->{$FGS}.'\', \''.$id .'\')" class=\'cs_subnet\'>Sub-network</button>' : '') .'</td>' ; 

$content .= '</tr>';
}
$content .="\n".'</table>
<script   type="text/javascript">HSonReady();
 var table = $("#'.$tableID.'").DataTable('.HS_html_gen::DTparameters(1).');
table.buttons().container().appendTo( $("#'.$tableID.'_wrapper").children()[0], table.table().container() ) ; 
table.buttons().container().prependTo($($("#'.$tableID.'_wrapper").children()[0]) ) ; 
//table.buttons().container().prependTo($($("#'.$tableID.'_length").children()) ) ; 
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
my($tableID, $i);

my @lst = @{$HSconfig::matrixTab->{displayList}}; 
my $executeStatement = "Rscript $HSconfig::nea_reader  --vanilla --args nea=".
	tmpFileName('NEArender', $jid).
	" tables=".join($HSconfig::RscriptParameterDelimiter , @lst).
	" htmlmask=".$main::usersTMP.$HSconfig::matrixHTML.'.'.$jid; 
	# print $executeStatement.'<br>';
system($executeStatement); #
my $content = '<div style="width:100%; text-align: right; ">
<span style="vertical-align: middle; padding-bottom: 20px;">Open detailed matrix: </span><select name="matrix_select" id="matrix_select">';
	for $i(0..$#lst) {
	# this is the old direct link
	# $tableID = $HSconfig::tmpVennHTML.$projectID.'/'.$HSconfig::matrixHTML.'.'.$jid.'.'.$lst[$i].'.html';
	# this is the new version
	$tableID = $HSconfig::BASE.'/table.html#'.$projectID.'/'.$HSconfig::matrixHTML.'.'.$jid.'.'.$lst[$i].'.html';
	$content .= '<option class="clickable" value="'.$tableID.'">'. $HSconfig::matrixTab -> {caption} -> {$lst[$i]} .'</option>';
}
$content .= '</select></div>
<script type="text/javascript"> 
$( "#matrix_select" ).selectmenu({
		width: 350,
		select: function( event, data ) {
			window.open(data.item.value, "_blank");
			}
});
</script>';
return ($content) ;
}

sub generateSubTabContent {
my($type, $species) = @_;

my $content = '';
my($field, $tbl, $cond1, $cond2, $ID, $table, $fl, $criteria, $cr, $cntr, $fld, $order);
#################
#################
if ($type =~ m/^csw|tbl$/) {
$content = tabByURL($q->param("jid"), $q->param("type"));
}
elsif ($type eq 'create_venn') {
my $vennFile  = $usersDir.$q->param("selectradio-table-ags-ele"); #$HSconfig::usersDir.'venn/P.matrix.NoModNodiff.2.txt'; ####
print STDERR 'vennFile: '.$vennFile;
my $vennData =  HStextProcessor::vennInput($vennFile, "\t", 100000);
if (ref($vennData) ne 'HASH') {
print $vennData;
exit;
}
# $content .= HS_html_gen::errorDialog("error", "Message", "Please select number of comparsions for venn-diagrams (1,2,3,4) <br> The possible contrasts from the header line of input file will appear as dropdown menu <br> ");
$content .=  HS_html_gen::vennControls(HStextProcessor::vennHeader($vennFile, "\t"), $vennData);
$content .=  '<script type="text/javascript">
$(\'[name="selected-table-venn"]\').val("'.$q->param("selectradio-table-ags-ele").'");
</script>';
}
elsif ($type eq 'update_venn') {
my $vennFile  = $usersDir.$q->param("selected-table-venn"); #$HSconfig::usersDir.'venn/P.matrix.NoModNodiff.2.txt'; ####

system("rm venn*.png vennGenes*.pm") if (system("chmod g+rwx $usersTMP")==0);  #on success system returns 0

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
my $tm = HStextProcessor::generateJID();
my $venName = "venn".$tm.".png";
my $gTable = "vennGenes".$tm.".pm";
my $new_venPath = $HSconfig::usersPNG.$venName;
my $gene_listPath = $usersTMP.$gTable;
print "<p style=\"color: green;\">$new_venPath</p>" if $debug;
print "<p style=\"color: blue;\">$gene_listPath</p>" if $debug;
my $parametersFile = join('.', $usersTMP.$HSconfig::parameters4vennGen, $tm, 'r');
HStextProcessor::writeParameters4vennGen($parametersFile, $vennFile, $criteria, $new_venPath, $gene_listPath, $q->param('venn-hidden-genecolumn'));
my $cmd = "Rscript $HSconfig::venn_software $parametersFile";
# system($cmd);
my $proc=Proc::Background->new($cmd);
my $alive=$proc->alive;
while ($alive == 1) {
	$alive=$proc->alive;
	sleep 1;
	system("echo 1 > /dev/null");
}


if (-e $new_venPath && -e $gene_listPath) {
#print $usersTMP."\n";
#print q{"$projectID"\n};
#BEGIN { push @INC, $usersTMP };
	my $debug_filename = "/var/www/html/research/users_tmp/myveryfirstproject/debug_i.cgi.txt";
	open(my $fh, '>', $debug_filename);
	#print $fh $projectID.'/'.$gTable;
	require $projectID.'/'.$gTable;
	import $projectID.'/'.$gTable;		

$content = HS_html_gen::make_gene_list($GeneList::gList, $GeneList::contrasts, $criteria, $species);
$content .= "<img src=\"$HSconfig::tmpVennPNG/$venName\" id=\"map-venn\" usemap=\"#for-venn-".$comp."\">\n";
$content .= HS_html_gen::get_map_html(\%{$venn_click_points::venn_coord},$comp);
$content .= '<script type=\"text/javascript\">
                        (function (){
                                jq_mp("#map-venn").mapster({
                                        mapKey: "data-key",
                                        isSelectable: true,
                                        fill : true,
                                        fillOpacity : 0.5,
                                        fillColor : "a4a4a4"
                                        });})(jQuery);
		$(function (){
		var Div = $("#venn-container");
		Div.animate({		bottom: \'+250px\', left: 	\'+125px\'	});	
});
                        </script>';
print $content;
}
else {
$content .= HS_html_gen::errorDialog('error', "Cutoffs are too stringent","No genes have met the chosen cutoff requirements. Lower the stringency and try to re-generate the Venn diagram" );
}
}
elsif ($type =~ m/list_([a-z]+)_files/i) {
$content .= listFiles($usersDir, $1);
}
elsif ($type eq 'wrong_upload_format') {
$content .= HS_html_gen::errorDialog("error", "File upload error", $err_msg); # exit;
# $content .= listFiles($usersDir, '');
}
elsif ($type =~ m/delete_([a-z]+)_files/i) {
# print 'type : '.$type.'<br>SR: '.$q->param("delete-file").'<br>';
my $err_status = 1;
if (defined($usersTMP)) {
$err_status = deleteFiles($usersDir, $q->param("delete-file"));
# my $err_status = deleteFiles($usersDir, $q->param("selectradio-table-$1-ele"));
$content .= HS_html_gen::errorDialog("error", "File deletion error", 'Insufficient access level: you do not have rights to delete files in this project') if $err_status;
}
$content .= listFiles($usersDir, $1);
}
elsif ($type eq 'save_json_into_project') {
if (defined($usersTMP)) {
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
$content .= listFiles($usersTMP, $HSconfig::users_file_extension{'JSON'});
}}
elsif ($type =~ m/^sgs|ags|cpw|fgf$/ ) {
our %GS; #
my %JSJobType = ("ags" => "ags", "fgf" => "fgs");
print  STDERR "Type: ".$type; # if $debug;
my $file = $q->param('selectradio-table-'.$JSJobType{$type}.'-ele') ? $q->param('selectradio-table-'.$JSJobType{$type}.'-ele') : $savedFiles -> {data} -> {$type."_table"}; #
$table = $usersDir.$file; #
my($textFileFields);
%{$textFileFields} = (
 'group'  => $q->param('group_column_id'.'_'.$JSJobType{$type}) - 1,
 'id'  => $q->param('gene_column_id'.'_'.$JSJobType{$type}) - 1,
 'score'  => $q->param('score_column_id'.'_'.$JSJobType{$type}) - 1,
 'subset'  => $q->param('subset_column_id'.'_'.$JSJobType{$type}) - 1
 );

$GS{readin} = HStextProcessor::read_group_list3($table, 0, $textFileFields, "\t", '_AGS', $q->param('display-file-header')); #
$pre_NEAoptions -> {$type} -> {$species} -> {ne} =  HS_html_gen::listGS(
	$GS{readin}, uc($JSJobType{$type}), 
	(($type =~ m/sgs|cpw/) ? 0 : 1), # <- $hasGroup
	$file, 	$usersDir); 
# $content .=  HS_html_gen::pre_selectJQ($JSJobType{$type}); #
# $content .=  '<input type="hidden" name="analysis_type" value="'.$mode.'"> '; #
$content .= '<br>'.$pre_NEAoptions -> {$type} -> {$species} -> {ne}.'<br>'.HS_html_gen::pre_selectJQ($JSJobType{$type});
}
elsif (($type eq 'display-file' )) {
# print STDERR 'Filetype: '.$q->param('filetype')."\n";# if $debug; filetype
# print STDERR 'SSSSSSSSSSSSSSSSSSSS: '.$q->param('selectradio-table-'.$q->param('filetype').'-ele')."\n";
$content .= '<div>'.HS_html_gen::displayUserTable($q->param('selectradio-table-'.$q->param('filetype').'-ele'), $usersDir, $delimiter, $q->param('display-file-header')).'</div>';
} 
 
elsif (
($type eq 'arc') or 
($type eq 'res') or 
($type eq 'usr') or 
($type eq 'net') or 
($type eq 'fgs') or 
($type eq 'sbm')) {
$content .= HS_html_gen::ajaxSubTab($type, $species).HS_html_gen::ajaxJScode($type);
} 
else {
print $q->param("action").": no such job defined...".'<br>'."\n";
exit;
}
return($content);
}

sub saveFiles { #save primary user-uploaded files
my($filename, $type) = @_; 
return undef if !defined($usersTMP);
my($name, $path, $extension ) = fileparse ($filename, '\..*');
$filename = $name.$extension;
$filename =~ tr/ /_/;
$filename =~ s/[^$HStextProcessor::safe_filename_characters]//g;
my $upload_filehandle = $q->upload($type);
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>'  if $debug;
open ( UPLOADFILE, "> $usersDir/$filename" ) or print STDERR "Did not open filehandle... $!";
binmode UPLOADFILE;
while ( <$upload_filehandle> )
{
print UPLOADFILE;
}
print "checking filename:$filename"."<br>" if $debug;
close UPLOADFILE;
my ($fail_status, $fail_msg) = HStextProcessor::checkUploadedFile("$usersDir/$filename");
if ($fail_status){
    return($fail_status, $fail_msg);
}
$savedFiles -> {data} -> {$type} = $filename;
print "input file type: ".$type.'<br>' if $debug;
return();
}

sub deleteFiles {
return undef if !defined($usersTMP);
$stat = qq/SELECT permission_granted(\'$uname'\, \'$projectID'\) /;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $allowed = $sth->fetchrow_array;
$sth->finish;
if ($allowed ne 0) {
	my ($location, $filename) = @_; 
	# print "Remove $filename in $location.\n";
	my($name, $path, $extension ) = fileparse ($filename, '\..*'); 
	# print "Trying to remove $location.$filename...\n";
	system ( 'rm '.$location.$filename) and print "Could not remove files... $!";
	system ( 'rm '.$location.$name.$HSconfig::file_stat_ext) and print "Could not remove stat file... $!";
	}
else {
return(1);
	# print("Cannot delete file: not enough rights");
}
return(undef);
}

sub saveIntoProject { #save user-created intermediate/final files
my($location, $filename, $ext, $content) = @_;
return undef if !defined($usersTMP);
my ($fi); 
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>'  if $debug;
open ( SAVE, ' > '.$location.$filename.'.'.$ext ) or return "Did not open filehandle... $!";
print SAVE '"'.$content.'"';
close SAVE;
return(undef);
}

sub listFiles {
my($location, $type) = @_;
return undef if !defined($usersTMP);
my ($filename, $heads, $cons, @a2, $content, $row, $header, $ty, %data, $name, $columns, $text, $localButton, $cleanName, $target, $defaultIcon, $assumedIcon, $stcontent, $stat_info_qtip, $stat_info_div); 
my $i = 0;

chdir($location);

open ( LS, 'ls -hl --time-style=full-iso --block-size=K * | grep -v "'.$HSconfig::file_stat_ext.'" | ') or print "Could not list files... $!";
$content .= $HS_html_gen::elementContent{'file_buttons'};
$content =~ s/###typeplaceholder###/$type/g;
$content .= '<table id="listFiles_'.$type.'" class="ui-state-default ui-corner-all" style="width: auto; font-size: 11px; float: left;">';
for $i(0..$#{$HSconfig::uploadedFile}) {  # <- columns
$header .= '<th>'.$HSconfig::uploadedFile->[$i]->{text}.'</th>';
} 
$content .=  '<thead><tr>'.$header.'</tr></thead>'."\n";
while ($filename = <LS> ) {  # <- rows
$stcontent = $stat_info_qtip = $stat_info_div = '';

@a2 = split(/\s+/, $filename);
$name = $a2[8];
if ($a2[4]) { 
# my($stname, $stpath, $stext) = fileparse ($name, '\..*');
$cleanName = HStextProcessor::JavascriptCompatibleID($name);
my $stfile = $name.$HSconfig::file_stat_ext; #$location.$stname.$HSconfig::file_stat_ext;
 
if (-e $stfile) {
open (my $ifh, '<' , $stfile ) or die "Cannot open file";
my $flstatname = 'flstat-'.$cleanName;
$stcontent .= '<div id="'.$flstatname.'" class="vennhdline"><p>';
while (<$ifh>) {
chomp $_;
$stcontent .= '<b>'.$_.'</b><br>';
}
close $ifh;
$stcontent .= '</p></div>';
# $stat_info_div = '<span class="vennhdlineOpener" onclick="openDialog(\''.$flstatname.'\');"> &#9432 </span>';
$stat_info_qtip = '<span class="vennhdlineOpener stat_info" title=\''.$stcontent.'\'"> &#9432 </span>';
}
$row = '<tr id="row-'.$cleanName.'">'; # http://outbottle.com/jquery-ui-specifying-different-button-icon-colors-using-only-css-classes/
# print 'i: 3 '.join(' ', keys(%{$HSconfig::uploadedFile->})).'<br>';

for $i(0..$#{$HSconfig::uploadedFile}) { # <- columns
# for $i(0..3) {
$row .= '<td>';
if ($i < 3) {
$text = ${$HSconfig::uploadedFile->[$i]}{text};
$text = $name.$stat_info_div if ($text eq 'File');
$text = join(' ', ($a2[5], $1)) if ($text eq 'Date' and ($a2[6] =~ m/([0-9\:]+)\./));
$text = $a2[4] if ($text eq 'Size');
$row .= $text;
}  
else { 
if ($i == 3) { # the "File type" column:
#DIALOG DIALOG DIALOG DIALOG DIALOG DIALOG DIALOG:
$defaultIcon = 'ui-icon-help-plain'; #<span class=\'ui-icon '.$data{icon}.'\' ></span>
$row .= '
<span class="sbm-icon ui-icon assumed-icon '.$defaultIcon.'" id=\'icon-###typeplaceholder###-'.$cleanName.'\' filename=\''.$name.'\' onclick="$(\'#selectradio-table-'.$type.'-ele\').val(\''.$name.'\'); openFileDialog(\'#dialog-###typeplaceholder###-'.$cleanName.'\', \''.$type.'\', \''.$name.'\'); updatechecksbm(\'###typeplaceholder###\', \'file\')" title=\'\'></span>
<div id=\'dialog-###typeplaceholder###-'.$cleanName.'\' style="display: none;"  >
<table id=\'qtip-file-table-###typeplaceholder###-'.$cleanName.'\' border="0"><tr>
<td><h4>Select tab according to file type and define format:</h4>
<div id=\'tabs-###typeplaceholder###-'.$cleanName.'\' class=\'qtip-tabs\'>';
 $heads = ''; $cons = ''; $assumedIcon = '';
for $ty(sort {$HSconfig::fileType{$a} <=> $HSconfig::fileType{$b}} keys(%{$HSconfig::uploadedFile->[$i]})) {
	if ($ty ne 'text') {
		%data = %{$HSconfig::uploadedFile->[$i] -> {$ty}}; 
		$assumedIcon = ' '.$data{icon} if ($name =~ m/$data{mask}/i and $name =~ m/$data{keyword}/i);
		$heads .= '<li><a href=\'#'.$ty.'-###typeplaceholder###-'.$cleanName.'\'>'.$data{caption}.'</a></li>';
		$cons .= '<div id=\''.$ty.'-###typeplaceholder###-'.$cleanName.'\'>'.$data{title}.'</div>';
$target = '###typeplaceholder###_select-'.$cleanName;
		$localButton = '
<button type=\'submit\' form=\'form_ne\' class=\'sbm-icon icon-ok\' id=\''.$data{button}.$cleanName.'\' optionstarget=\''.$target.'\' title="Open to use file content"><span class=\'ui-icon ui-icon-action\'></span>'; 
$cons =~ s/\<###submitbuttonplaceholder###\>/$localButton/g; #\<button type\=\'submit\' /; 
		}
}
$row =~ s/$defaultIcon/$assumedIcon/ if $assumedIcon;
$row = $row.'<ul>'.$heads.'</ul>'.$cons.'</div>
 <p><span style=\'padding: 8px;\'>Columns are delimited with <select id=\'delimiter-table-ele-###typeplaceholder###-###filenameplaceholder###\' class=\'qtip-select ctrl-###typeplaceholder###\'> 
      <option value=\'tab\'>TAB</option>
      <option disabled value=\'comma\'>comma</option> 
      <option disabled value=\'space\'>space</option>
    </select> 
	</span>
	 
	 <span style=\'padding: 8px;\'>First line is a header <input type=\'checkbox\' name=\'display-file-header\' id=\'display-file-header-###typeplaceholder###-###filenameplaceholder###\' value=\'yes\' class=\'venn_box_control\'></span></p>
<span style="font-weight: bold;">Data preview:</span>
<div id=\'display-qtip-###typeplaceholder###-'.$cleanName.'\'></div>
</td>
<td>
<div id=\''.$target.'\'></div>
</td></tr>
</table>
</div>';
$row =~ s/###filenameplaceholder###/$cleanName/g;
}
else {#'parentclass' => 'sbm-icon icon-warn',

if (${$HSconfig::uploadedFile->[$i]}{icon}) { # the Delete column:  $(\'#selectradio-table-###typeplaceholder###-ele\').val(\''.$name.'\'); 
$row .= ($name =~ m/${$HSconfig::uploadedFile->[$i]}{mask}/i and $name =~ m/${$HSconfig::uploadedFile->[$i]}{keyword}/i) ? 
# '<button type="submit" onclick="$(\'#selectradio-table-###typeplaceholder###-ele\').val(\''.$name.'\');" id="'.${$HSconfig::uploadedFile->[$i]}{button}.$cleanName.'" class="'.${$HSconfig::uploadedFile->[$i]}{parentclass}.'" title="'.${$HSconfig::uploadedFile->[$i]}{title}.'" class="tempdisabled ui-widget-header ui-corner-all" '.
# ($projectID =~ m/^myveryfirstproject|stemcell$/ ? ' disabled="disabled" ' : '')
# .'><span class="ui-icon '.${$HSconfig::uploadedFile->[$i]}{icon}.' "></span></button>'  
'<span class="venn_box_control ui-icon ui-icon-trash" id="'.${$HSconfig::uploadedFile->[$i]}{button}.$cleanName.'" onclick="removeFromProjectTable(&quot;display-filetable-###typeplaceholder###&quot;, &quot;'.$cleanName.'&quot;, &quot;'.$name.'&quot;);" title="'.${$HSconfig::uploadedFile->[$i]}{title}.'" ></span>'
 : '<span title="'.${$HSconfig::uploadedFile->[$i]}{empty}.'">&nbsp;&nbsp;&nbsp;</span>'; 
$row =~ s/icon-warn// if $projectID =~ m/^myveryfirstproject|stemcell$/;
}
}
}
$row .= '</td>';
}
$row =~ s/###typeplaceholder###/$type/g;
$row =~ s/###statinfoplaceholder###/$stat_info_qtip/g;
$content .= $row.'</tr>'."\n";
}}
$content .= '</table>'.
# $stcontent.
'	
<script   type="text/javascript">
/*$(function() {
//console.log("DIALOG");
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
   });*/

   $(".assumed-icon").each( 
	   function () {
		   var savedType = (getCookie($(this).attr("id").replace("icon-", "tabs-") + "_filetype").split("|"))[0];
		   //console.log($(this).attr("id") + " savedType: " + savedType);
		   var typeList = Object.keys(fileType);
		   if (savedType == "") {
		   		for (var i = 0; i < typeList.length; i++) {
					if ($(this).hasClass(fileType[typeList[i]]["icon"]) == true) {
						savedType = typeList[i];
// console.log($(this).hasClass(fileType[typeList[i]]["icon"]) + $(this).attr("id") + \': \' + typeList[i] + \', \' + fileType[typeList[i]]["icon"])
					}
				}
			}			
	
				for (var i = 0; i < typeList.length; i++) {
					$(this).removeClass(fileType[typeList[i]]["icon"]);
				}
				//console.log(savedType);
			   var newIcon = fileType[savedType]["icon"];
			   $(this).addClass(newIcon);
			   $(this).attr("title", fileType[savedType]["caption"])
	   }
   );
   
$("#listFiles_'.$type.'").DataTable({
	"lengthMenu": [ [10, 50, -1], [10, 50, "All"] ], 
	"order": [[ 1, "desc" ]],
	responsive: false, 
	fixedHeader: true, 
	"processing": true
 });
 $("[id=\'listFiles_'.$type.'_wrapper\']").children( ".fg-toolbar" ).css({"background-color": "#dfeffc", "background-image": "none"});
 $(".stat_info").qtip({
    show: "mouseover", 
     hide: "unfocus", 

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
                //classes: "qtip-bootstrap",
                tip: {
                        width: 16,
                        height: 8
                }}
				
});
var Type = "'.$type.'";
var Button = "#" + Type + "uploadbutton-table-" + Type + "-ele";
$("#file-table-'.$type.'-ele").val("");
$(Button).css({"border-color": "#7799aa"});
$(Button + " > span").css({"color": "#7799aa"});
$(Button).removeClass("icon-ok");

 HSonReady();
 updatechecksbmAll();

</script>';
close LS;
return($content);
}

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

