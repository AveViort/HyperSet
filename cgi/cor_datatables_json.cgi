#!/usr/bin/speedy -w
# use warnings;

# script for retrieving drug list for each source
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;

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
$stat = qq/SELECT retrieve_correlations(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\, \'$id'\, $fdr, $mindrug, \'$columns'\);/;

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
	push(@field_names, @column_names[$i]);
}
while (@row = $sth->fetchrow_array()) {
	print "{";
	my @field_values = split /\|/, @row[0];
	#print '"id":"',$row_id,'",';
	# all columns except for the last one - which has to be transformed into HTML element
	$colnumber = @field_values;
	foreach $i(0..$colnumber-2) {
		print '"'.@field_names[$i].'":"'.@field_values[$i].'",';
	}
	my $plot = "";
	if (@field_values[2] ne "MUT") {
		$plot = '<button id=\"cor-plot'.$row_id.'\" class=\"ui-button ui-widget ui-corner-all\" onclick=\"plot(\'scatter\', \'ccle\', \'ctd\', [\''.@field_values[2].'\', \'drug\'], [\''.@field_values[4].'\', \''.@field_values[5].'\'], [\''.@field_values[0].'\', \''.@field_values[1].'\'], [\'linear\', \'linear\'], [\'all\', \'all\'])\">Plot</button>';
	}
	my $cohort_selector = "";
	my $km_button = "";
	my $cohorts = @field_values[$colnumber-1];
	if ($cohorts ne " ") {
		my @cohort_list = split /,/, $cohorts;
		$cohort_selector = '<select id=\"TCGAcohortSelector'.$row_id.'\" class=\"ui-helper\">';
		foreach (@cohort_list) {
			my ($cohort_name, $datatype_name, $platform_name, $measure) = split /\#/, $_;
			$cohort_selector .= '<option value=\"'.$cohort_name.'#'.$datatype_name.'#'.$platform_name.'#'.$measure.'\">'.$cohort_name.'-'.$platform_name.'-'.$measure.'</option>';
		}
		$cohort_selector .= '</select>';
		$km_button = '<button id=\"cor-KM'.$row_id.'\" class=\"ui-button ui-widget ui-corner-all\" onclick=\"plot(\'cor-KM\', \'tcga\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[0], [\'drug\', \'clin\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[1]], [\'drug\', $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[3].toLowerCase(), $(\'#TCGAcohortSelector'.$row_id.' option:selected\').val().split(\'#\')[2]], [\''.@field_values[1].'\', \'\',\''.@field_values[0].'\'], [\'linear\', \'linear\', \'linear\'], [\'all\', \'all\', \'all\'])\">KM</button>';
	}
	print '"plot":"'.$plot.'",';
	print '"cohort-selector":"'.$cohort_selector.'",';
	print '"KM-button":"'.$km_button.'"';
	print "}";
	if ($row_id != $rows) { print ","; }
	$row_id = $row_id + 1;
}
print ']';
print '}';
$sth->finish;
$dbh->disconnect;