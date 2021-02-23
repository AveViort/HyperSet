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
print "Content-type: text/html\n\n";
srand(); my $r = rand();
my $file = 'tmp'.$1.'.html' if $r =~  m/0\.([0-9]{12})/;
system("Rscript ../R/druggable.".$type.".r --vanilla --args source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids='$ids' tcga_codes=$codes scales=$scales out=$file");
print $file;