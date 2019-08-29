# export re to SQL
print(paste0("Job started: ", Sys.time()))
rch <- odbcConnect("dg_pg", uid = "hyperset", pwd = "SuperSet");
data_types <- c("MUT");
for (data_type in data_types) {
  inner_datatype <- tolower(data_type);
  #print(paste0("Current datatype: ", inner_data_type));
  platforms <- names(re[[data_type]]);
  for (platform in platforms) {
    # flag to get rid of "garbage" tables (they have no p tables)
    flag <- FALSE;
    # have to delete -
    inner_platform <- tolower(gsub("_", "", platform));
    #print(paste0("Data platform: ", inner_platform));
    for (data_formation_method in names(re[[data_type]][[platform]])) {
      inner_data_formation_method <- tolower(data_formation_method);
      #print(paste0("Data formation method: ", inner_data_formation_method));
      for (drug_screen in names(re[[data_type]][[platform]][[data_formation_method]])) {
        # we don't allow dots here
        dot_pos <- gregexpr("\\.", drug_screen)[[1]][1];
        inner_drug_screen <- tolower(ifelse(dot_pos != -1, substr(drug_screen, 1, dot_pos-1), drug_screen));
        #print(paste0("Drug screen: ", inner_drug_screen));
        for (sensitivity_measure in names(re[[data_type]][[platform]][[data_formation_method]][[drug_screen]])) {
          inner_sensitivity_measure <- tolower(gsub("_", "", sensitivity_measure));
          table_name <- paste0("cor_", inner_datatype, "_", inner_platform, "_", inner_data_formation_method, "_", inner_drug_screen, "_", inner_sensitivity_measure);
          #print(table_name);
          query <- paste0("CREATE TABLE ", table_name, " (gene character varying(256), feature character varying(256)");
          for (method in names(re[[data_type]][[platform]][[data_formation_method]][[drug_screen]][[sensitivity_measure]])) {
            # use - instead of _
            inner_method <- tolower(gsub("_", "", method));
            for (p.type in names(re[[data_type]][[platform]][[data_formation_method]][[drug_screen]][[sensitivity_measure]][[method]])) {
              flag <- TRUE;
              inner_p.type <- paste0(inner_method, "_", gsub("\\.", "_", p.type));
              # PAY attention! Change p to q here! Can't change it later due to possible problems - e.g. gsub("p", "q", "p_spearman")
              inner_q.type <- paste0(inner_method, "_", gsub("\\.", "_", gsub("p", "q", p.type)));
              query <- paste0(query, ",", inner_p.type, " numeric, ", inner_q.type, " numeric");
            }
          }
          query <- paste0(query, ");");
          if (flag) {
            print(query);
            sqlQuery(rch, query);
            query <- paste0("INSERT INTO cor_guide_table(table_name,datatype,platform,formation_method,screen,sensitivity_measure) VALUES('",table_name, "','", data_type, "','", platform, "','", data_formation_method, "','", drug_screen, "','", sensitivity_measure, "');");
            print(query);
            sqlQuery(rch, query);
            i <- 0;
            for (method in names(re[[data_type]][[platform]][[data_formation_method]][[drug_screen]][[sensitivity_measure]])) {
              # use - instead of _
              inner_method <- tolower(gsub("_", "", method));
              #print(paste0("Method: ", inner_method));
              temp_p <- re[[data_type]][[platform]][[data_formation_method]][[drug_screen]][[sensitivity_measure]][[method]];
              for (feature in colnames(temp_p$p.2x.feature)) {
                q_vector <- p.adjust(temp_p$p.2x.feature[,feature], method = "BH");
                pick <- names(q_vector)[which((!is.na(q_vector)) & (q_vector < 0.05))];
                for (gene in pick) {
                  columns_to_use <- c();
                  values_to_add <- c();
                  for (p.type in names(temp_p)) {
                    inner_p.type <- paste0(inner_method, "_", gsub("\\.", "_", p.type));
                    inner_q.type <- paste0(inner_method, "_", gsub("\\.", "_", gsub("p", "q", p.type)));
                    temp1 <- NULL;
                    if ((p.type == "p.2x.cov1") | (p.type == "p.1x")) {
                      temp1 <- temp_p[[p.type]][feature,gene];
                    } else {
                      temp1 <- temp_p[[p.type]][gene,feature];
                    }
                    if (p.type != "p.2x.feature") {
                      if (!is.na(temp1)) {
                        columns_to_use <- c(columns_to_use, inner_p.type);
                        values_to_add <- c(values_to_add, temp1);
                      }
                    }
                    else {
                      columns_to_use <- c(columns_to_use, inner_p.type, inner_q.type);
                      values_to_add <- c(values_to_add, temp1, q_vector[gene]);
                    }
                  }
                  query <- paste0("INSERT INTO ", table_name, "(gene,feature");
                  for (used_column in columns_to_use) {
                    query <- paste0(query, ",", used_column);
                  }
                  query <- paste0(query, ") VALUES('", gene, "','", feature, "'");
                  for (insert_value in values_to_add) {
                    query <- paste0(query, ",", insert_value);
                  }
                  query <- paste0(query, ");");
                  sqlQuery(rch, query);
                  i <- i+1;
                }
              }
              print(paste0("Number of records: ", i));
            }
          }
        }
      }
    }
  }
}

odbcClose(rch)
print(paste0("Job finished: ", Sys.time()))
