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

# datatypes which use patients, not samples
druggable.patient.datatypes <- c("clin", "immuno", "drug");