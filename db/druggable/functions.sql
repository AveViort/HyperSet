-- FUNCTIONS WHICH RETURNS COHORTS, DATATYPES, DRUGS ETC.

-- return all drugs/features and genes for given combination of parameters
CREATE OR REPLACE FUNCTION feature_gene_list(source_n text, data_type text, platform_n text, screen_name text, sensitivity_m text) RETURNS setof text AS $$
DECLARE
table_name text;
res text;
res_array text array;
i numeric;
BEGIN
res_array = ARRAY[]::text[];
IF (data_type = '%') AND (platform_n = '%') AND (screen_name = '%')
THEN
FOR res IN SELECT id FROM cor_all_ids
LOOP
SELECT array_append(res_array, res) INTO res_array;
END LOOP;
ELSE
FOR table_name IN EXECUTE E'SELECT table_name FROM cor_guide_table WHERE source=\'' || source_n ||  E'\' AND datatype LIKE \'' || data_type || E'\' AND platform LIKE \'' || platform_n || E'\' AND screen LIKE \'' || screen_name || E'\' AND sensitivity_measure LIKE \'' || sensitivity_m || E'\';'
LOOP
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
END IF;
FOR i IN 1..array_length(res_array, 1)
LOOP
RETURN NEXT res_array[i];
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- get annotations for all genes and drugs/features, this function is used for qtips
CREATE OR REPLACE FUNCTION annotation_list() RETURNS setof text AS $$
DECLARE
res_id text;
res_annot text;
BEGIN
FOR res_id,res_annot IN SELECT internal_id,annotation FROM synonyms
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
BEGIN
FOR syn,id IN SELECT external_id,internal_id FROM synonyms WHERE id_type='gene'
LOOP
RETURN NEXT syn || '|' || id;
END LOOP;
-- drugs are special case! We use external_id for them
FOR syn,id IN SELECT external_id,external_id FROM synonyms WHERE id_type='drug'
LOOP
RETURN NEXT syn || '|' || id;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- return available screens for correlation tables
CREATE OR REPLACE FUNCTION screen_list(source_n text, data_type text, platform_n text, sensitivity_m text) RETURNS setof text AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT DISTINCT screen FROM cor_guide_table WHERE source=source_n AND datatype LIKE data_type AND platform LIKE platform_n AND sensitivity_measure=sensitivity_m
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- this version returns platforms and their human-readable names (without sources or data types!)
CREATE OR REPLACE FUNCTION platform_list (cohort_n text, data_type text, previous_platforms text) RETURNS setof text
AS $$
DECLARE
table_n text;
platforms_array text array;
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
platforms_array := string_to_array(previous_platforms, ',');
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
IF NOT (previous_platforms = '')
THEN
SELECT check_platforms_compatibility(platform_n, platforms_array) INTO flag;
IF (flag AND NOT exclude)
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
ELSE
IF NOT (exclude)
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
CREATE OR REPLACE FUNCTION cor_platform_list (source_n text, data_type text, sensitivity_m text) RETURNS setof text
AS $$
DECLARE
res text;
BEGIN
-- NOTE that we have to use LIKE, not =, because user can ask for platforms for all datatypes 
FOR res IN SELECT DISTINCT platform FROM cor_guide_table WHERE source=source_n AND datatype LIKE data_type AND sensitivity_measure=sensitivity_m 
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- return data types for the given source (takes previous datatypes into account)
CREATE OR REPLACE FUNCTION datatype_list (cohort_n text, previous_datatypes text) RETURNS setof text
AS $$
DECLARE
res text;
datatypes_array text array;
flag boolean;
BEGIN
datatypes_array := string_to_array(previous_datatypes, ',');
FOR res IN SELECT type FROM guide_table WHERE cohort=cohort_n
LOOP
IF NOT (previous_datatypes = '')
THEN
SELECT check_datatypes_compatibility(res, datatypes_array) INTO flag;
IF (flag)
THEN 
RETURN NEXT res;
END IF;
ELSE
RETURN NEXT res;
END IF;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- same, but for correlations
CREATE OR REPLACE FUNCTION cor_datatype_list (source_n text, sensitivity_m text) RETURNS setof text
AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT DISTINCT datatype FROM cor_guide_table WHERE source=source_n AND sensitivity_measure=sensitivity_m 
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function to get available transformations for plot axis. Note that "linear" in fact means "no transformations"
CREATE OR REPLACE FUNCTION get_available_transformations(cohort text, datatype text, platform text) RETURNS setof text AS $$
DECLARE
table_name text;
column_type text;
res text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || datatype || E'\';' INTO table_name;
EXECUTE E'SELECT data_type FROM information_schema.columns WHERE table_name=\'' || table_name || E'\' AND column_name=\'' || platform || E'\';' INTO column_type;
FOR res IN EXECUTE E'SELECT transform_type FROM data_transform_types WHERE variable_type=\'' || column_type || E'\';' 
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONS TO WORK WITH COMPATIBILITY

CREATE OR REPLACE FUNCTION check_datatypes_compatibility(datatype text, previous_datatypes text array) RETURNS boolean
AS $$
DECLARE
res boolean;
i integer;
BEGIN
res := true;
FOR i IN 1 .. array_length(previous_datatypes, 1)
LOOP
IF NOT EXISTS (SELECT type1, type2 FROM datatypes_compatibility WHERE ((type1=datatype) AND (type2=previous_datatypes[i])) OR ((type1=previous_datatypes[i]) AND (type2=datatype)))
THEN
res := false;
END IF;
END LOOP;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_platforms_compatibility(platform text, previous_platforms text array) RETURNS boolean
AS $$
DECLARE
res boolean;
i integer;
BEGIN
res := true;
FOR i IN 1 .. array_length(previous_platforms, 1)
LOOP
IF NOT EXISTS (SELECT platform1, platform2 FROM platforms_compatibility WHERE ((platform1=platform) AND (platform2=previous_platforms[i])) OR ((platform1=previous_platforms[i]) AND (platform2=platform)))
THEN
res := false;
END IF;
END LOOP;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_all_platforms_compatible() RETURNS boolean AS $$
DECLARE
table_n text;
datatype text;
platform_n text;
platforms_array text array;
offset_v integer;
i integer;
j integer;
BEGIN
DELETE FROM platforms_compatibility;
platforms_array := ARRAY[]::text[];
RAISE NOTICE 'Collecting platforms...';
FOR table_n IN SELECT table_name FROM guide_table WHERE cohort IS NOT NULL
LOOP
RAISE NOTICE 'Current table: %', table_n;
SELECT type FROM guide_table WHERE table_name=table_n INTO datatype;
IF (SELECT check_ids_availability(datatype) = true) THEN
offset_v := 2;
ELSE
offset_v := 1;
END IF;
FOR platform_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset_v || ';'
LOOP
--RAISE NOTICE 'Platform: %', platform_n;
IF NOT (SELECT platform_n = ANY (platforms_array))
THEN
SELECT array_append(platforms_array, platform_n) INTO platforms_array;
END IF;
END LOOP;
END LOOP;
RAISE NOTICE 'Unique platforms found: %', array_length(platforms_array, 1);
FOR i IN 1..array_length(platforms_array, 1)
LOOP
FOR j IN i..array_length(platforms_array, 1)
LOOP
INSERT INTO platforms_compatibility VALUES(platforms_array[i], platforms_array[j]);
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_platforms_compatible(platform_n1 text, platform_n2 text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
IF EXISTS (SELECT * FROM platforms_compatibility WHERE ((platform1=platform_n1) AND (platform2=platform_n2)) OR ((platform1=platform_n2) AND (platform2=platform_n1))) THEN
res := FALSE;
ELSE
INSERT INTO platforms_compatibility VALUES(platform_n1, platform_n2);
res := TRUE;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_platforms_incompatible(platform_n1 text, platform_n2 text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
IF EXISTS (SELECT * FROM platforms_compatibility WHERE ((platform1=platform_n1) AND (platform2=platform_n2)) OR ((platform1=platform_n2) AND (platform2=platform_n1))) THEN
DELETE FROM platforms_compatibility WHERE ((platform1=platform_n1) AND (platform2=platform_n2)) OR ((platform1=platform_n2) AND (platform2=platform_n1));
res := TRUE;
ELSE
res := FALSE;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;



-- FUNCTIONs TO WORK WITH PLOTS 

CREATE OR REPLACE FUNCTION available_plot_types(platforms text) RETURNS setof text AS $$
DECLARE
n integer;
temp_array text array; 
plots_array text array;
i integer;
BEGIN
temp_array := string_to_array(platforms, ',');
n := array_length(temp_array, 1);
plots_array := ARRAY[]::text[];
-- 1D plots
IF (n =1) THEN
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.platform1=ANY(temp_array)) AND (plot_types.platform2 IS NULL));
ELSE
-- 2D plots
IF (n=2) THEN
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.platform1=temp_array[1] AND plot_types.platform2=temp_array[2]) OR (plot_types.platform1=temp_array[2] AND plot_types.platform2=temp_array[1]));
ELSE
-- 3D plots
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.platform1=temp_array[1] AND plot_types.platform2=temp_array[2] AND plot_types.platform3=temp_array[3]) OR (plot_types.platform1=temp_array[2] AND plot_types.platform2=temp_array[1] AND plot_types.platform3=temp_array[3]) OR (plot_types.platform1=temp_array[2] AND plot_types.platform2=temp_array[3] AND plot_types.platform3=temp_array[1]) OR (plot_types.platform1=temp_array[1] AND plot_types.platform2=temp_array[3] AND plot_types.platform3=temp_array[2]) OR (plot_types.platform1=temp_array[3] AND plot_types.platform2=temp_array[2] AND plot_types.platform3=temp_array[1]) OR (plot_types.platform1=temp_array[3] AND plot_types.platform2=temp_array[1] AND plot_types.platform3=temp_array[2]));
END IF;
END IF;
FOR i IN 1..array_length(plots_array, 1)
LOOP
RETURN NEXT plots_array[i];
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- this function fills table plot_types according to internal rules
-- table should exist before the first function call
CREATE OR REPLACE FUNCTION autofill_plot_types () RETURNS boolean AS $$
DECLARE
table_n text;
datatype text;
platform_n text;
platform_type text;
platforms_array text array;
platforms_type_array text array;
-- need this array to check if we should offer KM plot
km_array text array;
plots text array;
-- name 'offset' cannot be used anymore!
offset_v integer;
i integer;
j integer;
k integer;
n integer;
BEGIN
DELETE FROM plot_types;
platforms_array := ARRAY[]::text[];
platforms_type_array := ARRAY[]::text[];
km_array := ARRAY ['os', 'dss', 'dfi', 'pfs', 'pfi':: text];
RAISE NOTICE 'Collecting platforms...';
FOR table_n IN SELECT table_name FROM guide_table WHERE cohort IS NOT NULL
LOOP
RAISE NOTICE 'Current table: %', table_n;
SELECT type FROM guide_table WHERE table_name=table_n INTO datatype;
IF (SELECT check_ids_availability(datatype) = true) THEN
offset_v := 2;
ELSE
offset_v := 1;
END IF;
FOR platform_n, platform_type  IN EXECUTE E'SELECT column_name, data_type FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset_v || ';'
LOOP
--RAISE NOTICE 'Platform: %', platform_n;
IF NOT (SELECT platform_n = ANY (platforms_array))
THEN
SELECT array_append(platforms_array, platform_n) INTO platforms_array;
SELECT array_append(platforms_type_array, platform_type) INTO platforms_type_array;
END IF;
END LOOP;
END LOOP;
RAISE NOTICE 'Unique platforms found: %', array_length(platforms_array, 1);
--RAISE NOTICE '%', platforms_array;
--RAISE NOTICE '%', platforms_type_array;
FOR i IN 1..array_length(platforms_array, 1)
LOOP
-- 1D plots
-- we have only two datatypes: character and numeric
IF (platforms_type_array[i] = 'character varying') THEN
plots := ARRAY ['bar','piechart'::text];
ELSE 
plots := ARRAY ['histogram'::text];
END IF;
FOR k IN 1..array_length(plots, 1)
LOOP
INSERT INTO plot_types(platform1, plot) VALUES(platforms_array[i], plots[k]);
END LOOP;
-- 2D case
FOR j IN i..array_length(platforms_array, 1)
LOOP
plots := ARRAY[]::text[];
IF ((platforms_array[i] = ANY(km_array)) OR (platforms_array[j] = ANY(km_array)) AND NOT (platforms_array[i] = ANY(km_array) AND platforms_array[j] = ANY(km_array))) THEN
plots := ARRAY ['KM'::text];
ELSE
IF ((platforms_type_array[i] = 'numeric') AND (platforms_type_array[j] = 'numeric')) THEN
plots := ARRAY ['scatter'::text];
ELSE
IF ((platforms_type_array[i] = 'character varying') AND (platforms_type_array[j] = 'character varying')) THEN
plots := ARRAY ['venn'::text];
ELSE
IF (((platforms_type_array[i] = 'numeric') AND (platforms_type_array[j] = 'character varying')) OR ((platforms_type_array[j] = 'numeric') AND (platforms_type_array[i] = 'character varying'))) THEN
plots := ARRAY ['box'::text];
END IF;
END IF;
END IF;
END IF;
SELECT array_length(plots, 1) INTO n;
IF (n>0) THEN
FOR k IN 1..n
LOOP
INSERT INTO plot_types(platform1, platform2, plot) VALUES(platforms_array[i],  platforms_array[j], plots[k]);
END LOOP;
END IF;
END LOOP;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;

-- it is probably better to pass an array, but there are potential problems
-- see this: https://stackoverflow.com/questions/570393/postgres-integer-arrays-as-parameters
-- example of args: 'snp6,affymetrix,,scatter'
-- example of condition: '((platform1='snp6') AND (platform2='affymetrix') AND (plot='scatter')) OR ((platform1='affymetrix') AND (platform2='snp6') AND (plot='scatter'))'
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
EXECUTE E'INSERT INTO plot_types(platform1,plot) VALUES(\'' || args_array[1] || E'\',\'' || args_array[4] || E'\');';
ELSE
--RAISE NOTICE 'args_array[2] = %', args_array[2];
IF (args_array[3] = '') THEN
-- 2D plot
EXECUTE E'INSERT INTO plot_types(platform1,platform2,plot) VALUES(\'' || args_array[1] || E'\',\'' || args_array[2] || E'\',\'' || args_array[4] || E'\');';
ELSE
-- 3D plot
EXECUTE E'INSERT INTO plot_types(platform1,platform2,platform3,plot) VALUES(\'' || args_array[1] || E'\',\'' || args_array[2] || E'\',\'' || args_array[3] || E'\',\'' || args_array[4] || E'\');';
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
CREATE OR REPLACE FUNCTION get_platform_types(cohort text, datatype1 text, platform1 text, datatype2 text DEFAULT '', platform2 text DEFAULT '', datatype3 text DEFAULT '', platform3 text DEFAULT '') RETURNS setof text AS $$
DECLARE
table_n text;
res text;
BEGIN
table_n := cohort || '_' || datatype1;
SELECT data_type INTO res FROM information_schema.columns WHERE table_name = table_n AND column_name = platform1;
RETURN NEXT res;
IF (datatype2 <> '') THEN
table_n := cohort || '_' || datatype2;
SELECT data_type INTO res FROM information_schema.columns WHERE table_name = table_n AND column_name = platform2;
RETURN NEXT res;
IF (datatype3 <> '') THEN
table_n := cohort || '_' || datatype3;
SELECT data_type INTO res FROM information_schema.columns WHERE table_name = table_n AND column_name = platform3;
RETURN NEXT res;
END IF;
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
CREATE OR REPLACE FUNCTION bar() RETURNS setof text AS $$
DECLARE
table_name text;
res text;
res_array text array;
i numeric;
BEGIN
CREATE TABLE cor_all_ids (id text);
res_array = ARRAY[]::text[];
FOR table_name IN EXECUTE E'SELECT table_name FROM cor_guide_table ;'
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
INSERT INTO cor_all_ids(id) VALUES (res_array[i]);
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function to retrieve correlations
-- mindrug is a min number of patients which have to be treated with the specific drug to offer KM plot for this drug
-- cor_columns is a string with comma-separated columns to use for query 
-- first column is ALWAYS gene
-- second column is ALWAYS feature
-- last column is ALWAYS q
CREATE OR REPLACE FUNCTION retrieve_correlations(data_type text, platform_n text, screen_n text, sensitivity_m text, id text, fdr numeric, mindrug numeric, cor_columns text) RETURNS setof text AS $$
DECLARE
gene_n text;
feature_n text;
visible_feature_name text;
table_name text;
datatype_name text;
platform_name text;
screen_name text;
cohorts text;
res text array;
columns_array text array;
query text;
i numeric;
BEGIN
columns_array := string_to_array(cor_columns, ',');
FOR table_name, datatype_name, platform_name, screen_name IN EXECUTE E'SELECT table_name,datatype,platform,screen FROM cor_guide_table WHERE datatype LIKE \'' || data_type || E'\' AND platform LIKE \'' || platform_n || E'\' AND screen LIKE \'' || screen_n || E'\' AND sensitivity_measure LIKE \'' || sensitivity_m || E'\';'
LOOP
RAISE notice 'table name: %', table_name;
query := 'SELECT ARRAY (SELECT upper(' || columns_array[1] || E') \|\| \'\|\' \|\| drug_synonym(' || columns_array[2] || E') \|\| \'\|\' \|\| \'' || datatype_name || E'\' \|\| \'\|\' \|\| \'' || platform_name || E'\' \|\| \'\|\' \|\| \'' || screen_name || E'\'';
FOR i IN 3..array_length(columns_array, 1)
LOOP
query := query || E' \|\| \'\|\' \|\| ' || columns_array[i]; 
-- i does not save it's value! Reassign
RAISE notice '%: query: %', i, query;
END LOOP;
i := array_length(columns_array, 1);
query := query || E' \|\| \'\|\' \|\| retrieve_cohorts_for_drug(' || columns_array[2] || ',' || mindrug || ') FROM ' || table_name || E' WHERE ((gene LIKE \'' || id || E'\') OR (feature LIKE \'' || id || E'\')) AND (' || columns_array[i] || '<=' || fdr || ') ORDER BY ' || columns_array[i] || ' DESC);'; 
RAISE notice '%: query: %', i, query;
--FOR gene_n,feature_n,p1,p2,p3,q IN EXECUTE 'SELECT upper(gene),feature,ancova_p_1x,ancova_p_2x_cov1,ancova_p_2x_feature,ancova_q_2x_feature FROM ' || table_name || E' WHERE ((gene LIKE \'' || id || E'\') OR (feature LIKE \'' || id || E'\')) AND (ancova_q_2x_feature<=' || fdr || ') ORDER BY ancova_q_2x_feature DESC;'
--LOOP
--SELECT external_id INTO visible_feature_name FROM synonyms WHERE internal_id=feature_n AND id_type='drug';
--SELECT retrieve_cohorts_for_drug(feature_n, mindrug) INTO cohorts;
--res := gene_n || '|' || visible_feature_name || '|' || datatype_name || '|' || platform_name || '|' || screen_name || '|' || p1 || '|' || p2 || '|' || p3 || '|' || q || '|' || cohorts || '|';
--RETURN NEXT res;
--END LOOP;
EXECUTE query INTO res;
RAISE notice 'Query complete, number of rows: %', array_length(res,1);
IF array_length(res,1) > 0
THEN
FOR i in 1..array_length(res, 1)
LOOP
RETURN NEXT res[i];
END LOOP;
END IF;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function to get TCGA cohorts for retrieve_correlations
CREATE OR REPLACE FUNCTION retrieve_cohorts_for_drug(drug_name character varying, mindrug numeric) RETURNS text AS $$
DECLARE
cohort_n text;
res text;
n_pats numeric;
BEGIN
res := '';
FOR cohort_n, n_pats IN SELECT cohort,counts FROM drug_counts WHERE drug=drug_name
LOOP
IF (n_pats > mindrug)
THEN
res := res || cohort_n || ',';
END IF;
END LOOP;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION drug_synonym(drug text) RETURNS text AS $$
DECLARE
res text;
syn text;
BEGIN
FOR syn IN SELECT external_id FROM synonyms WHERE internal_id=drug AND id_type='drug'
LOOP
res := syn;
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
EXECUTE E'SELECT EXISTS(SELECT ' || platform || E' FROM druggable_ids WHERE cohort=\''|| cohort || E'\' AND ' || platform || ' IS NOT NULL);' INTO flag;
-- if we have - delete old value
IF (flag=true) THEN
EXECUTE 'UPDATE druggable_ids SET ' || platform || E'=\'' || res || E'\' WHERE cohort=\''|| cohort || E'\';';
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
-- use ONLY for initialization!
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
CREATE OR REPLACE FUNCTION update_platform_description (platform_n text, description text, display boolean) RETURNS boolean AS $$
DECLARE
flag boolean;
BEGIN
EXECUTE E'SELECT EXISTS (SELECT * FROM platform_descriptions WHERE shortname=\'' || platform_n || E'\');' INTO flag;
IF (flag = true)
THEN
EXECUTE E'UPDATE platform_descriptions SET fullname=\'' || description || E'\',visibility='|| display || E' WHERE shortname=\'' || platform_n || E'\';';
ELSE
EXECUTE E'INSERT INTO platform_descriptions VALUES (\'' || platform_n || E'\', \'' || description || E'\', ' || display || ');';
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
CREATE OR REPLACE FUNCTION get_tcga_codes(cohort_n text, datatype_n text, previous_datatypes text) RETURNS text AS $$
DECLARE
res text;
table_n text;
datatypes_array text array;
source_n text;
i integer;
flag boolean;
BEGIN
res := '';
SELECT source INTO source_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatype_n);
IF (source_n = 'TCGA') THEN
SELECT table_name INTO table_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatype_n);
IF (EXISTS (SELECT * FROM tcga_codes WHERE table_name = table_n)) THEN
SELECT codes INTO res FROM tcga_codes WHERE table_name = table_n;
flag := TRUE;
END IF;
IF (previous_datatypes <> '') THEN
datatypes_array := string_to_array(previous_datatypes, ',');
FOR i IN 1 .. array_length(datatypes_array, 1)
LOOP
SELECT table_name INTO table_n FROM guide_table WHERE (cohort = cohort_n) AND (type = datatypes_array[i]);
IF (EXISTS (SELECT * FROM tcga_codes WHERE table_name = table_n)) THEN
flag := flag AND TRUE;
ELSE
flag := FALSE;
END IF;
END LOOP;
END IF;
IF (flag = TRUE) THEN
res := 'all,healthy,cancer,' || res;
END IF;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- function to create table with sample codes available for TCGA tables
-- if table contains patients - it is not present here
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
i integer;
j integer;
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



-- ADDITIONAL FUNCTIONS


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

CREATE OR REPLACE FUNCTION forget_platform(platform_n text) RETURNS boolean AS $$
BEGIN
DELETE FROM platforms_compatibility WHERE (platform1=platform_n) OR (platform2=platform_n);
RETURN true;
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

-- autocreate indices for all tables registered in guide_table
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


-- DEPRICATED FUNCTIONS

-- DEPRICATED
CREATE OR REPLACE FUNCTION all_indexes_size () RETURNS setof text AS $$
DECLARE
res text;
BEGIN
DROP VIEW IF EXISTS indexes_size;
CREATE VIEW indexes_size AS SELECT indexname, tablename FROM pg_indexes;
FOR res IN SELECT * FROM  indexes_size
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION DEPRICATED!
-- data for the given sample from the specified datatable, can use TCGA codes
CREATE OR REPLACE FUNCTION select_by_sample (data_table text, sample_name text, tcga_code text default '%') RETURNS setof text AS $$
DECLARE 
res record;
source_type text;
BEGIN
DROP VIEW IF EXISTS data_for_sample;
SELECT source INTO source_type FROM guide_table WHERE table_name LIKE data_table;
IF (source_type = 'TCGA')
THEN
EXECUTE 'CREATE VIEW data_for_sample AS SELECT * FROM ' || data_table || E' WHERE sample LIKE \'' || sample_name || '-' || tcga_code || E'\';';
ELSE
EXECUTE 'CREATE VIEW data_for_sample AS SELECT * FROM ' || data_table || E' WHERE sample=\'' || sample_name || E'\';';
END IF;
FOR res IN SELECT * FROM  data_for_sample
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION DEPRICATED! Problems with combining TCGA data from patients and samples
-- this function creates views which should be read in R
-- fname is file name - used for unique tables
-- returns 3 columns, first column is samples 
CREATE OR REPLACE FUNCTION plot_data_by_id (fname text, cohort text, type1 text, platform1 text, id1 text, tcga_code1 text default '', type2 text default '', platform2 text default '', id2 text default '', tcga_code2 text default '',  type3 text default '', platform3 text default '', id3 text default '', tcga_code3 text default '') RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
table3 text;
source text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
EXECUTE E'SELECT source FROM guide_table WHERE table_name LIKE\'' || table1 || E'\';' INTO source;
IF (type3 = '') THEN
IF (type2 = '') THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,' || platform1 || ' FROM ' || table1 || E' WHERE id=\'' || id1 || E'\' AND sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,' || platform1 || ' FROM ' || table1 || E' WHERE id=\'' || id1 || E'\';';
END IF;
ELSE
-- have to do this, otherwise will get error table name "..." specified more than once
IF (type1 = type2) THEN
-- need expressions 2 and 3 to exclude situation when user have chosen "all" for both rows
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample, A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || E' IS NOT NULL) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample, A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || ' IS NOT NULL);';
END IF;
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' AND '|| table2 || '.' || platform2 ||' IS NOT NULL AND ' || table1 ||  E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' AND '|| table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
END IF;
END IF;
ELSE
IF ((type1 = type2) AND (type1 = type3)) THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || ' B,' || table1 || ' C ' || E' WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\') AND (A.sample=B.sample) AND (A.sample=C.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) AND (C.' || platform3 || E' IS NOT NULL) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || ' B,' || table1 || ' C ' || E' WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\') AND (A.sample=B.sample) AND (A.sample=C.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) AND (C.' || platform3 || ' IS NOT NULL);';
END IF;
ELSE
IF (type1 = type2) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1  || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) ' || ' JOIN ' || table3 || ' ON (A.sample='|| table3 || '.sample) AND (' || table3 || E'.id=\'' || id3 || E'\') AND (' || table3 || '.' || platform3 || ' IS NOT NULL) AND (' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1  || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) ' || ' JOIN ' || table3 || ' ON (A.sample='|| table3 || '.sample) AND (' || table3 || E'.id=\'' || id3 || E'\') AND (' || table3 || '.' || platform3 || ' IS NOT NULL);';
END IF;
ELSE
IF (type1 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\') AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\');';
END IF;
ELSE
IF (type2 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table2 || ' C,' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\') AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table2 || ' C,' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\');';
END IF;
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 || '1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' JOIN ' || table3 || ' ON ' || table1 || '.sample=' || table3 || '.sample AND ' || table3 || E'.id=\'' || id3 || E'\' AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 || '1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' JOIN ' || table3 || ' ON ' || table1 || '.sample=' || table3 || '.sample AND ' || table3 || E'.id=\'' || id3 || E'\';';
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
EXECUTE E'SELECT COUNT (\*) FROM temp_view' || fname || ';' INTO n;
IF (n = 0) THEN
res := 'error';
ELSE
res := 'ok';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION DEPRICATED! Problems with combining TCGA data from patients and samples
-- this version does not use ids, it is just a  function for CLIN and IMMUNO data
CREATE OR REPLACE FUNCTION plot_data_without_id (fname text, cohort text, type1 text, platform1 text, tcga_code1 text default '', type2 text default '', platform2 text default '', tcga_code2 text default '', type3 text default '', platform3 text default '', tcga_code3 text default '') RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
table3 text;
source text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
EXECUTE E'SELECT source FROM guide_table WHERE table_name LIKE\'' || table1 || E'\';' INTO source;
IF (type3 = '') THEN
IF (type2 = '') THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,' || platform1 || ' FROM ' || table1 || E' WHERE sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,' || platform1 || ' FROM ' || table1 || ';';
END IF;
ELSE
-- have to do this, otherwise will get error table name "..." specified more than once
IF (type1 = type2) THEN
-- have to do this, otherwise will receive ERROR:  column "..." specified more than once
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || E' IS NOT NULL) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || ' IS NOT NULL);';
END IF;
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || '.' || platform2 || ' IS NOT NULL AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || '.' || platform2 || ' IS NOT NULL;';
END IF;
END IF;
END IF;
ELSE
IF ((type1 = type2) AND (type1 = type3)) THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (A.sample=C.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) AND (C.' || platform3 || E' IS NOT NULL) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (A.sample=C.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) AND (C.' || platform3 || ' IS NOT NULL);';
END IF;
ELSE
IF (type1 = type2) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1  || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) ' || ' JOIN ' || table3 || ' ON (A.sample='|| table3 || '.sample) AND (' || table3 || '.' || platform3 || ' IS NOT NULL) AND (' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1  || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) ' || ' JOIN ' || table3 || ' ON (A.sample='|| table3 || '.sample) AND (' || table3 || '.' || platform3 || ' IS NOT NULL);';
END IF;
ELSE
IF (type1 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table1 || ' C ' || ' WHERE (A.sample=B.sample) AND (C.sample=A.sample);';
END IF;
ELSE
IF (type2 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table2 || ' C,' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table2 || ' C,' || ' WHERE (A.sample=B.sample) AND (C.sample=A.sample);';
END IF;
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 || '1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample' || ' JOIN ' || table3 || ' ON ' || table1 || '.sample=' || table3 || '.sample AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 || '1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample' || ' JOIN ' || table3 || ' ON ' || table1 || '.sample=' || table3 || '.sample;';
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
EXECUTE E'SELECT COUNT (\*) FROM temp_view' || fname || ';' INTO n;
IF (n = 0) THEN
res := 'error';
ELSE
res := 'ok';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION DEPRICATED! Problems with combining TCGA data from patients and samples
-- function for boxplot: ids are optional for both axises
CREATE OR REPLACE FUNCTION boxplot_data (fname text, cohort text, type1 text, platform1 text, id1 text, tcga_code1 text, type2 text, platform2 text, id2 text,  tcga_code2 text) RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
source text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
EXECUTE E'SELECT source FROM guide_table WHERE table_name LIKE\'' || table1 || E'\';' INTO source;
IF (id1='') THEN
IF (id2 = '') THEN
-- same table, no ids
IF (type1 = type2) THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || E' IS NOT NULL) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || E' IS NOT NULL);';
END IF;
-- different tables, no ids
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || '.' || platform2 || ' IS NOT NULL AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || '.' || platform2 || ' IS NOT NULL;';
END IF;
END IF;
-- platform1 does not have ids, platform2 does
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || E'.id=\'' || id2 || E'\' AND ' || table2 || '.' || platform2 ||' IS NOT NULL AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || E'.id=\'' || id2 || E'\' AND ' || table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
END IF;
ELSE
-- same table, ids are present
IF (type1 = type2) THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.id=\'' || id1 || E'\') AND (A.' || platform1 || E' IS NOT NULL) AND (B.id=\'' || id2 || E'\') AND (B.' || platform2 || E' IS NOT NULL) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.id=\'' || id1 || E'\') AND (A.' || platform1 || E' IS NOT NULL) AND (B.id=\'' || id2 || E'\') AND (B.' || platform2 || E' IS NOT NULL);';
END IF;
ELSE
-- platform1 has ids, platform2 does not
IF (id2='') THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || '.' || platform2 || ' IS NOT NULL AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
-- different tables, ids are present
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || '.' || platform2 ||' IS NOT NULL AND ' || table2 || E'.id=\'' || id2 || E'\' AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || '.' || platform2 ||' IS NOT NULL AND ' || table2 || E'.id=\'' || id2 || E'\';';
END IF;
END IF;
END IF;
END IF;
EXECUTE E'SELECT COUNT (\*) FROM temp_view' || fname || ';' INTO n;
IF (n = 0) THEN
res := 'error';
ELSE
res := 'ok';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION DEPRICATED! Problems with combining TCGA data from patients and samples
-- function for special types of boxplots (or other plots which are in need of binary data): when we have many categories and want to categorize results as "TRUE/FALSE"
-- e.g. instead of having all types of mutations for TP53 from MUT-MAF, we will have TRUE if mutation is present and FALSE if mutation is absent
-- note: binarization ALWAYS occurs for the second platform, except for 1D cases!
-- Caution! Autocomplement is a special parameter, use it with great caution! If autocomplement=true, than all samples which are present in table1 but not present in
-- table2 which is being binarized are considered to be FALSE
-- this function can pick up TCGA samples by TCGA-codes: all samples, all healthy, all cancer etc.
-- this function was originally used for boxplots only, but now it can be used for other purposes as well
CREATE OR REPLACE FUNCTION boxplot_data_binary_categories (fname text, cohort text, type1 text, platform1 text, id1 text, tcga_code1 text, type2 text, platform2 text, id2 text, tcga_code2 text, autocomplement boolean default false) RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
source text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
EXECUTE E'SELECT source FROM guide_table WHERE table_name LIKE\'' || table1 || E'\';' INTO source;
-- 1D-case
IF (type2 = '') THEN
-- 1D without ids
IF (id1='') THEN
-- ignore samples according to tcga_code IF data from TCGA and specific flag is set
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,binarize(' || platform1 || ') FROM ' || table1 || E' WHERE sample LIKE \'' || tcga_code1 || E'\';';
-- when data is not from TCGA OR flag is not set
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,binarize(' || platform1 || ') FROM ' || table1 || ';';
END IF;
-- 1D with IDs
ELSE
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,binarize(' || platform1 || ') FROM ' || table1 || E' WHERE (id=\'' || id1 || E'\') AND (sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT sample,binarize(' || platform1 || ') FROM ' || table1 || E' WHERE id=\'' || id1 || E'\';';
END IF;
END IF;
-- 2D-case
ELSE
-- data comes from one table
IF (type1 = type2) THEN
-- case when table1 has no ids and table2=table1
IF (id1 = '') THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,binarize(B.' || platform2 || ') AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1,binarize(B.' || platform2 || ') AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || ' B WHERE (A.sample=B.sample);';
END IF;
-- table1 has ids
ELSE
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1, binarize(B.' || platform2 || ') AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.id=\'' || id1 || E'\') AND (B.id =\'' || id2 || E'\') AND (A.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.sample,A.' || platform1 || ' AS ' || platform1 || '1, binarize(B.' || platform2 || ') AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.id=\'' || id1 || E'\') AND (B.id =\'' || id2 || E'\');';
END IF;
END IF;
-- data comes from different tables
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
IF (id1='') THEN
-- both tables has no ids
IF (id2='') THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON (' || table1 || '.sample=' || table2 || '.sample) AND (' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample;';
END IF;
-- table1 has no ids, table2 has
ELSE
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || E'.id=\'' || id2 || E'\' AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || E'.id=\'' || id2 || E'\';';
END IF;
END IF;
ELSE
-- table1 has ids, table2 does not
IF (id2='') THEN
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\';';
END IF;
-- both tables have ids
ELSE
IF (source='TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id =\'' || id2 || E'\' AND ' || table1 || E'.sample LIKE \'' || tcga_code1 || E'\';';
ELSE 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.sample,' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,binarize(' || table2 || '.' || platform2 || ') AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id =\'' || id2 || E'\';';
END IF;
END IF;
END IF;
-- autocomplement
IF (autocomplement = TRUE) THEN
EXECUTE 'CREATE TABLE temp_table' || fname || ' AS SELECT * FROM temp_view' || fname || ';';
IF (id2 = '') THEN
IF (source='TCGA') THEN
EXECUTE 'INSERT INTO temp_table' || fname || ' SELECT B.sample,B.'  || platform1 || E',\'FALSE\' FROM ' || table2 || ' A RIGHT JOIN ' || table1 || E' B ON A.sample=B.sample WHERE A.sample IS NULL AND B.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'INSERT INTO temp_table' || fname || ' SELECT B.sample,B.' || platform1 || E',\'FALSE\' FROM ' || table2 || ' A RIGHT JOIN ' || table1 || ' B ON A.sample=B.sample WHERE A.sample IS NULL;';
END IF;
ELSE
IF (source='TCGA') THEN
EXECUTE 'INSERT INTO temp_table' || fname || ' SELECT B.sample,B.' || platform1 || E',\'FALSE\' FROM ' || table2 || ' A RIGHT JOIN ' || table1 || E' B ON A.sample=B.sample WHERE A.sample IS NULL AND B.id=\'' || id2 || E'\' AND B.sample LIKE \'' || tcga_code1 || E'\';';
ELSE
EXECUTE 'INSERT INTO temp_table' || fname || ' SELECT B.sample,B.' || platform1 || E',\'FALSE\' FROM ' || table2 || ' A RIGHT JOIN ' || table1 || E' B ON A.sample=B.sample WHERE A.sample IS NULL AND B.id=\'' || id2 || E'\';';
END IF;
END IF;
END IF;
END IF;
END IF;
IF (autocomplement = FALSE) THEN
EXECUTE E'SELECT COUNT (\*) FROM temp_view' || fname || ';' INTO n;
ELSE
EXECUTE E'SELECT COUNT (\*) FROM temp_table' || fname || ';' INTO n;
END IF;
IF (n = 0) THEN
res := 'error';
ELSE
res := 'ok';
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION data_for_cohort(cohort regclass) RETURNS 
TABLE (
feature character varying(64),
sample character varying(64),
value real)
AS $$
BEGIN
RETURN QUERY EXECUTE 'SELECT * FROM ' || cohort;
END;
$$ LANGUAGE plpgsql;

-- this version uses tables specific for data type, one table can store results for multiple platforms
CREATE OR REPLACE FUNCTION feature_list_source (source_n text) RETURNS
TABLE (
screen_name character varying(64),
feature_name character varying(256))
AS $$
BEGIN
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'features')
THEN
DELETE FROM features;
ELSE
CREATE TABLE features (source character varying(64), feature character varying(256));
END IF;
IF (source_n = 'all') THEN
INSERT INTO features SELECT DISTINCT screen, platform FROM best_drug_corrs_counts ORDER BY screen;
ELSE
INSERT INTO features SELECT DISTINCT screen, platform FROM best_drug_corrs_counts WHERE (screen = source_n) ORDER BY screen;
END IF;
UPDATE features SET source=subquery.show_name FROM (SELECT DISTINCT screen, display_name FROM guide_table) AS subquery(source_name,show_name) WHERE features.source=subquery.source_name;
UPDATE features SET feature=subquery.show_name FROM (SELECT DISTINCT short_name, full_name FROM feature_table) AS subquery(short,show_name) WHERE features.feature=subquery.short;
RETURN QUERY SELECT * FROM features WHERE feature IN (SELECT full_name FROM feature_table) ORDER BY source;
END;
$$ LANGUAGE plpgsql;


-- return all sources with drug sensitivity
CREATE OR REPLACE FUNCTION sources_and_drugs() RETURNS
TABLE (
code character varying(64),
visible_name character varying(256))
AS $$
BEGIN
RETURN QUERY SELECT table_name, display_name FROM guide_table  WHERE type LIKE 'Drug sensitivity';
END;
$$ LANGUAGE plpgsql;