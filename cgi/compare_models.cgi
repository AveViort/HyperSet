#!/usr/bin/speedy -w

# compare several models with each other
# use warnings;
use strict vars;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

my $query = new CGI;
my $models = $query->param('models');
my $filename = $query->param('filename');

print "Content-type: text/html\n\n";
system("Rscript ../R/compare_models.r --vanilla --args models=$models filename=$filename");
print $filename;