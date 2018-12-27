#! /usr/bin/gawk -f

BEGIN {
srand("fgsdffg"); 
FS="\t"; 
OFS="\t"
} 

{
if (FNR==1) {
split(FILENAME,a, "."); 
la = a[4] a[5]; 
sub("coNA", "", la);
sub("BOTH", "", la);  
} 

if ($1 == "prd" && ($23 || (rand() < ($3 * 30) / 15000))) {
line = la; 
for (i=1; i<=8; i++) {
line = line "\t" $i
} 
line = line "\t" $11;
line = line "\t" $23; 
# line = line "\t" $19; 
# line = line "\t" $21; 
# line = line "\t" $22; 
print line
} 
}
