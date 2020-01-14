#!/usr/bin/speedy -w

# script for marking plot file as "do not delete"
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HSconfig;

my $query = new CGI;
my $plot_name = $query->param("plot");
my $file_name = '../'.$HSconfig::Rplots->{dir}.'do_not_delete.txt';

print "Content-type: text/html\n\n";
open(my $fh, '>>', $file_name);
print $fh $plot_name."\n";
close $fh;
print $file_name.": added ".$plot_name;