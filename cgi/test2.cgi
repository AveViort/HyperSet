#!/usr/bin/perl -w


use CGI; # qw(-no_xhtml);
use Proc::Background;

print "Content-type: text/html\n\nTesting timeout with background process<br>";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
print "Start time: ".$hour.":".$min.":".$sec." <br>";
print "------<br>";
my $cmd= "perl /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/wait.cgi";
print $cmd."<br>";
my $proc=Proc::Background->new($cmd);
my $alive=$proc->alive;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
print "Process spawned: ".$hour.":".$min.":".$sec." <br>";
my $pid=$proc->pid;
print "Child PID: ".$pid."<br>";
print "Self PID: ".$$."<br>";
#my $debug_filename = "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/debug_wait.txt";
#open(my $fh, '>', $debug_filename);
#print $fh "Debug report test2.cgi, PID: ".$pid."\n";
while ($alive == 1) {
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	print "Child process (".$pid.") is alive: ".$hour.":".$min.":".$sec." (self: ". $$. ") <br>";
	#print $fh "Child process (".$pid.") is alive: ".$hour.":".$min.":".$sec." (self: ". $$. ") \n";
	$alive=$proc->alive;
	sleep 1;
	system("echo 1 > /dev/null");
}
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
print "Script over: ".$hour.":".$min.":".$sec." <br>";
#print $fh "Script over: ".$hour.":".$min.":".$sec." \n";
#close $fh;