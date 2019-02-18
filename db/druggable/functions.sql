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
CREATE OR REPLACE FUNCTION data_for_source(source regclass) RETURNS 
TABLE (
feature character varying(64),
sample character varying(64),
value real)
AS $$
BEGIN
RETURN QUERY EXECUTE 'SELECT * FROM ' || source;
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
feature_name character varying(64))
AS $$
BEGIN
IF
EXISTS (SELECT * FROM pg_catalog.pg_tables 
WHERE schemaname = 'pg_temp_1'
AND tablename  = 'features')
THEN
DELETE FROM features;
ELSE
CREATE TEMP TABLE features (source character varying(64), feature character varying(64));
END IF;
INSERT INTO features SELECT DISTINCT screen, platform FROM best_drug_corrs_counts ORDER BY screen;
UPDATE features SET source=subquery.show_name FROM (SELECT DISTINCT screen, display_name FROM guide_table) AS subquery(source_name,show_name) WHERE features.source=subquery.source_name;
UPDATE features SET feature=subquery.show_name FROM (SELECT DISTINCT short_name, full_name FROM feature_table) AS subquery(short,show_name) WHERE features.feature=subquery.short;
RETURN QUERY SELECT * FROM features;
END;
$$ LANGUAGE plpgsql;