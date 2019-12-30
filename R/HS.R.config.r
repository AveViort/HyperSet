#.libPaths("/var/www/html/research/HyperSet/dev/HyperSet/R/lib");

########################################################################################
# 18:35 b4:/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/pics >>>> ln -s /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/plots/ .
# users_tmp/plots/ is a physical location. 
# Therefore /HyperSet/pics/plots/ must be synchronized with it via  $Aconfig::Rplots->{dir}
r.plots = "/var/www/html/research/users_tmp/plots"; 
##########################################################################################
#  These must be also synchronized with perl:
RscriptParameterDelimiter = '###'; 
RscriptKeyValueDelimiter = "=";
RscriptfieldRdelimiter = "+";
##########################################################################################
# options for plots - absolute values
plotHeight = 720;
plotWidth = 1280;
plotSize = 1280;
druggable.cex = 2;
druggable.cex.error = 10;
druggable.cex.main = 3;
druggable.cex.sub = 1.5;
druggable.cex.axis = 1.5;
druggable.cex.lab = 2;
druggable.precision.cor.legend = 3;
druggable.precision.pval.legend = 2;
druggable.cex.legend = 0.75;

# options for plots - relative size
druggable.cex.relative = druggable.cex * plotSize / 1280;
druggable.cex.error.relative = druggable.cex.error * plotSize / 1280;
druggable.cex.main.relative = druggable.cex.main * plotSize / 1280;
druggable.cex.sub.relative = druggable.cex.sub * plotSize / 1280;
druggable.cex.axis.relative = druggable.cex.axis * plotSize / 1280;
druggable.cex.lab.relative = druggable.cex.lab * plotSize / 1280;
druggable.cex.legend.relative = druggable.cex.lab * plotSize / 1280;

# options for print
druggable.precision.cor.legend = 2;
druggable.precision.pval.legend = 2;

# options for plotly
font1 <- list(
  family = "Arial, sans-serif",
  size = 14,
  color = "black"
);
font2 <- list(
  family = "Old Standard TT, serif",
  size = 12,
  color = "black"
);
druggable.plotly.legend.style <- list(
	x = 1,
	y = 0.8,
	font = list(
		family = "sans-serif",
		size = 12,
		color = "#000"),
	bgcolor = "#E2E2E2",
	bordercolor = "#FFFFFF",
	borderwidth = 2)
	
druggable.plotly.marker_shapes <- c("circle", "triangle-up", "square", "diamond", "x", "star", "cross", "triangle-down", "hexagon", "octagon");
druggable.plotly.tissue_colours <- c(
					"ADRENAL_CORTEX" = "#9000ab",
					"AUTONOMIC_GANGLIA" = "#1200f8",
					"BILIARY_TRACT"	= "#46d112",       
                    "BONE" = "#8824ee",
					"BREAST" = "#618925",
					"CENTRAL_NERVOUS_SYSTEM"= "#c4aaff", 
                    "CERVIX" = "#a6a64b",
					"ENDOMETRIUM" = "#96895f",
					"FIBROBLAST" = "#86ffff",                                          
					"HAEMATOPOIETIC_AND_LYMPHOID" = "#27005c",
					"KIDNEY" = "#96d3a5",
					"LARGE_INTESTINE" = "#708400",                             
                    "LIVER" = "#97a687",
					"LUNG" = "#8f7459",
					"MATCHED_NORMAL_TISSUE" = "#888888",                                   
					"OESOPHAGUS" = "#62c115" ,
					"OVARY" = "#76a663",
                    "PANCREAS" = "#7bd100",                                     
					"PLACENTA" = "#3e3723"  ,
					"PLEURA" = "#bbe3e8" ,
					"PRIMARY" = "#CCA8CC",                                                  
					"PROSTATE" = "#776538",
					"SALIVARY_GLAND" = "#9fd225",
					"SKIN" = "#be81d0",                                                         
					"SMALL_INTESTINE" = "#be0eb2",
					"SOFT_TISSUE" = "#6149de",
					"STOMACH" = "#9c7f0a",                                                         
                    "TESTIS" = "#000876",
					"THYROID" = "#c7a5bc",
					"UPPER_AERODIGESTIVE_TRACT" = "#00ff14",                                                      
					"URINARY_TRACT" = "#b2c738",
					"UVEA" = "#2b2bd3",
					"VULVA" = "#00c710"
                );

# datatypes which use patients, not samples
druggable.patient.datatypes <- c("clin", "immuno", "drug");