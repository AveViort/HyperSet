op_fl <- "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/gidconv/test.pm";
#convertIDs <- getMatrixWithSelectedIds(inputTable, keys=user_input, type=user_output);
convertIDs <- c("t","addndds")
write.table(convertIDs,file=op_fl,sep="\t",col.names=T,row.names=F,quote=F)
