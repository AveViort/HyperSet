#! /usr/bin/gawk -f

BEGIN {
FS="\t"; 
OFS="\t"; 
nl[1] = 2;
nl[2] = 4;
nl[3] = 9;

co[1] = 0
co[2] = 2.57
co[3] = 3.09
co[4] = 4
co[5] = 6
z_col = 8
nl_col = 5
link_col = 1;
link = "prd"
#grp = "top_400"
grp = ""
grp_col = 4
}

{
if (FNR == 1) {
	line = FILENAME "\t" grp;
	header = "TEST\tGROUP" ;
}
if ($link_col != link) {next}
if (grp && $grp_col !~ grp) {next}

for (i in nl) {
for (j in co) {

	if ($nl_col > nl[i])  {
		if ($z_col < -co[j]) {
lo[nl[i] co[j]] = lo[nl[i] co[j]] + 1;
		}
		if ($z_col > co[j]) {
hi[nl[i] co[j]] = hi[nl[i] co[j]] + 1;
		}
}}}}

END {
for (i=1; i<4; i++) {
for (j=1; j<5; j++) {
header = header "\t" nl[i] "_" co[j] "_high" "\t" nl[i] "_" co[j] "_FDR"
if (!lo[nl[i] co[j]]) {ratio = 1.000}
else {
	FDR = lo[nl[i] co[j]] / hi[nl[i] co[j]]
	}
line = line "\t" hi[nl[i] co[j]] "\t" FDR

}}
#print header;
print line;

}