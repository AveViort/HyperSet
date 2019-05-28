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
# options for plots
druggable.cex = 2;
druggable.cex.error = 10;
druggable.cex.main = 3;
druggable.cex.axis = 1.5;
druggable.cex.lab = 2;
druggable.precision.cor.legend=3;
druggable.precision.pval.legend=2;
druggable.cex.legend = 0.75;