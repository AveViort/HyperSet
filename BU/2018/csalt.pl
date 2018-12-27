use Digest::SHA qw(hmac_sha256_hex);
use CGI;

# exprected parameters: cname, cvalue, ctimestamp
#my $csign = hsign("username", "ikpetrov", 1495531615204);
#print $csign . "\n";
#my $csign2 = hsign("username", "ikpetrov", 1495531615204);
#my $csign3 = hsign("username", "ikpetrov", 1495531615204);
#my $cond1 = ($csign == $csign2);
#my $cond2 = ($csign == $csign3);
#print "Condition 1: " . $cond1 ." Condition2: ". $cond2 . "\n";

my $cgi = new CGI;
my $cname = $query->param('cname');
#my $cvalue = $query->param('cvalue');
#my $ctimestamp = $query->param('ctimestamp');
my $csign = hsign($cname, 1, 1);
print $csign;

sub hsign
{
        my ($cname, $cvalue, $ctimestamp) = @_ ;
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
        $salt = "HasChanged";
        #print "Salt for the next 5 cycles: " . $salt . "\n";
        for ($i=1; $i <= 5; $i = $i+1) {
                $hash = hmac_sha256_hex($hash, $salt);
                #print "Hash after iteration " . $i . " of hmac_sha256_hex(hash, salt): " . $hash . "\n";
        }
        $hash
}        
