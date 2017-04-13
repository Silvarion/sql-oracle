/********************
* File: report_invalid_objects.sql
*
* Author: Jesus Sanchez (jsanchez.consultant@gmail.com)
*
* Copyright Notice: Creative Commons Attribution-ShareAlike 4.0 International License
************************************/
set feedback off
set heading off
SELECT '.........................'|| db_unique_name ||'...........................' FROM v$database;
set heading on
set linesize 300;
set pagesize 999;
col EDITION_NAME format a15
col OBJECT_NAME format a30
col OBJECT_TYPE format a20
col OWNER       format a20
col REFERENCED_OBJECT format a50
col REFERENCED_TYPE format a20
col REFERENCED_STATUS format a10
set lines 120 trims on pages 999
prom
set heading off
SELECT '......................... INVALID DEPENDENCY-FREE OBJECT COUNT ...........................' FROM dual;
set heading on
select do.edition_name, do.owner, do.object_type, count(do.object_name) "# of Invalid Objs"
from dba_objects do
where do.status = 'INVALID'
and do.owner not in ('PUBLIC','SYS','OLAPSYS')
and NOT EXISTS (
    select dd.name
    from dba_dependencies dd
    where dd.referenced_owner=do.owner
    and dd.referenced_name=do.object_name
)
group by do.edition_name, do.owner, do.object_type
order by 1,2,3;
prom
set heading off
SELECT '......................... INVALID DEPENDENCY-FREE OBJECT LIST WITH INVALID REFERENCES ...........................' FROM dual;
BREAK ON OBJECT_NAME
set heading on
select do.edition_name, do.owner, do.object_type, do.object_name
    , dd.referenced_owner||'.'||dd.referenced_name referenced_object, referenced_type, ro.status REF_STATUS
    , de.line, CASE 
WHEN INSTR(UPPER(de.text),'DOES NOT EXIST') > 1 THEN 'DO NOT EXIST: '||LTRIM(ds.text)
WHEN INSTR(UPPER(de.text),'TRANSLATION IS NO LONGER VALID') > 1 THEN 'SYNONYM INVALID: '||LTRIM(ds.text)
ELSE de.text
END error_msg_obj, do.last_ddl_time
from dba_objects do, dba_dependencies dd, dba_objects ro, dba_errors de, dba_source ds
where do.status = 'INVALID'
and do.owner not in ('PUBLIC','SYS','OLAPSYS')
and dd.owner = do.owner
and dd.name = do.object_name
and dd.type = do.object_type
and ro.object_type(+) = ds.type
and ro.owner(+) = ds.owner
and ro.object_name(+) = ds.name
and de.line = ds.line
and ro.owner = de.owner
and ro.object_type = de.type
and ro.object_name = de.name
and dd.referenced_owner = ro.owner
and dd.referenced_name = ro.object_name
and dd.referenced_type = ro.object_type
and de.text not like '%Statement ignored%'
and de.text not like '%Item ignored%'
and de.text not like '%Declaration ignored%'
and ro.status = 'INVALID'
and NOT EXISTS (
    select dd.name
    from dba_dependencies dd
    where dd.referenced_owner=do.owner
    and dd.referenced_name=do.object_name
    and dd.dependency_type='HARD'
)
order by 1 NULLS FIRST,2,3,5,4;
prom
column LINE format 999,999
column TEXT format a50
column LAST_DDL_TIME format a25
set heading off
SELECT '......................... INVALID DEPENDENCY-FREE OBJECT LIST WITH ERRORS ...........................' FROM dual;
set heading on
WITH invalids AS (
    SELECT distinct do.edition_name, do.owner, do.object_type, do.object_name, do.last_ddl_time 
    FROM dba_objects do, dba_dependencies dd, dba_objects ro
    WHERE do.status = 'INVALID'
    AND do.owner not in ('PUBLIC','SYS','OLAPSYS')
    AND dd.owner = do.owner
    AND dd.name = do.object_name
    AND dd.type = do.object_type
    AND dd.referenced_owner = ro.owner
    AND dd.referenced_name = ro.object_name
    AND dd.referenced_type = ro.object_type
    AND ro.status = 'VALID'
    AND NOT EXISTS (
        select dd.name
        from dba_dependencies dd
        where dd.referenced_owner=do.owner
        and dd.referenced_name=do.object_name
        and dd.dependency_type='HARD'
    )
)
SELECT inv.edition_name, inv.owner, inv.object_type, inv.object_name, de.line, 
CASE 
WHEN INSTR(UPPER(de.text),'DOES NOT EXIST') > 1 THEN 'NOT EXIST: '||TRIM(ds.text)
WHEN INSTR(UPPER(de.text),'TRANSLATION IS NO LONGER VALID') > 1 THEN 'SYNONYM INVALID: '||TRIM(ds.text)
ELSE de.text
END error_msg_obj, inv.last_ddl_time
FROM invalids inv, dba_errors de, dba_source ds
WHERE inv.owner = de.owner
AND inv.object_type = ds.type
AND inv.object_name = ds.name
AND inv.owner = ds.owner
AND inv.object_type = de.type
AND inv.object_name = de.name
AND de.line = ds.line
and de.text not like '%Statement ignored%'
and de.text not like '%Item ignored%'
and de.text not like '%Declaration ignored%'
order by 1 NULLS FIRST,2,3,4,5;
prom
set heading off
SELECT '......................... INVALID REFERENCED OBJECT LIST ...........................' FROM dual;
set heading on
select do.edition_name, do.owner, do.object_type, do.object_name, de.line, CASE 
WHEN INSTR(UPPER(de.text),'DOES NOT EXIST') > 1 THEN 'DO NOT EXIST: '||ds.text
WHEN INSTR(UPPER(de.text),'TRANSLATION IS NO LONGER VALID') > 1 THEN 'SYNONYM INVALID: '||ds.text
ELSE de.text
END error_msg_obj, do.last_ddl_time 
from dba_objects do, dba_errors de, dba_source ds
where do.status = 'INVALID'
and do.owner not in ('PUBLIC','SYS','OLAPSYS')
and do.owner = de.owner
and do.object_type = de.type
and do.object_name = de.name
and do.object_type = ds.type
and do.owner = ds.owner
and do.object_name = ds.name
and de.line = ds.line
and de.text not like '%Statement ignored%'
and de.text not like '%Item ignored%'
and de.text not like '%Declaration ignored%'
and EXISTS (
    select dd.name
    from dba_dependencies dd
    where dd.referenced_owner=do.owner
    and dd.referenced_name=do.object_name
    and dd.dependency_type='HARD'
)
order by 1,2,3;
