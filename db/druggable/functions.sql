-- FUNCTIONS WHICH RETURN COHORTS, DATATYPES, DRUGS ETC.

-- return all drugs/features and genes for given combination of parameters (for correlations)
CREATE OR REPLACE FUNCTION feature_gene_list(source_n text, data_type text, cohort_n text, platform_n text, screen_name text, sensitivity_m text) RETURNS text AS $$
DECLARE
table_n text;
res_temp text;
res text;
sensitivity_array text array;
i numeric;
BEGIN
res := '';
IF (data_type = '%') AND (cohort_n = '%') AND (platform_n = '%') AND (screen_name = '%')
THEN
FOR res_temp IN EXECUTE 'SELECT id FROM cor_all_ids_' || source_n
LOOP
res := res || '|' || res_temp;
END LOOP;
ELSE
sensitivity_array := string_to_array(sensitivity_m, ',');
FOR table_n IN SELECT table_name FROM cor_guide_table WHERE source=source_n AND datatype LIKE data_type AND cohort LIKE cohort_n AND platform LIKE platform_n AND screen LIKE screen_name AND sensitivity_measure=ANY(sensitivity_array)
LOOP
SELECT genes_features INTO res_temp FROM cor_genes_features WHERE table_name=table_n;
res := res || res_temp;
END LOOP;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- get annotations for all genes (pay attention to condition!), this function is used for qtips
CREATE OR REPLACE FUNCTION annotation_list() RETURNS setof text AS $$
DECLARE
res_id text;
res_annot text;
BEGIN
FOR res_id,res_annot IN SELECT DISTINCT internal_id,annotation FROM synonyms WHERE source='ENSEMBL Gene stable ID'
LOOP
RETURN NEXT res_id || '|' || res_annot;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- get synonyms
CREATE OR REPLACE FUNCTION synonyms_list() RETURNS setof text AS $$
DECLARE
id text;
syn text;
link text;
BEGIN
FOR syn,id, link IN SELECT external_id,internal_id, url FROM synonyms WHERE (id_type='gene') OR (id_type='pathway') OR (id_type='antibody')
LOOP
RETURN NEXT syn || '|' || id || '|' || link;
END LOOP;
-- drugs are special case! We use external_id for them
FOR syn,id, link IN SELECT external_id,external_id, url FROM synonyms WHERE id_type='drug'
LOOP
RETURN NEXT syn || '|' || id || '|' || link;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but for json format
CREATE OR REPLACE FUNCTION synonyms_list_json() RETURNS setof text AS $$
DECLARE
id text;
syn text;
BEGIN
FOR syn,id IN SELECT external_id,internal_id FROM synonyms WHERE (id_type='gene') OR (id_type='pathway') OR (id_type='antibody')
LOOP
RETURN NEXT E'{\"external\":\"' || syn || E'\",\"internal\":\"' || id || E'\"}';
END LOOP;
-- drugs are special case! We use external_id for them
FOR syn,id IN SELECT external_id,external_id FROM synonyms WHERE id_type='drug'
LOOP
RETURN NEXT E'{\"external\":\"' || syn || E'\",\"internal\":\"' || id || E'\"}';
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- retrieve platform and their external names
CREATE OR REPLACE FUNCTION platform_synonyms() RETURNS setof text AS $$
DECLARE
platform_int_name text;
platform_ext_name text;
BEGIN
FOR platform_int_name,platform_ext_name IN SELECT shortname,fullname FROM platform_descriptions WHERE visibility=TRUE
LOOP
RETURN NEXT platform_int_name || '|' || platform_ext_name;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, for datatypes
CREATE OR REPLACE FUNCTION datatype_synonyms() RETURNS setof text AS $$
DECLARE
datatype_int_name text;
datatype_ext_name text;
BEGIN
FOR datatype_int_name,datatype_ext_name IN SELECT shortname,fullname FROM datatype_descriptions WHERE visibility=TRUE
LOOP
RETURN NEXT datatype_int_name || '|' || datatype_ext_name;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- get all possible tissue types for cohort
CREATE OR REPLACE FUNCTION get_tissue_types(cohort_n text) RETURNS setof text AS $$
DECLARE
table_n text;
query text;
res text;
BEGIN
SELECT table_name INTO table_n FROM guide_table WHERE cohort=cohort_n AND type='TISSUE';
query := 'SELECT DISTINCT tissue FROM ' || table_n || ';';
FOR res IN EXECUTE query
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but returns number as well
CREATE OR REPLACE FUNCTION get_tissue_types_n(cohort_n text) RETURNS setof text AS $$
DECLARE
table_n text;
query text;
tissue_name text;
n numeric;
BEGIN
SELECT table_name INTO table_n FROM guide_table WHERE cohort=cohort_n AND type='TISSUE';
query := 'SELECT tissue, COUNT(tissue) AS total FROM ' || table_n || ' GROUP BY tissue ORDER BY total DESC;';
FOR tissue_name, n IN EXECUTE query
LOOP
RETURN NEXT tissue_name || '|' || n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same as get_tissue_types, but with metacodes - does not require cohort name
CREATE OR REPLACE FUNCTION get_tissue_types_meta() RETURNS setof text AS $$
DECLARE
tissue_name text;
n numeric;
BEGIN
FOR tissue_name IN SELECT tissue FROM tissue_counts
LOOP
RETURN NEXT tissue_name;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but with counts
CREATE OR REPLACE FUNCTION get_tissue_types_meta_n() RETURNS setof text AS $$
DECLARE
tissue_name text;
n numeric;
BEGIN
FOR tissue_name, n IN SELECT tissue, counts FROM tissue_counts
LOOP
RETURN NEXT tissue_name || '|' || n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- return available screens for correlation tables
CREATE OR REPLACE FUNCTION screen_list(source_n text, data_type text, cohort_n text, platform_n text, sensitivity_m text) RETURNS setof text AS $$
DECLARE
res text;
sensitivity_array text array;
BEGIN
sensitivity_array := string_to_array(sensitivity_m, ',');
FOR res IN SELECT DISTINCT screen FROM cor_guide_table WHERE source=source_n AND datatype LIKE data_type AND cohort LIKE cohort_n AND platform LIKE platform_n AND sensitivity_measure=ANY(sensitivity_array)
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but for dependent variable
CREATE OR REPLACE FUNCTION response_screen_list(source_n text, cohort_n text, data_type text, platform_n text) RETURNS setof text AS $$
DECLARE
res text;
query text;
BEGIN
query := E'SELECT DISTINCT screen FROM model_guide_table WHERE source=\'' || source_n || E'\'AND cohort=\'' || cohort_n || E'\' AND datatype=\'' || data_type || E'\'';
IF (platform_n <> '') THEN
query := query || E' AND platform=\'' || platform_n || E'\'';
END IF;
query := query || E' AND table_type=\'response\';';
FOR res IN EXECUTE query
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- similiar to previous function, but returns sensitivity measures
CREATE OR REPLACE FUNCTION response_sensitivity_list(source_n text, cohort_n text, data_type text, platform_n text, screen_n text) RETURNS setof text AS $$
DECLARE
res text;
query text;
description text;
BEGIN
query := E'SELECT DISTINCT sensitivity FROM model_guide_table WHERE source=\'' || source_n || E'\'AND cohort=\'' || cohort_n || E'\' AND datatype=\'' || data_type || E'\'';
IF (platform_n <> '') THEN
query := query || E' AND platform=\'' || platform_n || E'\'';
END IF;
IF (screen_n <> '') THEN
query := query || E' AND screen=\'' || screen_n || E'\'';
END IF;
query := query || E' AND table_type=\'response\';';
FOR res IN EXECUTE query
LOOP
SELECT fullname INTO description FROM platform_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- similiar to previous function, but returns survival measures
CREATE OR REPLACE FUNCTION response_survival_list(source_n text, cohort_n text, data_type text, platform_n text, screen_n text, sensitivity_m text) RETURNS setof text AS $$
DECLARE
res text;
query text;
description text;
BEGIN
query := E'SELECT DISTINCT survival FROM model_guide_table WHERE source=\'' || source_n || E'\'AND cohort=\'' || cohort_n || E'\' AND datatype=\'' || data_type || E'\'';
IF (platform_n <> '') THEN
query := query || E' AND platform=\'' || platform_n || E'\'';
END IF;
IF (screen_n <> '') THEN
query := query || E' AND screen=\'' || screen_n || E'\'';
END IF;
IF (sensitivity_m <> '') THEN
query := query || E' AND sensitivity=\'' || sensitivity_m || E'\'';
END IF;
query := query || E' AND table_type=\'response\';';
FOR res IN EXECUTE query
LOOP
SELECT fullname INTO description FROM platform_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description;
END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION response_variable_list(source_n text, cohort_n text, data_type text) RETURNS setof text AS $$
DECLARE
variable_nm text;
query text;
description text;
exclude boolean;
response_flag boolean;
table_n text;
data_types text array;
cohorts text array;
n_samp numeric;
BEGIN
data_types := ARRAY['all', data_type];
cohorts := ARRAY['all', cohort_n];
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'response_variables')
THEN
DELETE FROM response_variables;
ELSE
-- n_samp - number of samples/patients for the given table
CREATE TABLE response_variables (variable_n character varying(256), visible_name character varying(256), n_samp numeric);
END IF;
query := E'SELECT table_name FROM model_guide_table WHERE source=\'' || source_n || E'\'AND cohort=\'' || cohort_n || E'\' AND datatype=\'' || data_type || E'\' AND table_type=\'response\';';
EXECUTE query INTO table_n;
-- if table exists
IF (table_n IS NOT NULL) THEN
EXECUTE 'INSERT INTO response_variables SELECT druggable.INFORMATION_SCHEMA.COLUMNS.column_name,platform_descriptions.fullname,variable_samples.' || cohort_n || E' FROM druggable.INFORMATION_SCHEMA.COLUMNS JOIN platform_descriptions ON (druggable.INFORMATION_SCHEMA.COLUMNS.column_name=platform_descriptions.shortname) JOIN variable_samples ON druggable.INFORMATION_SCHEMA.COLUMNS.column_name=variable_samples.variable_name WHERE (druggable.INFORMATION_SCHEMA.COLUMNS.TABLE_NAME=\'' || table_n || E'\') AND (platform_descriptions.visibility = true);';
FOR variable_nm, description, n_samp IN SELECT * FROM response_variables 
LOOP
SELECT EXISTS (SELECT * FROM no_show_exclusions WHERE cohort=ANY(cohorts) AND datatype=ANY(data_types) AND platform=variable_nm) INTO exclude;
SELECT response INTO response_flag FROM variable_guide_table WHERE variable_name=variable_nm;
IF ((NOT exclude) AND response_flag)
THEN 
RETURN NEXT variable_nm || '|' || description || '|' || n_samp;
END IF;
END LOOP;
-- if table does not exist
ELSE
variable_nm := '|';
RETURN NEXT variable_nm;
END IF;
END;
$$ LANGUAGE plpgsql;

-- families may be defined for certain platforms (variables) or datatypes
CREATE OR REPLACE FUNCTION glmnet_family (response_variable_n text, response_datatype_n text) RETURNS setof text
AS $$
DECLARE
res text;
flag boolean;
BEGIN
SELECT EXISTS (SELECT family FROM glmnet_families_exceptions WHERE response_variable=response_variable_n) INTO flag;
-- if our variable is exceptional
IF flag THEN
FOR res IN SELECT family FROM glmnet_families_exceptions WHERE response_variable=response_variable_n
LOOP
RETURN NEXT res;
END LOOP;
ELSE
-- if variable not exceptional - return families for the datatype
FOR res IN SELECT family FROM glmnet_families WHERE response_datatype=response_datatype_n
LOOP
RETURN NEXT res;
END LOOP;
END IF;
END;
$$ LANGUAGE plpgsql;

-- this version returns platforms and their human-readable names (without sources or data types!)
CREATE OR REPLACE FUNCTION platform_list (cohort_n text, data_type text) RETURNS setof text
AS $$
DECLARE
table_n text;
flag boolean;
exclude boolean;
platform_n text;
description text;
nrows numeric;
notempty numeric;
data_types text array;
cohorts text array;
BEGIN
data_types := ARRAY['all', data_type];
cohorts := ARRAY['all', cohort_n];
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'platforms')
THEN
DELETE FROM platforms;
ELSE
CREATE TABLE platforms (platform character varying(256), visible_name character varying(256));
END IF;
SELECT table_name INTO table_n FROM guide_table WHERE (cohort=cohort_n) AND (type=data_type);
-- if table exists
IF (table_n IS NOT NULL) THEN
EXECUTE E'INSERT INTO platforms SELECT druggable.INFORMATION_SCHEMA.COLUMNS.column_name,platform_descriptions.fullname FROM druggable.INFORMATION_SCHEMA.COLUMNS JOIN platform_descriptions ON (druggable.INFORMATION_SCHEMA.COLUMNS.column_name=platform_descriptions.shortname) WHERE (druggable.INFORMATION_SCHEMA.COLUMNS.TABLE_NAME=\'' || table_n || E'\') AND (platform_descriptions.visibility = true);';
FOR platform_n, description IN SELECT * FROM platforms 
LOOP
SELECT EXISTS (SELECT * FROM no_show_exclusions WHERE cohort=ANY(cohorts) AND datatype=ANY(data_types) AND platform=platform_n) INTO exclude;
IF (NOT exclude)
THEN 
IF NOT (data_type = 'CLIN')
THEN
RETURN NEXT platform_n || '|' || description;
ELSE
-- for CLIN - show platform only if we have data for platform for more than 1/4 of all patients
EXECUTE 'SELECT COUNT (*) FROM ' || table_n || ';' INTO nrows;
EXECUTE 'SELECT COUNT (*) FROM ' || table_n || ' WHERE ' || platform_n || ' IS NOT NULL;' INTO notempty;
-- Pay attention to CAST! Otherwise int/int=int
IF (SELECT CAST(notempty AS FLOAT)/nrows > 0.25)
THEN
RETURN NEXT platform_n || '|' || description;
END IF;  
END IF;
END IF;
END LOOP;
-- if table does not exist
ELSE
platform_n := '|';
RETURN NEXT platform_n;
END IF;
END;
$$ LANGUAGE plpgsql;

-- same, but for correlations
CREATE OR REPLACE FUNCTION cor_platform_list (source_n text, data_type text, cohort_n text, sensitivity_m text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
sensitivity_array text array;
BEGIN
sensitivity_array := string_to_array(sensitivity_m, ',');
-- NOTE that we have to use LIKE, not =, because user can ask for platforms for all datatypes 
FOR res IN SELECT DISTINCT platform FROM cor_guide_table WHERE source=source_n AND datatype LIKE data_type AND cohort LIKE cohort_n AND sensitivity_measure=ANY(sensitivity_array)
LOOP
SELECT fullname INTO description_n FROM platform_descriptions WHERE shortname=lower(res);
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but for models
CREATE OR REPLACE FUNCTION model_platform_list (source_n text, cohort_n text, data_type text) RETURNS setof text
AS $$
DECLARE
table_n text;
exclude boolean;
predictor_flag boolean;
platform_n text;
description text;
data_types text array;
cohorts text array;
BEGIN
data_types := ARRAY['all', data_type];
cohorts := ARRAY['all', cohort_n];
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'model_platforms')
THEN
DELETE FROM model_platforms;
ELSE
CREATE TABLE model_platforms (platform character varying(256), visible_name character varying(256));
END IF;
SELECT table_name INTO table_n FROM model_guide_table WHERE (cohort=cohort_n) AND (datatype=data_type) AND (table_type='predictor');
-- if table exists
IF (table_n IS NOT NULL) THEN
EXECUTE E'INSERT INTO model_platforms SELECT druggable.INFORMATION_SCHEMA.COLUMNS.column_name,platform_descriptions.fullname FROM druggable.INFORMATION_SCHEMA.COLUMNS JOIN platform_descriptions ON (druggable.INFORMATION_SCHEMA.COLUMNS.column_name=platform_descriptions.shortname) WHERE (druggable.INFORMATION_SCHEMA.COLUMNS.TABLE_NAME=\'' || table_n || E'\') AND (platform_descriptions.visibility = true);';
FOR platform_n, description IN SELECT * FROM model_platforms 
LOOP
SELECT EXISTS (SELECT * FROM no_show_exclusions WHERE cohort=ANY(cohorts) AND datatype=ANY(data_types) AND platform=platform_n) INTO exclude;
SELECT predictor INTO predictor_flag FROM variable_guide_table WHERE variable_name=platform_n;
IF ((NOT exclude) AND predictor_flag)
THEN 
RETURN NEXT platform_n || '|' || description;
END IF;
END LOOP;
-- if table does not exist
ELSE
platform_n := '|';
RETURN NEXT platform_n;
END IF;
END;
$$ LANGUAGE plpgsql;

-- same, but for dependent variables
CREATE OR REPLACE FUNCTION response_platform_list (source_n text, cohort_n text, data_type text) RETURNS setof text
AS $$
DECLARE
table_n text;
exclude boolean;
visible boolean;
platform_n text;
description text;
data_types text array;
cohorts text array;
flag boolean;
BEGIN
-- this flag is needed in case if we don't have platforms
flag := TRUE;
data_types := ARRAY['all', data_type];
cohorts := ARRAY['all', cohort_n];
FOR platform_n IN SELECT DISTINCT platform FROM model_guide_table WHERE source=source_n AND cohort=cohort_n AND datatype=data_type AND table_type='response' 
LOOP
SELECT EXISTS (SELECT * FROM no_show_exclusions WHERE cohort=ANY(cohorts) AND datatype=ANY(data_types) AND platform=platform_n) INTO exclude;
SELECT visibility FROM platform_descriptions WHERE shortname=platform_n INTO visible;
IF ((NOT exclude) AND visible)
THEN 
SELECT fullname INTO description FROM platform_descriptions WHERE shortname=platform_n;
RETURN NEXT platform_n || '|' || description;
flag := FALSE;
END IF;
END LOOP;
IF (flag)
THEN
RETURN NEXT '|';
END IF;
END;
$$ LANGUAGE plpgsql;

-- return data types for the given source (we assume that cohort has at least one datatype with visible platforms)
CREATE OR REPLACE FUNCTION datatype_list (cohort_n text) RETURNS setof text
AS $$
DECLARE
res text;
datatable text;
description_n text;
flag boolean;
BEGIN
FOR datatable,res IN SELECT table_name, type FROM guide_table WHERE cohort=cohort_n
LOOP
SELECT table_has_visible_platforms(datatable) INTO flag;
IF (flag=true)
THEN
SELECT fullname INTO description_n FROM datatype_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END IF;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- this function shows if table has any visible platforms 
-- required then we have just 1 row in tab for plots (because we cannot delete row if it is the only one=
CREATE OR REPLACE FUNCTION table_has_visible_platforms (datatable text) RETURNS boolean
AS $$
DECLARE
res boolean;
ids boolean;
offset_v numeric;
BEGIN
SELECT EXISTS (SELECT column_name FROM information_schema.columns A INNER JOIN platform_descriptions B ON A.column_name=B.shortname WHERE A.table_name=datatable AND B.visibility=true) INTO res;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- same as datatype_list, but for correlations
CREATE OR REPLACE FUNCTION cor_datatype_list (source_n text, sensitivity_m text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
sensitivity_array text array;
BEGIN
sensitivity_array := string_to_array(sensitivity_m, ',');
FOR res IN SELECT DISTINCT datatype FROM cor_guide_table WHERE source=source_n AND sensitivity_measure=ANY(sensitivity_array) 
LOOP
SELECT fullname INTO description_n FROM datatype_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but for models; gives only predictors
CREATE OR REPLACE FUNCTION model_datatype_list (source_n text, cohort_n text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
BEGIN
FOR res IN SELECT DISTINCT datatype FROM model_guide_table WHERE source=source_n AND cohort=cohort_n AND table_type='predictor' 
LOOP
SELECT fullname INTO description_n FROM datatype_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but for dependent variable (response)
CREATE OR REPLACE FUNCTION response_datatype_list (source_n text, cohort_n text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
BEGIN
FOR res IN SELECT DISTINCT datatype FROM model_guide_table WHERE source=source_n AND cohort=cohort_n AND table_type='response' 
LOOP
SELECT fullname INTO description_n FROM datatype_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- get correlations and their public names
CREATE OR REPLACE FUNCTION cohort_list (source_n text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
BEGIN
FOR res IN SELECT DISTINCT cohort FROM guide_table WHERE source=source_n ORDER BY cohort ASC 
LOOP
SELECT fullname INTO description_n FROM cohort_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- get cohorts for correlations, used only for TCGA
CREATE OR REPLACE FUNCTION cor_cohort_list (source_n text, datatype_n text, sensitivity_m text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
sensitivity_array text array;
BEGIN
sensitivity_array := string_to_array(sensitivity_m, ',');
FOR res IN SELECT DISTINCT cohort FROM cor_guide_table WHERE source=source_n AND sensitivity_measure=ANY(sensitivity_array) AND datatype LIKE datatype_n ORDER BY cohort ASC 
LOOP
SELECT fullname INTO description_n FROM cohort_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- get cohorts for models
CREATE OR REPLACE FUNCTION model_cohort_list (source_n text) RETURNS setof text
AS $$
DECLARE
res text;
description_n text;
BEGIN
FOR res IN SELECT DISTINCT cohort FROM model_guide_table WHERE source=source_n AND table_type='response' 
LOOP
SELECT fullname INTO description_n FROM cohort_descriptions WHERE shortname=res;
RETURN NEXT res || '|' || description_n;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function to get available transformations for plot axis. Note that "linear" in fact means "no transformations"
CREATE OR REPLACE FUNCTION get_available_transformations(cohort text, datatype text, platform text) RETURNS setof text AS $$
DECLARE
table_name text;
column_type text;
query text;
res text;
BEGIN
query := '';
-- exceptions: datatype/platform in the following table
IF EXISTS(SELECT * FROM data_transform_exclusions WHERE variable_name=datatype OR variable_name=platform)
THEN
-- pay attention: datatypes and platforms are mixed in this table
query := E'SELECT transform_type FROM data_transform_exclusions WHERE variable_name=\'' || datatype || E'\' OR variable_name=\'' || platform || E'\';';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || datatype || E'\';' INTO table_name;
EXECUTE E'SELECT data_type FROM information_schema.columns WHERE table_name=\'' || table_name || E'\' AND column_name=\'' || platform || E'\';' INTO column_type;
query := E'SELECT transform_type FROM data_transform_types WHERE variable_type=\'' || column_type || E'\';';
END IF;
FOR res IN EXECUTE query
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONs TO WORK WITH PLOTS 

CREATE OR REPLACE FUNCTION available_plot_types(platforms text) RETURNS setof text AS $$
DECLARE
n integer;
temp text;
temp_array text array; 
datatypes_array text array;
plots_array text array;
i integer;
BEGIN
temp_array := string_to_array(platforms, ',');
n := array_length(temp_array, 1);
-- plots are offered based on datatypes of platforms combinations
-- datatypes are: continuous, survival, binary, ordered_categorical etc.
-- don't uncomment the following string! This is example of a bug. It will give just 1 result in case of same platforms, e.g. 'snp6,snp6'
--datatypes_array := ARRAY(SELECT datatype FROM platform_descriptions WHERE shortname=ALL(temp_array));
datatypes_array := ARRAY[]::text[];
FOR i IN 1..n
LOOP
FOR temp IN SELECT datatype FROM platform_descriptions WHERE shortname=temp_array[i]
LOOP
datatypes_array[i] := temp;
END LOOP;
END LOOP;
--RAISE notice '%', datatypes_array;
plots_array := ARRAY[]::text[];
-- 1D plots
IF (n =1) THEN
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.datatype1=ANY(datatypes_array)) AND (plot_types.datatype2 IS NULL));
ELSE
-- 2D plots
IF (n=2) THEN
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (((plot_types.datatype1=datatypes_array[1] AND plot_types.datatype2=datatypes_array[2]) OR (plot_types.datatype1=datatypes_array[2] AND plot_types.datatype2=datatypes_array[1])) AND (plot_types.datatype3 IS NULL)));
ELSE
-- 3D plots
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.datatype1=datatypes_array[1] AND plot_types.datatype2=datatypes_array[2] AND plot_types.datatype3=datatypes_array[3]) OR (plot_types.datatype1=datatypes_array[2] AND plot_types.datatype2=datatypes_array[1] AND plot_types.datatype3=datatypes_array[3]) OR (plot_types.datatype1=datatypes_array[2] AND plot_types.datatype2=datatypes_array[3] AND plot_types.datatype3=datatypes_array[1]) OR (plot_types.datatype1=datatypes_array[1] AND plot_types.datatype2=datatypes_array[3] AND plot_types.datatype3=datatypes_array[2]) OR (plot_types.datatype1=datatypes_array[3] AND plot_types.datatype2=datatypes_array[2] AND plot_types.datatype3=datatypes_array[1]) OR (plot_types.datatype1=datatypes_array[3] AND plot_types.datatype2=datatypes_array[1] AND plot_types.datatype3=datatypes_array[2]));
END IF;
END IF;
IF (array_length(plots_array, 1) <> 0)
THEN
FOR i IN 1..array_length(plots_array, 1)
LOOP
RETURN NEXT plots_array[i];
END LOOP;
ELSE
RETURN NEXT NULL;
END IF;
END;
$$ LANGUAGE plpgsql;

-- it is probably better to pass an array, but there are potential problems
-- see this: https://stackoverflow.com/questions/570393/postgres-integer-arrays-as-parameters
-- example of args: 'continuous,survival,,KM'
-- example of condition: '((datatype1='continuous') AND (datatype2='survival') AND (plot='KM')) OR ((datatype1='survival') AND (datatype2='continuous') AND (plot='KM'))'
-- pay attention: no need in escape symbols when passing string from R
CREATE OR REPLACE FUNCTION add_plot_type(args text, condition text) RETURNS boolean AS $$
DECLARE
res boolean;
args_array text array;
BEGIN
args_array := string_to_array(args, ',');
-- check if record already exists
EXECUTE 'SELECT EXISTS (SELECT * FROM plot_types WHERE ' || condition || ');' INTO res;
IF (res = FALSE) THEN 
--RAISE NOTICE 'args_array[1] = %', args_array[1];
IF (args_array[2] = '') THEN
-- 1D plot 
EXECUTE E'INSERT INTO plot_types(datatype1,plot) VALUES(\'' || args_array[1] || E'\',\'' || args_array[4] || E'\');';
ELSE
--RAISE NOTICE 'args_array[2] = %', args_array[2];
IF (args_array[3] = '') THEN
-- 2D plot
EXECUTE E'INSERT INTO plot_types(datatype1,datatype2,plot) VALUES(\'' || args_array[1] || E'\',\'' || args_array[2] || E'\',\'' || args_array[4] || E'\');';
ELSE
-- 3D plot
EXECUTE E'INSERT INTO plot_types(datatype1,datatype2,datatype3,plot) VALUES(\'' || args_array[1] || E'\',\'' || args_array[2] || E'\',\'' || args_array[3] || E'\',\'' || args_array[4] || E'\');';
--RAISE NOTICE 'args_array[3] = %', args_array[3];
END IF;
END IF;
res := TRUE;
ELSE
res := FALSE;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- this function is intended to be used from R
-- example of condition: 'E((platform1='snp6') AND (platform2='affymetrix') AND (plot='scatter')) OR ((platform1='affymetrix') AND (platform2='snp6') AND (plot='scatter'))'
CREATE OR REPLACE FUNCTION remove_plot_type(condition text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
EXECUTE 'SELECT EXISTS (SELECT * FROM plot_types WHERE ' || condition || ';' INTO res;
EXECUTE 'DELETE FROM plot_types WHERE ' || condition || ';';
RETURN flag;
END;
$$ LANGUAGE plpgsql;

-- function to return platform types
-- used by 3D scatter to decide: if z axis is numeric or character
CREATE OR REPLACE FUNCTION get_platform_types(cohort_name text, datatype1 text, platform1 text, datatype2 text DEFAULT '', platform2 text DEFAULT '', datatype3 text DEFAULT '', platform3 text DEFAULT '') RETURNS setof text AS $$
DECLARE
table_n text;
res text;
BEGIN
SELECT table_name INTO table_n FROM guide_table WHERE cohort=cohort_name AND type=datatype1;
SELECT data_type INTO res FROM information_schema.columns WHERE table_name = table_n AND column_name = platform1;
RETURN NEXT res;
IF (datatype2 <> '') THEN
SELECT table_name INTO table_n FROM guide_table WHERE cohort=cohort_name AND type=datatype2;
SELECT data_type INTO res FROM information_schema.columns WHERE table_name = table_n AND column_name = platform2;
RETURN NEXT res;
IF (datatype3 <> '') THEN
SELECT table_name INTO table_n FROM guide_table WHERE cohort=cohort_name AND type=datatype3;
SELECT data_type INTO res FROM information_schema.columns WHERE table_name = table_n AND column_name = platform3;
RETURN NEXT res;
END IF;
END IF;
END;
$$ LANGUAGE plpgsql;

-- additional functions to find datatypes for the given platform
CREATE OR REPLACE FUNCTION find_datatype_for_platform(platform text) RETURNS setof text AS $$
DECLARE
table_n text;
datatype_n text;
datatype_array text array;
flag boolean;
BEGIN
datatype_array := ARRAY[]::text[];
FOR table_n, datatype_n IN SELECT table_name,type FROM guide_table
LOOP
IF NOT (SELECT datatype_n = ANY (datatype_array))
THEN
EXECUTE E'SELECT EXISTS (SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' AND column_name=\'' || platform || E'\');' INTO flag;
IF (flag=true)
THEN
SELECT array_append(datatype_array, datatype_n) INTO datatype_array;
END IF;
END IF;
END LOOP;
IF (array_length(datatype_array, 1) <> 0)
THEN
FOR i IN 1..array_length(datatype_array, 1)
LOOP
RETURN NEXT datatype_array[i];
END LOOP;
ELSE
RETURN NEXT NULL;
END IF;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH CORRELATIONS

CREATE OR REPLACE FUNCTION foo(b text) RETURNS setof text AS $$
DECLARE
a text array;
b_array text array;
query text;
i numeric;
BEGIN
b_array := string_to_array(b, ',');
query := 'SELECT ARRAY (SELECT ' || b_array[1];
FOR i IN 2..array_length(b_array, 1)
LOOP
query := query || E' \|\| \'\|\' \|\| ' || b_array[i]; 
END LOOP;
query := query || ' FROM guide_table)'; 
RAISE notice 'query: %', query;
EXECUTE query INTO a;
FOR i in 1..array_length(a, 1)
LOOP
RETURN NEXT a[i];
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- creates table with ALL unique ids from correlations
CREATE OR REPLACE FUNCTION bar(source text) RETURNS setof text AS $$
DECLARE
table_name text;
res text;
res_array text array;
query text;
i numeric;
BEGIN
query := 'CREATE TABLE cor_all_ids_' || source || ' (id text);';
EXECUTE query;
RAISE NOTICE 'query: %', query;
res_array = ARRAY[]::text[];
FOR table_name IN EXECUTE E'SELECT table_name FROM cor_guide_table WHERE source=\'' || source || E'\';'
LOOP
RAISE NOTICE 'Table: %', table_name;
FOR res IN EXECUTE 'SELECT DISTINCT feature FROM ' || table_name || ';'
LOOP
IF NOT (SELECT res = ANY (res_array))
THEN
SELECT array_append(res_array, res) INTO res_array;
END IF;
END LOOP;
FOR res IN EXECUTE 'SELECT DISTINCT upper(gene) FROM ' || table_name || ';'
LOOP
IF NOT (SELECT res = ANY (res_array))
THEN
SELECT array_append(res_array, res) INTO res_array;
END IF;
END LOOP;
END LOOP;
FOR i IN 1..array_length(res_array, 1)
LOOP
EXECUTE 'INSERT INTO cor_all_ids_' || source || E'(id) VALUES (\'' || res_array[i] || E'\');';
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function to retrieve correlations
-- mindrug is a min number of patients which have to be treated with the specific drug to offer KM plot for this drug
-- cor_data_columns is a string with comma-separated columns to use for query 
-- first column is ALWAYS gene
-- second column is ALWAYS feature
-- cor_filter_columns is a string with comma-separated columns to use for filtration
-- concat_op is a string containing either one logical operator or comma-separated string with n-1 operators (n = number of columns in cor_data_columns)
-- limit_by is name of the column by which table will be sorted (one of p-value columns)
-- limit_num is max num of records (e.g. 100 smallest p-values)
CREATE OR REPLACE FUNCTION retrieve_correlations(source_n text, data_type text, cohort_n text, platform_n text, screen_n text, sensitivity_m text, id text, fdr numeric, mindrug numeric, cor_data_columns text, cor_filter_columns text, concat_op text, limit_by text, limit_num numeric) RETURNS setof text AS $$
DECLARE
table_n text;
datatype_name text;
cohort_name text;
platform_name text;
screen_name text;
sensitivity_type text;
res text array;
columns_array text array;
sensitivity_array text array;
filter_cond text;
query text;
temp_table text;
i numeric;
BEGIN
columns_array := string_to_array(cor_data_columns, ',');
sensitivity_array := string_to_array(sensitivity_m, ',');
temp_table := 'cor' || floor(random() * 10000);
--RAISE notice 'temp_table: %', temp_table;
query := 'CREATE TABLE ' || temp_table || '(gene text,feature text,datatype text,cohort text,platform text,screen text,sensitivity text';
FOR i IN 3..array_length(columns_array, 1)
LOOP
query := query || ',' || columns_array[i] || ' numeric';
END LOOP;
query := query ||',url1 text);';
--RAISE notice 'query: %', query;
EXECUTE query;
FOR table_n, datatype_name, cohort_name, platform_name, screen_name, sensitivity_type IN SELECT table_name,datatype,cohort,platform,screen,sensitivity_measure FROM cor_guide_table WHERE datatype LIKE data_type AND cohort LIKE cohort_n AND platform LIKE platform_n AND screen LIKE screen_n AND sensitivity_measure=ANY(sensitivity_array) 
LOOP
--RAISE notice 'table name: %', table_n;
query := 'INSERT INTO ' || temp_table || ' SELECT upper(' || columns_array[1] || ') AS gene,' || columns_array[2] || E' AS feature,\'' || datatype_name || E'\' AS datatype,\'' || cohort_name || E'\' AS cohort,\'' || platform_name || E'\' AS platform, \'' || screen_name || E'\' AS screen' || E',\'' || sensitivity_type || E'\' AS sensitivity';
FOR i IN 3..array_length(columns_array, 1)
LOOP
query := query || ',' || columns_array[i]; 
END LOOP;
query := query || ',get_url(';
IF (datatype_name LIKE '%NEA%') THEN
query := query || columns_array[1];
ELSE
query :=  query || 'upper(' || columns_array[1] || ')';
END IF;
i := array_length(columns_array, 1);
SELECT generate_filter_condition(datatype_name, cor_filter_columns, concat_op, fdr) INTO filter_cond;
query := query || ') AS url1 FROM ' || table_n || E' WHERE ((gene LIKE \'' || id || E'\') OR (feature LIKE \'' || id || E'\')) AND (' || filter_cond || ') ORDER BY ' || limit_by || ' ASC LIMIT ' || limit_num || ';'; 
--RAISE notice 'query: %', query;
EXECUTE query;
END LOOP;
query := 'CREATE TABLE ' || temp_table || '2 AS SELECT * FROM ' || temp_table || ' ORDER BY ' || limit_by || ' LIMIT ' || limit_num || ';';
EXECUTE query;
query := 'DROP TABLE ' || temp_table || ';';
EXECUTE query;
query := E'SELECT ARRAY(SELECT gene \|\| \'\|\' \|\| drug_synonym(feature) \|\| \'\|\' \|\| datatype \|\| \'\|\' \|\| cohort \|\| \'\|\' \|\| platform \|\| \'\|\' \|\| screen \|\| \'\|\' \|\| sensitivity';
FOR i IN 3..array_length(columns_array, 1)
LOOP
query := query || E'\|\| \'\|\' \|\|' || columns_array[i]; 
END LOOP;
query := query || E'\|\| \'\|\' \|\| url1 \|\| \'\|\' \|\| get_url(drug_synonym(feature)) \|\| \'\|\' \|\| retrieve_cohorts_for_drug_extended(LOWER(gene),LOWER(feature),\'' || source_n || E'\',cohort,datatype,platform,screen,sensitivity,' || fdr || ') FROM ' || temp_table || '2);';
--RAISE notice 'query: %', query;
EXECUTE query INTO res;
query := 'DROP TABLE ' || temp_table || '2;';
EXECUTE query;
--RAISE notice '%2', temp_table;
IF array_length(res,1) > 0
THEN
FOR i in 1..array_length(res, 1)
LOOP
--RAISE notice 'res[%]: %', i, res[i];
RETURN NEXT res[i];
END LOOP;
END IF;
END;
$$ LANGUAGE plpgsql;

-- this function is used for batch jobs, it's signature is the same as retrieve_correlations, but most columns are ommited
-- additionally, returns only distinct records
CREATE OR REPLACE FUNCTION retrieve_correlations_simplified(source_n text, data_type text, cohort_n text, platform_n text, screen_n text, sensitivity_m text, id text, fdr numeric, mindrug numeric, cor_columns text, limit_by text, limit_num numeric) RETURNS setof text AS $$
DECLARE
table_n text;
datatype_name text;
cohort_name text;
platform_name text;
screen_name text;
sensitivity_type text;
res text array;
columns_array text array;
sensitivity_array text array;
query text;
temp_table text;
i numeric;
BEGIN
columns_array := string_to_array(cor_columns, ',');
sensitivity_array := string_to_array(sensitivity_m, ',');
temp_table := 'cor' || floor(random() * 10000);
--RAISE notice 'temp_table: %', temp_table;
query := 'CREATE TABLE ' || temp_table || '(gene text,feature text,datatype text,cohort text,platform text,fdr numeric);';
--RAISE notice 'query: %', query;
EXECUTE query;
i := array_length(columns_array, 1);
FOR table_n, datatype_name, cohort_name, platform_name, screen_name, sensitivity_type IN SELECT table_name,datatype,cohort,platform,screen,sensitivity_measure FROM cor_guide_table WHERE datatype LIKE data_type AND cohort LIKE cohort_n AND platform LIKE platform_n AND screen LIKE screen_n AND sensitivity_measure=ANY(sensitivity_array) 
LOOP
--RAISE notice 'table name: %', table_n;
query := 'INSERT INTO ' || temp_table || ' SELECT DISTINCT upper(' || columns_array[1] || ') AS gene,drug_synonym(' || columns_array[2] || E') AS feature,\'' || datatype_name || E'\' AS datatype,\'' || cohort_name || E'\' AS cohort,\'' || platform_name || E'\' AS platform,' || limit_by || E' AS fdr FROM ' || table_n || E' WHERE ((gene LIKE \'' || id || E'\') OR (feature LIKE \'' || id || E'\')) AND (' || columns_array[i] || '<=' || fdr || ') ORDER BY ' || limit_by || ' ASC LIMIT ' || limit_num || ';'; 
--RAISE notice 'query: %', query;
EXECUTE query;
END LOOP;
-- unfortunatelly, cannot use DISTINCT here, refer to this page: https://dba.stackexchange.com/questions/34951/order-by-clause-is-allowed-over-column-that-is-not-in-select-list
query := E'SELECT ARRAY(SELECT gene \|\| \'\|\' \|\| feature \|\| \'\|\' \|\| datatype \|\| \'\|\' \|\| cohort \|\| \'\|\' \|\| platform \|\| \'\|\' \|\| fdr FROM ' || temp_table || ' ORDER BY fdr LIMIT ' || limit_num || ');';
--RAISE notice 'query: %', query;
EXECUTE query INTO res;
query := 'DROP TABLE ' || temp_table || ';';
EXECUTE query;
IF array_length(res,1) > 0
THEN
FOR i in 1..array_length(res, 1)
LOOP
--RAISE notice 'res[%]: %', i, res[i];
RETURN NEXT res[i];
END LOOP;
END IF;
END;
$$ LANGUAGE plpgsql;

-- function to generate filtering conditions for correlations retrieval + cohorts retrieval
CREATE OR REPLACE FUNCTION generate_filter_condition(data_type character varying, cor_filter_columns character varying, concat_op character varying, fdr numeric) RETURNS text AS $$
DECLARE
columns_array text array;
op_array text array;
i numeric;
res text;
BEGIN
columns_array := string_to_array(cor_filter_columns, ',');
op_array := string_to_array(concat_op, ',');
IF (array_length(op_array,1) = 1)
THEN
FOR i IN 2..array_length(columns_array,1)
LOOP
op_array[i] := concat_op;
END LOOP;
END IF;
res := columns_array[1] || '<=' || fdr;
FOR i IN 2..array_length(columns_array,1)
LOOP
res := res || ' ' || op_array[i-1] || ' ' || columns_array[i] || '<=' || fdr;
END LOOP;
IF ((data_type = 'GE_NEA') OR (data_type = 'MUT_NEA'))
THEN
res := res || ' AND meanfeature>1 AND sdevfeature>2';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- function to get cohorts for retrieve_correlations
CREATE OR REPLACE FUNCTION retrieve_cohorts_for_drug(target_id character varying, drug_name character varying, data_type character varying, cor_filter_columns character varying, concat_op character varying, coff numeric) RETURNS text AS $$
DECLARE
cohort_n text;
platform_n text;
measure_n text;
query text;
filter_cond text;
res text;
BEGIN
res := '';
query := E'SELECT DISTINCT cohort,platform,measure FROM significant_interactions WHERE feature=\'' || drug_name || E'\' AND id=\'' || target_id || E'\' AND datatype=\'' || data_type || E'\' AND (';
SELECT generate_filter_condition(data_type, cor_filter_columns, concat_op, coff) INTO filter_cond;
query := query || filter_cond || ');'; 
--RAISE notice '%', query;
FOR cohort_n, platform_n, measure_n IN EXECUTE query
LOOP
res := res || cohort_n || '#' || data_type || '#' || platform_n || '#' || measure_n || ',';
END LOOP;
IF (res='') THEN
res := ' ';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- same as retrieve_cohorts_for_drug, but has extended format. It additionally returns:
-- type of plot, cohort
-- first entry is always a plot pointing to self
-- no generate_filter_condition to decrease latency
CREATE OR REPLACE FUNCTION retrieve_cohorts_for_drug_extended(target_id character varying, drug_name character varying, target_source character varying, target_cohort character varying, data_type character varying, target_platform character varying, target_screen character varying, target_measure character varying, coff numeric) RETURNS text AS $$
DECLARE
source_n text;
cohort_n text;
platform_n text;
measure_n text;
screen_n text;
query text;
filter_cond text;
res text;
temp_flag boolean;
verification_flag boolean;
BEGIN
res := '';
verification_flag := FALSE;
IF (target_source = 'CCLE')
THEN
res := 'CCLE#CCLE#' || data_type || '#' || target_platform || '#' || target_screen || ',';
ELSE
-- check if we have data on the 3rd tab to offer KM plot
query := E'SELECT EXISTS (SELECT * FROM information_schema.columns WHERE table_name=\'' || LOWER(target_cohort) || E'_clin\' AND column_name=\'' || target_measure || E'\');';
--RAISE notice '%', query;
EXECUTE query INTO temp_flag;
IF (temp_flag = TRUE)
THEN
res := target_source || '#' || target_cohort || '#' || data_type || '#' || target_platform || '#' || target_measure || ',';
END IF;
END IF;
-- significant TCGA correlations
query := E'SELECT DISTINCT cohort,platform,measure FROM significant_interactions WHERE feature=\'' || drug_name || E'\' AND id=\'' || target_id || E'\' AND datatype=\'' || data_type || E'\' AND (';
filter_cond := 'min_expr_drug_interaction<' || coff;
query := query || filter_cond || E') AND NOT (cohort=\'' || target_cohort || E'\');'; 
--RAISE notice '%', query;
FOR cohort_n, platform_n, measure_n IN EXECUTE query
LOOP
res := res || 'TCGA#' || cohort_n || '#' || data_type || '#' || platform_n || '#' || measure_n || ',';
verification_flag := TRUE;
END LOOP;
-- significant CCLE correlations
query := E'SELECT DISTINCT platform,screen FROM significant_interactions WHERE source=\'CCLE\' AND';
filter_cond := ' ancova_q_2x_feature<' || coff;
query := query || filter_cond;
IF (target_source = 'CCLE')
THEN
query := query || E' AND NOT (screen=\'' || target_screen || E'\')';
END IF;
query := query || E' AND datatype=\'' || data_type || E'\' AND id=\'' || target_id || E'\' AND feature=\'' || drug_name || E'\';';
--RAISE notice '%', query;
FOR platform_n,screen_n IN EXECUTE query
LOOP
res := res || 'CCLE#CCLE#' || data_type || '#' || platform_n || '#' || screen_n || ',';
verification_flag := TRUE;
END LOOP;
IF (verification_flag = TRUE)
THEN
res := res || 'yes';
ELSE
res := res || ' ';
END IF;
res := res || ',';
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- addition to previous function: this function allows to find data in significant interactions which is not represented in CLIN tables
-- e.g. we had data for LUSC-RFS in significant results,  
CREATE OR REPLACE FUNCTION missing_measurment_types() RETURNS setof text AS $$
DECLARE
record_count numeric;
cohort_n text;
measure_n text;
table_n text;
flag numeric;
query text;
res text;
BEGIN
FOR cohort_n, measure_n IN SELECT DISTINCT cohort, measure FROM significant_interactions WHERE source='TCGA'
LOOP
table_n := LOWER(cohort_n) || '_clin';
query := E'SELECT COUNT (druggable.INFORMATION_SCHEMA.COLUMNS.column_name) FROM druggable.INFORMATION_SCHEMA.COLUMNS JOIN platform_descriptions ON (druggable.INFORMATION_SCHEMA.COLUMNS.column_name=platform_descriptions.shortname) WHERE (druggable.INFORMATION_SCHEMA.COLUMNS.TABLE_NAME=\'' || table_n || E'\') AND (platform_descriptions.visibility = true) AND (druggable.INFORMATION_SCHEMA.COLUMNS.column_name=\'' || LOWER(measure_n) || E'\');';
EXECUTE query INTO flag;
IF (flag = 0) THEN
SELECT COUNT (*) FROM significant_interactions WHERE (cohort=cohort_n) AND (measure=measure_n) INTO record_count;
res := 'Missing measure ' || measure_n || ' for cohort ' || cohort_n || ' (' || record_count || ' records)';
RETURN NEXT res;
END IF;
END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION drug_synonym(drug text) RETURNS text AS $$
DECLARE
res text;
syn text;
BEGIN
-- external_id=drug is weird, but otherwise we have problems with retrieving correlations
FOR syn IN SELECT external_id FROM synonyms WHERE (internal_id=drug OR external_id=drug OR internal_id=LOWER(drug)) AND id_type='drug'
LOOP
res := syn;
END LOOP;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_url(ext_id text) RETURNS text AS $$
DECLARE
res text;
link text;
BEGIN
FOR link IN SELECT url FROM synonyms WHERE (external_id=ext_id)
LOOP
res := link;
END LOOP;
RETURN res;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH AUTOCOMPLETE

-- function returns ids for autocomplete in web interface
CREATE OR REPLACE FUNCTION autocomplete_ids(cohort text, platform text) RETURNS setof text AS $$
BEGIN
RETURN QUERY EXECUTE 'SELECT ' || platform || E' FROM druggable_ids WHERE cohort=\''|| cohort || E'\' AND ' || platform || ' IS NOT NULL;';
END;
$$ LANGUAGE plpgsql;

-- same, but "simplified" version: limited types of synonyms, <br> as separator, no whitespaces
CREATE OR REPLACE FUNCTION autocomplete_ids_simplified(cohort text, platform text) RETURNS setof text AS $$
BEGIN
RETURN QUERY EXECUTE 'SELECT ' || platform || E' FROM druggable_ids_compact WHERE cohort=\''|| cohort || E'\' AND ' || platform || ' IS NOT NULL;';
END;
$$ LANGUAGE plpgsql;

-- function to create strings for autocomplete. Note that all ids are stored as a string with separators for the given cohort, datatype and platform
CREATE OR REPLACE FUNCTION create_ids_for_platform(cohort text, datatype text, platform text) RETURNS text AS $$
DECLARE
res text;
id_string text;
data_table text;
flag boolean;
query_string text;
id_synonym text;
BEGIN
res := '';
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || datatype || E'\';' INTO data_table;
EXECUTE E'SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=\'druggable_ids\' AND column_name=\'' || platform || E'\');' INTO flag;
IF (flag=false) THEN
EXECUTE 'ALTER TABLE druggable_ids ADD ' || platform || ' text;';
END IF;
IF (datatype='DRUG') THEN
query_string := 'SELECT DISTINCT(drug) FROM ' || data_table || ';';
ELSE
query_string := 'SELECT DISTINCT(id) FROM ' || data_table || ' WHERE ' || platform || ' IS NOT NULL;';
END IF;
FOR id_string IN EXECUTE query_string
LOOP
FOR id_synonym IN EXECUTE E'SELECT external_id FROM synonyms WHERE internal_id=\'' || id_string || E'\' AND source=ANY(ARRAY(SELECT source FROM autocomplete_sources WHERE datatype=\'' || datatype || E'\'));'
LOOP
res := res || '||' || id_synonym;
END LOOP;
END LOOP;
-- very special case - for drugs empty value is also legitimate
IF (platform='drug')
THEN
res := res || '||';
END IF;
-- check if we have values already
--EXECUTE E'SELECT EXISTS(SELECT ' || platform || E' FROM druggable_ids WHERE cohort=\'' || cohort || E'\' AND ' || platform || ' IS NOT NULL);' INTO flag;
EXECUTE E'SELECT EXISTS(SELECT cohort FROM druggable_ids WHERE cohort=\'' || cohort || E'\');' INTO flag;
-- if we have - delete old value
IF (flag=true) THEN
EXECUTE 'UPDATE druggable_ids SET ' || platform || E'=\'' || res || E'\' WHERE cohort=\'' || cohort || E'\';';
ELSE
EXECUTE 'INSERT INTO druggable_ids(cohort,'|| platform || E') VALUES(\'' || cohort || E'\',\'' || res || E'\');';
END IF;
RETURN 'ok';
END;
$$ LANGUAGE plpgsql;

-- automatically run the previous function
CREATE OR REPLACE FUNCTION autocreate_ids(target_cohort text) RETURNS boolean AS $$
DECLARE
datatable text;
datatype text;
platform text;
flag boolean;
temp text;
BEGIN
FOR datatable,datatype IN SELECT table_name,type FROM guide_table WHERE (cohort=target_cohort)
LOOP
SELECT check_ids_availability(datatype) INTO flag;
IF (flag=true) THEN
FOR platform IN SELECT column_name FROM information_schema.columns WHERE table_name=datatable OFFSET 2
LOOP
raise notice 'table name: % datatype: % platform: %', datatable, datatype, platform;
SELECT create_ids_for_platform(target_cohort, datatype, platform) INTO temp;
raise notice 'status: %', temp;
END LOOP;
END IF;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- create ids for ALL cohorts
CREATE OR REPLACE FUNCTION autocreate_ids_all() RETURNS boolean AS $$
DECLARE
cohort_n text;
BEGIN
FOR cohort_n IN SELECT DISTINCT cohort FROM guide_table WHERE cohort<>''
LOOP
raise notice 'Current cohort: %', cohort_n;
PERFORM autocreate_ids(cohort_n);
raise notice '------------';
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- check for tables with missing autocomplete ids
CREATE OR REPLACE FUNCTION check_missing_autocomplete() RETURNS numeric AS $$
DECLARE
datatable text;
cohort_n text;
datatype_n text;
platform_n text;
flag boolean;
visible boolean;
i numeric;
BEGIN
i := 0;
FOR cohort_n IN SELECT DISTINCT cohort FROM guide_table WHERE cohort<>''
LOOP
raise notice 'Current cohort: %', cohort_n;
FOR datatable,datatype_n IN SELECT table_name,type FROM guide_table WHERE (cohort=cohort_n)
LOOP
SELECT check_ids_availability(datatype_n) INTO flag;
IF (flag=true) THEN
FOR platform_n IN SELECT column_name FROM information_schema.columns WHERE table_name=datatable OFFSET 2
LOOP
SELECT visibility INTO visible FROM platform_descriptions WHERE shortname=platform_n;
IF (visible=true)
THEN
EXECUTE 'SELECT EXISTS (SELECT * FROM druggable_ids WHERE ((' || platform_n || ' IS NULL) OR (' || platform_n || E'=\'\')) AND (cohort=\'' || cohort_n || E'\'));' INTO flag;
IF (flag=true)
THEN
raise notice 'Missing ids found. Table name: % datatype: % platform: %', datatable, datatype_n, platform_n;
i = i+1;
END IF;
END IF;
END LOOP;
END IF;
END LOOP;
END LOOP;
RETURN i;
END;
$$ LANGUAGE plpgsql;

-- simplified version of create_ids_for_platform - uses only gene symbols/pathway names/drug names
CREATE OR REPLACE FUNCTION create_ids_for_platform_simplified(cohort text, datatype text, platform text) RETURNS text AS $$
DECLARE
res text;
id_string text;
data_table text;
flag boolean;
query_string text;
id_synonym text;
synonym_type text;
BEGIN
res := '';
synonym_type = '';
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || datatype || E'\';' INTO data_table;
EXECUTE E'SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=\'druggable_ids_compact\' AND column_name=\'' || platform || E'\');' INTO flag;
IF (flag=false) THEN
EXECUTE 'ALTER TABLE druggable_ids_compact ADD ' || platform || ' text;';
END IF;
IF (datatype='DRUG') THEN
query_string := 'SELECT DISTINCT(drug) FROM ' || data_table || ';';
synonym_type := 'Drug';
ELSE
query_string := 'SELECT DISTINCT(id) FROM ' || data_table || ' WHERE ' || platform || ' IS NOT NULL;';
CASE datatype
WHEN 'PE' THEN synonym_type := 'RPPA';
WHEN 'SENS' THEN synonym_type := 'Drug';
WHEN 'NEA_MUT' THEN synonym_type := '1469 pathways';
WHEN 'NEA_GE' THEN synonym_type := '1469 pathways';
ELSE synonym_type := 'Gene symbol';
END CASE;
END IF;
FOR id_string IN EXECUTE query_string
LOOP
FOR id_synonym IN EXECUTE E'SELECT external_id FROM synonyms WHERE internal_id=\'' || id_string || E'\' AND source=\'' || synonym_type || E'\';'
LOOP
res := res || '<br>' || id_synonym;
END LOOP;
END LOOP;
--EXECUTE E'SELECT EXISTS(SELECT ' || platform || E' FROM druggable_ids_compact WHERE cohort=\'' || cohort || E'\' AND ' || platform || ' IS NOT NULL);' INTO flag;
EXECUTE E'SELECT EXISTS(SELECT cohort FROM druggable_ids_compact WHERE cohort=\'' || cohort || E'\');' INTO flag;
-- if we have - delete old value
IF (flag=true) THEN
EXECUTE 'UPDATE druggable_ids_compact SET ' || platform || E'=\'' || res || E'\' WHERE cohort=\'' || cohort || E'\';';
ELSE
EXECUTE 'INSERT INTO druggable_ids_compact(cohort,'|| platform || E') VALUES(\'' || cohort || E'\',\'' || res || E'\');';
END IF;
RETURN 'ok';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION autocreate_ids_simplified(target_cohort text) RETURNS boolean AS $$
DECLARE
datatable text;
datatype text;
platform text;
flag boolean;
temp text;
platform_offset numeric;
BEGIN
FOR datatable,datatype IN SELECT table_name,type FROM guide_table WHERE (cohort=target_cohort)
LOOP
platform_offset := 2;
SELECT check_ids_availability(datatype) INTO flag;
IF (datatype='DRUG') THEN
platform_offset := 1;
flag := TRUE;
END IF;
IF (flag=true) THEN
FOR platform IN SELECT column_name FROM information_schema.columns WHERE table_name=datatable OFFSET platform_offset
LOOP
raise notice 'table name: % datatype: % platform: %', datatable, datatype, platform;
SELECT create_ids_for_platform_simplified(target_cohort, datatype, platform) INTO temp;
raise notice 'status: %', temp;
END LOOP;
END IF;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION autocreate_ids_all_simplified() RETURNS boolean AS $$
DECLARE
cohort_n text;
BEGIN
FOR cohort_n IN SELECT DISTINCT cohort FROM guide_table WHERE cohort<>''
LOOP
raise notice 'Current cohort: %', cohort_n;
PERFORM autocreate_ids_simplified(cohort_n);
raise notice '------------';
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- function to check if dataset has ids or not
CREATE OR REPLACE FUNCTION check_ids_availability(datatype text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
SELECT has_ids INTO res FROM type_ids WHERE data_type=datatype;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- this function updates table which is used for connection between "Significant results" tab and TCGA data
CREATE OR REPLACE FUNCTION tcga_count_drugs() RETURNS boolean AS $$
DECLARE
table_n text;
cohort_n text;
BEGIN
DELETE FROM drug_counts;
FOR table_n, cohort_n IN SELECT table_name,cohort FROM guide_table WHERE (source='TCGA') AND (type='DRUG')
LOOP
EXECUTE E'INSERT INTO drug_counts SELECT drug,\'' || cohort_n || E'\',count(drug) FROM ' || table_n || ' GROUP BY drug;';
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH PLATFORM DESCRIPTIONS, VISIBILITY ETC.

-- this functions adds ALL platforms to platform_descriptions and makes them visible
-- use ONLY for initialization! Does not add platform types!
CREATE OR REPLACE FUNCTION import_platforms() RETURNS boolean AS $$
DECLARE
table_n text;
platform_n text;
data_type text;
offset_v integer;
platforms_array text array;
i integer;
BEGIN
platforms_array := ARRAY[]::text[];
DELETE FROM platform_descriptions;
FOR table_n IN SELECT table_name FROM guide_table WHERE cohort IS NOT NULL
LOOP
EXECUTE E'SELECT type FROM guide_table WHERE table_name=\'' || table_n || E'\';' INTO data_type;
IF (SELECT check_ids_availability(data_type) = true) THEN
offset_v := 2;
ELSE
offset_v := 1;
END IF;
FOR platform_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset_v || ';'
LOOP
IF NOT (SELECT platform_n = ANY (platforms_array))
THEN
SELECT array_append(platforms_array, platform_n) INTO platforms_array;
END IF;
END LOOP;
END LOOP;
RAISE NOTICE 'Unique platforms found: %', array_length(platforms_array, 1);
FOR i IN 1..array_length(platforms_array, 1)
LOOP
INSERT INTO platform_descriptions VALUES(platforms_array[i], platforms_array[i], true);
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- this function switches platform visibility
CREATE OR REPLACE FUNCTION display_platform(platform_n text, display boolean) RETURNS boolean AS $$
BEGIN
EXECUTE 'UPDATE platform_descriptions SET visibility=' || display || E' WHERE shortname=\'' || platform_n || E'\';';
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- function to create/update records in platform_descriptions
-- can be used standalone or from R code
CREATE OR REPLACE FUNCTION update_platform_description (platform_n text, fullname text, display boolean, datatype text, description text, stats text) RETURNS boolean AS $$
DECLARE
flag boolean;
BEGIN
EXECUTE E'SELECT EXISTS (SELECT * FROM platform_descriptions WHERE shortname=\'' || platform_n || E'\');' INTO flag;
IF (flag = true)
THEN
EXECUTE E'UPDATE platform_descriptions SET fullname=\'' || fullname || E'\',visibility='|| display || E',datatype=\'' || datatype || E'\'description=\'' || description || E'\',stats=\'' || stats || E'\' WHERE shortname=\'' || platform_n || E'\';';
ELSE
EXECUTE E'INSERT INTO platform_descriptions VALUES (\'' || platform_n || E'\', \'' || fullname || E'\', ' || display || E',\'' || datatype || E'\',\'' || description || E'\',\'' || stats || E'\');';
END IF;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- same for datatypes
CREATE OR REPLACE FUNCTION update_datatype_description (datatype_n text, description text, display boolean) RETURNS boolean AS $$
DECLARE
flag boolean;
BEGIN
EXECUTE E'SELECT EXISTS (SELECT * FROM datatype_descriptions WHERE shortname=\'' || datatype_n || E'\');' INTO flag;
IF (flag = true)
THEN
EXECUTE E'UPDATE datatype_descriptions SET fullname=\'' || description || E'\',visibility='|| display || E' WHERE shortname=\'' || datatype_n || E'\';';
ELSE
EXECUTE E'INSERT INTO datatype_descriptions VALUES (\'' || datatype_n || E'\', \'' || description || E'\', ' || display || ');';
END IF;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- same for cohorts
CREATE OR REPLACE FUNCTION update_cohort_description (cohort_n text, description text, display boolean) RETURNS boolean AS $$
DECLARE
flag boolean;
BEGIN
EXECUTE E'SELECT EXISTS (SELECT * FROM cohort_descriptions WHERE shortname=\'' || cohort_n || E'\');' INTO flag;
IF (flag = true)
THEN
EXECUTE E'UPDATE cohort_descriptions SET fullname=\'' || description || E'\',visibility='|| display || E' WHERE shortname=\'' || cohort_n || E'\';';
ELSE
EXECUTE E'INSERT INTO cohort_descriptions VALUES (\'' || cohort_n || E'\', \'' || description || E'\', ' || display || ');';
END IF;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- function to add an exclusion
-- exclusions are platforms which are not shown for specific cohort and/or datatype
CREATE OR REPLACE FUNCTION add_exclusion (cohort_n text, datatype_n text, platform_n text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
-- pay attention! We don't add a new record if we have more general record existing, i.e. if platform was disabled for all cohorts 
IF EXISTS (SELECT * FROM no_show_exclusions WHERE (cohort=ANY(ARRAY['all', cohort_n])) AND (datatype=ANY(ARRAY['all', datatype_n])) AND (platform=platform_n)) THEN
res := FALSE;
ELSE
INSERT INTO no_show_exclusions VALUES(cohort_n, datatype_n, platform_n);
res := TRUE;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH TCGA DATA

-- function to get TCGA sample codes 
-- if datatype uses patients (not samples) - return emplty string
-- it also takes previous datatypes into account: if one of the chose datatypes
-- uses patients - do not allow meta-codes ("all", "cancer", "healthy")
CREATE OR REPLACE FUNCTION get_tcga_codes(cohort_n text, datatype_n text, platform_n text, previous_datatypes text, previous_platforms text) RETURNS text AS $$
DECLARE
res text;
meta_res text;
temp text;
res_array text array;
temp_array text array;
meta_res_array text array;
meta_temp_array text array;
table_n text;
datatypes_array text array;
platforms_array text array;
source_n text;
i integer;
flag boolean;
BEGIN
res := '';
SELECT source INTO source_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatype_n);
IF (source_n = 'TCGA') THEN
SELECT table_name INTO table_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatype_n);
-- we assume that tcga_codes and tcga_meta_codes are synchronized
IF (EXISTS (SELECT * FROM tcga_codes WHERE table_name = table_n || '_' || platform_n)) THEN
SELECT codes INTO res FROM tcga_codes WHERE table_name = table_n || '_' || platform_n;
SELECT codes INTO meta_res FROM tcga_metacodes WHERE table_name = table_n || '_' || platform_n;
flag := TRUE;
ELSE 
flag := FALSE;
END IF;
IF (previous_datatypes <> '') THEN
datatypes_array := string_to_array(previous_datatypes, ',');
platforms_array := string_to_array(previous_platforms, ',');
res_array := string_to_array(res, ',');
meta_res_array := string_to_array(meta_res, ',');
FOR i IN 1 .. array_length(datatypes_array, 1)
LOOP
SELECT table_name INTO table_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatypes_array[i]);
IF (EXISTS (SELECT * FROM tcga_codes WHERE table_name = table_n || '_' || platforms_array[i])) THEN
SELECT codes INTO temp FROM tcga_codes WHERE table_name = table_n || '_' || platforms_array[i];
temp_array := string_to_array(temp, ',');
IF (array_length(res_array, 1) > 0) THEN
res_array := array_intersect(res_array, temp_array);
ELSE
res_array := temp_array;
END IF;
flag := flag AND TRUE;
ELSE
flag := FALSE;
END IF;
END LOOP;
res := array_to_string(res_array, ',');
END IF;
END IF;
IF (flag = TRUE) THEN
IF (previous_datatypes <> '') THEN
FOR i IN 1 .. array_length(datatypes_array, 1)
LOOP
SELECT table_name INTO table_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatypes_array[i]);
IF (EXISTS (SELECT * FROM tcga_metacodes WHERE table_name = table_n || '_' || platforms_array[i])) THEN
SELECT codes INTO temp FROM tcga_metacodes WHERE table_name = table_n || '_' || platforms_array[i];
temp_array := string_to_array(temp, ',');
meta_res_array := array_intersect(meta_res_array, temp_array);
END IF;
END LOOP;
-- do this to order, so 'all' will be the first
meta_res_array := ARRAY(SELECT unnest(meta_res_array) ORDER BY unnest);
meta_res := array_to_string(meta_res_array, ',');
END IF;
res := meta_res || ',' || res;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- simplified fucntion, but also returns numbers per code
-- USE ONLY FOR MULTISELECTOR!
CREATE OR REPLACE FUNCTION get_tcga_codes_n(cohort_n text, datatype_n text, platform_n text) RETURNS text AS $$
DECLARE
res text;
-- we have a special result variable for meta-codes, sp they will be in order all-healthy-cancer and before the actual codes
meta_res text;
temp_codes text;
temp_n text;
codes_array text array;
n_array text array;
table_n text;
source_n text;
i integer;
flag boolean;
BEGIN
res := '';
meta_res := '';
SELECT source INTO source_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatype_n);
IF (source_n = 'TCGA') THEN
SELECT table_name INTO table_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatype_n);
IF (EXISTS (SELECT * FROM tcga_codes WHERE table_name = table_n || '_' || platform_n)) THEN
SELECT codes INTO temp_codes FROM tcga_codes WHERE table_name = table_n || '_' || platform_n;
SELECT counts INTO temp_n FROM tcga_codes WHERE table_name = table_n || '_' || platform_n;
codes_array := string_to_array(temp_codes, ',');
n_array := string_to_array(temp_n, ',');
res := codes_array[1] || ',' || n_array [1];
FOR i in 2 .. array_length(codes_array, 1)
LOOP
res := res || ',' || codes_array[i] || ',' || n_array[i];
END LOOP;
flag := TRUE;
ELSE 
flag := FALSE;
END IF;
IF (flag = TRUE) THEN
SELECT codes INTO temp_codes FROM tcga_metacodes WHERE table_name = table_n || '_' || platform_n;
SELECT counts INTO temp_n FROM tcga_metacodes WHERE table_name = table_n || '_' || platform_n;
codes_array := string_to_array(temp_codes, ',');
n_array := string_to_array(temp_n, ',');
meta_res := codes_array[1] || ',' || n_array [1];
FOR i in 2 .. array_length(codes_array, 1)
LOOP
meta_res := meta_res || ',' || codes_array[i] || ',' || n_array[i];
END LOOP;
res := meta_res || ',' || res;
END IF;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- function to create table with sample codes available for TCGA tables
-- if table contains patients - it is not present here
-- WARNING! This function creates codes for tables, not platforms in tables! Results can be very different!
-- use the new function (create_count_tcga_codes_table) instead
CREATE OR REPLACE FUNCTION create_tcga_codes_table() RETURNS boolean AS $$
DECLARE
table_n text;
table_codes text;
-- this variable is used to test if table contains patients or samples
table_sample text;
flag boolean;
temp_array text array;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'tcga_codes')
THEN
DELETE FROM tcga_codes;
ELSE
CREATE TABLE tcga_codes (table_name character varying(256), codes character varying(256));
END IF;
FOR table_n IN SELECT table_name FROM guide_table WHERE source = 'TCGA'
LOOP
table_codes := '';
RAISE NOTICE 'Table: %', table_n;
EXECUTE 'SELECT sample FROM ' || table_n || ' LIMIT 1;' INTO table_sample;
--RAISE NOTICE 'Chosen sample: %', table_sample;
-- tables with samples have two digits in the end
SELECT table_sample LIKE '%-__' INTO flag;
IF (flag = TRUE) THEN
EXECUTE 'SELECT ARRAY(SELECT DISTINCT (left_trim(sample, 13)) FROM ' || table_n || ');' INTO temp_array;
table_codes := array_to_string(temp_array, ',');
INSERT INTO tcga_codes(table_name, codes) VALUES (table_n, table_codes);
END IF;
RAISE NOTICE 'table_codes: %', table_codes;
END LOOP;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- count samples per code - use it after the previous function (create_tcga_codes_table())
CREATE OR REPLACE FUNCTION count_tcga_codes() RETURNS boolean AS $$
DECLARE
table_n text;
table_codes text;
temp_array text array;
code_counts numeric array;
i numeric;
n numeric;
code_count_str text;
BEGIN
FOR table_n,table_codes IN SELECT table_name,codes FROM tcga_codes 
LOOP
RAISE NOTICE 'Table: %', table_n;
temp_array := string_to_array(table_codes,',');
code_counts := ARRAY[]::numeric[];
FOR i in 1 .. array_length(temp_array,1)
LOOP
EXECUTE 'SELECT COUNT (DISTINCT sample) FROM ' || table_n || E' WHERE sample LIKE \'%-' || temp_array[i] || E'\';' INTO n;
code_counts := array_append (code_counts, n);
RAISE NOTICE '%: %', temp_array[i], code_counts[i];
END LOOP;
code_count_str := array_to_string(code_counts, ',');
UPDATE tcga_codes SET counts=code_count_str WHERE table_name=table_n;
END LOOP;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- this function will add codes for missing tables
CREATE OR REPLACE FUNCTION update_tcga_codes_table() RETURNS boolean AS $$
DECLARE
table_n text;
table_codes text;
-- this variable is used to test if table contains patients or samples
table_sample text;
flag boolean;
temp_array text array;
BEGIN
FOR table_n IN SELECT table_name FROM guide_table WHERE source = 'TCGA'
LOOP
SELECT EXISTS(SELECT * FROM tcga_codes WHERE table_name=table_n) INTO flag;
IF (flag = FALSE)
THEN
table_codes := '';
--RAISE NOTICE 'Table: %', table_n;
EXECUTE 'SELECT sample FROM ' || table_n || ' LIMIT 1;' INTO table_sample;
--RAISE NOTICE 'Chosen sample: %', table_sample;
-- tables with samples have two digits in the end
SELECT table_sample LIKE '%-__' INTO flag;
IF (flag = TRUE) THEN
RAISE NOTICE 'Table: %', table_n;
EXECUTE 'SELECT ARRAY(SELECT DISTINCT (left_trim(sample, 13)) FROM ' || table_n || ');' INTO temp_array;
table_codes := array_to_string(temp_array, ',');
INSERT INTO tcga_codes(table_name, codes) VALUES (table_n, table_codes);
RAISE NOTICE 'table_codes: %', table_codes;
END IF;
END IF;
END LOOP;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_count_tcga_codes_table() RETURNS boolean AS $$
DECLARE
table_n text;
platform_n text;
platform_codes text;
-- this variable is used to test if table contains patients or samples
table_sample text;
flag boolean;
temp_array text array;
code_counts text;
code_count numeric;
i numeric;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'tcga_codes')
THEN
DELETE FROM tcga_codes;
ELSE
CREATE TABLE tcga_codes (table_name character varying(256), codes character varying(256), counts character varying(256));
END IF;
FOR table_n IN SELECT table_name FROM guide_table WHERE source = 'TCGA'
LOOP
RAISE NOTICE 'Table: %', table_n;
EXECUTE 'SELECT sample FROM ' || table_n || ' LIMIT 1;' INTO table_sample;
--RAISE NOTICE 'Chosen sample: %', table_sample;
-- tables with samples have two digits in the end
SELECT table_sample LIKE '%-__' INTO flag;
IF (flag = TRUE) THEN
FOR platform_n IN EXECUTE E'SELECT column_name FROM information_schema.columns A INNER JOIN platform_descriptions B ON A.column_name=B.shortname WHERE A.table_name=\'' || table_n || E'\' AND B.visibility=true'
LOOP
RAISE NOTICE 'platform: %', platform_n;
platform_codes := '';
code_counts := '';
EXECUTE 'SELECT ARRAY(SELECT DISTINCT (left_trim(sample, 13)) FROM ' || table_n || ' WHERE ' || platform_n || ' IS NOT NULL);' INTO temp_array;
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || E' WHERE (sample LIKE \'%-' || temp_array[1] || E'\') AND (' || platform_n || ' IS NOT NULL);' INTO code_count;
platform_codes := platform_codes || temp_array[1];
code_counts := code_counts || code_count;
FOR i IN 2..array_length(temp_array, 1)
LOOP
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || E' WHERE (sample LIKE \'%-' || temp_array[i] || E'\') AND (' || platform_n || ' IS NOT NULL);' INTO code_count;
IF (code_count <> 0)
THEN
platform_codes := platform_codes || ',' || temp_array[i];
code_counts := code_counts || ',' || code_count;
END IF;
END LOOP;
RAISE NOTICE 'platform_codes: %', platform_codes;
INSERT INTO tcga_codes(table_name, codes, counts) VALUES (table_n || '_' || platform_n, platform_codes, code_counts);
END LOOP;
END IF;
END LOOP;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- similar to create_tcga_codes_table + count_tcga_codes (or create_count_tcga_codes_table), but works with meta-codes
CREATE OR REPLACE FUNCTION create_tcga_metacodes_table() RETURNS boolean AS $$
DECLARE
table_n text;
platform_n text;
platform_codes text;
-- this variable is used to test if table contains patients or samples
table_sample text;
flag boolean;
code_count numeric;
code_counts text;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'tcga_metacodes')
THEN
DELETE FROM tcga_metacodes;
ELSE
CREATE TABLE tcga_metacodes (table_name character varying(256), codes character varying(256), counts character varying(256));
END IF;
FOR table_n IN SELECT table_name FROM guide_table WHERE source = 'TCGA'
LOOP
RAISE NOTICE 'Table: %', table_n;
EXECUTE 'SELECT sample FROM ' || table_n || ' LIMIT 1;' INTO table_sample;
-- tables with samples have two digits in the end
SELECT table_sample LIKE '%-__' INTO flag;
IF (flag = TRUE) THEN
-- codes are created for evey visible platform
FOR platform_n IN EXECUTE E'SELECT column_name FROM information_schema.columns A INNER JOIN platform_descriptions B ON A.column_name=B.shortname WHERE A.table_name=\'' || table_n || E'\' AND B.visibility=true'
LOOP
RAISE NOTICE 'platform: %', platform_n;
-- first - all samples
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || ' WHERE ' || platform_n || ' IS NOT NULL;' INTO code_count;
platform_codes := 'all';
code_counts := '' || code_count;
-- second - healthy
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || E' WHERE (sample LIKE \'%-1_\') AND (' || platform_n || ' IS NOT NULL);' INTO code_count;
IF (code_count <> 0)
THEN
platform_codes := platform_codes || ',healthy';
code_counts := code_counts || ',' || code_count;
END IF;
-- third - cancer samples
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || E' WHERE (sample ~ \'-(0[0-9]{1}|20)\') AND (' || platform_n || ' IS NOT NULL);' INTO code_count;
IF (code_count <> 0)
THEN
platform_codes := platform_codes || ',cancer';
code_counts := code_counts || ',' || code_count;
END IF;
-- fourth - metastatic cancer samples 
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || E' WHERE (sample ~ \'-0(6|7)$\') AND (' || platform_n || ' IS NOT NULL);' INTO code_count;
IF (code_count <> 0)
THEN
platform_codes := platform_codes || ',metastatic';
code_counts := code_counts || ',' || code_count;
END IF;
-- last - non-metastatic cancer samples
EXECUTE 'SELECT COUNT(DISTINCT sample) FROM ' || table_n || E' WHERE (sample ~ \'-(0[0-5,8,9]{1})$\') AND (' || platform_n || ' IS NOT NULL);' INTO code_count;
IF (code_count <> 0)
THEN
platform_codes := platform_codes || ',non_metastatic';
code_counts := code_counts || ',' || code_count;
END IF;
RAISE NOTICE 'table_codes: %', platform_codes;
INSERT INTO tcga_metacodes(table_name, codes, counts) VALUES (table_n || '_' || platform_n, platform_codes, code_counts);
END LOOP;
END IF;
END LOOP;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- create table with tissue counts
CREATE OR REPLACE FUNCTION create_tissue_counts_table() RETURNS boolean AS $$
DECLARE
query text;
tissue_name text;
n numeric;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'tissue_counts')
THEN
DELETE FROM tissue_counts;
ELSE
CREATE TABLE tissue_counts (tissue character varying(256), counts numeric);
END IF;
query := 'SELECT tissue, COUNT(tissue) AS total FROM ctd_tissue GROUP BY tissue ORDER BY total DESC;';
FOR tissue_name, n IN EXECUTE query
LOOP
INSERT INTO tissue_counts(tissue,counts) VALUES (tissue_name,n);
END LOOP;
-- add meta-codes
SELECT COUNT (*) INTO n FROM ctd_tissue;
INSERT INTO tissue_counts(tissue,counts) VALUES ('all',n);
SELECT COUNT (*) INTO n FROM ctd_tissue WHERE tissue=ANY('{CENTRAL_NERVOUS_SYSTEM,STOMACH,VULVA,URINARY_TRACT,BREAST,ADRENAL_CORTEX,CERVIX,PROSTATE,ENDOMETRIUM,LARGE_INTESTINE,SKIN,THYROID,TESTIS,LUNG,OESOPHAGUS,HAEMATOPOIETIC_AND_LYMPHOID,LIVER,PLEURA,PANCREAS,AUTONOMIC_GANGLIA,OVARY,UPPER_AERODIGESTIVE_TRACT,UVEA,BILIARY_TRACT,SALIVARY_GLAND,PLACENTA,BONE,KIDNEY,SMALL_INTESTINE,SOFT_TISSUE,PRIMARY}'::text[]);
INSERT INTO tissue_counts(tissue,counts) VALUES ('cancer',n);
SELECT COUNT (*) INTO n FROM ctd_tissue WHERE tissue=ANY('{FIBROBLAST,MATCHED_NORMAL_TISSUE}'::text[]);
INSERT INTO tissue_counts(tissue,counts) VALUES ('healthy',n);
RETURN true;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH SYNONYMS

-- function to create basic synonyms table
CREATE OR REPLACE FUNCTION create_synonyms_table() RETURNS boolean AS $$
DECLARE
table_n text;
id_n text;
datatype text;
synonym_type text;
ids_array text array;
query_string text;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'synonyms')
THEN
DELETE FROM synonyms;
ELSE
CREATE TABLE synonyms (external_id character varying(256), internal_id character varying(256), id_type character varying(256), annotation character varying(256));
END IF;
ids_array := ARRAY[]::text[];
FOR table_n IN SELECT table_name FROM guide_table WHERE cohort IS NOT NULL
LOOP
SELECT type FROM guide_table WHERE table_name=table_n INTO datatype;
-- we exclude CLIN and IMMUNO completely
IF ((datatype<>'CLIN') AND (datatype<>'IMMUNO')) THEN
RAISE NOTICE 'Current table: %', table_n;
IF (datatype='DRUG') THEN
query_string := 'SELECT DISTINCT drug FROM ' || table_n || ';';
ELSE
query_string := 'SELECT DISTINCT id FROM ' || table_n || ';';
END IF;
FOR id_n IN EXECUTE query_string
LOOP
IF NOT (SELECT id_n = ANY (ids_array)) THEN
SELECT array_append(ids_array, id_n) INTO ids_array;
IF (datatype='DRUG') THEN
synonym_type := 'drug';
ELSE
synonym_type := 'gene';
END IF;
INSERT INTO synonyms(external_id, internal_id, id_type) VALUES(id_n, id_n, synonym_type);
END IF;
END LOOP;
END IF;
END LOOP;
RAISE NOTICE 'Unique ids found: %', array_length(ids_array, 1);
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_synonym(visible_name text, internal_name text, syn_type text, annot text, source_n text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
IF EXISTS (SELECT * FROM synonyms WHERE (external_id=visible_name) AND (internal_id=internal_name) AND (source=source_n)) THEN
res := FALSE;
ELSE
INSERT INTO synonyms VALUES(visible_name, internal_name, syn_type, annot);
res := TRUE;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH GENES AND FEATURES - SIMILAR TO SYNONYMS

CREATE OR REPLACE FUNCTION create_genes_features_table() RETURNS boolean AS $$
DECLARE
table_n text;
gene_n text;
feature_n text;
genes text;
features text;
query_string text;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'cor_genes_features')
THEN
DELETE FROM cor_genes_features;
ELSE
CREATE TABLE cor_genes_features (table_name character varying(256), genes_features text);
END IF;
FOR table_n IN SELECT table_name FROM cor_guide_table
LOOP
RAISE NOTICE 'Current table: %', table_n;
genes := '';
features := '';
query_string := 'SELECT DISTINCT upper(gene) FROM ' || table_n || ';';
FOR gene_n IN EXECUTE query_string
LOOP
genes := genes || gene_n || '|';
END LOOP;
query_string := 'SELECT DISTINCT feature FROM ' || table_n || ';';
FOR feature_n IN EXECUTE query_string
LOOP
features := features || feature_n || '|';
END LOOP;
INSERT INTO cor_genes_features(table_name, genes_features) VALUES(table_n, genes || features);
END LOOP;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- same, for one table
CREATE OR REPLACE FUNCTION create_genes_features_single(table_n text) RETURNS boolean AS $$
DECLARE
gene_n text;
feature_n text;
genes text;
features text;
query_string text;
BEGIN
RAISE NOTICE 'Current table: %', table_n;
genes := '';
features := '';
query_string := 'SELECT DISTINCT upper(gene) FROM ' || table_n || ';';
FOR gene_n IN EXECUTE query_string
LOOP
genes := genes || gene_n || '|';
END LOOP;
query_string := 'SELECT DISTINCT feature FROM ' || table_n || ';';
FOR feature_n IN EXECUTE query_string
LOOP
features := features || feature_n || '|';
END LOOP;
INSERT INTO cor_genes_features(table_name, genes_features) VALUES(table_n, genes || features);
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH MODELS

-- function to register table in model_guide_table and register its columns in 
-- t_type is either 'response' or 'predictor'
CREATE OR REPLACE FUNCTION register_model_vars_from_table(t_source text, t_cohort text, t_datatype text, t_type text) RETURNS numeric AS $$
DECLARE
n numeric;
table_n text;
variable_n text;
query text;
flag boolean;
visible boolean;
exclude boolean;
forbidden boolean; 
new_t boolean;
data_types text array;
cohorts text array;
BEGIN
n := 0;
new_t := FALSE;
data_types := ARRAY['all', t_datatype];
cohorts := ARRAY['all', t_cohort];
query := E'SELECT table_name FROM guide_table WHERE source=\'' || t_source || E'\' AND cohort=\'' || t_cohort || E'\' AND type=\'' || t_datatype || E'\';';
EXECUTE QUERY query INTO table_n;
-- check if we have table registered in model_guide_table
query := E'SELECT EXISTS(SELECT * FROM model_guide_table WHERE table_name=\'' || table_n || E'\' AND table_type=\'' || t_type || E'\');';
EXECUTE QUERY query INTO flag;
IF (NOT flag) THEN
INSERT INTO model_guide_table(table_name, source, datatype, cohort, table_type) VALUES (table_n, t_source, t_datatype, t_cohort, t_type);
new_t := TRUE;
END IF;
query := E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\';';
FOR variable_n IN EXECUTE QUERY query
LOOP
SELECT visibility FROM platform_descriptions WHERE shortname=variable_n INTO visible;
SELECT EXISTS (SELECT * FROM no_show_exclusions WHERE cohort=ANY(cohorts) AND datatype=ANY(data_types) AND platform=variable_n) INTO exclude;
EXECUTE E'SELECT EXISTS(SELECT * FROM forbidden_variables WHERE variable_name=\'' || variable_n || E'\' AND ' || t_type || '=TRUE);' INTO forbidden;
IF ((NOT exclude) AND visible AND (NOT forbidden)) THEN
--RAISE notice 'column: %', variable_n;
-- check if we already have this variable
SELECT EXISTS(SELECT * FROM variable_guide_table WHERE variable_name=variable_n) INTO flag;
-- if we don't - add new row to table
IF (NOT flag) THEN
--RAISE notice 'Add variable: %', variable_n;
query := 'INSERT INTO variable_guide_table(variable_name,' || t_type || E') VALUES (\'' || variable_n || E'\', TRUE);';
EXECUTE QUERY query; 
n := n + 1;
ELSE
-- we have a variable - check if it is TRUE or FALSE
query := 'SELECT ' || t_type || E' FROM variable_guide_table WHERE variable_name=\'' || variable_n || E'\';';
EXECUTE QUERY query INTO flag;
IF ((NOT flag) OR (flag IS NULL)) THEN
--RAISE notice 'Update variable: %', variable_n;
query := 'UPDATE variable_guide_table SET ' || t_type || E'=TRUE WHERE variable_name=\'' || variable_n || E'\';';
EXECUTE QUERY query; 
n := n + 1;
ELSE
-- if the table was just registered - still count its variables, otherwise getting 0 can be misleading
IF (new_t) THEN
n := n + 1;
END IF;
END IF;
END IF;
END IF;
END LOOP;
RETURN n;
END;
$$ LANGUAGE plpgsql;

-- calls previous function for all tables for given datatype
CREATE OR REPLACE FUNCTION register_model_vars_from_datatype(t_source text, t_datatype text, t_type text) RETURNS numeric AS $$
DECLARE
n numeric;
temp numeric;
t_cohort text;
BEGIN
n := 0;
FOR t_cohort IN SELECT cohort FROM guide_table WHERE source=t_source AND type=t_datatype
LOOP
temp := register_model_vars_from_table(t_source, t_cohort, t_datatype, t_type);
n := n + temp;
END LOOP;
RETURN n;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH JOB QUEUE

-- return all jids
CREATE OR REPLACE FUNCTION current_jobs() RETURNS setof numeric AS $$
DECLARE
job_id numeric;
BEGIN
FOR job_id IN SELECT jid FROM job_queue
LOOP
RETURN NEXT job_id;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- try to add a new job
-- job_id (jid) is generated by Perl script - this is timestamp (in ms)
-- process_id (pid) is a system pid of parent Perl process 
-- responsible_mail is specified by user (one user = one job)
-- max_jobs is a max number of jobs in queue (including running job) defined in Aconfig.pm
CREATE OR REPLACE FUNCTION add_job(job_id numeric, process_id numeric, responsible_mail text, max_jobs numeric) RETURNS text AS $$
DECLARE
res text;
current_num numeric;
BEGIN
res := '';
SELECT COUNT (*) INTO current_num FROM job_queue;
IF (current_num >= max_jobs)
THEN
res := 'max_capacity_reached';
ELSE
-- if we have 0 jobs - we can start the job right away
IF (current_num = 0)
THEN
INSERT INTO job_queue(jid,pid,mail) VALUES (job_id, process_id, responsible_mail);
res := 'start';
ELSE
-- check if user already has other registered jobs
SELECT COUNT (*) INTO current_num FROM job_queue WHERE mail=responsible_mail;
IF (current_num > 0)
THEN
res := 'user_declined';
ELSE
INSERT INTO job_queue(jid,pid,mail) VALUES (job_id, process_id, responsible_mail);
res := 'scheduled';
END IF;
END IF;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- remove job using provided jid
CREATE OR REPLACE FUNCTION remove_job(job_id numeric) RETURNS boolean AS $$
BEGIN
DELETE FROM job_queue WHERE jid=job_id;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- check which job is running now - this function is used for creating wait loop in Perl
CREATE OR REPLACE FUNCTION running_job() RETURNS numeric AS $$
DECLARE
earliest_registered numeric;
BEGIN
-- since jids are time in ms - select the earliest registered job using MIN
SELECT MIN(jid) INTO earliest_registered FROM job_queue;
RETURN earliest_registered;
END;
$$ LANGUAGE plpgsql;



-- ADDITIONAL FUNCTIONS

-- function to find forbidden values and substitute them with NULL values
CREATE OR REPLACE FUNCTION substitute_forbidden_values() RETURNS boolean AS $$
DECLARE
table_n text;
platform_n text;
forbidden_values text;
n numeric;
BEGIN
forbidden_values := '{"[Not Applicable]", "[Not Evaluated]"}';
n := 0;
FOR table_n IN SELECT table_name FROM guide_table
LOOP
FOR platform_n IN SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE (table_name=table_n) AND ((data_type='text') OR (data_type='character varying'))
LOOP
EXECUTE 'SELECT COUNT (*) FROM ' || table_n || ' WHERE ' || platform_n || E'=ANY(\'' || forbidden_values || E'\');' INTO n;
IF (n>0)
THEN
RAISE NOTICE 'Table: % Platform: % Number of forbidden values to substitute: %', table_n, platform_n, n;
EXECUTE 'UPDATE ' || table_n || ' SET ' || platform_n || '=NULL WHERE ' || platform_n || E'=ANY(\'' || forbidden_values || E'\');';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- this function hides platforms which consist only of NULL values by adding them to no_show_exclusions
CREATE OR REPLACE FUNCTION hide_empty_platforms() RETURNS numeric AS $$
DECLARE
table_n text;
cohort_n text;
datatype_n text;
platform_n text;
n numeric;
visibility_flag boolean;
exclusion_flag boolean;
empty_flag boolean;
BEGIN
n := 0;
FOR table_n, cohort_n, datatype_n IN SELECT table_name, cohort, type FROM guide_table
LOOP
FOR platform_n IN SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE table_name=table_n
LOOP
-- make sure that platform is not hidden
SELECT visibility FROM platform_descriptions WHERE shortname=platform_n INTO visibility_flag;
SELECT EXISTS (SELECT * FROM no_show_exclusions WHERE (cohort=ANY(ARRAY['all', cohort_n])) AND (datatype=ANY(ARRAY['all', datatype_n])) AND (platform=platform_n)) INTO exclusion_flag;
visibility_flag := visibility_flag AND NOT exclusion_flag;
IF (visibility_flag = TRUE)
THEN
EXECUTE 'SELECT NOT EXISTS (SELECT * FROM ' || table_n || ' WHERE ' || platform_n || ' IS NOT NULL);' INTO empty_flag;
IF (empty_flag = TRUE)
THEN
RAISE NOTICE 'table: % Hiding platform %', table_n, platform_n;
INSERT INTO no_show_exclusions(cohort,datatype,platform) VALUES (cohort_n,datatype_n,platform_n);
n := n + 1;
END IF;
END IF;
END LOOP;
END LOOP;
RETURN n;
END;
$$ LANGUAGE plpgsql;

-- function to create table with "optimal" FDRs
CREATE OR REPLACE FUNCTION create_fdr_table() RETURNS numeric AS $$
DECLARE
res numeric;
i numeric;
j numeric;
k numeric;
l numeric;
opt_fdr numeric;
total_records numeric;
temp numeric;
query text;
table_n text;
source_n text;
cohort_n text;
cohort_array text array;
datatype_array text array;
platform_array text array;
screen_array text array;
measure_array text array;
comb_n text;
BEGIN
IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'optimal_fdrs')
THEN
DELETE FROM optimal_fdrs;
ELSE
CREATE TABLE optimal_fdrs (combination_name character varying(256), fdr numeric);
END IF;
res := 0;
FOR source_n IN SELECT DISTINCT source FROM cor_guide_table
LOOP
RAISE notice 'Source: %', source_n;
IF (source_n = 'CCLE')
THEN
SELECT string_to_array('LN_IC50_INVNORM_ROW,AUC_INVNORM_ROW',',') INTO measure_array;
ELSE
SELECT string_to_array('os,rfs,pfi',',') INTO measure_array;
END IF;
SELECT ARRAY (SELECT DISTINCT datatype FROM cor_guide_table WHERE source=source_n) INTO datatype_array;
IF (source_n = 'TCGA')
THEN
SELECT array_append(datatype_array, '%') INTO datatype_array;
END IF;
FOR i IN 1..array_length(datatype_array, 1)
LOOP
IF (source_n = 'CCLE')
THEN
SELECT string_to_array('all_data', ',') INTO cohort_array;
ELSE
SELECT ARRAY (SELECT DISTINCT cohort FROM cor_guide_table WHERE source=source_n AND datatype LIKE datatype_array[i]) INTO cohort_array;
SELECT array_append(cohort_array, '%') INTO cohort_array;
END IF;
FOR j IN 1..array_length(cohort_array, 1)
LOOP
SELECT ARRAY (SELECT DISTINCT platform FROM cor_guide_table WHERE source=source_n AND datatype LIKE datatype_array[i] AND cohort LIKE cohort_array[j]) INTO platform_array;
SELECT array_append(platform_array, '%') INTO platform_array;
FOR k IN 1..array_length(platform_array, 1)
LOOP
IF (source_n = 'CCLE')
THEN
SELECT ARRAY (SELECT DISTINCT screen FROM cor_guide_table WHERE source=source_n AND datatype LIKE datatype_array[i] AND cohort LIKE cohort_array[j] AND platform LIKE platform_array[k]) INTO screen_array;
SELECT array_append(screen_array, '%') INTO screen_array;
ELSE
SELECT string_to_array('all_data', ',') INTO screen_array;
END IF;
FOR l IN 1..array_length(screen_array, 1)
LOOP
total_records := 10000000;
opt_fdr := 0.05025;
WHILE (total_records>100000) AND (opt_fdr > 0.00025)
LOOP
total_records := 0;
opt_fdr := opt_fdr - 0.00025;
FOR table_n IN SELECT table_name FROM cor_guide_table WHERE source=source_n AND datatype LIKE datatype_array[i] AND cohort LIKE cohort_array[j] AND platform LIKE platform_array[k] AND screen LIKE screen_array[l] AND sensitivity_measure=ANY(measure_array)
LOOP
--RAISE notice '%', table_n;
query := 'SELECT COUNT (*) FROM ' || table_n || ' WHERE ';
IF (source_n='CCLE')
THEN
query := query || 'ancova_q_2x_feature<' || opt_fdr;
ELSE
query := query || 'drug<' || opt_fdr || ' OR expr<' || opt_fdr || ' OR interaction<' || opt_fdr; 
END IF;
query := query || ';';
EXECUTE query INTO temp;
total_records := total_records + temp;
--RAISE notice '%:%', opt_fdr, total_records;
END LOOP;
END LOOP;
res := res + 1;
comb_n := LOWER(source_n) || '_';
IF datatype_array[i]='%'
THEN
comb_n := comb_n || 'all';
ELSE
comb_n := comb_n || LOWER(datatype_array[i]);
END IF;
comb_n := comb_n || '_';
IF (cohort_array[j]='%') OR (cohort_array[j]='all_data')
THEN
comb_n := comb_n || 'all';
ELSE
comb_n := comb_n || LOWER(cohort_array[j]);
END IF;
comb_n := comb_n || '_';
IF platform_array[k]='%'
THEN
comb_n := comb_n || 'all';
ELSE
comb_n := comb_n || LOWER(platform_array[k]);
END IF;
comb_n := comb_n || '_';
IF (screen_array[l]='%') OR (screen_array[l]='all_data')
THEN
comb_n := comb_n || 'all';
ELSE
comb_n := comb_n || LOWER(screen_array[l]);
END IF;
INSERT INTO optimal_fdrs VALUES (comb_n, opt_fdr);
RAISE notice '%: %', comb_n, opt_fdr;
END LOOP;
END LOOP;
END LOOP;
END LOOP;
END LOOP;
RAISE notice 'Checked combinations: %', res;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- additional function for transforming values into TRUE/FALSE
CREATE OR REPLACE FUNCTION binarize (t_value text) RETURNS text AS $$
DECLARE
res text;
BEGIN
IF ((t_value = '') OR (t_value IS NULL)) THEN
res := 'FALSE';
ELSE
res := 'TRUE';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- remove this function after migration to the newer version of PostgreSQL!
-- this function trims n symbols from the right (equal to left(string, -n))
CREATE OR REPLACE FUNCTION right_trim (string text, n integer) RETURNS text AS $$
DECLARE 
res text;
string_length integer;
BEGIN
IF (string = '') THEN
res := '';
ELSE
SELECT length(string) INTO string_length;
string_length := string_length - n;
EXECUTE E'SELECT substring(\'' || string || E'\' FROM 1 FOR ' || string_length || ');' INTO res;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- same, but trims n symbols from the left
CREATE OR REPLACE FUNCTION left_trim (string text, n integer) RETURNS text AS $$
DECLARE 
res text;
string_length integer;
BEGIN
IF (string = '') THEN
res := '';
ELSE
SELECT length(string) INTO string_length;
EXECUTE E'SELECT substring(\'' || string || E'\' FROM ' || n+1 || ' FOR ' || string_length || ');' INTO res;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- intersection of two arrays
-- code taken from https://stackoverflow.com/questions/756871/postgres-function-to-return-the-intersection-of-2-arrays
CREATE FUNCTION array_intersect(anyarray, anyarray)
  RETURNS anyarray
  language sql
as $FUNCTION$
    SELECT ARRAY(
        SELECT UNNEST($1)
        INTERSECT
        SELECT UNNEST($2)
    );
$FUNCTION$;

-- either adds new row or updates the existing row
-- pay attention! val is numeric!
-- true = update, false = insert
CREATE OR REPLACE FUNCTION insert_or_update(table_name text, column_name text, sample_name text, gene_name text, val numeric) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
EXECUTE 'SELECT EXISTS (SELECT * FROM ' || table_name || E' WHERE (sample=\'' || sample_name || E'\') AND (id=\'' || gene_name || E'\') AND (' || column_name || ' IS NULL));' INTO res;
IF (res = FALSE) THEN 
EXECUTE 'INSERT INTO ' || table_name || '(sample,id,' || column_name || E') VALUES(\'' || sample_name || E'\',\'' || gene_name || E'\',' || val || ');';
ELSE
EXECUTE 'UPDATE ' || table_name || ' SET ' || column_name || '=' || val || E' WHERE (sample=\'' || sample_name || E'\') AND (id=\'' || gene_name || E'\');';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- same, but for drugs table, i.e. ctd_drug
CREATE OR REPLACE FUNCTION insert_or_update_drug(table_name text, column_name text, sample_name text, drug_name text, val numeric) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
EXECUTE 'SELECT EXISTS (SELECT * FROM ' || table_name || E' WHERE (sample=\'' || sample_name || E'\') AND (drug=\'' || drug_name || E'\') AND (' || column_name || ' IS NULL));' INTO res;
IF (res = FALSE) THEN 
EXECUTE 'INSERT INTO ' || table_name || '(sample,drug,' || column_name || E') VALUES(\'' || sample_name || E'\',\'' || drug_name || E'\',' || val || ');';
ELSE
EXECUTE 'UPDATE ' || table_name || ' SET ' || column_name || '=' || val || E' WHERE (sample=\'' || sample_name || E'\') AND (drug=\'' || drug_name || E'\');';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- same, for clinical records or other tables without id column
-- this version for numeric values
CREATE OR REPLACE FUNCTION insert_or_update_clin(table_name text, column_name text, sample_name text, val numeric) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
EXECUTE 'SELECT EXISTS (SELECT * FROM ' || table_name || E' WHERE (sample=\'' || sample_name || E'\') AND (' || column_name || ' IS NULL));' INTO res;
IF (res = FALSE) THEN 
EXECUTE 'INSERT INTO ' || table_name || '(sample,' || column_name || E') VALUES(\'' || sample_name || E'\',' || val || ');';
ELSE
EXECUTE 'UPDATE ' || table_name || ' SET ' || column_name || '=' || val || E' WHERE (sample=\'' || sample_name || E'\');';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- this version for char values
CREATE OR REPLACE FUNCTION insert_or_update_clin(table_name text, column_name text, sample_name text, val text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
EXECUTE 'SELECT EXISTS (SELECT * FROM ' || table_name || E' WHERE (sample=\'' || sample_name || E'\') AND (' || column_name || ' IS NULL));' INTO res;
IF (res = FALSE) THEN 
EXECUTE 'INSERT INTO ' || table_name || '(sample,' || column_name || E') VALUES(\'' || sample_name || E'\',\'' || val || E'\');';
ELSE
EXECUTE 'UPDATE ' || table_name || ' SET ' || column_name || E'=\'' || val || E'\' WHERE (sample=\'' || sample_name || E'\');';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- autocreate indices for all tables registered in guide_table
-- it creates indices only for single columns!
CREATE OR REPLACE FUNCTION autocreate_indices_all() RETURNS boolean AS $$
DECLARE
table_n text;
col_n text; 
flag boolean;
BEGIN
FOR table_n in SELECT table_name FROM guide_table
LOOP
FOR col_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\';'
LOOP
RAISE NOTICE 'Creating ids for table % platform %', table_n, col_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || '_' || col_n || E'_ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_' || col_n || '_ind ON ' || table_n || '(' || col_n || ');';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- this function create indices sample-platform for all tables in guide_table
CREATE OR REPLACE FUNCTION autocreate_double_indices_all() RETURNS boolean AS $$
DECLARE
table_n text;
col_n text; 
flag boolean;
BEGIN
FOR table_n in SELECT table_name FROM guide_table
LOOP
-- skip sample column with offset
FOR col_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET 1;'
LOOP
RAISE NOTICE 'Creating ids for table % platforms sample, %', table_n, col_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || '_sample_' || col_n || E'_ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_sample_' || col_n || '_ind ON ' || table_n || '(sample,' || col_n || ');';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- double ind for datatype (sample and id columns only)
CREATE OR REPLACE FUNCTION autocreate_double_indices_datatype(datatype_n text) RETURNS boolean AS $$
DECLARE
table_n text;
BEGIN
FOR table_n in SELECT table_name FROM guide_table WHERE type=datatype_n
LOOP
PERFORM autocreate_double_indices_table(table_n);
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- for one table
CREATE OR REPLACE FUNCTION autocreate_double_indices_table(table_n text) RETURNS boolean AS $$
DECLARE
datatype_n text;
flag boolean;
BEGIN
SELECT type INTO datatype_n FROM guide_table WHERE table_name=table_n;
-- check if table has id column
SELECT has_ids INTO flag FROM type_ids WHERE data_type=datatype_n;
IF (flag=true) THEN
-- skip sample,id columns with offset
RAISE NOTICE 'Creating ids for table % sample, id', table_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || E'_sample_id__ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_sample_id_ind ON ' || table_n || '(sample,id);';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END IF;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- this function create indices sample-id-platform for all tables (which have id column) in guide_table
CREATE OR REPLACE FUNCTION autocreate_triple_indices_all() RETURNS boolean AS $$
DECLARE
datatype_n text;
BEGIN
FOR datatype_n in SELECT DISTINCT type FROM guide_table
LOOP
RAISE NOTICE 'Current datatype: %', datatype_n;
PERFORM autocreate_triple_indices_datatype(datatype_n);
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- triple ind for datatype
CREATE OR REPLACE FUNCTION autocreate_triple_indices_datatype(datatype_n text) RETURNS boolean AS $$
DECLARE
table_n text;
BEGIN
FOR table_n in SELECT table_name FROM guide_table WHERE type=datatype_n
LOOP
PERFORM autocreate_triple_indices_table(table_n);
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- for one table
CREATE OR REPLACE FUNCTION autocreate_triple_indices_table(table_n text) RETURNS boolean AS $$
DECLARE
datatype_n text;
col_n text; 
flag boolean;
BEGIN
SELECT type INTO datatype_n FROM guide_table WHERE table_name=table_n;
-- check if table has id column
SELECT has_ids INTO flag FROM type_ids WHERE data_type=datatype_n;
IF (flag=true) THEN
-- skip sample,id columns with offset
FOR col_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET 2;'
LOOP
RAISE NOTICE 'Creating ids for table % platforms sample, id, %', table_n, col_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || '_sample_id_' || col_n || E'_ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_sample_id_' || col_n || '_ind ON ' || table_n || '(sample,id,' || col_n || ');';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END LOOP;
END IF;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- same for correlations
CREATE OR REPLACE FUNCTION autocreate_indices_cor() RETURNS boolean AS $$
DECLARE
table_n text;
col_n text; 
flag boolean;
BEGIN
FOR table_n in SELECT table_name FROM cor_guide_table
LOOP
FOR col_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\';'
LOOP
RAISE NOTICE 'Creating ids for table % platform %', table_n, col_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || '_' || col_n || E'_ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_' || col_n || '_ind ON ' || table_n || '(' || col_n || ');';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- gene-platform indexes for tables from cor_guide_table
CREATE OR REPLACE FUNCTION autocreate_double_indices_cor() RETURNS boolean AS $$
DECLARE
table_n text;
col_n text; 
flag boolean;
BEGIN
FOR table_n in SELECT table_name FROM cor_guide_table
LOOP
FOR col_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET 1;'
LOOP
RAISE NOTICE 'Creating ids for table % platforms gene, %', table_n, col_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || '_gene_' || col_n || E'_ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_gene_' || col_n || '_ind ON ' || table_n || '(gene,' || col_n || ');';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- same, for gene-feature-platform
-- all tables in cor_guide_table have gene and feature columns
CREATE OR REPLACE FUNCTION autocreate_triple_indices_cor() RETURNS boolean AS $$
DECLARE
table_n text;
col_n text; 
flag boolean;
BEGIN
FOR table_n in SELECT table_name FROM cor_guide_table
LOOP
FOR col_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET 2;'
LOOP
RAISE NOTICE 'Creating ids for table % platforms gene, feature, %', table_n, col_n;
EXECUTE E'SELECT EXISTS (SELECT * FROM  pg_catalog.pg_indexes WHERE indexname=\'' || table_n || '_gene_feature_' || col_n || E'_ind\');' INTO flag;
IF (flag=false)
THEN
EXECUTE E'CREATE INDEX ' || table_n || '_gene_feature_' || col_n || '_ind ON ' || table_n || '(gene,feature,' || col_n || ');';
ELSE
RAISE NOTICE 'Index already exists';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- function to create double/triple indexes for all
CREATE OR REPLACE FUNCTION create_multiple_indexes() RETURNS boolean AS $$
DECLARE
flag boolean;
BEGIN
RAISE notice 'Creating double indexes for tables in guide_table, time: %', clock_timestamp();
SELECT autocreate_double_indices_all() INTO flag;
RAISE notice 'Finished, status: %, time: %', flag, clock_timestamp();
RAISE notice 'Creating triple indexes for tables in guide_table, time: %', clock_timestamp();
SELECT autocreate_triple_indices_all() INTO flag;
RAISE notice 'Finished, status: %, time: %', flag, clock_timestamp();
RAISE notice 'Creating double indexes for tables in cor_guide_table, time: %', clock_timestamp();
SELECT autocreate_double_indices_cor() INTO flag;
RAISE notice 'Finished, status: %, time: %', flag, clock_timestamp();
RAISE notice 'Creating triple indexes for tables in cor_guide_table, time: %', clock_timestamp();
SELECT autocreate_triple_indices_cor() INTO flag;
RAISE notice 'Finished, status: %, time: %', flag, clock_timestamp();
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- this function is designed to control number of empty values in each column of CLIN tables
CREATE OR REPLACE FUNCTION control_clin_columns() RETURNS boolean AS $$
DECLARE
table_n text;
platform_n text;
offset_v numeric;
nrows numeric;
nempty numeric;
ndistinct numeric;
BEGIN
offset_v := 1;
FOR table_n IN SELECT table_name FROM guide_table WHERE type='CLIN'
LOOP
raise notice 'Table: %', table_n;
EXECUTE 'SELECT COUNT (*) FROM ' || table_n || ';' INTO nrows;
raise notice 'Rows: %', nrows;
FOR platform_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset_v || ';'
LOOP
EXECUTE 'SELECT COUNT (*) FROM ' || table_n || ' WHERE ' || platform_n || ' IS NULL;' INTO nempty;
EXECUTE 'SELECT COUNT (DISTINCT ' || platform_n || ') FROM ' || table_n || ';' INTO ndistinct; 
raise notice '% empty rows: % distinct values: %', platform_n, nempty, ndistinct;
END LOOP;
raise notice '---------------';
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- function to automatically report errors and warnings
-- levels are: info, warning, error
CREATE OR REPLACE FUNCTION report_event(e_source text, e_level text, e_description text, e_options text, e_message text, e_client_info text) RETURNS boolean AS $$
DECLARE
stimestamp timestamp;
BEGIN
SELECT LOCALTIMESTAMP INTO stimestamp;
INSERT INTO event_log (event_time, event_source, event_level, event_description, options, message, user_agent) VALUES (stimestamp, e_source, e_level, e_description, e_options, e_message, e_client_info);
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- functions to read log
CREATE OR REPLACE FUNCTION read_event_log(pass text) RETURNS setof text AS $$
DECLARE
stimestamp timestamp;
e_source text;
e_level text;
e_description text;
e_options text;
e_message text;
e_client_info text;
e_ack_status boolean;
control text;
BEGIN
SELECT passphrase INTO control FROM passphrases WHERE entity='event_log';
IF (pass=control) THEN
FOR stimestamp, e_source, e_level, e_description, e_options, e_client_info, e_ack_status, e_message IN SELECT * FROM event_log
LOOP
RETURN NEXT stimestamp || '||' || e_source || '||' || e_level || '||' || e_description || '||' || e_options || '||' || e_client_info || '||' || e_ack_status || '||' || e_message;
END LOOP;
ELSE
RETURN NEXT '';
END IF;
END;
$$ LANGUAGE plpgsql;

-- mark event as acknowledged/not acknowledged
CREATE OR REPLACE FUNCTION toggle_event_acknowledgement_status(pass text, e_timestamp timestamp, e_level text, status boolean) RETURNS boolean AS $$
DECLARE
control text;
BEGIN
SELECT passphrase INTO control FROM passphrases WHERE entity='event_log';
IF (pass=control) THEN
UPDATE event_log SET acknowledged=status WHERE event_time=e_timestamp AND event_level=e_level;
RETURN true;
ELSE
RETURN false;
END IF;
END;
$$ LANGUAGE plpgsql;

-- delete event from log
CREATE OR REPLACE FUNCTION delete_event(pass text, e_timestamp timestamp, e_source text, e_level text, e_description text, e_options text, e_client_info text) RETURNS boolean AS $$
DECLARE
control text;
BEGIN
SELECT passphrase INTO control FROM passphrases WHERE entity='event_log';
IF (pass=control) THEN
DELETE FROM event_log WHERE event_time=e_timestamp AND event_source=e_source AND event_level=e_level AND event_description=e_description AND options=e_options AND user_agent=e_client_info;
RETURN true;
ELSE
RETURN false;
END IF;
END;
$$ LANGUAGE plpgsql;

-- function to update variable_samples - this table is used to show how many unique samples each platform has (4th tab)
CREATE OR REPLACE FUNCTION update_variable_samples() RETURNS boolean AS $$
DECLARE
col_n text;
var_n text;
cohort_n text;
table_n text;
n_samp text;
BEGIN
DELETE FROM variable_samples;
FOR var_n IN SELECT variable_name FROM variable_guide_table 
LOOP
INSERT INTO variable_samples(variable_name) VALUES (var_n);
END LOOP;
FOR table_n, cohort_n IN SELECT table_name, cohort FROM guide_table
LOOP
FOR col_n IN SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE table_name=table_n
LOOP
IF EXISTS (SELECT * FROM variable_guide_table WHERE variable_name=col_n)
THEN
EXECUTE 'SELECT COUNT (DISTINCT sample) FROM ' || table_n || ' WHERE ' || col_n || ' IS NOT NULL;' INTO n_samp;
EXECUTE 'UPDATE variable_samples SET ' || cohort_n || '=' || n_samp || E' WHERE variable_name=\'' || col_n || E'\';';
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;


-- FUNCTIONS TO COPY BEHAVIOUR

-- copy variable info: use existing variable as an example
CREATE OR REPLACE FUNCTION copy_variable_info(new_variable text, original_variable text) RETURNS boolean AS $$
DECLARE
predictor_flag boolean;
response_flag boolean;
exception_flag boolean;
exception_family boolean;
flag boolean;
BEGIN
flag := FALSE;
SELECT predictor, response INTO predictor_flag, response_flag FROM variable_guide_table WHERE variable_name=original_variable;
IF (predictor_flag IS NOT NULL) OR (response_flag IS NOT NULL) THEN
flag := TRUE;
INSERT INTO variable_guide_table (variable_name, predictor, response) VALUES (new_variable, predictor_flag, response_flag);
-- check if original_variable has glmnet family defined different from its datatype
-- e.g. CLIN datatype by default has 'cox' family, but 'subtype' platform/variable has 'multinomial' family
SELECT EXISTS (SELECT * FROM glmnet_families_exceptions WHERE response_variable=original_variable) INTO exception_flag;
IF (exception_flag) THEN
-- normally we have only 1 family for variable, but this may be changed in future
FOR exception_family IN SELECT family FROM glmnet_families_exceptions WHERE response_variable=original_variable
LOOP
INSERT INTO glmnet_families_exceptions(response_variable,family) VALUES (new_variable,exception_family);
END LOOP;
END IF;
END IF;
RETURN flag;
END;
$$ LANGUAGE plpgsql;


-- DEPRECATED FUNCTIONS
