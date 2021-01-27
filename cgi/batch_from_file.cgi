#!/usr/bin/speedy -w

# script for retrieving parameters for auto
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

srand();
$dbh = HS_SQL::dbh('druggable');

# parameters for retrieving correlations
my $source, $datatypes, $cohorts, $platforms, $screens, $ids, $fdr, $mindrug, $columns;
# model parameters
my $model_cohort, $rdatatype, $rplatform, $rid, $xdatatypes, $xplatforms, $multiopt, $family, $measure, $alpha, $nlambda, $minlambda, $validation, $validation_fraction, $nfolds, $standardize;
# batch jobs parameters
my $iter, $stat_file, $mail;

while (my $line = <$data>) {
  chomp $line;
  if ($line ne "") {
	#print $line.'\n';
	@params = split /\;/, $line;
	$source 			= $params[0];
	$datatypes 			= $params[1];
	$cohorts			= $params[2];
	$platforms 			= $params[3];
	$screens			= $params[4];
	$ids				= $params[5];
	$fdr 				= $params[6];
	$mindrug 			= $params[7];
	$columns 			= $params[8];
	$method 			= $params[9];
	$model_cohort	 	= $params[10];
	$rdatatype 			= $params[11];
	$rplatform 			= $params[12];
	$rid 				= $params[13];
	$xdatatypes 		= $params[14];
	$xplatforms 		= $params[15];
	$multiopt 			= $params[16];
	$family 			= $params[17];
	$measure			= $params[18];
	$alpha 				= $params[19];
	$nlambda 			= $params[20];
	$minlambda 			= $params[21];
	$validation 		= $params[22];
	$validation_fraction= $params[23];
	$nfolds 			= $params[24];
	$standardize 		= $params[25];
	$iter 				= $params[26];
	$stat_file 			= $params[27];
	$mail 				= $params[28];
	
	my @split_datatypes		= split /\,/, $datatypes;
	my @split_cohorts 		= split /,/, $cohorts;
	my @split_platforms		= split /,/, $platforms;
	my @split_screens		= split /,/, $screens;
	my @split_ids			= split /,/, $ids;
	
	my $datatype, $cohort, $platform, $screen, $ids, @row, @xids, @unique_xids;
	my $all_ids = "";
	
	foreach $k(0..@split_datatypes-1) {
		$datatype	= ($split_datatypes[$k]	eq "all")	? "%" : $split_datatypes[$k];
		$cohort		= ($split_cohorts[$k]	eq "all")	? "%" : $split_cohorts[$k];
		$platform	= ($split_platforms[$k]	eq "all")	? "%" : $split_platforms[$k];
		$screen 	= ($split_screens[$k]	eq "all")	? "%" : $split_screens[$k];
		$id 		= ($split_ids[$k]		eq "") 		? "%" : $split_ids[$k];
		
		# retrieve correlations
		$stat = qq/SELECT retrieve_correlations_simplified(\'$source'\, \'$datatype'\, \'$cohort'\, \'$platform'\, \'$screen'\, \'$Aconfig::sensitivity_m{$source}'\, \'$id'\, $fdr, $mindrug, \'$columns'\, \'$Aconfig::limit_column{$source}'\, $Aconfig::batch_limit_num);/;
		# print $stat;
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
		if (($k != 0) && ($k != @split_datatypes-1)) {
			$all_ids = $all_ids.",";
		}
		$all_ids = $all_ids."[".join("|", @{ $unique_xids[$k] })."]"; 
	}
	
	foreach $j(1..$iter) {
		my $r = rand();
		my $file = 'model'.$1 if $r =~  m/0\.([0-9]{12})/;
		$header = ($i == 1) ? "TRUE" : "FALSE";
		$i = $i + 1;
		system("Rscript ../R/model.".$method.".r --vanilla --args ".
					"source=$source cohort=$model_cohort rdatatype=$rdatatype rplatform=$rplatform rid=$rid ".
					"xdatatypes=$xdatatypes xplatforms=$xplatforms xids='$all_ids' multiopt='$multiopt' ".
					"family=$family measure=$measure alpha=$alpha nlambda=$nlambda minlambda=$minlambda validation=$validation " .
					"validation_fraction=$validation_fraction nfolds=$nfolds standardize=$standardize out=$file statf=$stat_file header=$header");
	}
  }
}

my $smtp = Net::SMTP->new('localhost') or die $!;
my $from = 'webmaster@evinet.org';
my $subject = 'Your Druggable batch job is done';
my $message = 'Dear Druggable user, <br>'. 
	'Your job from file has been completed <br>'. 
	'Regards,<br>Druggable';
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