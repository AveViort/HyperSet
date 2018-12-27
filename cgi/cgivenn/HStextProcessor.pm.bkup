package HStextProcessor;
  
#use DBI;
use CGI qw(:standard);
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

sub parseGenes {
my ( $genestring, $delimiter) = @_;
my ( $gg, $genes);
# print '>>>'.($delimiter eq '') ? 'yES' : 'NO'.'<<<<br>';
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
# print ++$i.' : '.'}'.$gg.'{'.'<br>';
	$gg =~ s/\s//g;
	if ($gg !~ m/^[A-Za-z0-9\:\_\-\.]+$/ ) {
	return 'invalid input'; 
# die $gg . ': invalid input: gene/protein IDs shall only contain letters, digits, dash, underscore, and dot';
}}
return($genes);
}

sub parseGenes_old {
my ( $genestring ) = @_;
# my ( $gg, $genes);

	# $genestring =~ s/^\s+//        if $genestring;
	# $genestring =~ s/[\'\"\,\;]/ /g if $genestring;
	# @{$genes} = split( $HS_html_gen::arrayURLdelimiter, uc($genestring) );
# if ( $#{$genes} >= 0 ) {while ( !$genes->[0] ) { shift @{$genes}; }	}

# for $gg (@{$genes}) {
	# $gg =~ s/\s//g;
	# if ( $gg !~ m/^[A-Za-z0-9\:\_\-\.]+$/ ) {
# print $q->h4({ -style => 'Color: red;' }, $gg . ': invalid input: gene/protein IDs shall only contain letters, digits, dash, underscore, and dot');
# die;
# }}
	# return($genes);
}



sub nea_link_url {
my($genes1, $genes2, $species) = @_;

my(@arr, $AGS, $FGS, $genesAGS2, $genesFGS2, $or, $Nl, $i, $subnet_url); 
# $genesAGS, $genesFGS, 
# my $sn = 0;
# for $i(0..$#{$neaData}) { 
# @arr = split("\t", uc($neaData->[$i]->{wholeLine}));
# $genesAGS = $arr[$pl->{$table}->{ags_genes2}]; 
# $genesFGS = $arr[$pl->{$table}->{fgs_genes2}]; 
# $genesAGS2 = join($HS_html_gen::arrayURLdelimiter, split(/\s+/, $arr[$pl->{$table}->{ags_genes1}]));
# $genesFGS2 = join($HS_html_gen::arrayURLdelimiter, split(/\s+/, $arr[$pl->{$table}->{fgs_genes1}]));
# $or = 0;
# if ($or) {
# $Nl = $arr[$pl->{$table}->{n_genes_ags}] * 2;
# $Nl = 100 if ($Nl > 100) or ($Nl < 10);
# }
# else {
# $Nl =  1000;
# }
# $AGS = $arr[$pl->{$table}->{ags}];
# $FGS = $arr[$pl->{$table}->{fgs}];
# $subnet_url->{$AGS}->{$FGS} = $HS_html_gen::webLinkPage_AGS2FGS_nealink. 
# print scalar(keys(%{$genes1})).'<br>';
$subnet_url = $HS_html_gen::webLinkPage_nealink. 
'coff='.$HSconfig::fbsCutoff->{ags_fgs}.
';ags_fgs=yes'.
';species='.$species.
';genes1='.$genes1.
';genes2='.$genes2; 
#.';action=nealink-'.++$sn.';';  
# }
return($subnet_url);
}

sub compileGS { 
my($type, #AGS or FGS
$jid, $GSfile, $GSselected, $gene_column_id, $group_column_id, $Genewise, $species, $debug) = @_;
# print(join('<br>', @_)).'<br>' if $debug;
if ((uc($Genewise) ne 'FALSE') and (uc($Genewise) ne 'TRUE')) {die 'Wrong parameter "Genewise"...';}
my($op, @ar, $tmp, %selected, $line, $group, $gene, $genes, $groups, $gene_list, $hsgene, $fcgenes, $takeIt,
$venn, @a1, @a2);

$tmp = main::tmpFileName(uc($type), $jid);
open OUT, '> '.$tmp or die "Could not create temporary ".$type." file ...\n";
my $i = 0; 
# print $GSfile if $debug;
# print(join(' ', @{$GSselected})) if $debug;	
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
print '<br>ooo: ' .join(' - ', @a2).'<br>' if $debug;
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
print '<br>Selected '.$type.' member: '.uc($op).'<br>' if $debug;
$selected{uc($op)} = 1;
}}
# print '<br>AGS file: '.$GSfile.'<br>'  if ($GSfile ne '#sgs_list');
if ($GSfile !~ m/\#cpw_list|\#sgs_list/) {
# print $GSfile if $debug;
local($/) = "\r" if $main::q->param("useCR");  
open IN, $GSfile or die "Could not re-open '.$type.' file $GSfile ...\n"; #otherwise, 
while ($_ = <IN>) {
$takeIt = 0;
$line = $_;
chomp;
@ar = split("\t", $_);
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
$genesAGS = $arr[$pl->{$table}->{ags_genes2}]; 
$genesFGS = $arr[$pl->{$table}->{fgs_genes2}]; 
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
$head =~ s/\s*$//;
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
$hd =~ s/[\(\)\:\,]/_/g;
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
$contrasts->{mates}->{$cntr2}->{$cntr1} = 1;
}}
return $contrasts;
}

sub vennInput {
my($file4venn, $delimiter, $maxReadN, $useCR, $min_size, $max_size) = @_;
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
return HS_html_gen::errorDialog('error', "Wrong input for Venn diagram", "Invalid ID:<br> $thegene submitted at line $N in <br>$file4venn contains an empty space...", "Altered gene sets") if $thegene =~ m/[A-Z0-9_\.]\s[A-Z0-9_\.]/i;
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

1;
__END__



