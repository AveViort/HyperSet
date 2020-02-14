#!/usr/bin/speedy -w

# script for creating predictive models
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

my $query = new CGI;
my $method = $query->param('method');
my $source = $query->param('source');
my $cohort = $query->param('cohort');
my $datatypes = $query->param('datatypes');
my $platforms = $query->param('platforms');
my $ids = $query->param('ids');
my $multiopt = $query->param('multiopt');
print "Content-type: text/html\n\n";
srand(); my $r = rand();
my $file = 'model'.$1.'.pdf' if $r =~  m/0\.([0-9]{12})/;
system("Rscript ../R/model.".$method.".r --vanilla --args source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids='$ids' out=$file");
print $file;