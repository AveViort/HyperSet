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
#print "Rscript ../R/plotData.r --vanilla --args table1=$t1  table2=$t2 gene=$gene drug=$drug out=$file<br>";
#system("Rscript ../R/plotData.r --vanilla --args table1=$t1  table2=$t2 gene=$gene drug=$drug out=$file");
srand(); my $r = rand();
my $file = 'tmp'.$1.'.png' if $r =~  m/0\.([0-9]{12})/;
if ($ids eq '') {
	system("Rscript ../R/plotData_without_ids.r --vanilla --args type=$type cohort=$cohort datatypes=$datatypes platforms=$platforms out=$file");
}
else {
	system("Rscript ../R/plotData_test.r --vanilla --args type=$type cohort=$cohort datatypes=$datatypes platforms=$platforms ids=$ids scales=$scales out=$file");
}
print $file;