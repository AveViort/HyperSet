#!/usr/bin/speedy -w
# use warnings;

# script for retrieving correlations in JSON format
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;
use Switch;
use Scalar::Util qw(looks_like_number);

$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $stat);
my @row;

my $query = new CGI;
my $source 			= $query->param("source"); 
my $datatype 		= $query->param("datatype");
my $cohort 			= $query->param("cohort"); 
my $platform 		= $query->param("platform");
my $screen 			= $query->param("screen");
my $id 				= $query->param("id");
my $fdr 			= $query->param("fdr");
my $mindrug 		= $query->param("mindrug");
my $data_columns 	= $query->param("data_columns");
my $filter_columns	= $query->param("filter_columns");
my $concat_operator	= $query->param("concat_operator");
my $limit_by		= $query->param("limit_by");

$datatype	= "%" if $datatype	eq "all";
$cohort		= "%" if $cohort	eq "all";
$platform	= "%" if $platform	eq "all";
$screen 	= "%" if $screen	eq "all";
$id 		= "%" if $id 		eq "";

$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT retrieve_correlations(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\, \'$id'\, $fdr, $mindrug, \'$data_columns'\, \'$filter_columns'\, \'$concat_operator'\, \'$limit_by'\, $Aconfig::limit_num);/;

print $query->header("application/json");
#print $stat;
print '{"data":';
print "[";
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $row_id = 1;
# carefull! This method is driver-dependent!
my $rows = $sth->rows;
my @column_names = split /,/, $data_columns;
my $colnumber;
# column which contains survival interval (1, 0.5...), -1 means we have no such column
my $followup_column = -1;
my @field_names = ("gene", "feature", "datatype", "cohort", "platform", "screen", "sensitivity");
while (@row = $sth->fetchrow_array()) {
	if ($row[0] ne '') {
		print "{";
		my @field_values = split /\|/, $row[0];
		if ($row_id == 1) {
			# all columns except for the last one - which has to be transformed into HTML element
			$colnumber = @field_values;
			my $i;
			foreach $i(2..$colnumber-1) {
				push(@field_names, $column_names[$i]);
			}
			foreach $i(0..$colnumber-4) {
				if ($field_names[$i] eq 'followup') {
					# we assume that followup_part always comes right after followup
					$followup_column = $i+1;
				}
			}
		}
		#print '"id":"',$row_id,'",';
		#my $plot = '<span id=\"cor-plot'.$row_id.'\" class=\"adj-icon ui-icon ui-icon-chart-bars\" onclick=\"plot(\''.(($field_values[2] eq "MUT") ? "box" : "scatter").'\', \'ccle\', \'ctd\', [\''.$field_values[2].'\', \'sens\'], [\''.$field_values[4].'\', \''.$field_values[5].'\'.split(\'.\').join(\'\')], [\''.$field_values[0].'\', \''.$field_values[1].'\'], [\'linear\', \'linear\'], \'all\')\" title=\"Plot\"></span>';
		my $url1 = $field_values[$colnumber-3];
		my $url2 = $field_values[$colnumber-2];
		@temp = split /\//, $url2;
		my $cohort_selector = "";
		my $verification = "";
		my $cohorts = $field_values[$colnumber-1];
		if ($cohorts ne " ,") {
			my @cohort_list = split /,/, $cohorts;
			$cohort_selector = '<select id=\"TCGAcohortSelector'.$row_id.'\">';
			# $cohort_selector = '<button id=\"cor-KM'.$row_id.'\" class=\"ui-button ui-widget ui-corner-all\" onclick=\"plot_dialog(\''.@field_values[1].','.@field_values[0].','.$cohorts.'\')\">KMs</button>';
			for (my $j = 0; $j < (scalar(@cohort_list)-1); $j++) {
				my ($source_name, $cohort_name, $datatype_name, $platform_name, $measure) = split /\#/, $cohort_list[$j];
				my $plot_type = 'KM';
				if ($source_name eq 'CCLE') {
					$plot_type = $datatype_name eq 'MUT' ? 'box' : 'scatter';
				}
				my $surv_period = 1;
				if ($followup_column > -1) {
					$surv_period = $field_values[$followup_column];
				}	
				$cohort_selector .= '<option value=\"'.$plot_type.'#'.$cohort_list[$j].'#'.$field_values[1].'#'.$field_values[0].($plot_type eq 'KM' ? '#'.$surv_period : '').'\">'.$source_name.': '.$cohort_name.': '.$platform_name.': '.$measure.'</option>';
			}
			$cohort_selector .= '</select>';
			$verification = $cohort_list[scalar(@cohort_list)-1];
			# https://mkkeck.github.io/jquery-ui-iconfont/
			#$km_button = '<span id=\"cor-KM'.$row_id.'\" class=\"adj-icon ui-icon ui-icon-chart-line\" onclick=\"plot(\'cor-KM\', \'tcga\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[0], [\'DRUG\', \'CLIN\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[1]], [\'drug\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[3].toLowerCase(), $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[2]], [\''.@field_values[1].'\', \'\',\''.@field_values[0].'\'], [\'linear\', \'linear\', \'linear\'], \'all\')\"></span>';
		}
		$platform = $field_values[4];
		if ($source eq "CCLE") {
			$cohort = "CCLE";
		} else {
			if ($cohort eq "%") {
				$cohort = $field_values[3];
			}
		}
		# my $transfer_button = '<button class=\"ui-button ui-widget ui-corner-all\" onclick=\"transfer_id(\''.$source.'\', \''.$cohort.'\', \''. $field_values[2].'\', \''.$platform.'\', \''.$field_values[0].'\')\">+</button>';		 
		my $transfer_button = '<span class=\"adj-icon ui-icon ui-icon-copy\" onclick=\"transfer_id(\''.$source.'\', \''.$cohort.'\', \''. $field_values[2].'\', \''.$platform.'\', \''.$field_values[0].'\')\" title=\"Add to clipboard\"></span>';
		# my $transfer_button = '<span onclick=\"transfer_id(\''.$source.'\', \''.$cohort.'\', \''. $field_values[2].'\', \''.$platform.'\', \''.$field_values[0].'\')\"  style=\"float: left; margin-right: 0.5em;\"  class=\"ui-icon ui-icon-jquery\">icon</span>';
		my %maxchar; 	$maxchar{'gene'} = 21; 		$maxchar{'feature'} = 14;
		my($title, $display);
		my $span1 = '<span class=\"adj-icon ui-icon ui-icon-extlink\" onclick=\"window.open(\''.$url1.'\', \'_blank\')\" onmouseover=\"var x = annotations.get(\''.$field_values[0].'\'.toLowerCase());if(typeof x != \'undefined\'){this.setAttribute(\'title\', x);}\" >&nbsp;</span>';
		my $span2 = '<span class=\"adj-icon ui-icon ui-icon-extlink\" onclick=\"window.open(\''.$url2.'\', \'_blank\')\" title=\"'.$field_values[1].'\" ></span>';
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
				if ($field_names[$i] eq 'followup') {
					# we assume that followup_part always comes right after followup
					my $followup_with_qtip = '<a title=\"'.($field_values[$i+1]*100).' percent of cohort\">'.$field_values[$i].'</a>';
					print '"'.$field_names[$i].'":"'.$followup_with_qtip.'",';
				} else {
					if($field_names[$i] eq 'followup') {
						# do nothing - ignore this column, we use it for qtips only
					} else {
						my $field_value = looks_like_number($field_values[$i]) ? ($field_values[$i] < 10e-05 ? sprintf('%.2e', $field_values[$i]) : $field_values[$i]) : $field_values[$i];
						print '"'.$field_names[$i].'":"'.$field_value.'",';
					}
				}
			}
		}
		
		#print '"plot":"'.$plot.'",';
		print '"cohort-selector":"'.$cohort_selector.'",';
		print '"verification":"'.$verification.'",';
		#print '"KM-button":"'.$km_button.'",';
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