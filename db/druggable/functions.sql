-- return all drugs for each source
CREATE OR REPLACE FUNCTION sources_and_drugs() RETURNS setof text AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT table_name FROM information_schema.tables  WHERE table_type= 'BASE TABLE' AND table_name like 'ctd_%'
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;