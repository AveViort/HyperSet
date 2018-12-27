#!/usr/bin/perl

$log = '/etc/httpd/logs/evinet.org-ssl-error_log';
$interval = 300; #sec
$Ntimes = 1000;
for $t(0..$Ntimes) {
print "$t\n";
open LL, "ls -l $log | " or die "Could not open $log...\n";
print <LL>."\n";
close LL;
system("echo a > $log");
sleep $interval;
}
