#!/usr/bin/speedy -w

# script for creating predictive models
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

my $query = new CGI;
# common options
my $method 		= $query->param('method');
my $source 		= $query->param('source');
my $cohort 		= $query->param('cohort');
my $multiopt 	= $query->param('multiopt');

# independent variables
my $xdatatypes 	= $query->param('xdatatypes');
my $xplatforms 	= $query->param('xplatforms');
my $xids 		= $query->param('xids');

# dependent variables
my $rdatatype 	= $query->param('rdatatype');
my $rplatform 	= $query->param('rplatform');
my $rid 		= $query->param('rid');

# glmnet options
my $family 		= $query->param('family');
my $measure 	= $query->param('measure');
my $alpha 		= $query->param('alpha');
my $nlambda 	= $query->param('nlambda');
my $minlambda 	= $query->param('minlambda');
my $validation 	= $query->param('validation');
my $validation_fraction = $query->param('validation_fraction');
my $nfolds 		= $query->param('nfolds');
my $standardize = $query->param('standardize');

# additional option - if defined, model data is written to this file in append mode
my $stat_file 	= $query->param('stat_file');
# binary, TRUE allows header, FALSE suppresses it
# absolutely required for batch jobs - otherwise for n models header will be printed n times
my $header		= $query->param('header');

print "Content-type: text/html\n\n";
srand();
my $r = rand();
my $file = 'model'.$1 if $r =~  m/0\.([0-9]{12})/;
system("Rscript ../R/model.".$method.".r --vanilla --args ".
	"source=$source cohort=$cohort rdatatype=$rdatatype rplatform=$rplatform rid=$rid ".
	"xdatatypes=$xdatatypes xplatforms=$xplatforms xids='$xids' multiopt='$multiopt' ".
	"family=$family measure=$measure alpha=$alpha nlambda=$nlambda minlambda=$minlambda validation=$validation " .
	"validation_fraction=$validation_fraction nfolds=$nfolds standardize=$standardize out=$file statf=$stat_file header=$header");
print $file;