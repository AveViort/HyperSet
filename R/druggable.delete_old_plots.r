usedDir = '/var/www/html/research/users_tmp/';
plotsDir = '/var/www/html/research/users_tmp/plots/';

sink(file(paste(usedDir, "autoclean_plots.output.Rout", sep=""), open = "wt"), append = F, type = "output");
sink(file(paste(usedDir, "autoclean_plots.message.Rout", sep=""), open = "wt"), append = F, type = "message");

setwd(plotsDir);
# these files must not be deleted
exclusions <- read.delim("do_not_delete.txt", header=FALSE);
exclusions <- exclusions$V1;
print(paste0("Number of exclusions: ", length(exclusions)));
plots <- list.files();
for (plot_name in plots) {
	if (plot_name %in% exclusions) {
		print(paste0(plot_name, " is in exclusions list"));
	} else {
		print(paste0(plot_name, " is marked for delete"));
	}
}