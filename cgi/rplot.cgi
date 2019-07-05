#!/usr/bin/speedy -w
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use Switch;

my $query = new CGI;
my $type = $query->param('type');
my $source = $query->param('source');
my $cohort = $query->param('cohort');
my $datatypes = $query->param('datatypes');
my $platforms = $query->param('platforms');
my $ids = $query->param('ids');
my $tcga_codes = $query->param('tcga_codes');
my $scales = $query->param('scales');
print "Content-type: text/html\n\n";
srand(); my $r = rand();
my $file = 'tmp'.$1.'.html' if $r =~  m/0\.([0-9]{12})/;
switch($type) {
	case "box" {system("Rscript ../R/boxplots.r --vanilla --args source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids tcga_codes=$tcga_codes scales=$scales out=$file");}
	case "venn" {system("Rscript ../R/druggable.venn.r --vanilla --args source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids tcga_codes=$tcga_codes out=$file");}
	else {
		if (($ids eq '') || ($ids eq ',') || ($ids eq ',,')) {
			system("Rscript ../R/plotData_without_ids.r --vanilla --args type=$type source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms tcga_codes=$tcga_codes scales=$scales out=$file");
		}
		else {
			system("Rscript ../R/plotData_with_ids.r --vanilla --args type=$type source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids tcga_codes=$tcga_codes scales=$scales out=$file");
		}
	}
}
print $file;