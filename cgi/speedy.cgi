#!/usr/bin/speedy -w

print "Content-type: text/html\n\nHello World!\n";
use CGI::SpeedyCGI;
my $sp = CGI::SpeedyCGI->new;
print "Running under speedy=", $sp->i_am_speedy ? 'yes' : 'no', "\n";
