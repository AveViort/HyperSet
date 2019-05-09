-- return all sources with drug sensitivity
CREATE OR REPLACE FUNCTION sources_and_drugs() RETURNS setof text AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT display_name FROM guide_table  WHERE type LIKE 'Drug sensitivity'
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- return data for given table (passed as string)
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

-- return all drugs
CREATE OR REPLACE FUNCTION drug_list() RETURNS
TABLE (
screen_name character varying(64),
drug_name character varying(64))
AS $$
BEGIN
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE schemaname = 'pg_temp_1'
AND tablename  = 'drugs')
THEN
DELETE FROM drugs;
ELSE
-- have to use "source" and "compound" names, otherwise will get an error like that:
-- ERROR:  syntax error at or near "$1"
-- LINE 1: CREATE TEMP TABLE drugs ( $1  character varying(64),  $2  ch...
-- This is because "screen" and "drug" are already used
CREATE TEMP TABLE drugs (source character varying(64), compound character varying(64));
END IF;
INSERT INTO drugs SELECT DISTINCT screen, drug FROM best_drug_corrs_counts ORDER BY screen;
UPDATE drugs SET source=subquery.show_name FROM (SELECT DISTINCT screen, display_name FROM guide_table) AS subquery(source_name,show_name) WHERE drugs.source=subquery.source_name;
RETURN QUERY SELECT * FROM drugs;
END;
$$ LANGUAGE plpgsql;

-- return features
CREATE OR REPLACE FUNCTION feature_list() RETURNS
TABLE (
screen_name character varying(64),
feature_name character varying(256))
AS $$
BEGIN
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE schemaname = 'pg_temp_1'
AND tablename  = 'features')
THEN
DELETE FROM features;
ELSE
CREATE TEMP TABLE features (source character varying(64), feature character varying(256));
END IF;
INSERT INTO features SELECT DISTINCT screen, platform FROM best_drug_corrs_counts ORDER BY screen;
UPDATE features SET source=subquery.show_name FROM (SELECT DISTINCT screen, display_name FROM guide_table) AS subquery(source_name,show_name) WHERE features.source=subquery.source_name;
UPDATE features SET feature=subquery.show_name FROM (SELECT DISTINCT short_name, full_name FROM feature_table) AS subquery(short,show_name) WHERE features.feature=subquery.short;
RETURN QUERY SELECT * FROM features WHERE feature IN (SELECT full_name FROM feature_table) ORDER BY source;
END;
$$ LANGUAGE plpgsql;

-- this version is for broad tables, storing all types of data (MUT, GE, PE etc.)
CREATE OR REPLACE FUNCTION feature_list_broad() RETURNS
TABLE (
screen_name character varying(64),
feature_name character varying(256))
AS $$
BEGIN
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE schemaname = 'pg_temp_1'
AND tablename  = 'features')
THEN
DELETE FROM features;
ELSE
CREATE TEMP TABLE features (source character varying(64), feature character varying(256));
END IF;
INSERT INTO features SELECT 'BRCA', column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ctd_tcga_brca';
UPDATE features SET source=subquery.show_name FROM (SELECT DISTINCT screen, display_name FROM guide_table) AS subquery(source_name,show_name) WHERE features.source=subquery.source_name;
UPDATE features SET feature=subquery.show_name FROM (SELECT DISTINCT short_name, full_name FROM feature_table) AS subquery(short,show_name) WHERE REPLACE(features.feature, '_', '.')=subquery.short;
RETURN QUERY SELECT * FROM features WHERE feature IN (SELECT full_name FROM feature_table) ORDER BY source;
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
WHERE schemaname = 'pg_temp_1'
AND tablename  = 'features')
THEN
DELETE FROM features;
ELSE
CREATE TEMP TABLE features (source character varying(64), feature character varying(256));
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

-- this version returns ONLY features (without sources or data types!)
CREATE OR REPLACE FUNCTION platform_list (cohort_n text, data_type text, previous_platforms text) RETURNS setof text
AS $$
DECLARE
table_n text;
res text;
platforms_array text array;
flag boolean;
BEGIN
platforms_array := string_to_array(previous_platforms, ',');
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE schemaname = 'pg_temp_1'
AND tablename  = 'platforms')
THEN
DELETE FROM platforms;
ELSE
CREATE TEMP TABLE platforms (platform character varying(256));
END IF;
SELECT table_name INTO table_n FROM guide_table WHERE (cohort=cohort_n) AND (type=data_type);
-- offset is 2 because first two columns are always sample and id
EXECUTE E'INSERT INTO platforms SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET 2;';
FOR res IN SELECT * FROM platforms
LOOP
IF NOT (previous_platforms = '')
THEN
SELECT check_platforms_compatibility(res, platforms_array) INTO flag;
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

-- this function creates views which should be read in R
-- fname is file name - used for unique tables 
CREATE OR REPLACE FUNCTION plot_data_by_id (fname text, cohort text, type1 text, platform1 text, id1 text, type2 text default '', platform2 text default '', id2 text default '', type3 text default '', platform3 text default '', id3 text default '') RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
table3 text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
IF (type3 = '') THEN
IF (type2 = '') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || platform1 || ' FROM ' || table1 || E' WHERE id=\'' || id1 || E'\';';
ELSE
-- have to do this, otherwise will get error table name "..." specified more than once
IF (type1 = type2) THEN
-- have to do this, otherwise will receive ERROR:  column "..." specified more than once
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL);';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' AND '|| table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
END IF;
ELSE
IF ((type1 = type2) AND (type1 = type3)) THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || ' B,' || table1 || ' C ' || E' WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\') AND (A.sample=B.sample) AND (A.sample=C.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) AND (C.' || platform3 || ' IS NOT NULL);';
ELSE
IF (type1 = type2) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1  || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) ' || ' JOIN ' || table3 || ' ON (A.sample='|| table3 || '.sample) AND (' || table3 || E'.id=\'' || id3 || E'\') AND (' || table3 || '.' || platform3 || ' IS NOT NULL);';
ELSE
IF (type1 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || ' A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\');';
ELSE
IF (type2 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' ||  ' A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table2 || ' C,' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample) AND (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (C.id=\'' || id3 || E'\');';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 || '1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' JOIN ' || table3 || ' ON ' || table1 || '.sample=' || table3 || '.sample AND ' || table3 || E'.id=\'' || id3 || E'\';';
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

-- this version does not use ids, it is just a  function for CLIN and IMMUNO data
CREATE OR REPLACE FUNCTION plot_data_without_id (fname text, cohort text, type1 text, platform1 text, type2 text default '', platform2 text default '', type3 text default '', platform3 text default '') RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
table3 text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
IF (type3 = '') THEN
IF (type2 = '') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || platform1 || ' FROM ' || table1 || ';';
ELSE
-- have to do this, otherwise will get error table name "..." specified more than once
IF (type1 = type2) THEN
-- have to do this, otherwise will receive ERROR:  column "..." specified more than once
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL);';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
END IF;
ELSE
IF ((type1 = type2) AND (type1 = type3)) THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (A.sample=C.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) AND (C.' || platform3 || ' IS NOT NULL);';
ELSE
IF (type1 = type2) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1  || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL) ' || ' JOIN ' || table3 || ' ON (A.sample='|| table3 || '.sample) AND (' || table3 || '.' || platform3 || ' IS NOT NULL);';
ELSE
IF (type1 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || ' A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table1 || ' C ' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample);';
ELSE
IF (type2 = type3) THEN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' ||  ' A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS ' || platform2 || '2,C.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' A,' || table2 || ' B,' || table2 || ' C,' || E' WHERE (A.sample=B.sample) AND (C.sample=A.sample);';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type3 || E'\';' INTO table3; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 || '1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2,' || table3 || '.' || platform3 || ' AS ' || platform3 || '3 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample' || ' JOIN ' || table3 || ' ON ' || table1 || '.sample=' || table3 || '.sample;';
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

CREATE OR REPLACE FUNCTION available_plot_types(platforms text) RETURNS setof text AS $$
DECLARE
n integer;
temp_array text array; 
res text;
BEGIN
temp_array := string_to_array(platforms, ',');
n := array_length(temp_array, 1);
FOR res IN SELECT DISTINCT (plot_types.plot) FROM plot_types JOIN plot_dimensions ON plot_types.datatype=ANY(temp_array) AND plot_types.plot=plot_dimensions.plot AND plot_dimensions.dims=n
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function returns ids for autocomplete in web interface
CREATE OR REPLACE FUNCTION autocomplete_ids(cohort text, platform text) RETURNS setof text AS $$
BEGIN
RETURN QUERY EXECUTE 'SELECT ' || platform || E' FROM druggable_ids WHERE cohort=\''|| cohort || E'\';';
END;
$$ LANGUAGE plpgsql;

-- function to create strings for autocomplete. Note that all ids are stored as a string with separators for the given cohort, datatype and platform
CREATE OR REPLACE FUNCTION create_ids_for_platform (cohort text, datatype text, platform text) RETURNS text AS $$
DECLARE
res text;
id_string text;
data_table text;
flag boolean;
BEGIN
res := '';
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || datatype || E'\';' INTO data_table;
EXECUTE E'SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=\'druggable_ids\' AND column_name=\'' || platform || E'\');' INTO flag;
IF (flag=false) THEN
EXECUTE 'ALTER TABLE druggable_ids ADD ' || platform || ' text;';
END IF;
FOR id_string IN EXECUTE 'SELECT DISTINCT(id) FROM ' || data_table ||' WHERE ' || platform || ' IS NOT NULL;'
LOOP
res := res || '||' || id_string;
END LOOP;
EXECUTE 'INSERT INTO druggable_ids(cohort,'|| platform || E') VALUES(\'' || cohort || E'\',\'' || res || E'\');';
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

-- function to check if dataset has ids or not
CREATE OR REPLACE FUNCTION check_ids_availability(datatype text) RETURNS boolean AS $$
DECLARE
res boolean;
BEGIN
SELECT has_ids INTO res FROM type_ids WHERE data_type=datatype;
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

CREATE OR REPLACE FUNCTION make_all_platforms_compatible() RETURNS boolean AS $$
DECLARE
table_n text;
datatype text;
platform_n text;
platforms_array text array;
offset integer;
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
offset := 2;
ELSE
offset := 1;
END IF;
FOR platform_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset || ';'
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

CREATE OR REPLACE FUNCTION make_platforms_incompatible(platform_n1 text, platform_n2 text) RETURNS boolean AS $$
BEGIN
DELETE FROM platforms_compatibility WHERE ((platform1=platform_n1) AND (platform2=platform_n2)) OR ((platform1=platform_n2) AND (platform2=platform_n1));
RETURN true;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION forget_platform(platform_n text) RETURNS boolean AS $$
BEGIN
DELETE FROM platforms_compatibility WHERE (platform1=platform_n) OR (platform2=platform_n);
RETURN true;
END;
$$ LANGUAGE plpgsql;