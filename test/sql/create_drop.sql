-- create_drop.sql : prepare groups content and test emaj_create_group(), emaj_comment_group() 
-- emaj_drop_group(), emaj_force_drop_group() and emaj_alter_group() functions
--
SET client_min_messages TO WARNING;
-----------------------------
-- prepare groups
-----------------------------
delete from emaj.emaj_group_def;
insert into emaj.emaj_group_def values ('myGroup1','myschema1','mytbl1',20);
insert into emaj.emaj_group_def values ('myGroup1','myschema1','mytbl2',NULL,NULL,NULL,'tsplog1','tsplog1');
insert into emaj.emaj_group_def values ('myGroup1','myschema1','mytbl2b',NULL,'b',NULL,'tsp log''2','tsp log''2');
insert into emaj.emaj_group_def values ('myGroup1','myschema1','myTbl3_col31_seq',1);
insert into emaj.emaj_group_def values ('myGroup1','myschema1','myTbl3',10,'C',NULL,'tsplog1');
insert into emaj.emaj_group_def values ('myGroup1','myschema1','mytbl4',20,NULL,NULL,'tsplog1','tsp log''2');

insert into emaj.emaj_group_def values ('myGroup2','myschema2','mytbl1');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','mytbl2');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','myTbl3_col31_seq');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','myTbl3',NULL,'C');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','mytbl4',NULL,NULL,'myschema2_mytbl4');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','mytbl5',NULL,NULL,'otherPrefix4mytbl5');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','mytbl6');
insert into emaj.emaj_group_def values ('myGroup2','myschema2','myseq1');
-- The third group name contains space, comma # and '
-- (note myTbl4 from "phil's schema3" remains outside phil's group#3", group)
insert into emaj.emaj_group_def values ('phil''s group#3",','phil''s schema3','phil''s tbl1',NULL,' #''3');
insert into emaj.emaj_group_def values ('phil''s group#3",','phil''s schema3',E'myTbl2\\');
insert into emaj.emaj_group_def values ('phil''s group#3",','phil''s schema3',E'myTbl2\\_col21_seq');
insert into emaj.emaj_group_def values ('phil''s group#3",','phil''s schema3',E'phil''s seq\\1');

insert into emaj.emaj_group_def values ('myGroup4','myschema4','mytblm');
insert into emaj.emaj_group_def values ('myGroup4','myschema4','mytblc1');
insert into emaj.emaj_group_def values ('myGroup4','myschema4','mytblc2');

insert into emaj.emaj_group_def values ('dummyGrp1','dummySchema','mytbl4');
insert into emaj.emaj_group_def values ('dummyGrp1','myschema1','dummyTable');
insert into emaj.emaj_group_def values ('dummyGrp2','emaj','emaj_param');
insert into emaj.emaj_group_def values ('dummyGrp2','emajC','myschema1_myTbl3_log');
insert into emaj.emaj_group_def values ('dummyGrp3','myschema1','mytbl1');
insert into emaj.emaj_group_def values ('dummyGrp3','myschema2','mytbl2');

-----------------------------
-- disable event triggers 
-----------------------------
-- this is done to allow tests with missing or renamed or altered components
-- triggers will be re-enabled in misc.sql
select emaj.emaj_disable_protection_by_event_triggers();

-----------------------------
-- emaj_create_group() tests
-----------------------------

-- invalid group names
select emaj.emaj_create_group(NULL);
select emaj.emaj_create_group('',false);
-- group is unknown in emaj_group_def
select emaj.emaj_create_group('unknownGroup');
select emaj.emaj_create_group('unknownGroup',false);
-- unknown schema or table in emaj_group_def
select emaj.emaj_create_group('dummyGrp1');
-- group with a temp table
begin;
  CREATE TEMPORARY TABLE myTempTbl (
    col1       INT     NOT NULL,
    PRIMARY KEY (col1)
  );
  insert into emaj.emaj_group_def 
    select 'myGroup5',nspname,'mytemptbl' from pg_class, pg_namespace
      where relnamespace = pg_namespace.oid and relname = 'mytemptbl';
-- should be ko with pg 8.4+
  select emaj.emaj_create_group('myGroup5');
rollback;

-- group with an unlogged table
begin;
  insert into emaj.emaj_group_def values ('myGroup5','myschema5','myunloggedtbl');
  select emaj.emaj_create_group('myGroup5');
rollback;
-- table without pkey for a rollbackable group
select emaj.emaj_create_group('phil''s group#3",',true);
-- sequence with a log schema suffix defined in the emaj_group_def table
begin;
  update emaj.emaj_group_def set grpdef_log_schema_suffix = 'something' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_create_group('myGroup1');
rollback;
-- sequence with an emaj names prefix defined in the emaj_group_def table
begin;
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'something' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_create_group('myGroup1');
rollback;
-- sequence with tablespace defined in the emaj_group_def table
begin;
  update emaj.emaj_group_def set grpdef_log_dat_tsp = 'something' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_create_group('myGroup1');
rollback;
-- table with invalid tablespace
begin;
  update emaj.emaj_group_def set grpdef_log_dat_tsp = 'dummyTablespace' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
  select emaj.emaj_create_group('myGroup1');
rollback;
-- already existing secondary schema
begin;
  create schema emajb;
  select emaj.emaj_create_group('myGroup1');
rollback;
-- conflict on emaj names prefix inside the group to create
begin;
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'samePrefix' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'samePrefix' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl2';
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'myschema1_mytbl4' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3';
  select emaj.emaj_create_group('myGroup1');
rollback;
-- conflict on emaj names prefix with already create groups
begin;
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'samePrefix' where grpdef_group = 'myGroup1' and grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
  select emaj.emaj_create_group('myGroup1');
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'samePrefix' where grpdef_group = 'myGroup2' and grpdef_schema = 'myschema2' and grpdef_tblseq = 'mytbl1';
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'myschema1_mytbl2' where grpdef_group = 'myGroup2' and grpdef_schema = 'myschema2' and grpdef_tblseq = 'mytbl2';
  select emaj.emaj_create_group('myGroup2');
rollback;

-- should be OK
select emaj.emaj_create_group('myGroup1');

-- should be OK, but with a warning for linked table not protected by E-Maj
alter table myschema2.myTbl6 add foreign key (col61) references myschema2.myTbl7 (col71) deferrable initially immediate;
alter table myschema2.myTbl8 add foreign key (col81) references myschema2.myTbl6 (col61) deferrable;
select emaj.emaj_create_group('myGroup2',true);

-- should be OK, but with a warning for linked table belonging to another group
begin;
  update emaj.emaj_group_def set grpdef_group = 'dummyGrp3' 
    where grpdef_schema = 'phil''s schema3' and grpdef_tblseq = E'myTbl2\\';
  select emaj.emaj_create_group('phil''s group#3",',false);
rollback;

-- should be OK, but with a warning for linked table not belonging to any group
begin;
  delete from emaj.emaj_group_def
    where grpdef_schema = 'phil''s schema3' and grpdef_tblseq = E'myTbl2\\';
  select emaj.emaj_create_group('phil''s group#3",',false);
rollback;

-- should be OK
select emaj.emaj_create_group('phil''s group#3",',false);
select emaj.emaj_create_group('myGroup4');

-- create a group with a table from an E-Maj secondary schema
select emaj.emaj_create_group('dummyGrp2',false);

-- create a group with a table already belonging to another group
select emaj.emaj_create_group('dummyGrp3');

-- already created
select emaj.emaj_create_group('myGroup2');

-- impact of created groups
select nspname from pg_namespace where nspname like 'emaj%' order by nspname;
select group_name, group_is_logging, group_is_rlbk_protected, group_nb_table, group_nb_sequence, group_is_rollbackable, 
       group_creation_time_id, group_last_alter_time_id, group_comment
 from emaj.emaj_group order by group_name;
select * from emaj.emaj_relation order by rel_group, rel_priority, rel_schema, rel_tblseq;
select * from pg_tables where schemaname like 'emaj%' order by tablename;

-----------------------------
-- emaj_comment_group() tests
-----------------------------

-- unknown group
select emaj.emaj_comment_group(NULL,NULL);
select emaj.emaj_comment_group('unkownGroup',NULL);

-- should be OK
select emaj.emaj_comment_group('myGroup1','a first comment for group #1');
select emaj.emaj_comment_group('myGroup1','a better comment for group #1');

select group_name, group_comment from emaj.emaj_group where group_name = 'myGroup1';
select emaj.emaj_comment_group('myGroup1',NULL);
select group_name, group_comment from emaj.emaj_group where group_name = 'myGroup1';

-----------------------------
-- emaj_drop_group() tests
-----------------------------

-- unknown group
select emaj.emaj_drop_group(NULL);
select emaj.emaj_drop_group('unkownGroup');
-- group in logging state
select emaj.emaj_start_group('myGroup1','');
select emaj.emaj_drop_group('myGroup1');
select emaj.emaj_stop_group('myGroup1');
-- secondary schema with an object blocking the schema drop
begin;
  create table emajb.dummy_log (col1 int);
  select emaj.emaj_drop_group('myGroup1');
rollback;
-- should be OK
select emaj.emaj_drop_group('myGroup1');
select emaj.emaj_drop_group('myGroup2');

-- already dropped
select emaj.emaj_drop_group('myGroup2');

-----------------------------
-- emaj_force_drop_group() tests
-----------------------------

-- unknown group
select emaj.emaj_force_drop_group(NULL);
select emaj.emaj_force_drop_group('unkownGroup');
-- already dropped
select emaj.emaj_force_drop_group('myGroup2');
-- should be OK
select emaj.emaj_create_group('myGroup1',false);
select emaj.emaj_start_group('myGroup1','');
select emaj.emaj_force_drop_group('myGroup1');

select emaj.emaj_create_group('myGroup2',true);
select emaj.emaj_force_drop_group('myGroup2');

-----------------------------
-- emaj_alter_group() tests
-----------------------------
-- unknown group
select emaj.emaj_alter_group(NULL);
select emaj.emaj_alter_group('unkownGroup');
-- group in logging state
select emaj.emaj_create_group('myGroup1');
select emaj.emaj_start_group('myGroup1','');
select emaj.emaj_alter_group('myGroup1');
select emaj.emaj_stop_group('myGroup1');
-- alter a group with a table now already belonging to another group
begin;
  select emaj.emaj_create_group('myGroup2');
  insert into emaj.emaj_group_def values ('myGroup1','myschema2','mytbl1');
  select emaj.emaj_alter_group('myGroup1');
rollback;
-- the group is now empty
begin;
  delete from emaj.emaj_group_def where grpdef_group = 'myGroup1';
  select emaj.emaj_alter_group('myGroup1');
rollback;
-- schema suffix cannot be changed for sequence
begin;
  update emaj.emaj_group_def set grpdef_log_schema_suffix = 'dummy' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_alter_group('myGroup1');
rollback;
-- object names prefix cannot be changed for sequence
begin;
  update emaj.emaj_group_def set grpdef_emaj_names_prefix = 'dummy' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_alter_group('myGroup1');
rollback;
-- log tablespace cannot be changed for sequence
begin;
  update emaj.emaj_group_def set grpdef_log_dat_tsp = 'b' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_alter_group('myGroup1');
rollback;
begin;
  update emaj.emaj_group_def set grpdef_log_idx_tsp = 'b' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
  select emaj.emaj_alter_group('myGroup1');
rollback;

-- should be OK
-- nothing to change
select group_name, group_is_logging, group_is_rlbk_protected, group_nb_table, group_nb_sequence, group_is_rollbackable, 
       group_creation_time_id, group_last_alter_time_id, group_comment
 from emaj.emaj_group where group_name = 'myGroup1';
select emaj.emaj_alter_group('myGroup1');
select group_name, group_is_logging, group_is_rlbk_protected, group_nb_table, group_nb_sequence, group_is_rollbackable, 
       group_creation_time_id, group_last_alter_time_id, group_comment
 from emaj.emaj_group where group_name = 'myGroup1';
select nspname from pg_namespace where nspname like 'emaj%' order by nspname;
-- only 3 tables to remove (+ log schemas emajb and emajC)
delete from emaj.emaj_group_def where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl2b';
delete from emaj.emaj_group_def where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3';
delete from emaj.emaj_group_def where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl4';
select emaj.emaj_alter_group('myGroup1');
select group_nb_table, group_nb_sequence from emaj.emaj_group where group_name = 'myGroup1';
select nspname from pg_namespace where nspname like 'emaj%' order by nspname;
-- only 1 sequence to remove
delete from emaj.emaj_group_def where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3_col31_seq';
select emaj.emaj_alter_group('myGroup1');
select group_nb_table, group_nb_sequence from emaj.emaj_group where group_name = 'myGroup1';
-- 3 tables to add (+ log schemas emajb and emajC)
insert into emaj.emaj_group_def values ('myGroup1','myschema1','mytbl2b',NULL,'b',NULL,'tsp log''2','tsp log''2');
insert into emaj.emaj_group_def values ('myGroup1','myschema1','myTbl3',10,'C',NULL,'tsplog1');
insert into emaj.emaj_group_def values ('myGroup1','myschema1','mytbl4',20,NULL,NULL,'tsplog1','tsp log''2');
select emaj.emaj_alter_group('myGroup1');
select group_nb_table, group_nb_sequence from emaj.emaj_group where group_name = 'myGroup1';
select nspname from pg_namespace where nspname like 'emaj%' order by nspname;
-- only 1 sequence to add
insert into emaj.emaj_group_def values ('myGroup1','myschema1','myTbl3_col31_seq',1);
select emaj.emaj_alter_group('myGroup1');
select group_nb_table, group_nb_sequence from emaj.emaj_group where group_name = 'myGroup1';
-- only change the log schema
update emaj.emaj_group_def set grpdef_log_schema_suffix = NULL where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3';
select emaj.emaj_alter_group('myGroup1');
select nspname from pg_namespace, pg_class where relnamespace = pg_namespace.oid and relname = 'myschema1_myTbl3_log';
update emaj.emaj_group_def set grpdef_log_schema_suffix = 'C' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3';
select emaj.emaj_alter_group('myGroup1');
select nspname from pg_namespace, pg_class where relnamespace = pg_namespace.oid and relname = 'myschema1_myTbl3_log';
-- only change the emaj_names_prefix for 1 table
update emaj.emaj_group_def set grpdef_emaj_names_prefix = 's1t3' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3';
select emaj.emaj_alter_group('myGroup1');
select count(*) from "emajC".s1t3_log;
update emaj.emaj_group_def set grpdef_emaj_names_prefix = NULL where grpdef_schema = 'myschema1' and grpdef_tblseq = 'myTbl3';
select emaj.emaj_alter_group('myGroup1');
select count(*) from "emajC".myschema1_myTbl3_log;
-- only change the log data tablespace for 1 table
update emaj.emaj_group_def set grpdef_log_dat_tsp = NULL where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl2b';
select emaj.emaj_alter_group('myGroup1');
select spcname from pg_tablespace, pg_class where reltablespace = pg_tablespace.oid and relname = 'myschema1_mytbl2b_log';
update emaj.emaj_group_def set grpdef_log_dat_tsp = 'tsp log''2' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl2b';
select emaj.emaj_alter_group('myGroup1');
select spcname from pg_tablespace, pg_class where reltablespace = pg_tablespace.oid and relname = 'myschema1_mytbl2b_log';
-- change the log data tablespace for all tables of a group
update emaj.emaj_group_def set grpdef_log_dat_tsp = case when grpdef_log_dat_tsp is NULL then 'tsplog1' when grpdef_log_dat_tsp = 'tsplog1' then 'tsp log''2' else NULL end where grpdef_schema = 'myschema1' and grpdef_tblseq not like '%seq';
select emaj.emaj_alter_group('myGroup1');
update emaj.emaj_group_def set grpdef_log_dat_tsp = case when grpdef_log_dat_tsp = 'tsplog1' then NULL when grpdef_log_dat_tsp = 'tsp log''2' then 'tsplog1' else 'tsp log''2' end where grpdef_schema = 'myschema1' and grpdef_tblseq not like '%seq';
select emaj.emaj_alter_group('myGroup1');
-- only change the log index tablespace
update emaj.emaj_group_def set grpdef_log_idx_tsp = NULL where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl2b';
select emaj.emaj_alter_group('myGroup1');
select spcname from pg_tablespace, pg_class where reltablespace = pg_tablespace.oid and relname = 'myschema1_mytbl2b_log_idx';
update emaj.emaj_group_def set grpdef_log_idx_tsp = 'tsp log''2' where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl2b';
select emaj.emaj_alter_group('myGroup1');
select spcname from pg_tablespace, pg_class where reltablespace = pg_tablespace.oid and relname = 'myschema1_mytbl2b_log_idx';
-- only change the priority
update emaj.emaj_group_def set grpdef_priority = 30 where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
select emaj.emaj_alter_group('myGroup1');
select rel_priority from emaj.emaj_relation where rel_schema = 'myschema1' and rel_tblseq = 'mytbl1';
update emaj.emaj_group_def set grpdef_priority = NULL where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
select emaj.emaj_alter_group('myGroup1');
select rel_priority from emaj.emaj_relation where rel_schema = 'myschema1' and rel_tblseq = 'mytbl1';
update emaj.emaj_group_def set grpdef_priority = 20 where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
select emaj.emaj_alter_group('myGroup1');
select rel_priority from emaj.emaj_relation where rel_schema = 'myschema1' and rel_tblseq = 'mytbl1';

-- change the table structure
alter table myschema1.mytbl1 add column newcol int;
select emaj.emaj_alter_group('myGroup1');
alter table myschema1.mytbl1 rename newcol to newcol2;
select emaj.emaj_alter_group('myGroup1');
alter table myschema1.mytbl1 alter column newcol2 type bigint;
select emaj.emaj_alter_group('myGroup1');
alter table myschema1.mytbl1 alter column newcol2 set default 0;
-- NB: changing default has no impact on emaj component 
select emaj.emaj_alter_group('myGroup1');
alter table myschema1.mytbl1 drop column newcol2;
select emaj.emaj_alter_group('myGroup1');

-- rename a table and/or change its schema
alter table myschema1.mytbl1 rename to mytbl1_new_name;
update emaj.emaj_group_def set grpdef_tblseq = 'mytbl1_new_name' 
  where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1';
select emaj.emaj_alter_group('myGroup1');
alter table myschema1.mytbl1_new_name set schema public;
update emaj.emaj_group_def set grpdef_schema = 'public'
  where grpdef_schema = 'myschema1' and grpdef_tblseq = 'mytbl1_new_name';
select emaj.emaj_alter_group('myGroup1');
alter table public.mytbl1_new_name rename to mytbl1;
alter table public.mytbl1 set schema myschema1;
update emaj.emaj_group_def set grpdef_schema = 'myschema1', grpdef_tblseq = 'mytbl1'
  where grpdef_schema = 'public' and grpdef_tblseq = 'mytbl1_new_name';
select emaj.emaj_alter_group('myGroup1');

-- missing emaj components
drop trigger emaj_log_trg on myschema1.mytbl1;
select emaj.emaj_alter_group('myGroup1');
drop function emaj.myschema1_mytbl1_log_fnct() cascade;
select emaj.emaj_alter_group('myGroup1');
drop table emaj.myschema1_mytbl1_log;
select emaj.emaj_alter_group('myGroup1');

-----------------------------
-- test end: check and force sequences id
-----------------------------
select emaj.emaj_force_drop_group('myGroup1');
select emaj.emaj_force_drop_group('myGroup2');
select nspname from pg_namespace where nspname like 'emaj%' order by nspname;
select hist_function, hist_event, hist_object, regexp_replace(regexp_replace(hist_wording,E'\\d\\d\.\\d\\d\\.\\d\\d\\.\\d\\d\\d','%','g'),E'\\[.+\\]','(timestamp)','g'), hist_user from 
  (select * from emaj.emaj_hist order by hist_id) as t
  where hist_function <> 'EMAJ_INSTALL';
select time_id, time_last_emaj_gid, time_event from emaj.emaj_time_stamp order by time_id;

alter sequence emaj.emaj_hist_hist_id_seq restart 2000;
alter sequence emaj.emaj_time_stamp_time_id_seq restart 200;
alter sequence emaj.emaj_mark_mark_id_seq restart 200;

