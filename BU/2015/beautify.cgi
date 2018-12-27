#!/usr/bin/perl -w
use warnings;
use strict;
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";

use CGI qw(-no_xhtml);
use DBI;
use NET;


$ENV{'PATH'} = '/bin:/usr/bin:';
our ($dbh, $node_features, $nodeList, $Genes, $NlinksTotal, $conn_class_members, $network_links, %AGS_mem, %conn);
our $NN = 0;
my $NEAfile = '/var/www/html/research/andrej_alexeyenko/HyperSet/DATA/GO.BP_KEGG.mmu.5x4plus_minus.Mouse.merged4_and_tf.co7.prd';
read_NEA_output($NEAfile);
printContent();


sub printContent {
my($aa);

print "Content-type: text/html\n\n";
print printStart();
for $aa(keys(%{$nodeList -> {AGS}})) {
printNMobject($aa);
}
print printEnd();
}

sub printNMobject {
my($AGS) = @_;

print printNMheader($AGS).printNodes($AGS).printEdges($AGS).printNMfooter($AGS);
}

sub printNMheader {
my($AGS) = @_;
		my $ID = $AGS;
		$ID =~ s/\+/P/g;
		$ID =~ s/\-/M/g;
		$ID =~ s/\./\_/g;


my $out = '               function CWview_'.$ID.'() {
			        var div_id = "cytoscapeweb";
     var NMobject = {
                         dataSchema: {
                            nodes: [ 
							{ name: "id", type: "string" },
							{ name: "label", type: "string" },
							{ name: "nShape", type: "string" },
							{ name: "type", type: "string" },
							{ name: "weight", type: "number" }
                                ],
                            edges: [ { name: "label", type: "string" },
                                     { name: "bar", type: "string" },
							{ name: "weight", type: "number" }
                            ]
                        },
						data: {	'."\n";
return($out); 
}

sub printNMfooter {

my $out = '                   };
                
                 var visual_style = {
                    global: {
                        backgroundColor: "#FFFFDD"
                    },

                    nodes: {
                       shape: {defaultValue: "CIRCLE", passthroughMapper: { 
					   attrName: "type",
                       entries: [
                                    { attrValue: "AGS", value: "ROUNDRECT" }, 
                                    { attrValue: "gene", value: "ROUNDRECT" }
								]
 } },
compoundShape: "ROUNDRECT",
compoundLabel: { passthroughMapper: { attrName: "label" } } ,
compoundBorderWidth: 3,
compoundBorderColor: "#ff9999",
compoundColor: "#FFeaea", 
                       borderWidth: 1,
                        borderColor: "#999999",
                        size: {
                            defaultValue: 5,
                            continuousMapper: { attrName: "weight", minValue: 1, maxValue: 75 }
                        },
                        color: {defaultValue: "#1111FF", 
                            discreteMapper: {
                                attrName: "type",
                                entries: [
                                    { attrValue: "AGS", value: "#DD3333" },
                                    { attrValue: "gene", value: "#DD3333" }
                                ]
                            }
                        },
                        labelHorizontalAnchor: "center"
                    },
					edges: {
					        width: {
							defaultValue: 3,
                            continuousMapper: { attrName: "weight",  minValue: 1, maxValue: 9, minAttrValue: 1, maxAttrValue: 100 }
							}, 
                        color: "#0B94B1"
						
                    }
                };
                
                // initialization options
                var options = {
                    swfPath: "http://research.scilifelab.se/andrej_alexeyenko/HyperSet/swf/CytoscapeWeb",
                    flashInstallerPath: "http://research.scilifelab.se/andrej_alexeyenko/HyperSet/swf/playerProductInstall"
                };
                
                var vis = new org.cytoscapeweb.Visualization(div_id, options);
                
                vis.ready(function() {
                    // set the style programmatically
                    document.getElementById("color").onclick = function(){
                        vis.visualStyle(visual_style);
                    };
                });

                var draw_options = {
                     network: NMobject,
                    edgeLabelsVisible: true,
					edgeTooltipsEnabled: false, 
                    layout: "CompoundSpringEmbedder",
                    visualStyle: visual_style,
                    panZoomControlVisible: true 
                };
                vis.draw(draw_options);
            };
';
return($out); 
}

sub printNodes {
my($AGS) = @_;
my($out, $nn, $weight, $shape, $type, $memberGenes, @mem, $mm);

$out = 'nodes: [';
								
								for $nn(keys(%{$node_features})) {
next if (defined($nodeList -> {FGS} -> {$nn}) and !defined($network_links -> {$AGS} -> {$nn}));
next if defined($nodeList -> {AGS} -> {$nn}) and ($nn ne $AGS);
								$type = 'other';
								undef %AGS_mem;
if (defined($nodeList -> {AGS} -> {$nn})) {
$type = "AGS"; $memberGenes = '';

# @mem = split(' ', $node_features->{$nn}->{AGS_genes1});
# for $mm(@mem) {
# $AGS_mem{$mm} = 1;
# }
} else {
$memberGenes = $node_features->{$nn}->{FGS_genes1};
}
$weight = sprintf("%.1f", log($node_features->{$nn}->{N_genes}));
my $label = $nodeList -> {AGS} -> {$nn} ? $nn : $nn.', N(DE)='.$network_links -> {$AGS} -> {$nn} -> {GSEA_overlap};
$out .= printNMnode($nn, $label, $weight, $type);
if ($memberGenes) {
@mem = split(' ', $memberGenes);

for $mm(@mem) {
$out .= printNMnode($mm, $mm, ($AGS_mem{$mm} ? 3 : 1), 'gene', $nn);
}}
}
$out =~ s/\,\s+$//;
$out .= ']';

return($out);             
}

sub printNMnode {
my($id, $label, $weight, $type, $parent) = @_;

                 my $out .= ' { ';
					$out .= "id: \"$id\"\, "; 
					$out .= "type: \"$type\"\, ";
                    $out .= "label: \"$label\"\, ";
                    $out .= "weight: $weight\, ";
                    $out .= "parent\: \"$parent\"" if $parent;
$out =~ s/\,\s+$//;					
					$out .= ' },  '."\n";
return($out);
}

# 'N_linksTotal_AGS', 
# 'N_linksTotal_FGS', 
# 'N_genes_AGS', 
# 'N_genes_FGS', 
# 'NlinksReal_AGS_to_FGS', 
# 'ChiSquare_p-value', 
# 'ChiSquare_FDR'
# 'AGS_genes1'
# 'FGS_genes1'

sub printEdges {
my($AGS) = @_;
my($out, $FGS, $weight, $genes, $Nlinks);

$out = ', '."\n".'edges: [  ';
#for $AGS(keys(%{$network_links})) {
for $FGS(keys(%{$network_links -> {$AGS}})) {
$weight = $network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS};
$genes  = $network_links -> {$AGS} -> {$FGS} -> {AGS_genes2};

$Nlinks = $weight;
$out .= ' { id: "'.$AGS.'_vs_'.$FGS.'", ';
					$out .= "source: \"$AGS\"\, ";
					$out .= "target: \"$FGS\"\, ";
					$out .= "label: \"$weight links by DE genes: $genes\"\, ";
                    $out .= "weight: $weight\, ";
$out =~ s/\,\s+$//;
					$out .= '},  '."\n";

 }
$out =~ s/\,\s+$//;
$out .= ' ] } '."\n";

return($out);             
}

sub printStart {
my $out = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html>
    
    <head>
        <title>HyperSet visualization</title>
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
<!--script type="text/javascript" src="overlibmws.js"></script>
<script type="text/javascript" src="overlibmws_filter.js"></script>
<script type="text/javascript" src="overlibmws_shadow.js"></script-->
        <script type="text/javascript" src="http://research.scilifelab.se/andrej_alexeyenko/HyperSet/js/cytoscape_web/json2.min.js"></script>
        <script type="text/javascript" src="http://research.scilifelab.se/andrej_alexeyenko/HyperSet/js/cytoscape_web/AC_OETags.min.js"></script>
        <script type="text/javascript" src="http://research.scilifelab.se/andrej_alexeyenko/HyperSet/js/cytoscape_web/cytoscapeweb.min.js"></script>
        
        <script type="text/javascript">
';
return($out);
}

sub printEnd {
my($n, $ID );
my $out = '</script>     
       <div id="cytoscapeweb">
            Cytoscape Web will replace the contents of this div with your graph.
        </div>'."\n";
		for $n(sort {$a cmp $b} keys(%{$nodeList -> {AGS}})) {
		$ID = $n;
		$ID =~ s/\+/P/g;
		$ID =~ s/\-/M/g;
		$ID =~ s/\./\_/g;
		$out .= '<div id="displayNet" draggable="true"  onclick="CWview_'.$ID.'()" >'.$n.'</div>'."\n";
		}
    $out .= "\n".'</body>
</html>'."\n";
# <iframe id="cw1" src="test_net.OL.html" width="350" height="200" frameborder="0"  sandbox="" scrolling="no" draggable="true" ondragstart="drag(event)"></iframe>
# <div id="displayNet" draggable="true"  onclick="CWview_1()" >show it</div>

return($out);
}

sub read_NEA_output {
my($table) = @_;
my(@ar, $nn, $ff, $gr, $signature, %copied_edge, $conn_class, %pl, $FGS, $AGS);

my $useLinkConfidence = 1;
my $minNlinks = 5;
my $confidence_cutoff = 0.01;
my @usedFields = (
'N_linksTotal_AGS', 
'N_linksTotal_FGS', 
'N_genes_AGS', 
'N_genes_FGS', 
'NlinksReal_AGS_to_FGS', 
'ChiSquare_p-value', 
'AGS_genes1', 
'FGS_genes1', 
'AGS_genes2', 
'FGS_genes2', 
'ChiSquare_FDR',
'GSEA_overlap'
);
open IN, $table or die "Could not open $table\n";
NET::readHeader(<IN>, $table);
$pl{MODE} = $NET::pl->{$table}->{mode};
$pl{AGS} = $NET::pl->{$table}->{ags};
$pl{FGS} = $NET::pl->{$table}->{fgs};
$pl{pivotal_confidence} = $NET::pl->{$table}->{lc('ChiSquare_FDR')};
for $ff(@usedFields) {
$pl{$ff} = $NET::pl->{$table}->{lc($ff)};
}


my $isConf = 0;
while (<IN>) {
chomp;
@ar = split("\t", $_);
next if $ar[$pl{MODE}] ne 'prd';
next if $ar[$pl{NlinksReal_AGS_to_FGS}] < $minNlinks;
next if ($useLinkConfidence and ($ar[$pl{pivotal_confidence}] ne '') and ($ar[$pl{pivotal_confidence}] > $confidence_cutoff)) and (defined($confidence_cutoff) and defined($pl{pivotal_confidence}));
$isConf = 1 if ($ar[$pl{pivotal_confidence}] ne '');
$AGS = $ar[$pl{AGS}];
$FGS = $ar[$pl{FGS}];
next if !$AGS or !$FGS;

$signature = join('-#-#-#-', (sort {$a cmp $b} ($AGS, $FGS))); #protects against importing & counting duplicated edges
next if defined($copied_edge{$signature});
#next if $ar[$pl{AGS}] !~ m/wt\_phox2b\_onefold\+\+/;
next if $ar[$pl{FGS}] !~ m/kegg_041|kegg_042|kegg_043/;
$copied_edge{$signature} = 1;
# last if scalar(keys(%{$nodeList -> {AGS}}))  > 4;
# last if $NlinksTotal++  > 100;
$network_links -> {$AGS} -> {$FGS} -> {pivotal_confidence} = ($ar[$pl{pivotal_confidence}] ? $ar[$pl{pivotal_confidence}] : 1);
for $ff(@usedFields) {
$network_links -> {$AGS} -> {$FGS} -> {$ff} = $ar[$pl{$ff}];

}
$node_features->{$AGS}->{N_genes} = $ar[$pl{N_genes_AGS}];
$node_features->{$FGS}->{N_genes} = $ar[$pl{N_genes_FGS}];
$node_features->{$AGS}->{AGS_genes1} = $ar[$pl{AGS_genes1}];
$node_features->{$FGS}->{FGS_genes1} = $ar[$pl{FGS_genes1}];
$node_features->{$AGS}->{count}++;
$node_features->{$FGS}->{count}++;
$nodeList -> {AGS} -> {$AGS} = 1;
$nodeList -> {FGS} -> {$FGS} = 1;
$Genes -> {$AGS} = $Genes -> {$FGS} = 1;

}
close IN;
print STDERR "\n $NlinksTotal network edges  between ".scalar(keys(%{$node_features}))." nodes obtained from $table ...\n";
print STDERR '!!! '."The confidence cutoff you specifed was ignored: the ".($pl{pivotal_confidence}+1)." column in the input NEA file $table was empty ...\n" if $confidence_cutoff and !$isConf;

for $nn(sort {$a cmp $b} keys(%{$node_features})) {
$conn_class = sprintf("%u", log($node_features->{$nn}));
$node_features->{$nn}->{logConnectivity} = $conn_class;
push @{$conn_class_members->{$conn_class}}, $nn;
}
return($network_links);
}

sub printNodesXML {
my($out, $nn);
for $nn(keys(%{$node_features})) {
                    $out .= '<node id="';
                                        $out .= $nn;
                                        $out .= '">\\';
                    $out .= '<data key="label">';
                                        $out .= $nn;
                                        $out .= '</data>\\';
                    $out .= '<data key="weight">';
                                        $out .= '1.0';
                                        $out .= '</data>\\</node>\\';
}
print $out;
return(undef);
 }

sub printEdgesXML {
my($out, $FGS, $AGS);
for $AGS(keys(%{$network_links})) {
for $FGS(keys(%{$network_links -> {$AGS}})) {

                    $out .= '<edge source="';
					$out .= $AGS;
					$out .= '" target="';
                    $out .= $FGS;
					$out .= '">\\'."\n".'<data key="label">';
                    $out .= 'FDR=';
					$out .= '</data>\\
                    </edge>\\';
}}
print $out;
return(undef);             
}

sub printTestXML {
print '                   <node id="1">\\
                        <data key="label">A</data>\\
                        <data key="weight">2.0</data>\\
                    </node>\\
                    <node id="2">\\
                        <data key="label">B</data>\\
                        <data key="weight">1.5</data>\\
                    </node>\\
                    <node id="3">\\
                        <data key="label">C</data>\\
                        <data key="weight">1.0</data>\\
                    </node>\\
                   <node id="4">\\
                        <data key="label">D</data>\\
                        <data key="weight">1.0</data>\\
                    </node>\\
                    <edge source="1" target="2">\\
                        <data key="label">A to B</data>\\
                    </edge>\\
                    <edge source="1" target="3">\\
                        <data key="label">A to C</data>\\
                    </edge>\\
                    <edge source="2" target="4">\\
                        <data key="label">A to C</data>\\
                    </edge>\\
';
}

