# export re to SQL - global variable!
export_ccle_cor <- function(rch) {
  print(paste0("Job started: ", Sys.time()))
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
}

# /home/proj/func/Druggable/EXPORT/survXdrug.NEA.TCGA.2019-12-10.RData
# source is TCGA, CCLE etc.
export_surv_cor <- function(file_name, source, rch) {
  print(Sys.time());
  query <- "";
  load(file_name);
  cohorts <- names(survXdrug);
  for (cohort in cohorts) {
    print(cohort);
    datatypes <- names(survXdrug[[cohort]]);
    for (datatype in datatypes) {
      print(datatype);
      platforms <- names(survXdrug[[cohort]][[datatype]]);
      for (platform in platforms) {
        print(platform);
        measures <- names(survXdrug[[cohort]][[datatype]][[platform]]);
        for (measure in measures) {
          print(measure);
          table_name <- paste0("cor_", tolower(cohort), "_", tolower(gsub("\\.", "\\_", datatype)), "_", tolower(gsub("\\.", "\\_", platform)), "_", tolower(measure))
          query <- paste0("CREATE TABLE ", table_name," (gene character varying(256), feature character varying(256), followup_part numeric, interaction numeric, drug numeric, expr numeric, n_patients numeric, n_treated numeric, followup numeric);");
          print(query);
          stat <- sqlQuery(rch, query);
          #if (length(stat) != 0) {
          #  print(paste0("Error. Query: ", query));
          #  print(stat);
          #}
          query <- paste0("INSERT INTO cor_guide_table(table_name,source,cohort,datatype,platform,formation_method,screen,sensitivity_measure) VALUES('", table_name, "','", source, "','", cohort, "','", gsub("\\.", "\\_", datatype), "','", gsub("\\.", "\\_", platform), "','all_data','all_data','", tolower(measure),"');")
          print(query);
          stat <- sqlQuery(rch, query);
          if (length(stat) != 0) {
            print(paste0("Error. Query: ", query));
          }
          followup_parts <- names(survXdrug[[cohort]][[datatype]][[platform]][[measure]]);
          for (followup_part in followup_parts) {
            print(followup_part);
            genes <- rownames(survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["drug"]]);
            features <- colnames(survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["drug"]]);
            for (gene in genes) {
              for (feature in features) {
                columns <- "gene,feature,followup_part";
                values <- paste0("'", gsub("\\'", "", gene), "','", gsub("\\'", "", feature), "',",followup_part);
                drug <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["drug"]][gene,feature];
                if (!is.na(drug)) {
                  columns <- paste0(columns,",drug");
                  values <- paste0(values,",",drug);
                }
                interaction <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["interaction"]][gene,feature];
                if (!is.na(interaction)) {
                  columns <- paste0(columns,",interaction");
                  values <- paste0(values,",",interaction);
                }
                expr <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["expr"]][gene,feature];
                if (!is.na(expr)) {
                  columns <- paste0(columns,",expr");
                  values <- paste0(values,",",expr);
                }
                n_patients <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["meta"]][["N.patients"]];
                if (!is.na(n_patients)) {
                  columns <- paste0(columns,",n_patients");
                  values <- paste0(values,",",n_patients);
                }
                n_treated <-survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["meta"]][["N.treated"]][feature];
                if (!is.na(n_treated)) {
                  columns <- paste0(columns,",n_treated");
                  values <- paste0(values,",",n_treated);
                }
                followup <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["meta"]][["follow.up"]];
                if (!is.na(followup)) {
                  columns <- paste0(columns,",followup");
                  values <- paste0(values,",",followup);
                }
                query <- paste0("INSERT INTO ", table_name, "(", columns, ") VALUES(", values, ");");
                stat <- sqlQuery(rch, query);
                if (length(stat) != 0) {
                  print(paste0("Error. Query: ", query));
                }
              }
            }
          }
        }
      }
    }
    print("----------------------------");
  }
  print(Sys.time());
  odbcClose(rch);
}

# These values are just placeholders!!!
create_fake_q_values <- function(rch) {
  print(Sys.time());
  query <- "SELECT table_name FROM cor_guide_table WHERE source='TCGA';";
  tables <- sqlQuery(rch, query);
  for (table_name in tables$table_name) {
    print(table_name);
    query <- paste0("ALTER TABLE ", table_name, " ADD q numeric;");
    sqlQuery(rch, query);
    query <- paste0("UPDATE ", table_name, " SET q=0.01;");
    sqlQuery(rch, query);
  }
  print(Sys.time());
  odbcClose(rch);
}

clean_tcga_correlation_tables <- function(rch) {
  print(Sys.time());
  query <- "SELECT table_name FROM cor_guide_table WHERE source='TCGA';";
  tables <- sqlQuery(rch, query);
  for (table_name in tables$table_name) {
    print(table_name);
    query <- paste0("SELECT COUNT (*) FROM ", table_name, ";");
    count <- sqlQuery(rch, query)[1,1];
    print(paste0("Before: ", count));
    query <- paste0("DELETE FROM ", table_name, " WHERE interaction IS NULL and drug IS NULL and expr IS NULL;");
    sqlQuery(rch, query);
    query <- paste0("SELECT COUNT (*) FROM ", table_name, ";");
    count <- sqlQuery(rch, query)[1,1];
    print(paste0("After: ", count));
  }
  print(Sys.time());
}

delete_empty_tcga_correlation_tables <- function(rch) {
  print(Sys.time());
  query <- "SELECT table_name FROM cor_guide_table WHERE source='TCGA';";
  tables <- sqlQuery(rch, query);
  deleted <- 0;
  for (table_name in tables$table_name) {
    query <- paste0("SELECT COUNT (*) FROM ", table_name, ";");
    count <- sqlQuery(rch, query)[1,1];
    if (count == 0) {
      print(paste0("Delete table: ", table_name));
      query <- paste0("DROP TABLE ", table_name, ";");
      sqlQuery(rch, query);
      query <- paste0("DELETE FROM cor_guide_table WHERE table_name='", table_name, "';");
      sqlQuery(rch, query);
      deleted <- deleted+1;
    }
  }
  print(paste0("Number of deleted tables: ", deleted));
  print(Sys.time());
}

# synonyms is a named vector containing SQL platform names
# e.g. 
# "BOTH.RPPA" => rppa
# "IlluminaHiSeq_RNASeqV2_log2FPKM" => illuminahiseq_rnaseqv2
# "IlluminaHiSeq_RNASeqV2" => illuminahiseq_rnaseqv2
united_interaction_table <- function(filename, synonyms, rch) {
  print(Sys.time());
  load(filename);
  counter <- 0;
  query <- "CREATE TABLE significant_interactions (id character varying(256), feature character varying(256), cohort character varying (256), datatype character varying (256), platform character varying (256), measure character varying (32), followup_part numeric, interaction numeric, expr numeric, drug numeric);";
  print(query);
  sqlQuery(rch, query);
  cohorts <- names(survXdrug);
  for (cohort in cohorts) {
    print(cohort);
    datatypes <- names(survXdrug[[cohort]]);
    for (datatype in datatypes) {
      print(datatype);
      platforms <- names(survXdrug[[cohort]][[datatype]]);
      for (platform in platforms) {
        sql_platform <- synonyms[platform];
        print(paste0("Orig: ", platform, " SQL: ", sql_platform));
        measures <- names(survXdrug[[cohort]][[datatype]][[platform]]);
        for (measure in measures) {
          print(measure);
          followup_parts <- names(survXdrug[[cohort]][[datatype]][[platform]][[measure]]);
          for (followup_part in followup_parts) {
            print(followup_part);
            features <- colnames(survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["interaction"]]);
            tbl <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["interaction"]];
            for (feature in features) {
                signif_ids <- which((tbl[,feature] < 0.05));
                ids <- rownames(tbl)[signif_ids];
                for (id in ids) {
                  interaction <- tbl[id,feature];
                  columns <- "id,feature,cohort,datatype,platform,measure,followup_part,interaction";
                  values <- paste0("'", gsub("\\'", "", id), "','", gsub("\\'", "", feature), "','", cohort, "','", datatype, "','", synonyms[platform], "','", measure, "',", followup_part, ",", interaction);
                  drug <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["drug"]][id,feature];
                  expr <- survXdrug[[cohort]][[datatype]][[platform]][[measure]][[followup_part]][["expr"]][id,feature];
                  if (!is.na(drug)) {
                    columns <- paste0(columns,",drug");
                    values <- paste0(values,",",drug);
                  }
                  if(!is.na(expr)) {
                    columns <- paste0(columns,",expr");
                    values <- paste0(values,",",expr);
                  }
                  query <- paste0("INSERT INTO significant_interactions(", columns, ") VALUES(", values, ");");
                  stat <- sqlQuery(rch, query);
                  if (length(stat) != 0) {
                    print(paste0("Error. Query: ", query));
                  } else {
                    counter <- counter + 1;
                  }
                }
                
                print(counter);
            }
          }
        }
      }
    }
  }
  print(paste0("Total rows: ", counter));
}

import_sensitivity <- function(data_table, rch, table_name) {
  screens <- names(data_table$CLIN$DRUGSCREEN);
  query <- paste0("CREATE TABLE ", table_name, " (sample character varying(256), id character varying (256)");
  for (screen in screens) {
    query <- paste0(query, ", ", tolower(gsub("\\.", "", screen)), " numeric");
  }
  query <- paste0(query, ");");
  print(query);
  sqlQuery(rch, query);
  for (screen in screens) {
    screen_name <- tolower(gsub("\\.", "", screen));
    sensitivity_measure <- '';
    sensitivity_measure <- switch(screen_name,
      "ctrpv20" = "AUC_INVNORM_LOW",
      "gdsc1" = "LN_IC50_INVNORM_ROW",
      "gdsc2" = "LN_IC50_INVNORM_ROW",
      names(d1$CLIN$DRUGSCREEN[[screen]])[1]
    );
    #print(paste0(screen_name, " ", sensitivity_measure));
    # see the function in db/druggable/functions.sql
    for (sample_name in colnames(data_table$CLIN$DRUGSCREEN[[screen]][[sensitivity_measure]])) {
      for (id in rownames(data_table$CLIN$DRUGSCREEN[[screen]][[sensitivity_measure]])) {
        value <- data_table$CLIN$DRUGSCREEN[[screen]][[sensitivity_measure]][id,sample_name];
        if (!is.na(value)) {
          query <- paste0("SELECT insert_or_update('", table_name, "','", screen_name, "','", sample_name, "','", id, "',", value, ");");
          sqlQuery(rch, query);
        }
      }
    }
  }
}

import_ccle_depmap <- function(data_table, rch) {
  query <- paste0("CREATE TABLE ccle_links (sample character varying(256), depmap_id character varying (256));");
  print(query);
  sqlQuery(rch, query);
  for (i in 1:(nrow(data_table))) {
    query <- paste0("INSERT INTO ccle_links (sample, depmap_id) VALUES ('", tolower(data_table$stripped_cell_line_name[1]), "','", depmap_id$DepMap_ID[i],"');");
    sqlQuery(rch, query);
  }
} 