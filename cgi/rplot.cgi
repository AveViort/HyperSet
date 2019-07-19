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
system("Rscript ../R/druggable.".$type.".r --vanilla --args source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids tcga_codes=$tcga_codes scales=$scales out=$file");
print $file;