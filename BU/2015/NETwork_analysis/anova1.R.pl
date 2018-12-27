#!/usr/bin/perl

#open IN, 'VDX.GSE2034.286smp.trnsp.lab.txt';
$mode = 'reverse';
$mode = 'trainandtest';
#$mode = 'mregr';
define_data();

if ($mode eq 'trainandtest') {
$fbscolumn = 'fbs_max';
$fbscolumn = 'ppi';
#$fbscolumn = 'pearson';
$FBScutoff = 6;
readSymbols('ma', 'hsa');
readLabels($table->{labels});
readLinks($table->{network}->{$spe}, 'netw');
}
runR($mode);

#tbl1 = read.table("/scratch3/andale/BREAST/VDX/VDX.GSE2034.286smp.probes" , sep = "\t", header = T, strip.white = FALSE, comment.char = "");
#set1<-data.frame(tbl1[,11954])
#for (i in c(1:length(set2[[8]]))) {if (set2[i,8] == "ER+") {er[i]<-1} else {er[i]<-0}};
#search()
sub readLabels {
my($tbl, @a) = @_;
open IN, $tbl or die "Could not open $tbl\n";
$_ = <IN>; readHeader($_, $tbl);
while (<IN>) {
chomp;
@a = split("\t", $_);
$topByProbe->{$a[$pl->{$tbl}->{id}]}->{$a[$pl->{$tbl}->{label}]} = $rank{$a[$pl->{$tbl}->{label}]};
$topByLabel->{$a[$pl->{$tbl}->{label}]}->[$rank{$a[$pl->{$tbl}->{label}]}++] = $a[$pl->{$tbl}->{id}];
} }


sub readLinks {
my($tbl, $lbl) = @_;
my($Ntotal, @a);
open IN, $tbl or die "Could not open $tbl\n";

$_ = <IN>;  readHeader($_, $tbl);
$pl->{$tbl}->{fbs} = $pl->{$tbl}->{$fbscolumn};
$Ntestlines = 500000;

while (<IN>) {
last if  $Ntotal++ > $Ntestlines;
chomp;
@a = split("\t", $_);
next if defined($FBScutoff) and defined($pl->{$tbl}->{fbs}) and ($a[$pl->{$tbl}->{fbs}] < $FBScutoff);
next if !$a[$pl->{$tbl}->{protein1}] or !$a[$pl->{$tbl}->{protein2}];
#for $idtype('gene', 'ma') {
for $idtype('ma') {
if ($idtype eq 'gene') {($p1, $p2) = (lc($a[$pl->{$tbl}->{protein1}]), lc($a[$pl->{$tbl}->{protein2}]));}
elsif ($idtype eq 'ma') {
($p1, $p2) = (
'X'.$xref->{'ma2sym_hsa'}->{'sym2id'}->{lc($a[$pl->{$tbl}->{protein1}])},
'X'.$xref->{'ma2sym_hsa'}->{'sym2id'}->{lc($a[$pl->{$tbl}->{protein2}])});
}
else {die "ID type for the network ill defined...\n";}
next if (!defined($topByProbe->{$p1}) or !defined($topByProbe->{$p1}));
$link->{$p1}->{$p2} = $a[$pl->{$tbl}->{fbs}];
$conn->{$p1}++; $conn->{$p2}++;
}}
close IN;
}

sub readSymbols {
my($id, $species) = @_;
my(@a, $n);
my $tag = $id.'2sym_'.$species;
open SYM, $table->{$tag} or die("No $tag xref table...\n");
while (<SYM>) {
chomp; @a = split("\t", $_);
next if !$a[$pl->{$tag}->{'id'}] or !$a[$pl->{$tag}->{'sym'}];
$n++;
$xref->{$tag}->{'sym2id'}->{lc($a[$pl->{$tag}->{'sym'}])} = lc($a[$pl->{$tag}->{'id'}]);
$xref->{$tag}->{'id2sym'}->{lc($a[$pl->{$tag}->{'id'}])} = lc($a[$pl->{$tag}->{'sym'}]);
}
close SYM; 
print scalar(keys(%{$xref->{$tag}->{'sym2id'}})).' gene symbols, '.scalar(keys(%{$xref->{$tag}->{'id2sym'}})).' IDs, '."$n ID-symbol pairs in\n$table->{$tag}...\n\n";
return undef;
}

sub readHeader ($$) {
    my($head, $tbl) = @_;
my(@arr, $aa, $smp);
chomp($head);
@arr = split("\t", $head);
for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/^LLR_//i;
$arr[$aa] = lc($arr[$aa]);
$pl->{$tbl}->{$arr[$aa]} = $aa;
$nm->{$tbl}->{$aa} = $arr[$aa];
if ($arr[$aa] =~ m/(TCGA\-.+?\-.+?\-.+?)\-/i) {
$samples{$1} = 1 ;
$pl->{$tbl}->{$1} = $aa;
$nm->{$tbl}->{$aa} = $1;

}}
return undef;
}

sub define_data {
#our();

$spe = 'hsa';
$table->{network}->{'hsa'} = '/afs/pdc.kth.se/home/a/andale/m14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new';
$table->{'ma2sym_hsa'} = '/afs/pdc.kth.se/home/a/andale/Name_2_name/ENSG_2_gnf1b_andU133.human.txt';
$pl->{'ma2sym_hsa'}->{'id'} = 0; $pl->{'ma2sym_hsa'}->{'sym'} = 1;
$table->{labels} = '/afs/pdc.kth.se/home/a/andale/R/DE.Top1000.3options';

}

sub runR {
my($mode) = @_;
#my($R_path, $tempdata, $tempnode, $i);
#system("module add R");
$R_path = '/afs/pdc.kth.se/home/a/andale/mou1/software/R/2.2.0/install/amd64_fc3/bin/';
$R_path = '';
open(R,  ' | '.$R_path."R --save -q");
#open(R,  ' | '.$R_path."R --vanilla -q");
print R 'library(ROC) ;'."\n";
print R 'options(digits = 3);'."\n";
#print R 'tbl1 = read.table("VDX.GSE2034.286smp.trnsp.lab.txt" , sep = "\t", header = T, strip.white = FALSE, comment.char = "");'."\n";
#print R 'set2<-data.frame(tbl1);'."\n";
#print R ';'."\n";
#print R ';'."\n";
$row_start = '9';
$row_end = $#cols - $row_start;
print R '"aaaa";'."\n";

@top20 = (547, 2542, 4977, 7810, 8898, 9127, 10365, 10975, 12263, 12523, 12884, 14179, 14301, 18518, 19002, 20180, 20641, 21746, 21800, 22141);
$er = 'set2[,8]';
$relapse = 'set2[,5]';
$status = 'ALL';
$status = 'ER-';
#$status = 'ER+';
$set{'ALL'} = 'set2';
$set{'ER-'} = 'setminus';
$set{'ER+'} = 'setplus';

if ($mode eq 'trainandtest') {
$top = 990;  $nterms = 35;  $ntrials = 30;
$nCVtests = 10;
$train_size{'ALL'} = 215;
$train_size{'ER-'} = 50;
$train_size{'ER+'} = 170;

$outdata = join('.', ('AUCs', $set{$status}, $$, $nterms, $fbscolumn.'_'.$FBScutoff, 'R', 'out'));

for $testmode('netw', 'free') {
for (1..$ntrials) {
undef @lmTerms; undef %already;
if ($testmode eq 'free') {
for (1..$nterms) {
$term = $topByLabel->{$status}->[rand($top)];
push @lmTerms, $set{$status}.'$'.$term;
}}
elsif (1 ==2 and $testmode eq 'netw') {
while (scalar(@lmTerms) < $nterms) {
  $tt = rand($top);
$term = $topByLabel->{$status}->[$tt];
next if !defined($conn->{$term});
if (scalar(@lmTerms) > 3) {
undef $neighbors;
while (!$neighbors) {
for $previous(@lmTerms) {
if ((defined($link->{$previous}) and defined($link->{$previous}->{$term})) or (defined($link->{$term}) and defined($link->{$term}->{$previous}))) {
$neighbors = 1;
#$last;
}}}}
push @lmTerms, $term if !$already{$term};
$already{$term} = 1;
}
for $term(@lmTerms) {$term = $set{$status}.'$'.$term; }
}
elsif (1 == 1 and $testmode eq 'netw') {
while (scalar(@lmTerms) < $nterms) {
if ((scalar(@lmTerms) < 3) || ($tested > 10)) {
  $tt = rand($top);
$term = $topByLabel->{$status}->[$tt];
next if !defined($conn->{$term});
}
else {
$previous = $lmTerms[rand($#lmTerms)];
@neis = keys(%{$link->{$previous}}) ;
$term = $neis[rand($#neis)];
$tested++;
}
if ($term and !$already{$term} and defined($topByProbe->{$term})) {
push @lmTerms, $term;
$already{$term} = 1;
$tested = 0;
}}
for $term(@lmTerms) {$term = $set{$status}.'$'.$term; }
}

++$ID;
for $test(1..$nCVtests) {
print R 'smp_train = sample(1:length('.$set{$status}.'[,"ER"]), '.$train_size{$status}.');'."\n";
#print R 'smp_test = c(1:286)[-smp_train];'."\n";
#$cond =  (($status =~ /ER/) ? 'which('.$set{$status}.'$ER=="'.$status.'"' : '');
#print R 'smp_train = sample('.$cond.$train_size{$status}.');'."\n";
#print R 'smp_test = c(1:286)[-smp_train];'."\n";
#smp_train<-sample(1:length(setminus[,"ER"]), 10)
print R 'stp<-step(lm('.$set{$status}.'$RELAPSE~'.join('+', @lmTerms).', data='.$set{$status}.'[smp_train]));'."\n";

print R 'aucp<-AUC(rocdemo.sca('.$set{$status}.'$RELAPSE[-smp_train],  predict(stp)[-smp_train]));'."\n";

print R ' write.table(paste("'.$ID.'", "\t", "'.$testmode.'", "\t", aucp, "\t", gsub("[[:space:]]", "", summary(stp)$call)), file = "'.$outdata.'.'.$mode.'", append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "", eol = "\n", na = "", dec = ".");'."\n";
}}}}
#print R 'testp<-as.logical(set2$RELAPSE == 1 & set2$ER == "ER-");'."\n";
#smp_train<-sort(sample(286, 100))
#print R 'outp<-AUC(rocdemo.sca(set2$RELAPSE[1:286], predict(step(lm(set2$RELAPSE~'.join('+', @lmTerms).')))));'."\n";
#print R ';'."\n";
#print R ';'."\n";
#AUC(rocdemo.sca(set2$RELAPSE[1:286], predict(step(lm(set2[, 5]~set2$X200848_at+set2$X201008_s_at+set2$X201009_s_at)))))
else {
@list = ($row_start..22290);
@list = @top20;
$outdata = join('.', ('pValuesFull', $status, $$, 'ANOVA.R', 'out'));
for $gg (@list) {
#print R 'fit=lm(er~set2[,'.$gg.']);'."\n";
#print R 'fit=lm('.$relapse.'~set2[,'.$gg.']*'.$er.');'."\n";
if ($mode eq 'reverse') {
#print R 'fit=lm(set2[,'.$gg.']~'.$relapse.'*'.$er.');'."\n";
#print R 'outp<-anova(lm(set2[,'.$gg.']~'.$relapse.',  subset=(set2$ER == "'.$status.'")));'."\n";
print R 'outp<-anova(lm(set2[,'.$gg.']~'.$relapse.'));'."\n";
}
elsif ($mode eq 'mregr') {
#print R 'fit=lm('.$relapse.'~set2[,'.$gg.']*'.$er.', model = TRUE, x = TRUE, y = TRUE, qr = TRUE);'."\n";
print R 'outp<-anova(lm('.$relapse.'~set2[,'.$gg.']*'.$er.', model = TRUE, x = FALSE, y = FALSE, qr = TRUE));'."\n";
}
#print R 'outp<-anova(fit);'."\n";
print R ' write.table(c(colnames(set2[1,]['.$gg.']), outp), file = "'.$outdata.'.'.$mode.'", append = TRUE, col.names = FALSE, quote = FALSE, sep = "\t", eol = "\n", na = "", dec = ".");'."\n";
}}
#lda(set2[, 5]~set2$X202324_s_at*set2$X209835_x_at, subset=sample(1:287, 150))
#AUC(rocdemo.sca(c(1,1,1,0,0,0), c(11,10,9,8,9), rule = NULL))


#print R ';'."\n";
#print R ';'."\n";
#print R 'means1<-formatC(mean(set1, na.rm=TRUE), format = "f", mode = "double", digits = 2);'."\n";
#print R 'means1<-mean(set1, na.rm=TRUE);'."\n";
#print R 'for (i in c(1:length(means1))) {set1[i]<-apply(set1[i], 2, function(x)ifelse(is.na(x), ifelse(is.na(means1[i]), 0, means1[i]), x))}'."\n";
#print R 'rem<-NULL;'."\n";
#print R 'for (i in c(1:length(means1))) {if (is.na(var(set1[i]))|var(set1[i]) == 0) rem<-c(rem,i)};'."\n";
#print R 'for (i in c(1:length(means1))) {if (is.na(var(set1[i]))|var(set1[i]) == 0) rm(set1[i])}'."\n";
#print R 'if (is.null(rem)) rem<-c(1:length(means1));'."\n";
#print R 'if (is.null(rem)) rem<-'' else {};'."\n";
#print R 'unlink("'.$tempdata.'");'."\n";
#print R 'if (is.null(rem)) pca1<-princomp(set1, scores=TRUE, cor = TRUE, covmat=NULL, na.action=na.omit) else pca1<-princomp(set1[-rem], scores=TRUE, cor = TRUE, covmat=NULL, na.action=na.omit);'."\n";
#print R 'if (is.null(rem)) pca1<-princomp(set1, scores=TRUE, cor = FALSE, covmat=NULL, na.action=na.omit) else pca1<-princomp(set1[-rem], scores=TRUE, cor = FALSE, covmat=NULL, na.action=na.omit);'."\n";
#print R 'rm(set1)'."\n";
#print R 'set3<-apply(data.frame(tbl1[1:length(grep("class|group", names(tbl1)))], formatC(pca1$scores, format = "f", mode = "double", digits = '.$main::PCA_precision.')), 2, function(x)gsub(" ", "", x));'."\n";
#print R 'colnames(set3)<-gsub('."'".'\\\.'."'".', "_", colnames(set3));'."\n";
#print R 'write.table(set3, file = "'.$tempdata.'", append = FALSE, quote = FALSE, sep = "\t", eol = "\n", na = "", dec = ".", col.names = colnames(set3), row.names = FALSE, qmethod = "e");'."\n";
#print R 'write(paste("Parent", "Child", sep = "\t"), file = "'.$tempnode.'", append = FALSE, ncolumns = 1);'."\n";
#print R 'for (i in colnames(set3)[grep("class",colnames(set3))]) {for (j in colnames(set3)[c(-grep("class",colnames(set3)), -grep("group",colnames(set3)))]) '."\n".' write(paste(i, j, sep = "\t"), file = "'.$tempnode.'", append = TRUE, ncolumns = 1);}'."\n";
close R;
return($tempdata, $tempnode);
}
#gawk 'BEGIN {FS="\t"; OFS="\t"} {if (FNR == 1) {split(FILENAME, n, ".")} if ($0 ~ "RELAPS") {gsub(/set2/, "", $4); gsub(/setminus/, "", $4); gsub(/RELAPSE\~/, "", $4); gsub(/setplus/, "", $4);  gsub(/\$/, "", $4); gsub(/X/, " ", $4);  gsub(/\+/, "", $4); print $1, $2, n[2], n[4], n[5], $3, $4}}' AUC* | 


#gawk 'BEGIN {FS="\t"; OFS="\t"} {if (FNR == 1) {split(FILENAME, n, ".")} if ($0 ~ "RELAPS") {gsub(/set2/, "", $4); gsub(/setminus/, "", $4); gsub(/RELAPSE\~/, "", $4); gsub(/setplus/, "", $4);  gsub(/\$/, "", $4); gsub(/X/, " ", $4);  gsub(/\+/, "", $4); gsub(/fbs_max_3/, "fbs_m", n[5]); gsub(/fbs_max_4/, "fbs_m", n[5]); print $1, $2, n[2], n[4], n[5], $2 "_" FILENAME "_" $1, $3, $4}}' AUCs.se* | gawk 'BEGIN {FS="\t"; OFS="\t"} {if ($4 ~ "20") {$4 = "small"} else {$4 = "large"} print}' 
