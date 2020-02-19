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

# glmnet options
my $family = $query->param('family');
my $measure = $query->param('measure');
my $alpha = $query->param('alpha');
my $nlambda = $query->param('nlambda');
my $minlambda = $query->param('minlambda');
my $validation = $query->param('validation');
my $validation_fraction = $query->param('validation_fraction');
my $nfolds = $query->param('nfolds');
my $standardize = $query->param('standardize');

print "Content-type: text/html\n\n";
srand(); my $r = rand();
my $file = 'model'.$1.'.pdf' if $r =~  m/0\.([0-9]{12})/;
system("Rscript ../R/model.".$method.".r --vanilla --args ".
	"source=$source cohort=$cohort datatypes=$datatypes platforms=$platforms ids='$ids' multiopt='$multiopt' ".
	"family=$family measure=$measure alpha=$alpha nlambda=$nlambda minlambda=$minlambda validation=$validation " .
	"validation_fraction=$validation_fraction nfolds=$nfolds standardize=$standardize out=$file");
print $file;