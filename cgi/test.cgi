#!/usr/bin/perl -w


use CGI; # qw(-no_xhtml);

my $query = new CGI;
my $timeout = $query->param('timeout');
print "Content-type: text/html\n\nTesting timeout <br> \n";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
print "Start time: ".$hour.":".$min.":".$sec." <br>\n";
print "\n------\n <br>";
my $passed = 1;
for ($i = 0; $i < $timeout; $i = $i + 1) {
	sleep 1;
	system("echo 1 > /dev/null");
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	print $passed." sec passed, current time: ",$hour.":".$min.":".$sec.";<br> \n";
	$passed = $passed + 1;
}