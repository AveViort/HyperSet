#!/usr/bin/speedy -w

# script for creating druggable plot
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

my $query = new CGI;
my $type = $query->param('type');
my $source = $query->param('source');
my $cohort = $query->param('cohort');
my $datatypes = $query->param('datatypes');
my $platforms = $query->param('platforms');
my $ids = $query->param('ids');
my $codes = $query->param('codes');
my $scales = $query->param('scales');
print $query->header("application/json");
srand(); my $r = rand();
my $file = 'tmp'.$1.'.html' if $r =~  m/0\.([0-9]{12})/;
my $meta = `Rscript ../R/druggable.$type.r --vanilla --args source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids='$ids' tcga_codes=$codes scales=$scales out=$file`;
# remove \ for JSON.parse in JS
$meta =~ s/\\//g;
# use substr here, because R output starts with '[1] ', also removes " in the beginning and the end
$meta = substr $meta, 5, -2;
# simple error check - correct JSON starts with
if ((substr $meta, 0, 1) ne '{') {
	# create correct JSON response - code in JS will check this file and get 404
	$meta = '{"plot_filename":"'.$file.'"}';
}
print $meta;