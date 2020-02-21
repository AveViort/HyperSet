#!/usr/bin/speedy -w
# use warnings;

# script for retrieving correlations in JSON format
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;

$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $stat);
my @row;

my $query = new CGI;
my $pass = $query->param("pass");

$dbh = HS_SQL::dbh('druggable');
$stat = qq/SELECT read_event_log(\'$pass'\);/;

print $query->header("application/json");
print '{"data":';
print "[";
my $sth = $dbh->prepare($stat) or die $dbh->errstr;
$sth->execute( ) or die $sth->errstr;
my $row_id = 1;
# carefull! This method is driver-dependent!
my $rows = $sth->rows;
while (@row = $sth->fetchrow_array()) {
	print "{";
	my @field_values = split /\|\|/, @row[0];
	my $event_time = @field_values[0];
	my $event_source = @field_values[1];
	my $event_level = @field_values[2];
	my $event_description = @field_values[3];
	my $event_options = @field_values[4];
	my $user_agent = @field_values[5];
	my $acknowledged = "<input type='checkbox' onclick='toggle_event_acknowledgement_status(\\\"".$pass."\\\", \\\"".$event_time."\\\", \\\"".$event_source."\\\", \\\"".$event_level."\\\", \\\"".$event_description."\\\", \\\"".$event_options."\\\", \\\"".$user_agent."\\\", this.checked)'". (@field_values[6] eq "true" ? " checked" : "") .">";
	my $event_message = @field_values[7];
	# need to replace \n with <br> for Datatables
	# also, JSON does not support \n - it should be replaced with "\n"
	$event_message =~ s/\n/"<br>"/eg;
	
	print '"event_time":"'.$event_time.'",';
	print '"event_source":"'.$event_source.'",';
	print '"event_level":"'.$event_level.'",';
	print '"event_description":"'.$event_description.'",';
	print '"event_options":"'.$event_options.'",';
	print '"event_message":"'.$event_message.'",';
	print '"user_agent":"'.$user_agent.'",';
	print '"acknowledged":"'.$acknowledged.'"';
	print "}";
	if ($row_id != $rows) { print ","; }
	$row_id = $row_id + 1;
}
print ']';
print '}';
$sth->finish;
$dbh->disconnect;