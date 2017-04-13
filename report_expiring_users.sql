/********************
* File: plsql_schema_cleaner.sql
*
* Author: Jesus Sanchez (jsanchez.consultant@gmail.com)
*
* Copyright Notice: Creative Commons Attribution-ShareAlike 4.0 International License
************************************/

set heading off
SELECT '.........................'|| db_unique_name ||'...........................' FROM v$database;
set heading on
set verify off
set feedback off
set linesize 150
column "USER" format a15
column "EXPIRING" format a20
column "PROFILE" format a20
select distinct b.username "USER" , b.EXPIRY_DATE "EXPIRING",b.profile "PROFILE"
from dba_role_privs a, dba_users b 
where b.EXPIRY_DATE < SYSDATE
and b.profile in ('PROFILE_USER_PRIV', 'PROFILE_USER') 
and b.username not in (select distinct grantee from dba_role_privs where granted_role ='DBA') 
order by EXPIRY_DATE;
prom
