#!/usr/bin/speedy -w
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

my $query = new CGI;
my $type = $query->param('type');
my $cohort = $query->param('cohort');
my $datatypes = $query->param('datatypes');
my $platforms = $query->param('platforms');
my $ids = $query->param('ids');
my $scales = $query->param('scales');
print "Content-type: text/html\n\n";
srand(); my $r = rand();
my $file = 'tmp'.$1.'.png' if $r =~  m/0\.([0-9]{12})/;
if ($type eq 'box') {
	system("Rscript ../R/boxplots.r --vanilla --args cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids scales=$scales out=$file");
}
else {
	if (($ids eq '') || ($ids eq ',') || ($ids eq ',,')) {
		system("Rscript ../R/plotData_without_ids.r --vanilla --args type=$type cohort=$cohort datatypes=$datatypes platforms=$platforms scales=$scales out=$file");
	}
	else {
		system("Rscript ../R/plotData_with_ids.r --vanilla --args type=$type cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids scales=$scales out=$file");
	}
}
print $file;