#!/usr/bin/speedy -w
# use warnings;

# this scripts retrieves significant correlations and creates glmnet models
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;
use Switch;
use Net::SMTP;
use Time::HiRes qw(time);

$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $stat);
my @row;

my $query = new CGI;
# this section describes parameters for retrieving correlates (similar to cor_datatables_json.cgi)
my $source 		= $query->param("source"); 
my $datatypes 	= $query->param("datatype");
my $cohorts 	= $query->param("cohort"); 
my $platforms 	= $query->param("platform");
my $screens		= $query->param("screen");
my $ids			= $query->param("id");
my $fdr 		= $query->param("fdr");
my $mindrug 	= $query->param("mindrug");
my $columns 	= $query->param("columns");

# this section describes parameters for model creation
my $method = $query->param('method');
my $model_cohort = $query->param('model_cohort');
my $multiopt = $query->param('multiopt');

# independent variables
# datatatypes and platforms must be specified by user, ids are taken from correlations
my $xdatatypes = $query->param('xdatatypes');
my $xplatforms = $query->param('xplatforms');
my @xids;

# dependent variables
my $rdatatype = $query->param('rdatatype');
my $rplatform = $query->param('rplatform');
my $rid = $query->param('rid');

# glmnet options
my $family 				= $query->param('family');
my $measure 			= $query->param('measure');
my $alpha 				= $query->param('alpha');
my $nlambda 			= $query->param('nlambda');
my $minlambda 			= $query->param('minlambda');
my $validation 			= $query->param('validation');
my $validation_fraction = $query->param('validation_fraction');
my $nfolds 				= $query->param('nfolds');
my $standardize 		= $query->param('standardize');

# number of iterations - how many models should be created
my $iter = $query->param('iter');
# file, where stats should be stored
my $batch_file = $query->param('stat_file');

# send notifications to this address
my $mail = $query->param('mail');

# split our parameters
my @split_datatypes		= split /\,/, $datatypes;
my @split_cohorts 		= split /,/, $cohorts;
my @split_platforms		= split /,/, $platforms;
my @split_screens		= split /,/, $screens;
my @split_ids			= split /,/, $ids;
# iterator
my $i, $j;

# verify parameters
my $email_pattern= '^([a-zA-Z][\w\_\.]{6,24})\@([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,4})$';
my $verification_flag;

print "Content-type: text/html\n\n";
# verify email
$verification_flag = ($mail =~ email_pattern);
if (verification_flag) {
	srand();
	# this variable is unused by defaut - keep it as a reminder of table structure and for future possible uses
	my @field_names = ("gene", "feature", "datatype", "cohort", "platform", "screen", "sensitivity");
	my $colnumber = @column_names;
	my @row;
	my @unique_xids;
	my $all_ids = "";
	my $header;
	$dbh = HS_SQL::dbh('druggable');

	# generate job id based on time (time returns float, convert it to integer)
	my $jid = int(time);
	# get system pid of current script using special Perl variable 
	my $pid = $$;
	# check if we can run the job
	$stat = qq/SELECT add_job($jid, $pid, \'$mail'\, $Aconfig::queue_size);/;
	my $sth = $dbh->prepare($stat) or die $dbh->errstr;
	$sth->execute( ) or die $sth->errstr;
	$dbh->commit;
	my $job_status = $sth->fetchrow_array;
	#print $job_status;
	#print $query;

	switch($job_status) {
		case 'start' {
			START:
			$stat = qq/SELECT report_event(\'models_from_correlations_batch.cgi'\, \'info'\, \'job_started'\, \'placeholder'\, \'Batch job $jid has been started'\, \'internal'\);/;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			$dbh->commit;
			foreach $i(0..@split_datatypes-1) {
				$datatype	= ($split_datatypes[$i]	eq "all")	? "%" : $split_datatypes[$i];
				$cohort		= ($split_cohorts[$i]	eq "all")	? "%" : $split_cohorts[$i];
				$platform	= ($split_platforms[$i]	eq "all")	? "%" : $split_platforms[$i];
				$screen 	= ($split_screens[$i]	eq "all")	? "%" : $split_screens[$i];
				$id 		= ($split_ids[$i]		eq "") 		? "%" : $split_ids[$i];
		
				# retrieve correlations
				$stat = qq/SELECT retrieve_correlations_simplified(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\, \'$id'\, $fdr, $mindrug, \'$columns'\, \'$Aconfig::limit_column{$source}'\, $Aconfig::batch_limit_num);/;
				#print $stat;
				$sth = $dbh->prepare($stat) or die $dbh->errstr;
				$sth->execute( ) or die $sth->errstr;

				while (@row = $sth->fetchrow_array()) {
					if ($row[0] ne '') {
						my @field_values = split /\|/, $row[0];
						push @{ $xids[$i] }, $field_values[0];
					}
				}
				@{ $unique_xids[$i] } = keys { map { $_ => 1 } @{ $xids[$i] } };
				# print @xids.'|'.@unique_xids;
				# print join(",", @{ $unique_xids[$i] });
				# refer to build_model function in drugs.js for understanding $all_ids format 
				if (($i != 0) && ($i != @split_datatypes-1)) {
					$all_ids = $all_ids.",";
				}
				$all_ids = $all_ids."[".join("|", @{ $unique_xids[$i] })."]"; 
			}

			foreach $j(1..$iter) {
				print $j."<br>";
				my $r = rand();
				my $file = 'model'.$1 if $r =~  m/0\.([0-9]{12})/;
				$header = ($j == 1) ? "TRUE" : "FALSE";
				#print "Rscript ../R/model.".$method.".r --vanilla --args ".
				#	"source=".$source." cohort=".$cohort." rdatatype=".$rdatatype." rplatform=".$rplatform." rid=".$rid.
				#	" xdatatypes=".$xdatatypes." xplatforms=".$xplatforms." xids='".$all_ids."' multiopt='".$multiopt."' ".
				#	" family=".$family." measure=".$measure." alpha=".$alpha." nlambda=".$nlambda." minlambda=".$minlambda." validation=".$validation.
				#	" validation_fraction=".$validation_fraction." nfolds=".$nfolds." standardize=".$standardize." out=".$file." statf=$batch_file header=$header<br>";
				system("Rscript ../R/model.".$method.".r --vanilla --args ".
					"source=$source cohort=$model_cohort rdatatype=$rdatatype rplatform=$rplatform rid=$rid ".
					"xdatatypes=$xdatatypes xplatforms=$xplatforms xids='$all_ids' multiopt='$multiopt' ".
					"family=$family measure=$measure alpha=$alpha nlambda=$nlambda minlambda=$minlambda validation=$validation " .
					"validation_fraction=$validation_fraction nfolds=$nfolds standardize=$standardize out=$file statf=$batch_file header=$header");
			}
			
			$stat = qq/SELECT remove_job(\'$jid'\);/;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			$dbh->commit;
			
			my $stat_file = 'https://www.evinet.org/pics/plots/'.$batch_file.'.csv';
			# check how many iterations successfully passed (-1 because of header)
			my $pased_iterations = `wc -l < $stat_file` - 1;
			
			$stat = qq/SELECT report_event(\'models_from_correlations_batch.cgi'\, \'info'\, \'job_finished'\, \'placeholder'\, \'Batch job $jid has been finished'\, \'internal'\);/;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			$dbh->commit;
			
			my $smtp = Net::SMTP->new('localhost') or die $!;
			my $from = 'webmaster@evinet.org';
			my $subject = 'Your Druggable batch job is done';
			my $message = 'Dear Druggable user, \n\n'. 
				'the job you have submitted to Druggable is done. You can find results here: '.$stat_file.' \r\n\r\n'. 
				'Regards,\r\nDruggable';
			if ($passed_iterations < $iter) {
				$message = $message.'\r\nPlease note that some iterations failed.';
			}
			$smtp->mail( $from );
			$smtp->to( $mail );
			$smtp->data();
			$smtp->datasend("To: $mail\n");
			$smtp->datasend("From: $from\n");
			$smtp->datasend("Subject: $subject\n");
			$smtp->datasend("\n"); # done with header
			$smtp->datasend($message);
			$smtp->dataend();
			$smtp->quit();
			
		}
		case "scheduled" {
			$stat = qq/SELECT report_event(\'models_from_correlations_batch.cgi'\, \'info'\, \'job_scheduled'\, \'placeholder'\, \'Batch job $jid has been scheduled for execution'\, \'internal'\);/;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			$dbh->commit;
			
			my $smtp = Net::SMTP->new('localhost') or die $!;
			my $from = 'webmaster@evinet.org';
			my $subject = 'Your Druggable batch job is scheduled';
			my $message = 'Dear Druggable user, \r\n\r\n'. 
				'the job you have submitted to Druggable is placed to the queue. You will receive a message with the link to the results once it is done \r\n\r\n'. 
				'Regards,\r\nDruggable';
			$smtp->mail( $from );
			$smtp->to( $mail );
			$smtp->data();
			$smtp->datasend("To: $mail\n");
			$smtp->datasend("From: $from\n");
			$smtp->datasend("Subject: $subject\n");
			$smtp->datasend("\n"); # done with header
			$smtp->datasend($message);
			$smtp->dataend();
			$smtp->quit();
			
			while ($job_status == "scheduled") {
				sleep($Aconfig::job_wait);
				$stat = qq/SELECT add_job($jid, $pid, \'$mail'\, $Aconfig::queue_size);/;
				$sth = $dbh->prepare($stat) or die $dbh->errstr;
				$sth->execute( ) or die $sth->errstr;
				$dbh->commit;
				$job_status = $sth->fetchrow_array;
			}
			goto START;
		}
		case "max_capacity_reached" {
			$stat = qq/SELECT report_event(\'models_from_correlations_batch.cgi'\, \'info'\, \'job_declined'\, \'placeholder'\, \'Batch job $jid has been declined: maximum queue capacity reached'\, \'internal'\);/;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			$dbh->commit;
			
			my $smtp = Net::SMTP->new('localhost') or die $!;
			my $from = 'webmaster@evinet.org';
			my $subject = 'Cannot submit Druggable job';
			my $message = 'Dear Druggable user, \r\n\r\n'. 
				'At the moment your job cannot be submitted since the job queue reached its maximum capacity. Please try to submit your job later. \r\n\r\n'. 
				'Regards,\r\nDruggable';
			$smtp->mail( $from );
			$smtp->to( $mail );
			$smtp->data();
			$smtp->datasend("To: $mail\n");
			$smtp->datasend("From: $from\n");
			$smtp->datasend("Subject: $subject\n");
			$smtp->datasend("\n"); # done with header
			$smtp->datasend($message);
			$smtp->dataend();
			$smtp->quit();
		}
		case "user_declined" {
			$stat = qq/SELECT report_event(\'models_from_correlations_batch.cgi'\, \'info'\, \'job_declined'\, \'placeholder'\, \'Batch job $jid has been declined: only one job per user allowed'\, \'internal'\);/;
			$sth = $dbh->prepare($stat) or die $dbh->errstr;
			$sth->execute( ) or die $sth->errstr;
			$dbh->commit;
			
			my $smtp = Net::SMTP->new('localhost') or die $!;
			my $from = 'webmaster@evinet.org';
			my $subject = 'Cannot submit Druggable job';
			my $message = 'Dear Druggable user, \n\n'. 
				'Your job cannot be submitted since you have already one job running. Please try to submit your job later, when the first job is donw (you will recieve a mail notification). \n\n'. 
				'Regards,\nDruggable';
			$smtp->mail( $from );
			$smtp->to( $mail );
			$smtp->data();
			$smtp->datasend("To: $mail\n");
			$smtp->datasend("From: $from\n");
			$smtp->datasend("Subject: $subject\n");
			$smtp->datasend("\n"); # done with header
			$smtp->datasend($message);
			$smtp->dataend();
			$smtp->quit();
		}
	}

	$sth->finish;
	$dbh->disconnect;
	print $batch_file;
}
else {
	print "Wrong email provided;";
}