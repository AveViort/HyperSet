.libPaths("/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/dev/HyperSet/R/lib");
library(RODBC);

########################################################################################
# 18:35 b4:/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/pics >>>> ln -s /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/plots/ .
# users_tmp/plots/ is a physical location. 
# Therefore /HyperSet/pics/plots/ must be synchronized with it via  $Aconfig::Rplots->{dir}
r.plots = "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/plots"; 
##########################################################################################
#  These must be also synchronized with perl:
RscriptParameterDelimiter = '###'; 
RscriptKeyValueDelimiter = "=";
RscriptfieldRdelimiter = "+";
##########################################################################################
# options for plots - absolute values
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