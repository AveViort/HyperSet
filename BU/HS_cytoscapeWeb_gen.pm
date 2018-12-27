package HS_cytoscapeWeb_gen;

use DBI;
#use XML::LibXML;
#use XML::LibXSLT;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
#use List::Util qw[min max];
#use IPC::Open2;
#use Switch;
#use config;
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
our ($node_features, $nodeList, $network_links, %AGS_mem);

sub printNEA_JSON {
my($neaSorted, $pl) = @_; 

my(@ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $conn_class, $FGS, $AGS, $conn_class_members, );
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

for $i(0..$#{$neaSorted}) { 
@ar = split("\t", uc($neaSorted->[$i]->{wholeLine}));
#next if $ar[$pl{MODE}] ne 'prd';
#next if $ar[$pl{NlinksReal_AGS_to_FGS}] < $minNlinks;
$AGS = $ar[$pl->{ags}];
$FGS = $ar[$pl->{fgs}];
next if !$AGS or !$FGS;
$signature = join('-#-#-#-', (sort {$a cmp $b} ($AGS, $FGS))); #protects against importing & counting duplicated edges
next if defined($copied_edge{$signature});
$copied_edge{$signature} = 1;
# last if scalar(keys(%{$nodeList -> {AGS}}))  > 4;
# last if $NlinksTotal++  > 100;
$network_links -> {$AGS} -> {$FGS} -> {$main::pivotal_confidence} = ($ar[$pl->{$main::pivotal_confidence}] ? $ar[$pl->{$main::pivotal_confidence}] : 1);
for $ff(@usedFields) {
$network_links -> {$AGS} -> {$FGS} -> {$ff} = $ar[$pl->{lc($ff)}];
}
$node_features->{$AGS}->{N_genes} = $ar[$pl->{n_genes_ags}];
$node_features->{$FGS}->{N_genes} = $ar[$pl->{n_genes_fgs}];
$node_features->{$AGS}->{AGS_genes1} = $ar[$pl->{ags_genes1}];
$node_features->{$FGS}->{FGS_genes1} = $ar[$pl->{fgs_genes1}];
$node_features->{$AGS}->{count}++;
$node_features->{$FGS}->{count}++;
$nodeList -> {AGS} -> {$AGS} = 1;
$nodeList -> {FGS} -> {$FGS} = 1;
#$Genes -> {$AGS} = $Genes -> {$FGS} = 1;
}
#return(scalar((keys(%{$nodeList -> {AGS}}))));
# print STDERR "\n $NlinksTotal network edges  between ".scalar(keys(%{$node_features}))." nodes obtained  ...\n";
# print STDERR '!!! '."The confidence cutoff you specifed was ignored: the ".($pl{$main::pivotal_confidence}+1)." column in the input NEA file was empty ...\n" if $confidence_cutoff and !$isConf;

for $nn(sort {$a cmp $b} keys(%{$node_features})) {
$conn_class = sprintf("%u", log($node_features->{$nn}));
$node_features->{$nn}->{logConnectivity} = $conn_class;
push @{$conn_class_members->{$conn_class}}, $nn;
}

#print "Content-type: text/html\n\n";
my $content =  printCWstart();
for $aa(keys(%{$nodeList -> {AGS}})) {
$content .= printNMobject($aa);
}
$content .=  printCWend();
return($content);
}

sub printNMobject {
my($AGS) = @_;
return(printNMheader($AGS).printNodes($AGS).printEdges($AGS).printNMfooter($AGS));
}



sub printNMheader {
my($AGS) = @_;
		my $ID = $AGS;
		$ID =~ s/\+/P/g;
		$ID =~ s/\-/M/g;
		$ID =~ s/\./\_/g;


my $content = '               function CWview_'.$ID.'() {
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
return($content); 
}

sub printNMfooter {
my $content = '                   };
                
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
                vis.draw(draw_options);};';
return($content); 
}

sub printNodes {
my($AGS) = @_;
my($content, $nn, $weight, $shape, $type, $memberGenes, @mem, $mm);

$content = 'nodes: [';
for $nn(keys(%{$node_features})) {
next if (defined($nodeList -> {FGS} -> {$nn}) and !defined($network_links -> {$AGS} -> {$nn}));
next if defined($nodeList -> {AGS} -> {$nn}) and ($nn ne $AGS);
								$type = 'other';
								undef %AGS_mem;
if (defined($nodeList -> {AGS} -> {$nn})) {
$type = "AGS"; $memberGenes = '';
} else {
$memberGenes = $node_features->{$nn}->{FGS_genes1};
}
$weight = sprintf("%.1f", log($node_features->{$nn}->{N_genes}));
my $label = $nodeList -> {AGS} -> {$nn} ? $nn : $nn.', N(DE)='.$network_links -> {$AGS} -> {$nn} -> {GSEA_overlap};
$content .= printNMnode($nn, $label, $weight, $type);
if ($memberGenes) {
@mem = split(' ', $memberGenes);

for $mm(@mem) {
$content .= printNMnode($mm, $mm, ($AGS_mem{$mm} ? 3 : 1), 'gene', $nn);
}}
}
$content =~ s/\,\s+$//;
$content .= ']';
return($content);             
}

sub printNMnode {
my($id, $label, $weight, $type, $parent) = @_;

                 my $content = ' { ';
					$content .= "id: \"$id\"\, "; 
					$content .= "type: \"$type\"\, ";
                    $content .= "label: \"$label\"\, ";
                    $content .= "weight: $weight\, ";
                    $content .= "parent\: \"$parent\"" if $parent;
$content =~ s/\,\s+$//;					
					$content .= ' },  '."\n";
return($content);
}

sub printEdges {
my($AGS) = @_;
my($content, $FGS, $weight, $genes, $Nlinks);

$content = ', '."\n".'edges: [  ';
#for $AGS(keys(%{$network_links})) {
for $FGS(keys(%{$network_links -> {$AGS}})) {
$weight = $network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS};
$genes  = $network_links -> {$AGS} -> {$FGS} -> {AGS_genes2};

$Nlinks = $weight;
$content .= ' { id: "'.$AGS.'_vs_'.$FGS.'", ';
					$content .= "source: \"$AGS\"\, ";
					$content .= "target: \"$FGS\"\, ";
					$content .= "label: \"$weight links by DE genes: $genes\"\, ";
                    $content .= "weight: $weight\, ";
$content =~ s/\,\s+$//;
					$content .= '},  '."\n";

 }
$content =~ s/\,\s+$//;
$content .= ' ] } '."\n";

return($content);             
}

sub printCWstart {
my $content = '<script type="text/javascript">'."\n";
return($content);
}

sub printCWend {
my($n, $ID );
my $content = '</script>     
       <div id="cytoscapeweb">
            Cytoscape Web will replace the contents of this div with your graph.
        </div>'."\n";
		for $n(sort {$a cmp $b} keys(%{$nodeList -> {AGS}})) {
		$ID = $n;
		$ID =~ s/\+/P/g;
		$ID =~ s/\-/M/g;
		$ID =~ s/\./\_/g;
		$content .= '<div id="displayNet" draggable="true"  onclick="CWview_'.$ID.'()" >'.$n.'</div>'."\n";
		}
return($content);
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

sub define_ {}

1;
__END__
