#! /usr/bin/gawk -f

BEGIN {
coffs[0.50] = 1; 
coffs[1.64] = 1; 
coffs[2.57] = 1; 
coffs[3.09] = 1; 
coffs[4.00] = 1; 
coffs[5.00] = 1; 
coffs[6.00] = 1
FS="\t"; 
OFS = "\t"
} 

{
#if (FNR > 100000) {next}
if (FNR == 1) {
#delete re; delete nl
split(FILENAME, a, ".")
file = a[5] a[6] a[7]
if (!file) {file = "FI"}
files[file] = 1
}
if ($1 == "prd" || $1 == "pri") {
if ($23 > 0) {
for (co in coffs) {
if ($11 > co) {re[file "###" co "###" $1]++} 
if ($17 > co) {nl[file "###" co "###" $1]++} 
}
}
} }

END {

print "NET", "Z", "REAL.PRD", "NULL.PRD", "REAL.PRI", "NULL.PRI"
for (fi in files) {
for (co in coffs) {
print fi, co, re[fi "###" co "###" "prd"], nl[fi "###" co "###" "prd"], re[fi "###" co "###" "pri"], nl[fi "###" co "###" "pri"];
}
}
}
