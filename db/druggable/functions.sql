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
WHERE tablename  = 'drugs')
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
WHERE tablename  = 'features')
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

-- this version returns platforms and their human-readable names (without sources or data types!)
CREATE OR REPLACE FUNCTION platform_list (cohort_n text, data_type text, previous_platforms text) RETURNS setof text
AS $$
DECLARE
table_n text;
platforms_array text array;
flag boolean;
offset integer;
platform_n text;
description text;
BEGIN
platforms_array := string_to_array(previous_platforms, ',');
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE tablename  = 'platforms')
THEN
DELETE FROM platforms;
ELSE
CREATE TEMP TABLE platforms (platform character varying(256), visible_name character varying(256));
END IF;
SELECT table_name INTO table_n FROM guide_table WHERE (cohort=cohort_n) AND (type=data_type);
EXECUTE E'INSERT INTO platforms SELECT druggable.INFORMATION_SCHEMA.COLUMNS.column_name,platform_descriptions.fullname FROM druggable.INFORMATION_SCHEMA.COLUMNS JOIN platform_descriptions ON (druggable.INFORMATION_SCHEMA.COLUMNS.column_name=platform_descriptions.shortname) WHERE (druggable.INFORMATION_SCHEMA.COLUMNS.TABLE_NAME=\'' || table_n || E'\') AND (platform_descriptions.visibility = true);';
FOR platform_n, description IN SELECT * FROM platforms 
LOOP
IF NOT (previous_platforms = '')
THEN
SELECT check_platforms_compatibility(platform_n, platforms_array) INTO flag;
IF (flag)
THEN 
RETURN NEXT platform_n || '|' || description;
END IF;
ELSE
RETURN NEXT platform_n || '|' || description;
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

-- this function creates views which should be read in R
-- fname is file name - used for unique tables 
CREATE OR REPLACE FUNCTION plot_data_by_id (fname text, cohort text, type1 text, platform1 text, id1 text, tcga_code1 text default '%', type2 text default '', platform2 text default '', id2 text default '', tcga_code2 text default '%', type3 text default '', platform3 text default '', id3 text default '', tcga_code3 text default '%') RETURNS text AS $$
DECLARE
source_type text;
res text;
n integer;
table1 text;
table2 text;
table3 text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
SELECT source INTO source_type FROM guide_table WHERE table_name LIKE table1;
IF (type3 = '') THEN
IF (type2 = '') THEN
IF (source_type = 'TCGA') THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || platform1 || ' FROM ' || table1 || E' WHERE (id=\'' || id1 || E'\') AND (sample LIKE \'%-' || tcga_code1 || '\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || platform1 || ' FROM ' || table1 || E' WHERE id=\'' || id1 || E'\';';
END IF;
ELSE
-- have to do this, otherwise will get error table name "..." specified more than once
IF (type1 = type2) THEN
-- need expressions 2 and 3 to exclude situation when user have chosen "all" for both rows
IF ((source_type = 'TCGA') AND NOT(tcga_code1 = '%')) THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND ((SELECT right_trim(A.sample,2)) = (SELECT right_trim(B.sample,2))) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 || E' IS NOT NULL) AND (A.sample LIKE \'%-' || tcga_code1 || E'\') AND (B.sample LIKE \'%-' || tcga_code2 || E'\');';
ELSE
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.id=\'' || id1 || E'\') AND (B.id=\'' || id2 || E'\') AND (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL);';
END IF;
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2;
IF ((source_type = 'TCGA') AND NOT(tcga_code1 = tcga_code2) AND NOT(tcga_code1 = '%')) THEN
-- edit from here and below
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ((SELECT right_trim(' || table1 || '.sample, 2)) = (SELECT right_trim(' || table2 || '.sample, 2))) AND (' || table1 || E'.id=\'' || id1 || E'\') AND (' || table2 || E'.id=\'' || id2 || E'\') AND (' || table2 || '.' || platform2 ||' IS NOT NULL) AND ;';
ELSE 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || E'.id=\'' || id2 || E'\' AND '|| table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
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

-- function for boxplot: one axis with ids, the other without
CREATE OR REPLACE FUNCTION boxplot_data (fname text, cohort text, type1 text, platform1 text, id1 text, type2 text, platform2 text) RETURNS text AS $$
DECLARE
res text;
n integer;
table1 text;
table2 text;
BEGIN
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type1 || E'\';' INTO table1; 
IF (id1='') THEN
IF (type1 = type2) THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL);';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table2 || '.' || platform2 ||' IS NOT NULL;';
END IF;
ELSE
IF (type1 = type2) THEN
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT A.' || platform1 || ' AS ' || platform1 || '1,B.' || platform2 || ' AS '|| platform2 || '2 FROM ' || table1 || ' A,' || table1 || E' B WHERE (A.sample=B.sample) AND (A.id=\'' || id1 || E'\') (A.' || platform1 || ' IS NOT NULL) AND (B.' || platform2 ||' IS NOT NULL);';
ELSE
EXECUTE E'SELECT table_name FROM guide_table WHERE cohort=\'' || cohort || E'\' AND type=\'' || type2 || E'\';' INTO table2; 
EXECUTE 'CREATE VIEW temp_view' || fname || ' AS SELECT ' || table1 || '.' || platform1 || ' AS ' || platform1 ||'1,' || table2 || '.' || platform2 || ' AS ' || platform2 || '2 FROM ' || table1 || ' JOIN ' || table2 || ' ON ' || table1 || '.sample=' || table2 || '.sample AND ' || table1 || E'.id=\'' || id1 || E'\' AND ' || table2 || '.' || platform2 ||' IS NOT NULL;';
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
plots_array text array;
i integer;
BEGIN
temp_array := string_to_array(platforms, ',');
n := array_length(temp_array, 1);
plots_array := ARRAY[]::text[];
IF (n =1) THEN
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.platform1=ANY(temp_array)) AND (plot_types.platform2 IS NULL));
ELSE
IF (n=2) THEN
plots_array := ARRAY(SELECT DISTINCT (plot_types.plot) FROM plot_types WHERE (plot_types.platform1=temp_array[1] AND plot_types.platform2=temp_array[2]) OR (plot_types.platform1=temp_array[2] AND plot_types.platform2=temp_array[1]));
END IF;
END IF;
FOR i IN 1..array_length(plots_array, 1)
LOOP
RETURN NEXT plots_array[i];
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
string_length := string_length - 2;
EXECUTE E'SELECT substring(\'' || string || E'\' FROM 1 FOR ' || string_length || ');' INTO res;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION all_indexes_size () RETURNS setof text AS $$
BEGIN
DROP VIEW IF EXISTS indexes_size;
CREATE VIEW indexes_size AS SELECT indexname, tablename FROM pg_indexes;
FOR res IN SELECT * FROM  indexes_size
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

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
offset integer;
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
offset := 2;
ELSE
offset := 1;
END IF;
FOR platform_n, platform_type  IN EXECUTE E'SELECT column_name, data_type FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset || ';'
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
FOR j IN i..array_length(platforms_array, 1)
LOOP
plots := ARRAY[]::text[];
IF ((platforms_array[i] = ANY(km_array)) OR (platforms_array[j] = ANY(km_array)) AND NOT (platforms_array[i] = ANY(km_array) AND platforms_array[j] = ANY(km_array))) THEN
plots := ARRAY ['KM'::text];
ELSE
IF ((platforms_type_array[i] = 'numeric') AND (platforms_type_array[j] = 'numeric')) THEN
plots := ARRAY ['scatter'::text];
ELSE
IF (((platforms_type_array[i] = 'numeric') AND (platforms_type_array[j] = 'character varying')) OR ((platforms_type_array[j] = 'numeric') AND (platforms_type_array[i] = 'character varying'))) THEN
plots := ARRAY ['box'::text];
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
 
-- this functions adds ALL platforms to platform_descriptions and makes them visible
-- use ONLY for initial initialization!
CREATE OR REPLACE FUNCTION import_platforms() RETURNS boolean AS $$
DECLARE
table_n text;
platform_n text;
data_type text;
offset integer;
platforms_array text array;
i integer;
BEGIN
platforms_array := ARRAY[]::text[];
DELETE FROM platform_descriptions;
FOR table_n IN SELECT table_name FROM guide_table WHERE cohort IS NOT NULL
LOOP
EXECUTE E'SELECT type FROM guide_table WHERE table_name=\'' || table_n || E'\';' INTO data_type;
IF (SELECT check_ids_availability(data_type) = true) THEN
offset := 2;
ELSE
offset := 1;
END IF;
FOR platform_n IN EXECUTE E'SELECT column_name FROM druggable.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=\'' || table_n || E'\' OFFSET ' || offset || ';'
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
