#!/usr/bin/perl

use warnings;
use strict;

use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
# use CGI; # qw(-no_xhtml);
# use CGI::Carp qw ( fatalsToBrowser );
# use File::Basename;
# use DBI;
# use NET;
use HStextProcessor;
use HSconfig;
use HS_html_gen;

our($pl, $nm, $genome, $table);
$genome = 'human';
$table = '/home/proj/func/Projects/Laszlo/full_and_GO_VS_BasalCLPs.merged6';

HStextProcessor::readHeader($table);

our($genesAGS, $genesFGS, $genesAGS2, $genesFGS2);
my(@arr, $nl, $or, $signGSEA, $text, $ol);
my $GSEA_FDR_coff = 0.05;

my $head .= '<h3 style="color: #441;">';
$head .= 'Associations of altered gene sets (AGS) with functional groups (FGS)';
$head .= '</h3>';
#print $HS_html_gen::webLinkPage_AGS2FGS_head.$head."\n";
print HTML_BEGIN().$head."\n";

print'<h3>FunCoup legend:</h3>Cluster members: yellow diamonds<br>Functional  set genes: magenta diamonds

<table style="background-color: #DDD; color: #441; align=right; " width=1200>';
print '<tr class="bold normal">
<th class="AGSout">'.$HS_html_gen::OLbox1.'Altered gene set, the novel genes you want to characterize'.$HS_html_gen::OLbox2.'AGS</a></th>
<th class="AGSout">'.$HS_html_gen::OLbox1.'Number of AGS genes found in the used network'.$HS_html_gen::OLbox2.'#genes AGS</a></th>
<th class="AGSout">'.$HS_html_gen::OLbox1.'Total number of network links produced by AGS genes in the used network'.$HS_html_gen::OLbox2.'#links AGS</a></th>
<th class="FGSout">'.$HS_html_gen::OLbox1.'Functional gene set, a previously known group of genes that share functional annotation'.$HS_html_gen::OLbox2.'FGS</a></th>
<th class="FGSout">'.$HS_html_gen::OLbox1.'Number of FGS genes found in the used network'.$HS_html_gen::OLbox2.'#genes FGS</a></th>
<th class="FGSout">'.$HS_html_gen::OLbox1.'Total number of network links produced by FGS genes in the used network'.$HS_html_gen::OLbox2.'#links AGS</a></th>
<th>'.$HS_html_gen::OLbox1.'Number of links in the current network between genes of AGS and FGS'.$HS_html_gen::OLbox2.'#linksAGS2FGS</a></th>
<th>'.$HS_html_gen::OLbox1.'Network enrichment score (the chi-squared)'.$HS_html_gen::OLbox2.'Score</a></th>
<th>'.$HS_html_gen::OLbox1.'False discovery rate of the network analysis, i.e. the probability that this AGS-FGS relation does not exist'.$HS_html_gen::OLbox2.'FDR</a></th>
<th>'.$HS_html_gen::OLbox1.'Classical gene set enrichment analysis (the discrete, binomial version)'.$HS_html_gen::OLbox2.'Shared genes</a></th>
<th>Link to FunCoup</th></tr>';
open NEA, $table or die "Cannot open $table ... \n";
$_ = <NEA>;
while ($_ = <NEA>) {
chomp; @arr = split("\t", uc($_));
next if $arr[$pl->{$table}->{ags}] =~ m/\.n1\./i;
$genesAGS = $arr[$pl->{$table}->{ags_genes2}];
$genesFGS = $arr[$pl->{$table}->{fgs_genes2}];
$genesAGS2 = join('%0D%0A', split(/\s+/, $arr[$pl->{$table}->{ags_genes1}]));
$genesFGS2 = join('%0D%0A', split(/\s+/, $arr[$pl->{$table}->{fgs_genes1}]));

$text = $arr[$pl->{$table}->{ags}];
$text = substr($text, 0, 40);
$ol = ''; $ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{ags}].$HS_html_gen::OLbox2 
	if length($arr[$pl->{$table}->{ags}]) > 41;
print "\n".'<tr><td id="firstcol" class="AGSout">'.$ol.$text.'</a>'.'</td>';

print "\n".'<td class="AGSout">'.
$HS_html_gen::OLbox1.
'<b>AGS genes that contributed to the relation</b><br>(followed with and sorted by number of links):<br>'.$genesAGS.
$HS_html_gen::OLbox2.
$arr[$pl->{$table}->{n_genes_ags}].'</a>'.'</td>';
print "\n".'<td class="AGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_AGS')}].'</td>';
$text = $arr[$pl->{$table}->{fgs}];
$text = substr($text, 0, 40);

$ol = ''; $ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2 
	if length($arr[$pl->{$table}->{fgs}]) > 41;

	print "\n".'<td id="sndcol" class="FGSout">'.$ol.$text.'</a>'.'</td>';
print "\n".'<td class="FGSout">'.$HS_html_gen::OLbox1.$genesFGS.$HS_html_gen::OLbox2.$arr[$pl->{$table}->{'n_genes_fgs'}].'</a>'.'</td>';
print "\n".'<td class="FGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_FGS')}].'</td>';
print "\n".'<td>'.$arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}].'</td>';
print "\n".'<td>'.$arr[$pl->{$table}->{lc('ChiSquare_value')}].'</td>';
print "\n".'<td>'.$arr[$pl->{$table}->{lc('ChiSquare_FDR')}].'</td>';
$signGSEA = ($arr[$pl->{$table}->{lc('GSEA_FDR')}] < $GSEA_FDR_coff) ? $HS_html_gen::OLbox1.$arr[$pl->{$table}->{lc('GSEA_overlap')}].' genes shared between AGS and FGS, significant at FDR<'.$arr[$pl->{$table}->{lc('GSEA_FDR')}].
$HS_html_gen::OLbox2.'*</a>' : '';
print "\n".'<td>'.$arr[$pl->{$table}->{lc('GSEA_overlap')}].$signGSEA.'</td>';

for $or('1') {
if ($or) {
 $nl = $arr[$pl->{$table}->{n_genes_ags}] * 2;
$nl = 50 if $nl > 100;
}
else {
$nl =  1000;
}
print "\n".'<td>'.'<a href="'.$HS_html_gen::webLinkPage_AGS2FGS_FClim_link. 
'for_species='.$genome.
';context_genes='.$genesFGS2.
';genes='.$genesAGS2.
';order='.$or.
';no_of_links='.$nl.
';" target="_blank">network</a></td>';
}
print '</tr>';

}
close NEA;
print"\n".'</table>'."\n";
print $HS_html_gen::webLinkPage_AGS2FGS_end."\n";

sub HTML_BEGIN {
return ( 
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html lang="en-US">
        <head>
        <title>HyperSet visualization</title>
		<meta charset="windows-1252">
    <META content="application/javascript" http-equiv="Content-Script-Type">
    <LINK href="http://research.scilifelab.se/andrej_alexeyenko/hyperset.css" type="text/css" rel="stylesheet">
    <LINK href="http://tools.scilifelab.se/hyperset/static/favicon.ico" rel="shortcut icon">
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
		       <style type="text/css">
            * { margin: 0; padding: 0; font-family: Helvetica, Arial, Verdana, sans-serif; }
            html, body { height: 100%; width: 100%; padding: 0; margin: 0; background-color: #f0f0f0; }
            body { line-height: 1.5; color: #000000; font-size: 14px; }
            /* The Cytoscape Web container must have its dimensions set. */
            #cytoscapeweb { width: 100%; height: 100%; }
            note { width: 100%; text-align: center; padding-top: 1em; }
            #displayNet { text-decoration: underline; color: #0b94b1; cursor: pointer; }
        </style>

		    </head>
    <body>
<script type="text/javascript" src="http://funcoup.sbc.su.se/js/overlib.js"><!-- overLIB (c) Erik Bosrup --></script>
<script type="text/javascript" src="http://funcoup.sbc.su.se/js/fcout.js"><!-- fcout (c) Andrey Alexeyenko 2007 --></script>       
<script type="text/javascript" src="http://research.scilifelab.se/andrej_alexeyenko/HyperSet/js/cytoscape_web/json2.min.js"></script>
<script type="text/javascript" src="http://research.scilifelab.se/andrej_alexeyenko/HyperSet/js/cytoscape_web/AC_OETags.min.js"></script>
<script type="text/javascript" src="http://research.scilifelab.se/andrej_alexeyenko/HyperSet/js/cytoscape_web/cytoscapeweb.min.js"></script>'
		);
}



