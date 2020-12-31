#!/usr/bin/speedy -w
# use warnings;

# script for retrieving correlations in JSON format
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;
use Switch;

$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $stat);
my @row;

my $query = new CGI;
my $source 		= $query->param("source"); 
my $datatype 	= $query->param("datatype");
my $cohort 		= $query->param("cohort"); 
my $platform 	= $query->param("platform");
my $screen 		= $query->param("screen");
my $id 			= $query->param("id");
my $fdr 		= $query->param("fdr");
my $mindrug 	= $query->param("mindrug");
my $columns 	= $query->param("columns");

$datatype	= "%" if $datatype	eq "all";
$cohort		= "%" if $cohort	eq "all";
$platform	= "%" if $platform	eq "all";
$screen 	= "%" if $screen	eq "all";
$id 		= "%" if $id 		eq "";

$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT retrieve_correlations(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\, \'$id'\, $fdr, $mindrug, \'$columns'\, \'$Aconfig::limit_column{$source}'\, $Aconfig::limit_num);/;

print $query->header("application/json");
print '{"data":';
print "[";
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $row_id = 1;
# carefull! This method is driver-dependent!
my $rows = $sth->rows;
my @column_names = split /,/, $columns;
my @field_names = ("gene", "feature", "datatype", "cohort", "platform", "screen", "sensitivity");
my $colnumber = @column_names;
my $i;
foreach $i(2..$colnumber-1) {
	push(@field_names, $column_names[$i]);
}
while (@row = $sth->fetchrow_array()) {
	if ($row[0] ne '') {
		print "{";
		my @field_values = split /\|/, $row[0];
		#print '"id":"',$row_id,'",';
		# all columns except for the last one - which has to be transformed into HTML element
		$colnumber = @field_values;
		# foreach $i(0..$colnumber-4) {
			# print '"'.$field_names[$i].'":"'.$field_values[$i].'",';
		# }
		# my $plot = "";
		# if ($field_values[2] ne "MUT") {
			# $plot = '<button id=\"cor-plot'.$row_id.'\" class=\"ui-button ui-widget ui-corner-all\" onclick=\"plot(\'scatter\', \'ccle\', \'ctd\', [\''.$field_values[2].'\', \'drug\'], [\''.$field_values[4].'\', \''.$field_values[5].'\'.split(\'.\').join(\'\')], [\''.$field_values[0].'\', \''.$field_values[1].'\'], [\'linear\', \'linear\'], [\'all\', \'all\'])\">Plot</button>';
		# } else {
			# $plot = '<button id=\"cor-plot'.$row_id.'\" class=\"ui-button ui-widget ui-corner-all\" onclick=\"plot(\'box\', \'ccle\', \'ctd\', [\''.$field_values[2].'\', \'drug\'], [\''.$field_values[4].'\', \''.$field_values[5].'\'.split(\'.\').join(\'\')], [\''.$field_values[0].'\', \''.$field_values[1].'\'], [\'linear\', \'linear\'], [\'all\', \'all\'])\">Plot</button>';
		# }
				 my $plot = '<span id=\"cor-plot'.$row_id.'\" class=\"adj-icon ui-icon ui-icon-chart-bars\" onclick=\"plot(\''.(($field_values[2] eq "MUT") ? "box" : "scatter").'\', \'ccle\', \'ctd\', [\''.$field_values[2].'\', \'drug\'], [\''.$field_values[4].'\', \''.$field_values[5].'\'.split(\'.\').join(\'\')], [\''.$field_values[0].'\', \''.$field_values[1].'\'], [\'linear\', \'linear\'], [\'all\', \'all\'])\" title=\"Plot\"></span>';
		my $url1 = $field_values[$colnumber-3];
		my @temp = split /\//, $url1;
		my $site_name = (split /\./,$temp[2])[1];
		my $info1 = 'Info';
		switch($site_name) {
			case "genecards" 		{ $info1 = "GeneCards" }
			case "broadinstitute" 	{ $info1 = "MSigDB" }
			case "nlm"				{ $info1 = "PubChem" }
			case "ncbi" 			{ $info1 = "PubChem" }
			case "wikipathways"		{ $info1 = "WikiPathways" }
			case "jp"				{ $info1 = "KEGG" }
			case "google"  			{ $info1 = "Google" }
			else { $info1 = "Info" }
		}
		my $url2 = $field_values[$colnumber-2];
		@temp = split /\//, $url2;
		$site_name = (split /\./, $temp[2])[1];
		my $info2 = 'Info';
		switch($site_name) {
			case "genecards" 		{ $info2 = "GeneCards" }
			case "broadinstitute" 	{ $info2 = "MSigDB" }
			case "nlm"				{ $info2 = "PubChem" }
			case "ncbi" 			{ $info2 = "PubChem" }
			case "wikipathways"		{ $info2 = "WikiPathways" }
			case "jp"				{ $info2 = "KEGG" }
			case "google"  			{ $info2 = "Google" }
			else { $info2 = "Info" }
		}
		# my $cohort_selector = "";
		my $km_button = "";
		my $cohorts = $field_values[$colnumber-1];
		if ($cohorts ne " ") {
			my @cohort_list = split /,/, $cohorts;
			my $cohort_selector = '<select id=\"TCGAcohortSelector'.$row_id.'\" class=\"ui-helper\">';
			my $cohort_list = '<div id=\"TCGAcohortList'.$row_id.'\" class=\"\">';
			foreach (@cohort_list) {
				my ($cohort_name, $datatype_name, $platform_name, $measure) = split /\#/, $_;
				$cohort_selector .= '<option value=\"'.$cohort_name.'#'.$datatype_name.'#'.$platform_name.'#'.$measure.'\">'.$cohort_name.'-'.$platform_name.'-'.$measure.'</option>';
				$cohort_list .= '<p cohort=\"'.$cohort_name.'\" datatype_name=\"'.$datatype_name.'\" platform_name=\"'.$platform_name.'\" measure=\"'.$measure.'\" <a class=\"clickable\" href=\"\">'.$cohort_name.'-'.$platform_name.'-'.$measure.'</a></p>';
			}
			$cohort_selector .= '</select>';
			$cohort_list .= '</div>';
			$cohort_list = '<p cohort=\''.$cohort_name.'\'>ppp<p>';
			$cohort_list = '';
			# https://mkkeck.github.io/jquery-ui-iconfont/
			# $km_button = '<button id=\"cor-KM'.$row_id.'\" class=\"ui-button ui-widget ui-corner-all\" onclick=\"plot(\'cor-KM\', \'tcga\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[0], [\'drug\', \'clin\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[1]], [\'drug\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[3].toLowerCase(), $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[2]], [\''.$field_values[1].'\', \'\',\''.$field_values[0].'\'], [\'linear\', \'linear\', \'linear\'], [\'all\', \'all\', \'all\'])\">KM</button>';		
			# $km_button = '<span id=\"cor-KM'.$row_id.'\" class=\"ui-icon ui-icon-chart-line\" onclick=\"plot(\'cor-KM\', \'tcga\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[0], [\'drug\', \'clin\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[1]], [\'drug\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[3].toLowerCase(), $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[2]], [\''.$field_values[1].'\', \'\',\''.$field_values[0].'\'], [\'linear\', \'linear\', \'linear\'], [\'all\', \'all\', \'all\'])\"></span>';
			$km_button = '<span id=\"cor-KM'.$row_id.'\" class=\"adj-icon ui-icon ui-icon-chart-line\" onclick=\"$(this).html(\\\\\''.$cohort_list.'\\\\\')\"></span>';
		}
		$platform = $field_values[4];
		if ($source eq "CCLE") {
			$cohort = "CTD";
		} else {
			if ($cohort eq "%") {
				$cohort = $field_values[3];
			}
		}
		# my $transfer_button = '<button class=\"ui-button ui-widget ui-corner-all\" onclick=\"transfer_id(\''.$source.'\', \''.$cohort.'\', \''. $field_values[2].'\', \''.$platform.'\', \''.$field_values[0].'\')\">+</button>';		 
		# this.css({\"background-color\": \"green\"});
		my $transfer_button = '<span class=\"adj-icon ui-icon ui-icon-circle-b-check\" onclick=\"transfer_id(\''.$source.'\', \''.$cohort.'\', \''. $field_values[2].'\', \''.$platform.'\', \''.$field_values[0].'\')\" title=\"Add to clipboard\"></span>';
		# my $transfer_button = '<span onclick=\"transfer_id(\''.$source.'\', \''.$cohort.'\', \''. $field_values[2].'\', \''.$platform.'\', \''.$field_values[0].'\')\"  style=\"float: left; margin-right: 0.5em;\"  class=\"ui-icon ui-icon-jquery\">icon</span>';
		my %maxchar; 	$maxchar{'gene'} = 21; 		$maxchar{'feature'} = 14;
		my($title, $display);
		my $span1 = '<span class=\"adj-icon ui-icon ui-icon-extlink\" onclick=\"window.open(\''.$url1.'\', \'_blank\')\" title='.$info1.' >&nbsp;</span>';
		my $span2 = '<span class=\"adj-icon ui-icon ui-icon-extlink\" onclick=\"window.open(\''.$url2.'\', \'_blank\')\" title='.$info2.' ></span>';
		foreach $i(0..$colnumber-4) {
		if ($field_names[$i] eq 'gene' || $field_names[$i] eq 'feature') {
					my $post_icon = $field_names[$i] eq 'gene' ? $span1 : $span2;
				$display = $field_values[$i];
				if (length($field_values[$i]) > $maxchar{$field_names[$i]}) {
			$title = 'title=\"'.$field_values[$i].'\"';
			$display = '<span '.$title.'>'.substr($field_values[$i], 0, $maxchar{$field_names[$i]}).'...</span>';
			}
				print '"'.$field_names[$i].'":"'.$display.$post_icon.'",';
		} else {
			print '"'.$field_names[$i].'":"'.$field_values[$i].'",';
			}
		}
		
		print '"plot":"'.$plot.'",';
		print '"cohort-selector":"'.$cohort_selector.'",';
		print '"KM-button":"'.$km_button.'",';
		# print '"info1":"<button class=\"ui-button ui-widget ui-corner-all\" onclick=\"window.open(\''.$url1.'\', \'_blank\')\">'.$info1.'</button>",';
		# print '"info1":"'.$span1.'",';
		print '"info1":"",';
		# print '"info2":"<button class=\"ui-button ui-widget ui-corner-all\" onclick=\"window.open(\''.$url2.'\', \'_blank\')\">'.$info2.'</button>",';
		# print '"info2":"'.$span2.'",';
		print '"info2":"",';
		print '"trbut":"'.$transfer_button.'"';
		print "}";
		if ($row_id != $rows) { print ","; }
		$row_id = $row_id + 1;
	}
	else {
		$rows = $rows - 1;
	}
}
print ']';
print '}';
$sth->finish;
$dbh->disconnect;