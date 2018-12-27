#!/usr/bin/perl

use venn_click_points;
my $comp = 1;
my $tst = get_map_html(\%{$venn_click_points::venn_coord},$comp);
print $tst;

sub get_map_html{
	my ($vn_cord,$comp) = @_;
    my %area_cord= %{$vn_cord};
   	my $map_ky="for-venn-$comp";
	my $hlite = "";
	my $map_text = "<map name=\"".$map_ky."\">\n";
    my %pt_cord = %{$area_cord{$map_ky}};
    	for my $pt ( sort(keys %pt_cord) ){
    		my $pt_cd = $pt_cord{$pt};
		    my $pt_new = $pt;
		    $pt_new =~ tr/+-/PF/;
		    my ($left, $top, $right, $bottom) = split(',',$pt_cd);
	        $map_text .= "   <area shape=\"poly\" coords=\"".$pt_cord{$pt}."\" data-key=\"$pt_new\" href=\"javascript:void(0);\" onclick=\"openPopup(\'gene_list".$pt."\');\">\n";
#	        $hlite .=" <div style=\"top: ".$left."px; left: ".$top."px;\" id=\"$pt_new\" class=\"venn-highlight\" onclick=\"highlightIntersection(\'$pt_new\')\"></div>\n";
	        }
	$map_text .= "</map>\n";
	return ($hlite,$map_text);
    	
}