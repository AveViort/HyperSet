#!/usr/bin/speedy -w
# use warnings;

use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
my ($dbh, $stat, $pid);

my $flag = 1;

print "Content-type: text/html\n\n";
$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT pid FROM job_queue;/;
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;

while ($pid = $sth->fetchrow_array()) {
	$flag = 0;
	my $status = `ps -e | grep $pid`;
	print 'Process '.$pid.' is '.($status eq '' ? 'not' : '').' running<br>';
	if ($status eq '') {
		$stat = qq/DELETE FROM job_queue WHERE pid=$pid;/;
		my $sth2 = $dbh->prepare($stat) or die $dbh->errstr;
		$sth2->execute( ) or die $sth2->errstr;
		$dbh->commit;
		print '---> Job removed from the queue<br>';
	}
}
if ($flag) {
	print 'No jobs are running';
}

$sth->finish;
$dbh->disconnect;