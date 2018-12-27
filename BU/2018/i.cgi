#!/usr/bin/perl -w
use warnings;
use strict;
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

use lib "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
use lib "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp";
use NET;
use venn_click_points;
use constant SPACE => ' ';

no warnings;
# system(	'rm  /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_upload/*/exampl*');
# system('rmdir /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_upload/hyperset.');
# system('mv /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_upload/hyperset_ne /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_upload/hyperset');
 # exit;
my $debug = 0;
$ENV{'PATH'} = '/bin:/usr/bin:';
$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $conditions, $pl, $nm, $conditionPairs, $pre_NEAoptions, $itemFeatures, 
$savedFiles,  $fileUploadTag, $usersDir, $usersTMP, $sn, $URL);
our $NN = 0;
my($mode, @genes, $Genes, $type, $AGS, $FGS, $step, $NEAfile, @names, $mm, $callerNo);
our($AGSselected, $FGSselected, $NETselected);
our $species;
our $restoreSpecial = 0; # see sub tmpFileName()
$fileUploadTag = "_table";
#return 0;
$dbh = HS_SQL::dbh();
our $q = new CGI;
@names = $q->param;
$species 	= $q->param("species");
$species 	= '' if !defined($species);
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
		print "Permission denied. Project: ".$projectID." User: ".$uname." Signature: ".$sign." SID: ".$sid." Session status: ".$sessionstat." Ownership status: ".$ownership;
		exit 0;}
		
		}
}
my ($err_stat, $err_msg);
our $GSEA_pvalue_coff = 0.01;
our $NEA_FDR_coff = $q->param("fdr") ? $q->param("fdr") : 1.99;
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
if ($q->param("mode") eq 'begin') {
$step = 'mainTab';
}
if ($q->param("mode") eq 'fill_menu') {
$step = 'fillMenu';
}
if ($q->param("action") eq 'sbmRestore') {
$step = 'saved_nea';
} 
elsif ($q->param("action") eq 'display-archive') {$step = 'display-archive';} # <= a diplay of one archived josb in a separate window. not the same as 'arc' requested via function displayArchive  from HS.js
elsif ($q->param("action") eq 'display-file') {$step = 'display-file';} 
elsif ($q->param("action") eq 'sbmSubmit') {$step = 'executeNEA';} 
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
elsif ($q->param("action") eq 'agsuploadbutton-table-ags-ele') {
for $mm(@names) {
if ($mm =~ m/$fileUploadTag$/i) {
($err_stat, $err_msg) = saveFiles($q->param($mm), $mm)  if ($mm eq "ags_table") and $q->param($mm);
}}
$step = 'list_ags_files';
$step = 'wrong_upload_format' if ($err_stat);
} 
$type = $step if ($step eq 'save_json_into_project')
 or ($step eq 'display-file')
 or ($step eq 'create_venn')
 or ($step eq 'update_venn')
 or ($step eq 'list_ags_files')
 or ($step eq 'delete_ags_files')
 or ($step eq 'wrong_upload_format')
 or ($q->param("step") eq 'ags_select');
if (($q->param("mode") ne 'begin') and ($q->param("mode") ne 'fill_menu') and $step) {
# if (!$projectID) {
# print HS_html_gen::errorDialog('error', "Project ID ".$mode.'; step: '.$step, "Before starting any analysis, define project ID in the box above", 0).
# '<script type="text/javascript">
# $(function() {
# $("#project_id_ne").addClass("inputareahighlight");
# });
# </script>'; 
# exit;
# }
}

@{$AGSselected} = $q->param("AGSselector");
@{$FGSselected} = $q->param("FGSselector");
@{$NETselected} = $q->param('NETselector');

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
print STDERR '<br>AGSselected1: '.join(' ', @{$AGSselected}) if $debug;	
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
print STDERR '<br>Submitted form values: <br>'.$q->query_string.'<br>'  if $debug; 
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
if ($executed =~ m/[A-Z\>\<]+/i) {
print $executed;
exit;
}
$content .= printNEA($executed, $projectID);
}
elsif (($step eq 'display-archive') and $projectID) {
$content .= printNEA('project', $projectID);
}
elsif ($step eq 'saved_nea') { 
$content .= jobFromArchive($projectID, $q->param("jid"));  
}
elsif ($step eq 'saved_json') {
$content .= restoreNodesAndEdges($usersTMP, $q->param("selectradio-table-cy-ele"));
open OUT, '> '.$main::usersTMP.'debug.table-cy-ele.html'; print OUT $content; close OUT;
}
elsif ($step eq 'shownet') {
print STDERR "bsURL: ".$q->param("subneturlbox") if $debug;
$content .=  printNet($q->param("subneturlbox"), $callerNo, $AGS, $FGS); 

open OUT, '> '.$main::usersTMP.'debug_net.html'; print OUT $content; close OUT;
} 
else {
# print $type.'<br>';
# die "ARC" if ($type eq 'arc');
if ($type eq 'arc') {	
	our $jobToRemove; 
	$jobToRemove = $q->param("job_to_remove") if $q->param("job_to_remove");
	$content .= HS_html_gen::printTabArchive($projectID, $jobToRemove);
	} else {
$content .= generateSubTabContent($type, $species, $mode); 
}
# if ($type eq 'arc') {
# our $jobToRemove;
# $jobToRemove = $q->param("job_to_remove") if ($q->param("job_to_remove"));
# $content .=  = printTabArchive($main::projectID, $main::jobToRemove);
	# } else {
# $content .= generateSubTabContent($type, $species, $mode); 
# }
}
}
HS_html_gen::mainStart() if ($q->param("mode") eq 'standalone' or ($q->param("instance") eq 'new'));
my $newTitle = 'EviNet archive';
$HS_html_gen::mainStart =~ s/TLE\>(.+)\<\/TIT/TLE\>$newTitle<\/TIT/ if $step eq 'saved_nea';
$content = $HS_html_gen::mainStart.$content.$HS_html_gen::mainEnd if ($q->param("mode") eq 'standalone');
print $content; 
# open OUT, '> '.$main::usersTMP.'debug.'.join('.', ($step, $type, $mode)).'.html'; print OUT $content; close OUT;
$dbh->disconnect;

sub generateTabContent {
my($tab) = @_;
my @ar = split('_', $tab); my $main_type = $ar[2];
my $content = 
'<div id="analysis_type_'.$main_type.'"  class="main_ajax_menu form '.$main_type.'" >'.
HS_html_gen::ajaxSubTabList($main_type).
HS_html_gen::ajaxJScode($main_type);
return($content);
}

sub generateMenuContent {
return(HS_html_gen::ajaxMenu('menu'));
}

sub generateJID {return(sprintf("%u", rand(10**15)));}

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
'Altered gene set(s) not defined.<br>Use one of the alternative input options or run one of our Demos (see the side menu)', 
"Altered gene sets");
}
print  'AGS_TABLE: <br>'.$ags_table.'<br>'."\n" if $debug;
print  '<br>AGSselected2: '.join(' ', @{$AGSselected})."\n" if $debug;	

$jobParameters -> {jid} = $jid;
$jobParameters -> {rm} = $ENV{REMOTE_ADDR};
$jobParameters -> {projectid} = $projectID;
$jobParameters -> {species} = $species;
# $jobParameters -> {username} = $AGSselected;
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
print STDERR '<br>sbm_selected_ags: '.join(' ', @{$jobParameters -> {sbm_selected_ags}}) if $debug;	
$agsFile = HStextProcessor::compileGS('ags', 
$jid, 
$ags_table, 
$jobParameters -> {sbm_selected_ags}, 
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}} -> {gene},
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}} -> {group},
$jobParameters -> {genewiseAGS},
$species, 
0);
print  'AGS file: '.$agsFile."\n" if $debug;	
return HS_html_gen::errorDialog('error', "Input", 
'Altered gene set input was not usable.<br>This might be caused by submitting incompatible gene/protein IDs.<br><span  class=\'clickable dialogOpener\' onclick=\'openDialog(\"acceptedIDs\");\'>Accepted IDs</span>', 
"Altered gene sets") if $agsFile eq 'empty';

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
'Functional gene set input was not usable.<br>This might be caused by submitting incompatible gene/protein IDs.<br><span  class=\'clickable dialogOpener\' onclick=\'openDialog(\"acceptedIDs\");\'>Accepted IDs</span>', 
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
print STDERR '<br>'.$HSconfig::test.'<br>' if $debug;
print STDERR '<br>'.$executeStatement.'<br>' if $debug;
$email = $q->param('user-email') if ($q->param('user-email') =~ m/\@.+\./);
print STDERR 'saveJob';
saveJob($jid, $jobParameters);
sendNotification ($jobParameters -> {projectid}, $q->param('user-email'), $jid, undef, $jobParameters -> {url}, 'running')  if $email;
# my $returnCode = ;
print '<br>Start runNEAonEvinet.r...<br>'."\n" if $debug;
if (!system($executeStatement)) {
print STDERR 'confirmJob';
confirmJob($jid); 
sendNotification ($jobParameters -> {projectid}, $email, $jid, undef, $jobParameters -> {url}, 'done') if $email;
# system("rm  ".tmpFileName('AGS', $jid).' '.tmpFileName('FGS', $jid).' '.tmpFileName('NET', $jid)) if !$debug;
} else {
$dbh->do("ROLLBACK;");
}
return ($jid);
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

print $bsURLstring."\n"   if $debug;
($data, $node) = HS_bring_subnet::bring_subnet($bsURLstring);
return(	
	'<div id="net_graph" style="width: '.
		$HSconfig::cy_size->{net}->{width}.'px; height: '.$HSconfig::cy_size->{net}->{height}.'px;">'.
		HS_cytoscapeJS_gen::printNet_JSON($data, $node, $callerNo, $AGS, $FGS).
	'</div></div>');
}

sub readNEA {
my($table) = @_;
my($key, $i, @arr, $neaData);
my $current_usr_mask = $q->param('ags_mask');
my $current_fgs_mask = $q->param('fgs_mask');
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
next if (($arr[$pl->{$table}->{$HSconfig::pivotal_nea_score}] < $HSconfig::min_pivotal_nea_score) or 
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
return("empty") if (1 == 2 or !$i);
return($neaData);
}

sub jobFromArchive {
my($proj, $job) = @_;

my $content = '<div id="net_up" >
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

<div id="nea_archive_tabs">
'.printJobTabs($proj, $job).'
</div>';

$content = '
<FORM id="form_ne" action="cgi/i.cgi" method="POST" enctype="multipart/form-data" autocomplete="on" >
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
<li><a href="cgi/i.cgi?username='.$uname.';signature='.$sign.';sid='.$sid.';project_id='.$proj.';type=arc;analysis_type=ne;jid='.$job.';shared='.$shared.'">Archive</a></li>
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
$content = '<br><div id="net_up" >
<div id="ne-up-progressbar"></div>
</div>
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
urlfixtabs( "#nea_tabs" );
});
</script>';
if ($q->param("graphics")) {
$content .= '<div id="nea_graph" style="width: '.$HSconfig::cyPara->{size}->{nea}->{width}.'px; height: '.$HSconfig::cyPara->{size}->{nea}->{height}.'px;">'.
printTabGraphics($neaData, $pl, $table, $subnet_url).'</div>';
}
if (1 == 1 and $q->param("table")) { 
$content .= '<div id="nea_table">';
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

sub printTabPlot {
my($neaData, $pl, $table, $subnet_url) = @_;
#nea_link_url();
return '<iframe id="heatmap-iframe" src="pics/ttb.pairwise_correlations.156proteins.v3.html" style="width:100%; height:100%;"></iframe>';
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
my($i,$genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $text, $ol, $ol2, $signGSEA, $key, @arr, $AGS, $FGS);

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
# $ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2 if length($arr[$pl->{$table}->{fgs}]) > 41;

# $content .= "\n".'<td class="FGSout">'.$ol.$text.'</a>'.'</td>';

#CGIVENN#
if (length($arr[$pl->{$table}->{fgs}]) > 41) {
	$ol2 = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2;
}
else{
	$ol2 = "\<a\>";
}
if ($text =~ /^KEGG_([0-9]*)[^0-9].*$/){ # && $ol =~ /^[^\s*]$/ && $species ne 'ath'){
	my $kid = $1;
	my $khref = "href\=\"$HS_html_gen::kegg_url$species$kid\" class\=\"clickable\"";
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
.'" style="visibility: visible;" formmethod="get" onclick="fillREST(\'subneturlbox\', \''.$subnet_url->{$AGS}->{$FGS}.'\', \''.$id .'\')" class=\'cs_subnet\'>Sub-network</button>' : '') .'</td>' ; 

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
my($tableID, $i);

my @lst = @{$HSconfig::matrixTab->{displayList}}; 
my $executeStatement = "Rscript $HSconfig::nea_reader  --vanilla --args nea=".
	tmpFileName('NEArender', $jid).
	" tables=".join($HSconfig::RscriptParameterDelimiter , @lst).
	" htmlmask=".$main::usersTMP.$HSconfig::matrixHTML.'.'.$jid;
	# print $executeStatement.'<br>';
system($executeStatement); #
my $content = '<div style="width:100%; text-align: right; ">
<span style="vertical-align: middle; padding-bottom: 20px;">Open rectangular matrix: </span><select name="matrix_select" id="matrix_select">';
	for $i(0..$#lst) {
	# this is the old direct link
	# $tableID = $HSconfig::tmpVennHTML.$projectID.'/'.$HSconfig::matrixHTML.'.'.$jid.'.'.$lst[$i].'.html';
	# this is the new version
	$tableID = 'https://www.evinet.org/table.html#'.$projectID.'/'.$HSconfig::matrixHTML.'.'.$jid.'.'.$lst[$i].'.html';
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
my($type, $species, $mode) = @_;

my $content = '';
my($field, $tbl, $cond1, $cond2, $ID, $table, $fl, $criteria, $cr, $cntr, $fld, $order);
#################
#################
if ($type =~ m/^csw|tbl$/) {
$content = tabByURL($q->param("jid"), $q->param("type"));
}
elsif ($type eq 'update_venn') {
my $vennFile  = $usersDir.$q->param("selected-table-venn"); #$HSconfig::usersDir.'venn/P.matrix.NoModNodiff.2.txt'; ####

if (system("chmod g+rwx $usersTMP")==0) { #on success system returns 0
# $content .= "<p style=\"color: red;\">$vennFile</p>";
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
my $new_venPath = $HSconfig::usersPNG.$venName;
my $gene_listPath = $usersTMP.$gTable;
print "<p style=\"color: green;\">$new_venPath</p>" if $debug;
print "<p style=\"color: blue;\">$gene_listPath</p>" if $debug;
my $parametersFile = join('.', $usersTMP.$HSconfig::parameters4vennGen, $tm, 'r');
HStextProcessor::writeParameters4vennGen($parametersFile, $vennFile, $criteria, $new_venPath, $gene_listPath, $q->param('venn-hidden-genecolumn'));
my $cmd = "Rscript /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/vennGen.AA.r $parametersFile";
system($cmd);

if (-e $new_venPath && -e $gene_listPath) {
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
# $content .= "<p style=\"color: red;\">$new_venPath</p>";
# $content .= "<p style=\"color: red;\">$gene_listPath</p>";
# $content .= "<p style=\"color: red;\">Something went wrong while generating plot<br>Cutoff criterias might be too stringent</p>";
$content .= HS_html_gen::errorDialog('error', "Cutoffs are stringent","No genes meet the choosen cutoff requirements. Lower your stringency and Generate Venn diagram" );
}
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
elsif ($type eq 'list_ags_files') {
$content .= HS_html_gen::wrapColl(listFiles($usersDir, ''), $type, $species, $mode);
}
elsif ($type eq 'wrong_upload_format') {
$content .= HS_html_gen::errorDialog("error", "File upload error", $err_msg); # exit;
$content .= HS_html_gen::wrapColl(listFiles($usersDir, ''), $type, $species, $mode);
}
elsif ($type eq 'delete_ags_files') {
my $err_status = deleteFiles($usersDir, $q->param("selectradio-table-ags-ele"));
$content .= HS_html_gen::errorDialog("error", "File deletion error", 'Insufficient access level: you do not have rights to delete files in this project') if $err_status;
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
}
elsif (($type eq 'sgs')  or ($type eq  "ags" )) {
our %AGS; #
# print  "Type: ".$type if $debug;
my $file = $q->param('selectradio-table-ags-ele') ? $q->param('selectradio-table-ags-ele') : $savedFiles -> {data} -> {$type."_table"}; #
$table = $usersDir.$file; #
 print $type.' table '.$table.'<br>' if $debug;
#  
 $AGS{readin} = NET::read_group_list($table, 0, $pl->{$table}->{gene}, $pl->{$table}->{group}, $delimiter, '_AGS'); #
$pre_NEAoptions -> {$type} -> {$species} -> {ne} =  HS_html_gen::listAGS(
	$AGS{readin}, 'AGS', 
	(($type ne 'sgs') ? 1 : 0), 
	$file, 	$usersDir); 
$content .=  HS_html_gen::pre_selectJQ('ags'); #
$content .=  '<input type="hidden" name="analysis_type" value="'.$mode.'"> '; #
$content .= '<br>'.$pre_NEAoptions -> {$type} -> {$species} -> {ne}.'<br>';
}
elsif (($type eq 'display-file' )) {
$content .= '<div>'.HS_html_gen::displayUserTable($q->param('selectradio-table-ags-ele'), $usersDir, $delimiter, $q->param('display-file-header')).'</div>';
}
elsif (
($type eq 'arc') or 
# ($type eq 'hlp') or 
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
$HSconfig::fgsDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = $ar[$pl->{$statfile{$stat}}->{$fi}];
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
for $fi(@fields) {
$HSconfig::netDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = $ar[$pl->{$statfile{$stat}}->{$fi}];
 }}
  close IN;
 }}}}
$content .= HS_html_gen::ajaxSubTab($type, $species, $mode).HS_html_gen::ajaxJScode($type);
} 
else {
print "No such job defined...".'<br>'."\n";
exit;
}
return($content);
}

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
my ($fail_status, $fail_msg) = HStextProcessor::checkUploadedFile("$usersDir/$filename");
if ($fail_status){
    return($fail_status, $fail_msg);
}
$savedFiles -> {data} -> {$type} = $filename;
print "input file type: ".$type.'<br>' if $debug;
return();
}

sub deleteFiles {
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
my ($fi); 
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>'  if $debug;
open ( SAVE, ' > '.$location.$filename.'.'.$ext ) or return "Did not open filehandle... $!";
print SAVE '"'.$content.'"';
close SAVE;
return(undef);
}

sub listFiles {
my($location, $type) = @_;
my ($filename, $heads, $cons, @a2, $content, $row, $header, $ty, %data, $name, $columns, $text, $localButton, $cleanName, $target, $defaultIcon, $assumedIcon); 
my $i = 0;

chdir($location);
open ( LS, 'ls -hl --time-style=full-iso --block-size=K *'.(($type) ? '.'.$type : '').' | grep -v "'.$HSconfig::file_stat_ext.'" | ') or print "Could not list files... $!";
$content .= '<table id="listFiles" class="ui-state-default ui-corner-all" style="width: auto; font-size: 11px">';

for $i(0..$#{$HSconfig::uploadedFile}) {  # <- columns
$header .= '<th>'.$HSconfig::uploadedFile->[$i]->{text}.'</th>';
} 
$content .=  '<thead><tr>'.$header.'</tr></thead>'."\n";
my $tag = 'ags';
$tag = 'cy' if $type eq $HSconfig::users_file_extension{'JSON'};
my $stcontent = '';
while ($filename = <LS> ) {  # <- rows
@a2 = split(/\s+/, $filename);
$name = $a2[8];
if ($a2[4]) { 
my $stat_info_txt = '';
my($stname, $stpath, $stext) = fileparse ($name, '\..*');
my $stfile = $location.$stname.$HSconfig::file_stat_ext;
if (-e $stfile){
open (my $ifh, '<' , $stfile ) or die "Cant open file";
my $flstatname = 'flstat-'.$stname;
$stcontent .= '<div id="'.$flstatname.'" class="vennhdline"><p>';
while (<$ifh>) {
chomp $_;
$stcontent .= '<b>'.$_.'</b><br>';
}
$stcontent .= '</p></div>';
$stat_info_txt = '<span class="vennhdlineOpener" onclick="openDialog(\''.$flstatname.'\');"> &#9432 </span>';
close $ifh;
}
$row = '<tr>'; # http://outbottle.com/jquery-ui-specifying-different-button-icon-colors-using-only-css-classes/
# print 'i: 3 '.join(' ', keys(%{$HSconfig::uploadedFile->[3]})).'<br>';
for $i(0..$#{$HSconfig::uploadedFile}) { # <- columns
# for $i(0..3) {
$row .= '<td>';
if ($i < 3) {
$text = ${$HSconfig::uploadedFile->[$i]}{text};
$text = $name.$stat_info_txt if ($text eq 'File');
$text = join(' ', ($a2[5], $1)) if ($text eq 'Date' and ($a2[6] =~ m/([0-9\:]+)\./));
$text = $a2[4] if ($text eq 'Size');
$row .= $text;
} 
else {
$cleanName = HStextProcessor::JavascriptCompatibleID($name);

# $row .= $cleanName;
if ($i == 3) { # the "File type" column:

#DIALOG DIALOG DIALOG DIALOG DIALOG DIALOG DIALOG:
$defaultIcon = 'ui-icon-help-plain'; #<span class=\'ui-icon '.$data{icon}.'\' ></span>
$row .= '
<span class="sbm-icon ui-icon '.$defaultIcon.'" id=\'icon-'.$cleanName.'\' filename=\''.$name.'\' onclick="$(\'#selectradio-table-ags-ele\').val(\''.$name.'\'); openFileDialog(\'#dialog-'.$cleanName.'\');" title=\'\'></span>
<div id=\'dialog-'.$cleanName.'\' style="display: none;"  >
<table id=\'qtip-file-table-'.$cleanName.'\' border="0"><tr>
<td><h4>Select proper tab according to the file type and define its format:</h4>
<div id=\'tabs-'.$cleanName.'\' class=\'qtip-tabs\'>';
 $heads = ''; $cons = ''; $assumedIcon = '';
for $ty(keys(%{$HSconfig::uploadedFile->[$i]})) {
	if ($ty ne 'text') {
		%data = %{$HSconfig::uploadedFile->[$i] -> {$ty}}; 
		$assumedIcon = ' assumed-icon '.$data{icon} if ($name =~ m/$data{mask}/i and $name =~ m/$data{keyword}/i);
		$heads .= '<li><a href=\'#'.$ty.'-'.$cleanName.'\'>'.$data{caption}.'</a></li>';
		$cons .= '<div id=\''.$ty.'-'.$cleanName.'\'>'.$data{title}.'</div>';
$target = 'ags_select-'.$cleanName;
		$localButton = '
<button type=\'submit\' form=\'form_ne\' class=\'sbm-icon icon-ok\' id=\''.$data{button}.$cleanName.'\' target=\''.$target.'\'><span class=\'ui-icon ui-icon-action\'></span>'; 
$cons =~ s/\<###submitbuttonplaceholder###\>/$localButton/g; #\<button type\=\'submit\' /; 
$cons =~ s/###filenameplaceholder###/$cleanName/g;
		}
}
$row =~ s/$defaultIcon/$assumedIcon/;
$row = $row.'<ul>'.$heads.'</ul>'.$cons.'</div>
<div><h4>Re-read the file (showing top '.$HSconfig::maxLinesDisplay.' lines): <span id=\'display-file-'.$cleanName.'-header-yes\' class=\'ui-icon ui-icon-table sbm-controls\' title=\'First line is a header\'></span>
<span id=\'display-file-'.$cleanName.'-header-no\' class=\'ui-icon ui-icon-grid sbm-controls\' title=\'File has no header\'></span></h4>
	</div>
<div id=\'display-qtip-'.$cleanName.'\'></div>
</td>
<td>
<div id=\''.$target.'\'></div>
</td></tr>
</table>
</div>';

# OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD :

# for $ty(sort {$a cmp $b} keys(%{$HSconfig::uploadedFile->[$i]})) {
# if ($ty ne 'text') {
# %data = %{$HSconfig::uploadedFile->[$i] -> {$ty}};
# if ($data{button} =~ m/vennsubmitbutton-table-/) {
# $row .= ($name =~ m/$data{mask}/i and $name =~ m/$data{keyword}/i) ? 
# '<button type="submit" onclick="$(\'#selectradio-table-ags-ele\').val(\''.$name.'\');" id="'.$data{button}.$cleanName.'" class="'.$data{parentclass}.'" title="'.$data{title}.'"><span class="ui-icon '.$data{icon}.'"></span></button>' : 
# ''; 
# } 
# else { 
# $row .= ($name =~ m/$data{mask}/i and $name =~ m/$data{keyword}/i) ? 
# '<span class="sbm-icon ui-icon '.$data{icon}.'" filename=\''.$name.'\' title="
# '.$data{title}.' <p>The file is: <select name=\'delimiter\' id=\'file2upload-type\' class=\'qtip-select\'> 
		  # <option value=\'gs\'>Collection of gene sets (or a single set)</option>
		  # <option disabled value=\'venn\'>Differential expression (for Venn diagram)</option> 
		  # <option disabled value=\'net\'>Custom network (as a list of edges)</option>
		# </select>
		# </p>"
		# ></span>' : '';
# $localButton = '
# <button type=\'submit\' form=\'form_ne\' class=\'sbm-icon icon-ok\' id=\''.$data{button}.$name.'\' ><span class=\'ui-icon ui-icon-action\'></span>'; 
# $row =~ s/\<###submitbuttonplaceholder###\>/$localButton/; #\<button type\=\'submit\' /; 
# $row =~ s/###filenameplaceholder###/$name/g;
# }}}

# END  END  END  END  END  END 
# END  END  END  END  END  END 
}
else {
if (${$HSconfig::uploadedFile->[$i]}{icon}) { #currently the Delete column:
$row .= ($name =~ m/${$HSconfig::uploadedFile->[$i]}{mask}/i and $name =~ m/${$HSconfig::uploadedFile->[$i]}{keyword}/i) ? 
'<button type="submit" onclick="$(\'#selectradio-table-ags-ele\').val(\''.$name.'\');" id="'.${$HSconfig::uploadedFile->[$i]}{button}.$cleanName.'" class="'.${$HSconfig::uploadedFile->[$i]}{parentclass}.'" title="'.${$HSconfig::uploadedFile->[$i]}{title}.' ui-widget-header ui-corner-all"><span class="ui-icon '.${$HSconfig::uploadedFile->[$i]}{icon}.'"></span></button>' : 
'<span title="'.${$HSconfig::uploadedFile->[$i]}{empty}.'">&nbsp;&nbsp;&nbsp;</span>'; 
}
}
}
$row .= '</td>';
}
$content .= $row.'</tr>'."\n";
}}
$content .= '</table>'.
$stcontent.'	
<script   type="text/javascript">
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

   $(".assumed-icon" + ", ." + fileType["default"]["icon"]).each(
	   function () {
		   var savedType = (getCookie($(this).attr("id").replace("icon-", "tabs-") + "_filetype").split("|"))[0];
		   //console.log($(this).attr("id") + " savedType: " + savedType);
		   if (savedType != "") {
		   var typeList = Object.keys(fileType);
				for (var i = 0; i < typeList.length; i++) {
					$(this).removeClass(fileType[typeList[i]]["icon"]);
				}
			   var newIcon = fileType[savedType]["icon"];
			   $(this).addClass(newIcon);
			   $(this).attr("title", fileType[savedType]["caption"])
		   }
	   }
   );
   
$("#listFiles").DataTable({
	"lengthMenu": [ [-1, 10, 50], ["All", 10, 50] ], 
	"order": [[ 2, "desc" ]],
	responsive: false, 
	fixedHeader: true, 
	"processing": true
 });
// console.log(dTable);
 //$("#list_ags_files").css({"position": "relative", "left": "0px"});
 //$("#use_gene_symbols").css({"float": "right", "margin": "8px", "color": "white"})
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

