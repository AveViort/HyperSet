#!/usr/bin/speedy -w

# script for retrieving parameters for auto
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );

our ($dbh, $stat);
my(@option_line);

my $query = new CGI;
my $script = $query->param("script");

print "Content-type: text/html\n\n";
open(my $data, '<', $script) or die "Could not open '$script' $!\n";
 
while (my $line = <$data>) {
  chomp $line;
  if (($line ne "") and ((substr $line, 0, 1) ne "/")) {
	print $line.'|';
  }
}

close($script);