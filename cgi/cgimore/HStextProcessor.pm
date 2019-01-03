package HStextProcessor;
  
#use DBI;
use CGI qw(:standard);
use File::Basename;
#use CGI::Carp qw(fatalsToBrowser);
use strict;
BEGIN {
	require Exporter;
	use Exporter;
	require 5.002;
	our($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = 1.00;
	@ISA = 			qw(Exporter);
	#@EXPORT = 		qw();
	%EXPORT_TAGS = 	();
	@EXPORT_OK	 =	qw();
}
our $safe_filename_characters = "a-zA-Z0-9_.-";

our(%purgeTitle, %postfix, %filterList, $subnet_url);
%postfix = (
'padj' => 'fdr',
'fcdn' => lc('fpkm_Log2FC'),
'fcup' => lc('fpkm_Log2FC'),
'fdr'  => lc('Padj')
);
%filterList = (
'fdr'  => 'lt', 
'fcdn' => 'lt', 
'fcup' => 'gt'
);
$purgeTitle{'vs_'} = 1;

sub JavascriptCompatibleID {
my ($str) = @_; 
$str =~ s/[\.\;\:\\\/\,]/\-/g;
$str =~ s/[\"\'\*\@]//g;
return($str);
}

sub checkUploadedFile {
my($fl_name) = @_;
print STDERR "****UPLOADING: $fl_name\n";
 my $line_num = 1;
 my $err_status = 0;
 my $err_message = 0;
 my ($header, @head_val);
 my $pat = $HSconfig::vennFieldTypeMask;
 # if ($fl_name !~ m/\.VENN|\.groups|\.net/i) {
  # $err_status = 1;
  # $err_message = "The selected file does not satisfy our requirements <br>neither for pre-compiled AGS collections <br>not for differential expression (Venn mode) files<br>Examples: <br><b>P.matrix.NoModNodiff_wESC.VENN.txt, example.groups</b>";
# } els
if ($fl_name =~ m/.VENN/i) {
 open(my $fl, $fl_name);
 $header = <$fl>;
 @head_val = split(/\t/, $header); 
#my $pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-[FC|FDR|p]";
 if (! grep(/$pat/i, $header) ) {
  $err_status = 1;
  $err_message = "File doesnot contain the DE columns<br>Please ensure that the first line in the file should contain the pattern $pat<br><br>Example: A_vs_B-FC, A_vs_B-p, A_vs_B-FDR";
} else {
my $mask = '([A-Za-z0-9_\_\(\)\.]+vs[A-Za-z0-9\_\(\)\.]+)';
 my $p_pat = "$mask-P";
 my $fc_pat = "$mask-FC";
 my $fdr_pat = "$mask-FDR";
 # my $p_pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-P";
 # my $fc_pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-FC";
 # my $fdr_pat = "([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-FDR";
 my @checked_pair; my $ln;
 my @matches_p = $ln =~ m/$p_pat/gi;
 my @matches_fc = $ln =~ m/$fc_pat/gi;
 my @matches_fdr = $ln =~ m/$fdr_pat/gi;
 my @matches_all = (@matches_p, @matches_fc, @matches_fdr);

 for my $m(@matches_all){
     if ( grep(/$m/, @checked_pair) ){next;}
     my @missing_cat;
     if ( ! grep(/$m/, @matches_p) ) {$err_status = 1; push(@missing_cat, "P-val");}
     if ( ! grep(/$m/, @matches_fc) ) {$err_status = 1; push(@missing_cat, "FC-val");}
     if ( ! grep(/$m/, @matches_fdr) ) {$err_status = 1; push(@missing_cat, "FDR-val");}
     if ($err_status){
         $err_message = "Contrasts ".$m." is missing ".join(",", @missing_cat) ."<br>Requires all three columns for each contrast. <br> Example: (A_vs_B-P,A_vs_B-FC,A_vs_B-FDR). <br> Please modify accordingly and submit the file again.";
     }
     push(@checked_pair, $m);
 }}
 if(!$err_status) {
 my %duplicates;
 my @gene_ind = grep { $head_val[$_] =~ /gene/i } 0..$#head_val;
 while (my $fln = <$fl>) {
     $line_num++;
     my @col_val = split(/\t/, $fln);
     my $thegene = $col_val[$gene_ind[0]];
     if ($fln =~ m/\t\s*\t/){
         $err_status = 1;
         $err_message = "Line ".$line_num." contains missing columns.";
    } elsif ($thegene =~ m/[A-Z0-9_\.][\s\&\@][A-Z0-9_\.]/i) {
         $err_status = 1;
         $err_message = "Wrong gene symbol format in AGS file, Invalid ID:<br> ".$thegene." submitted at line ".$line_num." in <br>".$fl_name." contains an invalid gene name"
    } elsif (defined ($duplicates{$fln}) ) {
	$err_status = 1;
	$err_message = "File contains duplicate lines. Check line:".$line_num."<br>Please make sure duplicate lines does not exist in the file";	
     }
 $duplicates{$fln}++;
 }
 if ($line_num < 10) {
	my $n_genes = $line_num -1;
 	$err_status = 1;
        $err_message = "Low number of genes <br> File contains ".$n_genes." genes, required file with more than 10 genes";
     }
 close $fl;
 }
 }
 
 if ($err_status) {
   main::deleteFiles('', $fl_name);
 }
 else {
 my @hd_contrasts = ();
 foreach my $hd_val(@head_val){
  # if ($hd_val =~ /^([A-Za-z0-9_]+vs[A-Za-z0-9_]+)-[FC|FDR|p]$/){	
 my $mask = '([A-Za-z0-9_\_\(\)\.]+vs[A-Za-z0-9\_\(\)\.]+)';
 #my $template = $mask.'-FC|-FDR|-p';
   if ($hd_val =~ m/^($mask)('-FC|-FDR|-p')$/gi) {
   #if ($hd_val =~ m/^($template)/gi) {  
	push (@hd_contrasts, $1);
  	}	
 }
 
my $file_stat = "Number of rows: $line_num\nNumber of columns: $#head_val\n<br>The  ".scalar @hd_contrasts." sample contrasts provided in the header which contains -FC,-p, -FDR extensions are :\n<br>".join("\n", map { " - ".$_ } @hd_contrasts)."\n"; 
 # my($name, $path, $extension ) = fileparse ($fl_name, '\..*');
 # my $op_nm = $name.$HSconfig::file_stat_ext;
 # $op_nm =~ tr/ /_/;
 # $op_nm =~ s/[^$HStextProcessor::safe_filename_characters]//g;
 # open (my $ifl, "> $main::usersDir/$op_nm");
 open (my $ifl, "> $fl_name$HSconfig::file_stat_ext");
 print $ifl $file_stat;
 close $ifl;
 } 
return($err_status, $err_message);
}


sub parseGenes {
my ( $genestring, $delimiter) = @_;
my ( $gg, $genes);
if ((1 == 2) and $delimiter ne ' ') {
	$genestring =~ s/^\s+//        if $genestring;
	$genestring =~ s/[\'\"\,\;]/ /g if $genestring;
}
else {
	$genestring =~ s/^\s+//        if $genestring;
	$genestring =~ s/[\'\"\,\;]/ /g if $genestring;
	$genestring =~ s/\s+/ /g        if $genestring;
	}
@{$genes} = split( $delimiter, uc($genestring) );
# print $genestring.'<br>';
if ( $#{$genes} >= 0 ) {
while ( !$genes->[0] ) { shift @{$genes}; }	
while ( !$genes->[$#{$genes}] ) { pop @{$genes}; }	
}
# print join('#', @{$genes}).'<br>';
my $i = 0;
for $gg (@{$genes}) {
	$gg =~ s/\s//g;
	if ($gg !~ m/^[A-Za-z0-9\:\_\-\.]+$/ ) {
	return 'invalid input'; 
}}
return($genes);
}

sub compileGS { 
my($type, #AGS or FGS
$jid, $GSfile, $GSselected, $gene_column_id, $group_column_id, $Genewise, $species, $debug) = @_;
 print STDERR 'PARAMETERS TO HStextProcessor::compileGS: '.join(', ', @_)."\n" if $debug;
if ((uc($Genewise) ne 'FALSE') and (uc($Genewise) ne 'TRUE')) {die 'Wrong parameter order or value...';}
my($op, @ar, $tmp, %selected, $line, $group, $gene, $genes, $groups, $gene_list, $hsgene, $fcgenes, $takeIt,
$venn, @a1, @a2);

$tmp = main::tmpFileName(uc($type), $jid);
open OUT, '> '.$tmp or die "Could not create temporary ".$type." file ...\n";
print STDERR "Open ".$tmp."\n" if $debug;
my $i = 0; 
print STDERR $GSfile."\n" if $debug;
print STDERR join(' ', @{$GSselected})."\n" if $debug;	
if ($GSfile eq '#venn_lists') {
for $venn(@{$GSselected}) {
@a1 = split(':', $venn);
$op = $a1[0];
@a2 = split(';', $a1[1]);
for $gene(@a2) {
$i++;
$group = (uc($Genewise) eq 'TRUE') ? $gene : $op;
# print OUT join("\t", ($gene, $gene, $group))."\n";
$genes->{$gene} = $group; 
$groups->{$group}->{$gene} = $gene; 
}
}
} else {
for $op(@{$GSselected}) {
if  ($GSfile =~ m/\#cpw_list|\#sgs_list/) {
$op =~ s/\s//g;
$group = (uc($Genewise) eq 'TRUE') ? $op : $HSconfig::users_single_group.'_'.uc($type);
$genes->{$op} = $group; 
$groups->{$group}->{$op} = $op; 
# print OUT join("\t", ($op, $op, $group))."\n" ;  $i++;# print selected genes directly to the gsFile
} else {
# print '<br>Selected '.$type.' member: '.uc($op).'<br>' if $debug;
$selected{uc($op)} = 1;
}}
# print '<br>AGS file: '.$GSfile.'<br>'  if ($GSfile ne '#sgs_list');
if ($GSfile !~ m/\#cpw_list|\#sgs_list/) {
# local($/) = "\r" if $main::q->param("useCR");  
open IN, $GSfile or die "Could not re-open '.$type.' file $GSfile ...\n"; #otherwise, 
print STDERR "Open ".$GSfile if $debug;
while ($line = <IN>) {
# next if !defined($line);
$takeIt = 0;
$line = HStextProcessor::JavascriptCompatibleID($line);
chomp($line);
@ar = split("\t", $line);
$gene = $ar[$gene_column_id];   
$gene =~ s/\s//g;

if ($group_column_id < 0) {
$group = (uc($Genewise) eq 'FALSE') ? $HSconfig::users_single_group.'_'.uc($type) : $gene;
$takeIt = 1;
} else {
$group = $ar[$group_column_id];
$group =~ s/\s//g;
$takeIt = 1 if $selected{uc($group)};
$group = (uc($Genewise) eq 'FALSE') ? $group : $gene;
}
# print 'Gene '.$gene.'<br>'."\n"  ;
next if !$takeIt;
$genes->{$gene} = $group;
$groups->{$group}->{$gene}  = $gene;
# print OUT join("\t", ($gene, $gene, $group))."\n";$i++; 
}}
close IN;
}
print STDERR "Close ".$GSfile if $debug;
@{$gene_list} = keys(%{$genes});
$fcgenes = HS_SQL::gene_synonyms($gene_list, $species, 'ags');
$i = 0; 
for $group(keys(%{$groups})) {
for $gene(keys(%{$groups->{$group}})) {
for $hsgene(keys(%{$HS_SQL::translated_genes->{$species}->{uc($gene)}})) {
$i++; 
print OUT join("\t", ($hsgene, $hsgene, $group))."\n";
}}}
close OUT;
print STDERR "Close ".$tmp if $debug;

return('empty') if !$i;
return($tmp);
}

###########################################################


sub subnet_urls {
my($neaData, $pl, $table, $species, $networks) = @_;

my(@arr, $AGS, $FGS, $genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $or, $Nl, $i, $subnet_url);
my $sn = 0;
for $i(0..$#{$neaData}) { 
@arr = split("\t", uc($neaData->[$i]->{wholeLine}));
# $genesAGS = $arr[$pl->{$table}->{ags_genes2}]; 
# $genesFGS = $arr[$pl->{$table}->{fgs_genes2}]; 
$genesAGS2 = join($HS_html_gen::arrayURLdelimiter, split(/\s+/, $arr[$pl->{$table}->{ags_genes1}]));
$genesFGS2 = join($HS_html_gen::arrayURLdelimiter, split(/\s+/, $arr[$pl->{$table}->{fgs_genes1}]));
$genesAGS2 =~ s/\,//g; 
$genesFGS2 =~ s/\,//g; 
$or = 0;
if ($or) {
$Nl = $arr[$pl->{$table}->{n_genes_ags}] * 2;
$Nl = 100 if ($Nl > 100) or ($Nl < 10);
}
else {
$Nl =  1000;
}
$AGS = $arr[$pl->{$table}->{ags}];
$FGS = $arr[$pl->{$table}->{fgs}];
 # print $AGS.' '.$FGS.'<br>';
$subnet_url->{$AGS}->{$FGS} = $HS_html_gen::webLinkPage_AGS2FGS_HS_link. 
'coff='.$HSconfig::fbsCutoff->{ags_fgs}.
';ags_fgs=yes'.
';species='.$species.
';context_genes='.$genesFGS2.
';genes='.$genesAGS2.
';order='.$or.
';networks='.join($HS_html_gen::arrayURLdelimiter, split($HS_html_gen::fieldURLdelimiter, $networks)).
';action=subnet-'.++$sn.
';no_of_links='.$Nl.';';  
}
return($subnet_url);
}

sub title2values {
my($title, $postfix) = @_;

if ($title =~ m/(X[0-9].+)\_(X[0-9].+)\_$postfix/i) {
return($1, $2);
}
else {
return undef;
}}



sub id2title {
my($id, $postfix) = @_;
my( $pp);
my $TITLE_DELIMITER = '_';
my $title = join($TITLE_DELIMITER, ($id, $postfix));
for $pp(keys(%purgeTitle)) {
$title =~ s/$pp//;
}
return($title);
}

sub readHeader ($$$) {
my($head, $tbl, $delimiter) = @_;
my(@arr, $aa);
#open IN, $tbl or die "$!";
#$head = <IN>;
#close IN;
chomp($head);
# $head =~ s/\s*$\"\'\*\@//;
$head = HStextProcessor::JavascriptCompatibleID($head);
@arr = split($delimiter, $head);
for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/\./\_/gi;
$arr[$aa] =~  s/\s/\_/g;
$arr[$aa] = lc($arr[$aa]);
$main::pl->{$tbl}->{$arr[$aa]} = $aa;
$main::nm->{$tbl}->{$aa} = $arr[$aa];
# $main::pl->{$tbl}->{'gene'} = $aa if ($arr[$aa] =~ m/$HSconfig::geneColumnMask/i);
}

return undef;
}

sub replaceForbiddenCharacters {
my($hd) = @_;
$hd =~ s/[\(\)\:\;\,\.]/_/g;
$hd =~ s/ /_/g;
return $hd;
}

sub vennHeader {
my($file4venn, $delimiter, $useCR, $min_size, $max_size) = @_;
my($fld, $contrasts, $cntr1, $cntr2, $stat);
local($/) = "\r" if $useCR; 
open GS,  $file4venn or die "Cannot open file $file4venn\n";
#http://perldoc.perl.org/perlport.html#Newlines
$_ = <GS>; readHeader(replaceForbiddenCharacters($_), $file4venn, $delimiter); close GS;
for $fld(sort {$a cmp $b} keys(%{$main::pl->{$file4venn}})) {
chomp($fld);
# print $fld;
# if ($fld =~ m/^(.+)vs(.+)-(FC|p|FDR)/i) {
# if ($fld =~ m/^(.+)vs(.+)-(FC|P|FDR)/i) {
if ($fld =~ m/$HSconfig::vennFieldTypeMask/i) {
$cntr1 = $1;
$cntr2 = $2;
$stat = $3;
$cntr1 =~ s/^[\s_-]*//;
$cntr1 =~ s/[\s_-]*$//;
$cntr1 =~ s/\s/_/g;
$cntr2 =~ s/^[\s_-]*//;
$cntr2 =~ s/[\s_-]*$//;
$cntr2 =~ s/\s/_/g;

# print '<br>C1: '.$cntr1;
# print '<br>C2: '.$cntr2.'<br>';
$contrasts->{list}->{$cntr1} = 1;
# $contrasts->{list}->{$cntr2} = 1;

# push @{$contrasts->{pair}->{$cntr1."_vs_".$cntr2}}, $stat;
# push @{$contrasts->{pair}->{$cntr2."_vs_".$cntr1}}, $stat;
push @{$contrasts->{controls}->{$cntr1."_vs_".$cntr2}}, $fld;
 # print join('; ',  @{$contrasts->{controls}->{$cntr1."_vs_".$cntr2}}).'<br>';

#push @{$contrasts->{controls}->{$cntr2."_vs_".$cntr1}}, $fld;
$contrasts->{mates}->{$cntr1}->{$cntr2} = 1;
### $contrasts->{mates}->{$cntr2}->{$cntr1} = 1;
}}
return $contrasts;
}

sub vennInput {
my($file4venn, $delimiter, $maxReadN) = @_;
my($fld, @arr, $thegene, $file, $data, $col, $va);
my $N = 0;
open GS,  $file4venn or die "Cannot open file $file4venn\n";
$_ = <GS>;
readHeader(replaceForbiddenCharacters($_), $file4venn, $delimiter);
# $main::pl->{$tbl}->{$arr[$aa]} = $aa;
# $main::nm->{$tbl}->{$aa} = $arr[$aa];
my $p = $main::pl->{$file4venn};
my $n = $main::nm->{$file4venn};
while (<GS>) {

last if $N > $maxReadN;

chomp; @arr = split($delimiter, $_); $N++;
# $thegene = lc($arr[$main::pl{'gene'}]);
$thegene = lc($arr[$p->{'gene'}]);
# print "BEFORE: ".$thegene."\n";
# return HS_html_gen::errorDialog('error', "Wrong input for Venn diagram", "Invalid ID:<br> $thegene submitted at line $N in <br>$file4venn contains an empty space...", "Altered gene sets") if $thegene =~ m/[A-Z0-9_\.]\s[A-Z0-9_\.]/i;
# die "ID $thegene submitted at line $N in $file4venn contains an empty space..." if $thegene =~ m/[A-Z0-9_\.]\s[A-Z0-9_\.]/i;
$thegene =~ s/\s//g; #$thegene =~ s/\n//g; $thegene =~ s/\r//g;
# print "AFTER: ".$thegene."\n";
# $file->{GS}->[$N] = 1;
# print "GROUP: ".$file->{GS}->[$N]."\n";
for $col(keys(%{$p})) {
$va = $arr[$p->{$col}];
$va =~ s/\s*$//;
push @{$data->{$col}}, $va  if $va and  ($va !~ m/$HSconfig::NAmask/);
}
# $file->{row}->[$N] = $_;
# $file->{gene}->[$N] = $thegene;
# $file->{gene}->[$N] =~ s/\s//g;
}
close GS;
return $data;
}

sub writeParameters4vennGen {
my($para, $vennFile, $criteria, $venName, $gTable, $geneColumn) = @_;
my($fl, $cr);
# print $usersTMP.$HSconfig::parameters4vennGen.'<br>';
my $msk = $HSconfig::NAmask;
$msk =~ s/\\/\\\\/g;
open(OUT, '> '.$para) or die "Could not write into ".$para." ...\n";
print OUT 'para <- list();'."\n"; 
print OUT 'para[["input"]] <- "'.$vennFile.'";'."\n";
print OUT 'para[["num_comp"]] <- '.(scalar(keys(%{$criteria})) - 1).';'."\n";
print OUT 'para[["gene_col"]] <- '.$geneColumn.';'."\n";
print OUT 'para[["skip_genes"]] <- "'.$HSconfig::skipGenesInVennFile.'";'."\n";
print OUT 'para[["NAmask"]] <- "'.$msk.'";'."\n";
print OUT 'para[["plot_path"]] <- "'.$venName.'";'."\n";
print OUT 'para[["list_path"]] <- "'.$gTable.'";'."\n";
print OUT 'para[["contrasts"]]  <- list();'."\n";
print OUT 'para[["order"]] <- c("'.join('", "', @{$criteria->{order}}).'");'."\n";

for $fl(keys(%{$criteria})) {
if ($fl ne 'order') {
for $cr(keys(%{$criteria->{$fl}})) {
if ($cr ) {
print OUT 'para[["contrasts"]][["'.$fl.'"]][["'.$cr.'"]] = '.$criteria->{$fl}->{$cr}.';'."\n";
}}}} #$fl.' '.$cr.' '.
close OUT;
# open PWD, system("pwd");
# $_ = <PWD>;
# close(PWD);
return undef;
}

sub read_group_list2 {
my(%pl, $genelist, $random, $delimiter, $min_size, $max_size, $ty, $skipHeader);
($genelist, $random, $pl{mut_gene_name}, $pl{group}, $delimiter, $ty, $skipHeader) = @_;

my($GR, @arr, $groupID, $thegene, $file,$line, $N, $i, $ge);
# sed '{s/\r/\r\n/g}'
#$pl{mut_gene_name} = 1;  $pl{group} = 2;
# local($/) = "\r" if $useCR; 
#open(GS, "<:crlf", "my.txt");
#open( GS, "<:crlf", $genelist) or die "Cannot open file $genelist\n";
# print STDERR 'FILE: '.$genelist."\n";
open GS,  $genelist or die "Cannot open file $genelist\n";
#http://perldoc.perl.org/perlport.html#Newlines
#$_ = <GS>; 
$N = 0;
$_ = <GS> if $skipHeader;
while ($line = <GS>) {
chomp; 
$line = HStextProcessor::JavascriptCompatibleID($line);
@arr = split($delimiter, $line); $N++;
$thegene = lc($arr[$pl{mut_gene_name}]);
 # print STDERR "BEFORE: ".$thegene."\n";
# die "ID $thegene submitted at line $N in $genelist contains an empty space..." if $thegene =~ m/[A-Z0-9_\.]\s[A-Z0-9_\.]/i;
$thegene =~ s/\s//g; #$thegene =~ s/\n//g; $thegene =~ s/\r//g;
# print "AFTER: ".$thegene."\n";
$file->{GS}->[$N] = (($pl{group} > -1) and $arr[$pl{group}]) ? lc($arr[$pl{group}]): $HSconfig::users_single_group.$ty;
# print "GROUP: ".$file->{GS}->[$N]."\n";

$file->{GS}->[$N] =~ s/\s//g;
$file->{gene}->[$N] = $thegene;
$file->{gene}->[$N] =~ s/\s//g;
$main::Genes -> {$thegene} = 1;
}
close GS;

for ($i = 1; $i <= $N; $i++) {
$ge = $file->{gene}->[$i];
$groupID = $file->{GS}->[$i];
$GR->{$groupID}->{$ge} = 1;
$main::GS->{$ge}->{$groupID} = 1;
}
for $groupID(keys(%{$GR})) {
delete($GR->{$groupID}) if (defined($min_size) and (scalar(keys(%{$GR->{$groupID}})) <= $min_size));
delete($GR->{$groupID}) if (defined($max_size) and (scalar(keys(%{$GR->{$groupID}})) >= $max_size));
}

if ($random) {
	my($permge, $permGR);
for $groupID(keys(%{$GR})) {
for $ge(keys(%{$GR->{$groupID}})) {
while (scalar(keys(%{$permGR->{$groupID}})) < scalar(keys(%{$GR->{$groupID}}))) {
$permge = $file->{gene}->[rand($#{$file->{gene}})];
$permGR->{$groupID}->{$permge} = 1;
}}
$GR->{$groupID} = $permGR->{$groupID};
}}
close IN;
print STDERR scalar(keys(%{$GR})).' group IDs in '.$genelist."...\n\n" if $main::debug;
return $GR;
}

sub compileFGS2 {
my($jid, $FGStype, $FGScollected, $Genewise) = @_;
my($op, $tmpFGS, $pl, $line, @ar, $file, $group);
$tmpFGS = main::tmpFileName('FGS', $jid);
my $fgsA = $HSconfig::fgsAlias;
my $coff = 0; my $spe = $main::q->param("species");

open OUT, '> '.$tmpFGS or die "Could not create temporary file ...\n";
#print '> '.$HSconfig::usersTMP.$tmpFGS if $main::debug;
my $i = 0;
for $op(@{$FGScollected}) {
if  ($FGStype eq '#cpw_list') {
$op =~ s/\s//g;
$group = ($Genewise and (uc($Genewise) ne 'FALSE')) ? $op : $HSconfig::users_single_group.'_as_FGS';
print OUT join("\t", ($op, $op, $group))."\n";  $i++; # print selected genes directly to the agsFile
}
else {
$file = $HSconfig::fgsDir.$spe.'/'.$fgsA->{$spe}->{$op};
$pl->{$file}->{gene} = 1;
$pl->{$file}->{group} = 2;
print '<br>FGS file: '.$file.'<br>' if $main::debug;
open  IN, $file or die "Could not re-open FGS file $file ...\n";
while ($_ = <IN>) {
chomp;
@ar = split("\t", $_); 
$line = join("\t", (
uc($ar[$pl->{$file}->{gene}] ), 
uc($ar[$pl->{$file}->{gene}] ), 
($Genewise and (uc($Genewise) ne 'FALSE')) ? uc($ar[$pl->{$file}->{gene}]) : uc($ar[$pl->{$file}->{group}]), 
$op ));
print OUT $line."\n"; $i++; # if defined($selected{uc($ar[$pl->{$AGSfile}->{group}])});
}
close IN;
}}
close OUT;
die 'The FGS file is empty...<br>'."\n" if !$i;
return($tmpFGS);
}

sub compileNet2 {
my($jid, @options) = @_;
my($op, $tmpNet, $pl, $line, @ar, $file);
$tmpNet = main::tmpFileName('Net', $jid);
my $netA = $HSconfig::netAlias;
my $coff = 0; my $spe = $main::q->param("species");
   
open OUT, '> '.$tmpNet or die "Could not create temporary file ...\n";
my $i = 0;
for $op(@options) {
$file = $HSconfig::netDir.$main::q->param("species").'/'.$netA->{$spe}->{$op};

$pl->{$file}->{gene1} = 0;
$pl->{$file}->{gene2} = 1;
$pl->{$file}->{confidence} = 2;
print '<br>NET file: '.$file.'<br>'  if $main::debug;
open  IN, $file or die "Could not re-open $file ...\n";
while ($_ = <IN>) {
chomp;
@ar = split("\t", $_);
if (!$ar[$pl->{$file}->{confidence}] or ($ar[$pl->{$file}->{confidence}] >= $coff)) {
$line = join("\t", (
$ar[$pl->{$file}->{gene1}], 
$ar[$pl->{$file}->{gene2}]
));
print OUT $line."\n"; $i++;
}}
close IN;
}
close OUT;
die 'The NET file is empty...<br>'."\n" if !$i;
return($tmpNet);
}

1;
__END__


