#!/usr/bin/speedy -w
# use warnings;

# this script generates table for the first tab of Druggable website

use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $stat, $sth);

print "Content-type: text/html\n\n";

$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT cohort,type FROM guide_table ORDER BY cohort DESC;/;
$sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;

my @data;
my %cohorts_info;
while (@data = $sth->fetchrow_array()) {
	#print $data[0].'|'.$data[1].'<br>';
	$cohorts_info{$data[0]}{$data[1]} = {};
}

my @cohorts = keys %cohorts_info;
my @all_datatypes, @datatypes, $cohort, $datatype, $platform, $description;
foreach(@cohorts) {
	$cohort = $_;
	@datatypes = keys $cohorts_info{$cohort};
	push(@all_datatypes, @datatypes);
	foreach(@datatypes) {
		$datatype = $_;
		#print $cohort.'|'.$datatype.'<br>';
		$stat = qq/SELECT platform_list(\'$cohort'\, \'$datatype'\);/;
		my $sth2 = $dbh->prepare($stat) or die $dbh->errstr;
		$sth2->execute( ) or die $sth->errstr;
		my @platform_description;
		while(@platform_description = $sth2->fetchrow_array) {
			my @temp = split /\|/, $platform_description[0];
			$platform	= $temp[0];
			$description = $temp[1];
			$cohorts_info{$cohort}{$datatype}{$platform} = $description;
			#print $cohort.'|'.$datatype.'|'.$platform.'|'.$description.'<br>';
		}
		$sth2->finish;
	}
}
@all_datatypes = keys { map { $_ => 1 } @all_datatypes };

print '<table>';
# generate header
print '<thead><tr><th></th>';
foreach(@cohorts) {
	$cohort = $_;
	print '<th>'.$cohort.'</th>';
}
print '</thead></tr>';

# generate body
print '<tbody>';
foreach(@all_datatypes) {
	$datatype = $_;
	print '<tr><td>'.$datatype.'</td>';
	foreach(@cohorts) {
		$cohort = $_;
		print '<td>';
		if (exists($cohorts_info{$cohort}{$datatype})) {
			my @platforms = keys $cohorts_info{$cohort}{$datatype};
			if (($datatype eq "CLIN") or ($datatype eq "IMMUNO")) {
				print '<a href="https://dev.evinet.org/cgi/help_ids_platforms.cgi?cohort='.$cohort.'&datatype='.$datatype.'" target="_blank">'.@platforms.' variables</a>';
			}
			else {
				foreach(@platforms){
					$platform = $_;
					$description = $cohorts_info{$cohort}{$datatype}{$platform};
					print '<a href="https://dev.evinet.org/cgi/help_ids_platforms.cgi?cohort='.$cohort.'&datatype='.$datatype.'&platform='.$platform.'" target="_blank">'.$description.'</a><br>';
				}
			}
		}
		print '</td>';
	}
	print '</tr>';
}
print '</tbody>';

print '</table>';

$sth->finish;
$dbh->disconnect;