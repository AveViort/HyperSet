#!/usr/bin/speedy -w
# use warnings;
#use strict vars;
use Digest::SHA qw(hmac_sha256_hex);
use CGI;
use CGI::Carp qw ( fatalsToBrowser );
$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000; 

my $query = new CGI;
my $cname = $query->param('cname');
my $cvalue = $query->param('cvalue');
my $ctimestamp = $query->param('ctimestamp');
my $cvaltime = $query->param('cvaltime');
my $csign = hsign($cname, $cvalue, $ctimestamp, $cvaltime);
print "Content-type: text/html\n\n";
print $csign;

sub hsign
{
        my ($cname, $cvalue, $ctimestamp, $cvaltime) = @_ ;
        # add some additional sequence so it will be more difficult to break hash
        $cvalue = $cvalue . "rand";
        my $hash = hmac_sha256_hex($cvalue, $cname);
        #print "Hash after hmac_sha256_hex(cvalue, cname): " . $hash . "\n";
        my $salt = "VeryRand1";
        #print "Salt for the next 5 cycles: " . $salt . "\n";
        for ($i=1; $i <= 5; $i = $i+1) {
                $hash = hmac_sha256_hex($hash, $salt);
                #print "Hash after iteration " . $i . " of hmac_sha256_hex(hash, salt): " . $hash . "\n";
        }
        #print "Salt for the next 5 cycles: " . $ctimestamp . "\n";
        for ($i=1; $i <= 5; $i = $i+1) {
                $hash = hmac_sha256_hex($hash, $ctimestamp);
                #print "Hash after iteration " . $i . " of hmac_sha256_hex(hash, ctimestamp): " . $hash . "\n";
        }
		$hash = hmac_sha256_hex($hash, $cvaltime);
        $salt = "HasChanged";
        #print "Salt for the next 5 cycles: " . $salt . "\n";
        for ($i=1; $i <= 5; $i = $i+1) {
                $hash = hmac_sha256_hex($hash, $salt);
                #print "Hash after iteration " . $i . " of hmac_sha256_hex(hash, salt): " . $hash . "\n";
        }
        $hash
}        
