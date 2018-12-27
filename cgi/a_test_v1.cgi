#!/usr/bin/perl -w
# use warnings;
use strict vars;
#For help, please send mail to the webmaster (it@scilifelab.se), giving this error message and the time and date of the error. 
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
#use DBI;
use HStextProcessor;
use Aconfig;
# use HS_html_gen;
# use HS_cytoscapeJS_gen;
use lib "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
use NET;
use HS_SQL;
$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; our ($dbh, $conditions, $pl, $nm, $debug, $stat);
my($step, $param);
$debug = 0;

our $q = new CGI; print $q->header().'<br>' ; 
print '<br>Submitted form values: <br>'.$q->query_string.'<br>' if $debug;  
$step = 'showAll'; # $step = 'login';
#($q->param("username") ne $q->param("auth_user")) or 
if ((!$q->param("username") and !$q->param("auth_user")) or (lc(auth_user($q->param("auth_user"))) ne 'ok')) {
($step, $param) = ('auth1', undef);
} else {
$step = $q->param("pressed-button") if $q->param("pressed-button");
# $step="Rplot-CTD-GNEA-gneatop400affymetrix1-Basu-PRIMA1-TERF2###0.614#4e-14#4.47e-11#115"; 
$step = $q->param("step") if defined($q->param("step"));
($step, $param) = ($1, lc($2)) if $step =~ m/(Rplot)-(.+)$/i;
}
print &$step($param);

sub logout {}

sub auth1 {
return '<div id="authbegin">
<form id="loginForm" name="loginForm" method="POST" action="cgi/a.cgi">
	<fieldset> <legend>Enter information</legend>
    <p>   <label for="username">Username</label>      <br />
	<input type="text" id="username" name="username" size="20" />
    </p>    <p>      <label for="password">Password</label>      <br />
    <input type="password" id="password" name="password" size="20"/>
    </p>    <p>
	<input type="submit" id="login-login"  name="pressed-button" value="login"/>
    <input type="button" id="login-cancel" name="cancel" value="cancel"/>
    </p>  </fieldset>
</form></div>
<script type="text/javascript">
		HSonReady();
        $("#authbegin").dialog({
		resizable: false,        modal: false,        title: "Login",        width:  "300px",
        height: "auto",		autoOpen: true,
		position: { my: "center center", at: "center center" }, 
		});
		$("input[id^=\'login-\']").click(function () {
		$("#authbegin").dialog("close");
		}		);
</script>'
		.formTotal(); 
		} 
		
sub showAll {
# my $file = '';
# system("Rscript ../R/runExploratory.r --vanilla --args table=t1.txt out=$file");



my $sm = showMenu();
my $sa = showAvailable();
$sm->{html} =~ s/\n//g;
$sa->{html} =~ s/\n//g;
return '
<script type="text/javascript">
$("#containmentWrapper").append(\''.$sm->{html}.$sa->{html}.'\');
$("#tabs").css("visibility", "visible");
HSonReady(); 
$("#tabs").tabs(); 
$("#tabs").tabs().addClass( "ui-helper-clearfix" );
'.$sm->{js}."\n".$sa->{js}.'
</script>'; 
} 

sub login {

my $username = $q->param("username");
my $password = $q->param("password");
# print "TEST\n";
$dbh = HS_SQL::dbh() or die $DBI::errstr;
#$stat = qq{SELECT id FROM users WHERE username=? and password=?};
$stat = qq{SELECT check_hash(?, ?)};
print $stat if $debug;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute($username, $password) or die $sth->errstr;
my $userID = $sth->fetchrow_array;
if ($userID) {
my($current, $expires);
$sth = $dbh->prepare( "SELECT LOCALTIMESTAMP, expires from sessions where ip='".$q->remote_addr()."' AND username='$username';" );
$sth->execute(  );
$sth->bind_columns(\$current, \$expires);
my $ok; undef $ok;
while ( $sth->fetch ) {
$ok = $expires if ($current > $expires);
}
if (!$ok or !$expires) {
$stat = "INSERT INTO sessions (id, username, ip, started, expires) VALUES (default, '$username', '".$q->remote_addr()."', LOCALTIMESTAMP, LOCALTIMESTAMP + interval ".$HS_SQL::session_length.")";
$sth = $dbh->do($stat);    # or die $dbh->errstr;
$sth = $dbh->do('COMMIT;');# or die $dbh->errstr;
}
#$sth->execute(, , ) or die $sth->errstr;
return 'Logged in as: <br><b><input type="text" readonly id="uid" value="'.$username.'"></b>    
<br>
<!--a href="'.$Aconfig::Rplots->{dir}.'3js.widget7.html'.'" target="_blank" class="clickable">a 3D plot</a-->
<input type="submit" id="logout" name="pressed-button" value="logout"/>
<script type="text/javascript">
$("#login_again").css("visibility", "hidden");
$("#logout").button();
$("#logout").click(function() {
$("#auth_user").	remove();
$("#login").html(\'<input type="button" id="login_again" name="login_again" value="login"/>\');
$("#main"). 		html("");
//$("#login_again").button();
		HSonReady();
$("#login_again").		css("visibility", "visible");
$("#login_again").click(function() {
    location.reload();
});
});
$("#uid").css("width", $("#logout").css("width"));
$("#uid").css("background-color", $("#logout").css("background-color"));
$("#form_total").append(\'<input type="hidden" id="auth_user" name="auth_user" value="'.$username.'"/>\');
</script>'.showAll();
} 
else {
return  '<script type="text/javascript">
        $("#autherror").dialog({
		resizable: false,
        modal: false,
        title: "Authentication error",
        width:  "300px",
        height: "auto",
		position: { 		my: "center center", at: "center center"}, 
		autoOpen: true,
        buttons: {"Close": 
		function () {
		$(this).dialog("close");
		}}
		});
		</script>';		}
}

sub auth_user  {
my($user) = @_;

return('ok');
}

sub formTotal { 

my $content = '<div id="analysis_total">
<div id = "Rplot"></div>
<div id="progressbar"></div>
<div id="tabs" ><ul>
<li><a href="#showAvailable">Significant results</a></li>
<li><a href="#showMenu">Look up</a></li>
</ul><div id="containmentWrapper"></div></div></div>
<script type="text/javascript">
$( "#progressbar" ).progressbar({
value: false
});
$( "#progressbar" ).css({"visibility": "hidden"});
$( "#tabs" ).css({"visibility": "hidden"});
//HSonReady(); 
</script>';
print $content;
}

sub showAvailable {
my($dty, $showName, $id, $screen, $pls, $crs, $cn, $drug, %altScreens, %altMenus, $menuID, $alt);
my $ls = 'corr';

$pls = Aconfig::dataSourcesForAnalysis();
$crs = Aconfig::availableCorrelations();
# my $js_reference = 'var sqltable = new Array();'."\n";
$cn->{html} = '<div id="showAvailable">
<table id="select_layout"><tr>
<td id="selectFeature">
<select name="screenList" id="screenList" class="ui-helper-hidden" style="width: 40ch;" >'."\n";
$cn->{html} .= '<option value="all">All screens</option>'."\n";
for $screen(sort {$a cmp $b} keys %{$crs->{screen}}) {
$cn->{html} .= '<option value="'.$screen.'">'.$Aconfig::datasetLabels{$screen}.'</option>'."\n";
}
$cn->{html} .= '</select></td>'."\n";
$cn->{html} .= '<td id="selectDrug">';
for $alt(('all', keys %{$crs->{drug}})) {
if ($alt eq 'all') {
$menuID = 'drugList';
$altMenus{$menuID} = 1;
$altScreens{$alt} .= '<div id="'.$menuID.'_div"><select name="'.$menuID.'" id="'.$menuID.'" class="ui-helper-hidden" style="width: 20ch; " >'."\n".'<option value="all">All compounds</option>'."\n";
for $screen(sort {$a cmp $b} keys %{$crs->{drug}}) {
next if (!defined($Aconfig::datasetLabels{$screen}));
$altScreens{$alt} .= '<optgroup label="'.$Aconfig::datasetLabels{$screen}.'">';
for $drug(sort {$a cmp $b} keys %{$crs->{drug}->{$screen}}) {
$altScreens{$alt} .= '<option value="'.$drug.'">'.$drug.'</option>'."\n";
}
$altScreens{$alt} .= '</optgroup>'."\n";
}
$altScreens{$alt} .= '</select></div>';
} 
else {
next if (!defined($Aconfig::datasetLabels{$alt}));
$menuID = 'drugList_'.$alt;
$altMenus{$menuID} = 1;
$altScreens{$alt} .= '<div id="'.$menuID.'_div"><select name="'.$menuID.'" id="'.$menuID.'" class="ui-helper-hidden" style="width: 20ch;" >'."\n".'<option value="all">All in '.$Aconfig::datasetLabels{$alt}.'</option>'."\n";
for $drug(sort {$a cmp $b} keys %{$crs->{drug}->{$alt}}) {
$altScreens{$alt} .= '<option value="'.$drug.'">'.$drug.'</option>'."\n";
}
$altScreens{$alt} .= '</select></div>';
}
}
for $alt(('all', keys %{$crs->{drug}})) {
$cn->{html} .= $altScreens{$alt}."\n";
}
$cn->{html} .= '</td>'."\n";

$cn->{html} .= '<td id="selectTabList">
<select id="corrTabList" name="corrTabList" class="ui-helper-hidden" style="width: 50ch;" >'."\n";
$cn->{html} .= '<option value="all">All features</option>'."\n";
for $dty(sort {$a cmp $b} keys %{$crs}) {
next if (!defined($Aconfig::HTPmenuList->{'correlations'}->{$dty}));
$cn->{html} .= '<optgroup label="'.$Aconfig::datasetLabels{$dty}.'">';
for $pl(sort {$a cmp $b} keys %{$crs->{$dty}}) {
if (defined($pls->{$dty}->{$pl}) and defined($Aconfig::datasetLabels{$pl})) {
$id = join('_', ($pl, $ls));#id="'.$id.'"
$showName = $Aconfig::datasetLabels{$pl}; #showName="'.$showName.'
$cn->{html} .= '<option value="'.$Aconfig::datasetNames{$pl}.'" style="width: '.($Aconfig::datasetLabels{maxlength} + 3).'ch;" " >'.$showName.'</option>'."\n";
# $js_reference .= ' sqltable["'.$id.'"] = "'.$pls->{$dty}->{$pl}.'"; ';
}}
$cn->{html} .= '</optgroup>'."\n";
}
$cn->{html} .= '</select></td>'."\n";
$cn->{html} .= '
<td><button type="submit" id="submit-retrieve" name="pressed-button" value="sqlResults" style="width: 150; visibility: visible;">Retrieve correlations</button></td></tr></table>
<div id="sqlResults"></div></div>'."\n";
#$js_reference.
$cn->{js} = '
$("#submit-retrieve").button();
$("#screenList").selectmenu({
select: function( event, ui ) {
$("div[id*=\'drugList_\']").css("display", "none");
//console.log(ui.item.value);
var Val = (ui.item.value == \'all\') ? "" : "_" + ui.item.value;
$("#drugList" + Val + "_div").css("display", "block");
}
});';
for $menuID(keys %altMenus) {
$cn->{js} .= '$("#'.$menuID.'").selectmenu();';
$cn->{js} .= '$("#'.$menuID.'_div").css("display", "'.(($menuID eq 'drugList') ? 'block' : 'none').'");';
}
$cn->{js} .= '$("#corrTabList").selectmenu({
select: function( event, ui ) {
//$("#corrTabList_choice").val(ui.item.attr("showName")); //$("#tcorrTabList").val(ui.item.value); 
} });';
return $cn;
}

sub sqlResults {
my($sqltable, $order ) = ('best_drug_corrs', ' abs(correlation) DESC ');
my $condition = "  dataset=\'CTD\' ";
$condition .=  " AND screen=\'".$q->param("screenList")."\'" if $q->param("screenList") ne 'all'; 
$condition .=  " AND platform=\'".$q->param("corrTabList")."\'" if $q->param("corrTabList") ne 'all'; 
my $selectedDrug = $q->param("drugList");
$selectedDrug = $q->param("drugList_".$q->param("screenList")) if $q->param("screenList") ne 'all';
$condition .=  " AND drug=\'".$selectedDrug."\'" if $selectedDrug ne 'all'; 


my( $row , $rows, @r, $col, $tbl, $pl, $gene);
my $dbh = HS_SQL::dbh();
# return "AAAAAAAAAAAAAAAAAAAAAA"; exit:

my $stat = "select * from $sqltable where $condition order by  $order limit 10000;";
print $stat if $debug; #
$tbl = '<table id="best_drug_corrs" class="display dt-responsive compact" width="95%" cellspacing="0">
    <thead>
        <tr>';
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
push @{$row}, '<button type="submit" name="pressed-button" value="Rplot-'.join('-', (@{$row}[0..1], $pl, @{$row}[3..4], $gene)).'###'.join('#', @{$row}[6..9]).'" style="width: 50; visibility: visible;">Plot</button>';
$tbl .= '<tr><td>'.join('</td><td>', @{$row}).'</td></tr>'."\n";
}
$tbl .= '</table>
<script   type="text/javascript">

 $("#best_drug_corrs").DataTable({
//responsive: true, 
         "dom": \'T<"clear">lfrtip\',
        "tableTools": {
            "sSwfPath": "../HyperSet/swf/copy_csv_xls_pdf.swf"
        }
    } );
	$("#best_drug_corrs_length").append("<div id=\'font_control\' class=\'dataTables_length\'>Font size:<span onclick=\'change_font(1.1, \"best_drug_corrs\");\' id=\'dt_font_up\' class=\'ui-icon ui-icon-plusthick\'  style=\'{float: left; margin-right: .3em;}\'></span><span onclick=\'change_font(0.9, \"best_drug_corrs\");\'  id=\'dt_font_dn\' class=\'ui-icon ui-icon-minusthick\' style=\'{float: left; margin-right: .3em;}\'></span></div>");
$(function() {$( ":button[value^=\'Rplot-\']" ).click(
function () {
 pressedButton = $(this).attr("name"); 
 suggestedTarget = "Rplot"; 
});});
</script>';
return ''.$tbl.''; #style="width: 1350px; "<div id="sqlResults" ></div>
}
# 
# //select_layout style='{display: inline; float: right;}' 
# //style='{float: right; position: relative; float: right; margin-bottom: 1em;}'
# //css("display","block");
# $("#best_drug_corrs").css("font-size", "70%");

sub Rplot {
my($param) = @_;
#print $param."\n";
my(@a0, @ar, $t1, $t2, $t3, $gene, $drug, $stats);
if ($param =~ m/###/) {
@a0 = split('###', $param);
@ar = split('-', $a0[0]);
$t1 = join('_', $ar[0], $ar[1], $ar[2]);
$t2 = join('_', $ar[0], 'clin', $Aconfig::screenLabels{$ar[3]});
$gene = $ar[5]; $gene =~ s/@@@/-/g;
$drug = $ar[4];
$stats = $a0[1];
$t3 = $q->param("t3");
} 
else {
$t1 = $q->param("t1");
$t2 = $q->param("t2");
$t3 = $q->param("t3");
$gene = $q->param("gene");
$drug = $q->param("drug");
$stats = "";
}
srand(); my $r = rand(); 
my $file = 'tmp'.$1.'.png' if $r =~  m/0\.([0-9]{12})/;
print "Rscript ../R/plotData.r --vanilla --args table1=$t1  table2=$t2 ".($t3 ? "table3=$t3 " : "")."gene=$gene drug=$drug out=$file<br>" if $debug;
system("Rscript ../R/plotData.r --vanilla --args table1=$t1  table2=$t2 ".($t3 ? "table3=$t3 " : " ")."gene=$gene drug=$drug out=$file");
my($caption, @st);
if ($stats) {
@st = split('#', $stats);
@ar = split('_', $t1);
my $set1 = $Aconfig::datasetLabels{$ar[2]};
if ($t1 =~ m/_mut_/i) {
$caption = join('', ($set1, '; p0=', $st[1], '; FDR=', $st[2], '; N=', $st[3]));
} 
else {
$caption = join('', ($set1, '; rank R=', $st[0], '; p0=', $st[1], '; FDR=', $st[2], '; N=', $st[3]));
}
} 
else {
$caption = '';
}
my $plotFile = '<script type="text/javascript">
var Stats = $("#Rplot").html();
Stats = Stats.substring(0, Stats.indexOf("script"))
if (Stats.indexOf("N=") > -1) {
Stats = Stats.substring(Stats.indexOf("###")+3, Stats.indexOf("^^^"))
} 
else {
Stats = "";
}
$("#Rplot").html("");
$("#Rplot").append("<div id=\'Rplot_in\' ><img src=\''.$Aconfig::Rplots->{dir}.$file.'\' alt=\'plot\'></div>"); //../pics/email2.bmp
        $("#Rplot_in").dialog({
		resizable: true,
		resize: function( event, ui ) {}, 
        modal: false,
//        title: Stats, 
		title: '.($caption ? '"'.$caption.'"' : 'Stats').',
        width:  "'.$Aconfig::Rplots->{imgSize} * ($t3 ? 1.3 : 1).'",
        height: "'.($Aconfig::Rplots->{imgSize} + 25).'",
		position: { 		my: "center bottom", at: "center bottom", 		of: "#form_total" 		}, 
		autoOpen: true,
show: {
effect: "blind",
duration: 400
},
hide: {
effect: "explode",
duration: 500
}, 
//dialogClass: "rplot", 
resizeStop: function( event, ui ) {
var Margin = 60;
var Img = jQuery("#Rplot_in").children("img");
console.log(ui.size.width);
Img.css("width", ui.size.width - Margin) ;
Img.css("height", ui.size.height - Margin) ;
}
        /*buttons: {"Close": 
		function () {
		$(this).dialog("close");
		}}*/
		});
		</script>';
return($plotFile);
}

sub geneList {
my($con, $stat, @tables, $i, $features, $drugs);
my $dbh = HS_SQL::dbh();

if ($q->param("t2") =~ m/_clin_/i) {
for $i(('1', '2', '3')) {
push @tables, $q->param("t".$i).'_samples' if $q->param("t".$i);
}
print join('<br>', @tables) if $debug;
my ($t1, $t2) = @tables;
$stat = "create view used_samples (sample) as select $t2.sample from $t2 inner join $t1 on $t2.sample = $t1.sample;";
print $stat if $debug;
$dbh->do($stat);
$stat = "select distinct upper(".$q->param("t2").".feature) from ".$q->param("t2")." inner join used_samples on ".$q->param("t2").".sample = used_samples.sample;";
print $stat if $debug;
$drugs = $dbh->selectcol_arrayref($stat);

$stat = "select distinct upper(".$q->param("t1").".feature) from ".$q->param("t1")." inner join used_samples on ".$q->param("t1").".sample = used_samples.sample;";
print $stat if $debug;
$features = $dbh->selectcol_arrayref($stat);

} 
else {
for $i(('1', '2', '3')) {
push @tables, $q->param("t".$i).'_features' if $q->param("t".$i);
}
print join('<br>', @tables) if $debug;
if ($#tables == 2) {
my ($t1, $t2, $t3) = @tables;
$stat = "select  upper($t1.feature) from $t1 inner join $t2 on $t1.feature = $t2.feature inner join $t3 ON $t1.feature = $t3.feature";
} 
elsif ($#tables == 1) {
my ($t1, $t2) = @tables;
$stat = "select  upper($t1.feature) from $t1 inner join $t2 on $t1.feature = $t2.feature;";
} 
else {
die "Less than 2 data sources specified...<br>\n";
}
print $stat if $debug;
$features = $dbh->selectcol_arrayref($stat);
}
$dbh->do("DROP VIEW IF EXISTS used_samples;");
$dbh->disconnect;
$con = '
<label for="name_a_gene">For one of '.scalar(@{$features}).' genes: </label>
<input id="name_a_gene" name="gene"><br>
<label for="selected_a_gene">Selected genes:</label>
<input id="selected_a_gene" name="sgene" disabled="disabled"><br>';
if ($q->param("t2") =~ m/_clin_/i) {
$con .= '<label for="name_a_drug">For one of '.scalar(@{$drugs}).' drugs: </label>
<input id="name_a_drug" name="drug">';
}
$con .= '<script type="text/javascript">
/*$(function() {
var availableTags = ["'.join('", "', @{$features}).'"];
$( "#name_a_gene" ).autocomplete({
source: availableTags
});
});*/
$(function() {
var availableTags = ["'.join('", "', @{$features}).'"];
function split( val ) {
  return val.split( /,\s*/ );
}
function extractLast( term ) {
  return split( term ).pop();
}
$( "#name_a_gene" )
  .on( "keydown", function( event ) {
    if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).autocomplete( "instance" ).menu.active ) {
      event.preventDefault();
    }
  })
  .autocomplete({
    minLength: 0,
    source: function( request, response ) {
      response( $.ui.autocomplete.filter(
       availableTags, extractLast( request.term ) ) );
    },
    focus: function() {
      return false;
    },
    select: function( event, ui ) {
      var terms = split( this.value );
      terms.pop();
      terms.push( ui.item.value );
      terms.push( "" );
      this.value = terms.join( ", " );
      return false;
    }
  });
});
$( "#name_a_gene" ).keydown(function() {
    var strVal = $.trim($(this).val());
    strVal = strVal.replace(/\,/g, "");
    $( "#selected_a_gene" ).val(strVal);

});
';
if ($q->param("t2") =~ m/_clin_/i) {   
$con .= '
$(function() {
var availableTags = ["'.join('", "', @{$drugs}).'"];
$( "#name_a_drug" ).autocomplete({
source: availableTags
});
});';
}
$con .= '</script>';
return $con;
}
 

sub showMenu {
#my($table) = @_;
my ($project, $dty, $pl, @lists, $id, $i, $showName, $ls, $cn);
$cn->{html} = '
<div id="showMenu" >
HTP platform<br>
<table id="HTPmenuTab" style="width: 800px; border-width: 0"><tr>';
my $pls = Aconfig::dataSourcesForAnalysis($project);
my $js_reference = 'var sqltable = new Array();';
for my $plotRole(('As X axis','As Y axis','As color')) {
$ls = lc($plotRole);
$ls =~ s/ /_/g;
push @lists, 'platform_'.$ls;
$cn->{html} .= '<td><label for="'.$lists[$#lists].'"> '.$plotRole.'</label>
<ul id="'.$lists[$#lists].'" class="ui-helper-hidden" style="width: 20ch;" >';
for $dty(keys %{$pls}) {
next if (!defined($Aconfig::HTPmenuList->{$plotRole}->{$dty}));
$cn->{html} .= '<li>'.$Aconfig::datasetLabels{$dty}.'<ul>';
for $pl(keys %{$pls->{$dty}}) {
if (defined($Aconfig::datasetLabels{$pl})) {
$id = join('_', ($pl, $ls));
$showName = $Aconfig::datasetLabels{$pl};
$cn->{html} .= '<li style="width: '.($Aconfig::datasetLabels{maxlength} + 3).'ch;" showName="'.$showName.'" sql="'.$pls->{$dty}->{$pl}.'" id="'.$id.'">'.$showName.'</li>';
$js_reference .= ' sqltable["'.$id.'"] = "'.$pls->{$dty}->{$pl}.'"; ';
}}
$cn->{html} .= '</ul></li>';
}
$cn->{html} .= '</ul>
<br><input type="text" id="'.$lists[$#lists].'_choice" autocomplete="off"/><input type="hidden" name="t'.($#lists+1).'" id="t'.($#lists+1).'" value=""/>
</td>';
}
$cn->{html} .= '<td></td>';
$cn->{html} .= '</tr></table>';
$cn->{html} .= '<div class="ui-widget">
<button type="submit" id="submit-populate" name="pressed-button" value="geneList" style="width: 150; visibility: visible;">Retrieve available genes</button>
<div id="geneList">geneList</div>
<button type="submit" id="submit-show-plot" name="pressed-button" value="Rplot" style="width: 150; visibility: visible;">Plot</button>
</div>
</div>';

$cn->{js} = '$("#submit-populate").button();
$("#submit-show-plot").button();
'.$js_reference;
$i = 0;
for $id(@lists) {
$cn->{js} .= '$("#'.$id.'").menu({
select: function( event, ui ) {
$("#'.$id.'_choice").val(ui.item.attr("showName")); 
$("#t'.++$i.'").val(ui.item.attr("sql")); 
           }, 
		   //disabled: '.(($id =~ m/color/i) ? "true" : "false").'
		   });
$("#'.$id.'_choice").on("change", 
function (param) {
$(this).val("");
$("#t'.$i.'").val("");
});   ';
}
return $cn;
}

sub showTable {
my($table) = @_;
return HS_html_gen::textTable2dataTables_JS($table, $Aconfig::tableDir, 'testtable', 1, "\t");
}

#exit;



