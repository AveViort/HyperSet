#!/usr/bin/speedy -w

# running batch jobs from script file 
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use HS_SQL;
use Aconfig;
use Net::SMTP;

our ($dbh, $stat, $sth);

my $query = new CGI;
my $script = $query->param("script");

print "Content-type: text/html\n\n";
open(my $data, '<', $script) or die "Could not open '$script' $!\n";

my @params;
my $header = 'true';
my $i = 1;
my $j, $k;
my $script_line = 0;

srand();
$dbh = HS_SQL::dbh('druggable');

# parameters for retrieving correlations
my $source, $datatypes, $cohorts, $platforms, $screens, $ids, $fdrs, $mindrug, $columns;
# model parameters
my $model_cohort, $rdatatype, $rplatform, $rid, $xdatatypes, $xplatforms, $additional_xids, $multiopt, $family, $measure, $alpha, $nlambda, $minlambda, $validation, $validation_fraction, $nfolds, $standardize;
# batch jobs parameters
my $iter, $stat_file, $mail;

while (my $line = <$data>) {
  chomp $line;
  $script_line += 1;
  if ($line ne "") {
	#print $line.'\n';
	@params = split /\;/, $line;
	$source 			= $params[0];
	$datatypes 			= $params[1];
	$cohorts			= $params[2];
	$platforms 			= $params[3];
	$screens			= $params[4];
	$ids				= $params[5];
	$fdrs 				= $params[6];
	$mindrug 			= $params[7];
	$columns 			= $params[8];
	$method 			= $params[9];
	$model_cohort	 	= $params[10];
	$rdatatype 			= $params[11];
	$rplatform 			= $params[12];
	$rid 				= $params[13];
	$xdatatypes 		= $params[14];
	$xplatforms 		= $params[15];
	$additional_xids 	= $params[16];
	$multiopt 			= $params[17];
	$family 			= $params[18];
	$measure			= $params[19];
	$alpha 				= $params[20];
	$nlambda 			= $params[21];
	$minlambda 			= $params[22];
	$validation 		= $params[23];
	$validation_fraction= $params[24];
	$nfolds 			= $params[25];
	$standardize 		= $params[26];
	$iter 				= $params[27];
	$stat_file 			= $params[28];
	$mail 				= $params[29];
	
	my @split_datatypes			= split /\,/, $datatypes;
	my @split_cohorts 			= split /\,/, $cohorts;
	my @split_platforms			= split /\,/, $platforms;
	my @split_screens			= split /\,/, $screens;
	my @split_ids				= split /\,/, $ids;
	my @split_fdrs				= split /\,/, $fdrs;
	my @split_additional_xids 	= split /\,/, $additional_xids;
	
	my $datatype, $cohort, $platform, $screen, $ids, $fdr, @row, @xids, @unique_xids;
	my $all_ids = "";
	
	open(FH, '>', '/var/www/html/research/users_tmp/batch_debug.txt');
	
	foreach $k(0..@split_datatypes-1) {
		$datatype	= ($split_datatypes[$k]	eq "all")	? "%" : $split_datatypes[$k];
		$cohort		= ($split_cohorts[$k]	eq "all")	? "%" : $split_cohorts[$k];
		$platform	= ($split_platforms[$k]	eq "all")	? "%" : $split_platforms[$k];
		$screen 	= ($split_screens[$k]	eq "all")	? "%" : $split_screens[$k];
		$id 		= ($split_ids[$k]		eq "") 		? "%" : $split_ids[$k];
		$fdr 		= ($split_fdrs[$k]		eq "") 		? "0.05" : $split_fdrs[$k];
		
		@{ $xids[$k] } = ();
		@{ $unique_xids[$k] } = ();
		
		# retrieve correlations
		$stat = qq/SELECT retrieve_correlations_simplified(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\, \'$id'\, $fdr, $mindrug, \'$columns'\, \'$Aconfig::limit_column{$source}'\, $Aconfig::batch_limit_num);/;
		# write to debug file
		print FH $stat."\n";
		$sth = $dbh->prepare($stat) or die $dbh->errstr;
		$sth->execute( ) or die $sth->errstr;

		while (@row = $sth->fetchrow_array()) {
			# print @row."<br>";
			if ($row[0] ne '') {
				my @field_values = split /\|/, $row[0];
				push @{ $xids[$k] }, $field_values[0];
			}
		}
		@{ $unique_xids[$k] } = keys { map { $_ => 1 } @{ $xids[$k] } };
		# refer to build_model function in drugs.js for understanding $all_ids format 
		if ($k != 0) {
			$all_ids = $all_ids.",";
		}
		$all_ids = $all_ids."[".join("|", @{ $unique_xids[$k] });
		if (($additional_xids ne '') && (@split_additional_xids[$k] ne '')) {
			$all_ids = $all_ids."|".@split_additional_xids[$k];
		}
		$all_ids = $all_ids."]";
		print FH $all_ids."\n";
	}
	
	foreach $j(1..$iter) {
		my $r = rand();
		my $file = 'model'.$1 if $r =~  m/0\.([0-9]{12})/;
		$header = ($i == 1) ? "TRUE" : "FALSE";
		$i = $i + 1;
		# note that extended_output is always active for this type of batch jobs
		system("Rscript ../R/model.".$method.".r --vanilla --args ".
					"source=$source cohort=$model_cohort rdatatype=$rdatatype rplatform=$rplatform rid=$rid ".
					"xdatatypes=$xdatatypes xplatforms=$xplatforms xids='$all_ids' multiopt='$multiopt' ".
					"family=$family measure=$measure alpha=$alpha nlambda=$nlambda minlambda=$minlambda validation=$validation " .
					"validation_fraction=$validation_fraction nfolds=$nfolds standardize=$standardize out=$file statf=$stat_file ".
					"header=$header extended_output=TRUE script_line=$script_line");
	}
  }
}

close FH;

my $smtp = Net::SMTP->new('localhost') or die $!;
my $from = 'webmaster@evinet.org';
my $subject = 'Your Druggable batch job is done';
my $message = "Dear Druggable user, \r\n". 
	"Your job from file has been completed \r\n". 
	"Regards,\r\nDruggable";
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

print 'done';

$sth->finish;
$dbh->disconnect;