#!/usr/bin/perl
use strict vars;

my($return, $fname, @files, $file);
@files = @ARGV;

for $file(@files) {
print $file."\n";
$/ = undef;
open IN, $file or die "Cannot open GO\n";
$_ = <IN>;
# while (m/\s*sub\s+([a-z0-9]+)\s*\{(.+?)\}/sig) {
# $_ = s/\<script.+?\<\/script\>//sig;
while (m/\s*sub\s+([a-z0-9]+)\s*\{\s*(.+?)\s+/sig) {
undef $fname; undef $return;
$fname = $1;
$return = $1 if (defined($2) and $2 =~ m/return[\s\(]{1}([\w\$\:]+).+/i);
#m/return[\s\(]*([\w\_\$\:]+)[\s\)\;]+/i);
print join("\t", ($fname, $return))."\n";
}
close IN;
}
