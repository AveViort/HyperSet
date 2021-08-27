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
druggable.cex.main = 1.5;
druggable.cex.sub = 1;
druggable.cex.axis = 1;
druggable.cex.lab = 1.5;
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
  size = 12.5,
  color = "black"
);
font2 <- list(
  family = "Old Standard TT, serif",
  size = 12,
  color = "black"
);
# https://plotly.com/r/legend/
# legend_rows is numeric, number of lines in legend, used to calculate font size
druggable.plotly.legend.style <- function(legend_text, header_text = "") {
	legend_rows <- length(unlist(strsplit(paste0(legend_text, "\n", header_text), "\n")));
	header_font_size <- 12;
	font_size <- 12;
	if (legend_rows > 6) {
		font_size <- ifelse(legend_rows > 10, 8, 14 - 0.4*legend_rows);
		header_font_size <- 9;
	}
	print(paste0("Legend rows: ", legend_rows, " Font size: ", font_size));
	return(list(
		title = list(
			text = header_text,
			size = header_font_size
		),
		x = 100,
		y = 0.95,
		font = list(
			family = "sans-serif",
			size = font_size,
			# color = "#000"
			color = "#222"
		),
		# bgcolor = "#E2E2E2",
		bgcolor = "rgba(0,0,0,0.2)",
		bordercolor = "#FFFFFF",
		borderwidth = 2)
	);
}
	
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
druggable.plotly.brca_colours <- c(
					"HER" = "#49D1A3",
					"Lum A" = "#F79646",
					"Lum B" = "#4BACC6",
					"Lum HER" = "#EEEF46",
					"TNB" = "#47DC57"
				);

# datatypes which use patients, not samples
druggable.patient.datatypes <- c("clin", "immuno", "drug");

# this variable is used to set margins - so annotations will not overlap with axis labels
druggable.margins <- list(
	l = 20,
	r = 10,
	b = 50,
	t = 10,
	pad = 4);
	
# max number of characters in axis labels
druggable.axis.label.threshold <- 90;

# max number of characters in "short" string (otherwise string will be truncated with ... in the end)
druggable.short.string.threshold <- 45;

# custom modebar button - leads to EviNet website
druggable.evinet.modebar <- list(
  name = "This plot was generated on EviCor website",
  icon = list(
    path = 'M17.659,9.597h-1.224c-0.199-3.235-2.797-5.833-6.032-6.033V2.341c0-0.222-0.182-0.403-0.403-0.403S9.597,2.119,9.597,2.341v1.223c-3.235,0.2-5.833,2.798-6.033,6.033H2.341c-0.222,0-0.403,0.182-0.403,0.403s0.182,0.403,0.403,0.403h1.223c0.2,3.235,2.798,5.833,6.033,6.032v1.224c0,0.222,0.182,0.403,0.403,0.403s0.403-0.182,0.403-0.403v-1.224c3.235-0.199,5.833-2.797,6.032-6.032h1.224c0.222,0,0.403-0.182,0.403-0.403S17.881,9.597,17.659,9.597 M14.435,10.403h1.193c-0.198,2.791-2.434,5.026-5.225,5.225v-1.193c0-0.222-0.182-0.403-0.403-0.403s-0.403,0.182-0.403,0.403v1.193c-2.792-0.198-5.027-2.434-5.224-5.225h1.193c0.222,0,0.403-0.182,0.403-0.403S5.787,9.597,5.565,9.597H4.373C4.57,6.805,6.805,4.57,9.597,4.373v1.193c0,0.222,0.182,0.403,0.403,0.403s0.403-0.182,0.403-0.403V4.373c2.791,0.197,5.026,2.433,5.225,5.224h-1.193c-0.222,0-0.403,0.182-0.403,0.403S14.213,10.403,14.435,10.403',
    transform = 'matrix(1 0 0 1 -2 -2) scale(0.9)'
  ),
  click = htmlwidgets::JS(
    "function() {
       window.open('https://www.evinet.org/evicor', '_blank');
    }"
  )
);




