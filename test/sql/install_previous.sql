-- install_previous.sql : install previous version of E-Maj as an extension
--
------------------------------------------------------------
-- install dblink
------------------------------------------------------------
CREATE EXTENSION dblink;

-----------------------------
-- set the default_tablespace parameter to tspemaj to store new technical tables into this tablespace
-----------------------------
ALTER TABLESPACE tspemaj_renamed RENAME TO tspemaj;
SET default_tablespace TO tspemaj;

------------------------------------------------------------
-- emaj installation in 2.0.1 as extension
------------------------------------------------------------
CREATE EXTENSION emaj VERSION '2.0.1';

------------------------------------------------------------
-- check installation
------------------------------------------------------------
-- check impact in catalog
select extname, extversion from pg_extension where extname = 'emaj';

-- check the emaj_param content
SELECT param_value_text FROM emaj.emaj_param WHERE param_key = 'emaj_version';

-- check history
select hist_id, hist_function, hist_event, hist_object, regexp_replace(regexp_replace(hist_wording,E'\\d\\d\.\\d\\d\\.\\d\\d\\.\\d\\d\\d','%','g'),E'\\[.+\\]','(timestamp)','g'), hist_user from 
  (select * from emaj.emaj_hist order by hist_id) as t;

