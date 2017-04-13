/********************
* file: report_basic_health_check.sql
*
* author: Jesus Sanchez (jsanchez.consultant@gmail.com)
*
* copyright notice: creative commons attribution-sharealike 4.0 international license
************************************/

SET linesize 32000
SET pagesize 40000
SET trimspool ON
SET trimout ON
SET wrap OFF

COLUMN title format a100
COLUMN NAME format a30

SET heading OFF
SELECT '========== DATABASE INFORMATION ==========' title FROM dual;
SELECT 'DATABASE NAME: '||db_unique_name FROM v$database;
SELECT 'NUMBER OF INSTANCES: '||MAX(inst_id) FROM gv$instance;
SELECT 'DATABASE HOSTS: '||listagg(host_name,', ') WITHIN GROUP(ORDER BY inst_id) FROM gv$instance;
SELECT 'DATA DISKGROUP/PATH: '||VALUE FROM v$spparameter WHERE upper(NAME)='DB_CREATE_FILE_DEST';
SELECT 'RECOVERY DISKGROUP/PATH: '||VALUE FROM v$spparameter WHERE upper(NAME)='DB_RECOVERY_FILE_DEST';
PROMPT
SET heading OFF
SELECT '========== SGA INFO ==========' title FROM dual;
SET heading ON
COLUMN gb_per_instance FORMAT a30
SELECT NAME, listagg(round(bytes/1024/1024/1024,2),', ') WITHIN GROUP(ORDER BY inst_id) gb_per_instance 
FROM gv$sgainfo 
WHERE upper(NAME) LIKE '%SIZE' 
AND upper(NAME) NOT LIKE 'GRANULE%' 
GROUP BY NAME 
ORDER BY 2 DESC;
PROMPT
SET heading OFF
SELECT '========== CPU INFO ==========' title FROM dual;
SELECT 'Number of cores/CPUs assigned to instance '||inst_id||': '||VALUE
FROM gv$spparameter
WHERE UPPER(name)='CPU_COUNT'
ORDER BY inst_id;
SET heading ON
COLUMN metric_name FORMAT a40
COLUMN value_per_instance FORMAT a40
COLUMN metric_unit FORMAT a30
SELECT metric_name, listagg(ROUND(VALUE,4),' | ') WITHIN GROUP (ORDER BY inst_id) value_per_instance, metric_unit
FROM gv$sysmetric
WHERE metric_name LIKE '%CPU%' 
GROUP BY metric_name, metric_unit
ORDER BY 2,1;
PROMPT
SET heading OFF
SELECT '========== ASM OPERATIONS ==========' title FROM dual;
SET heading ON
SELECT ag.NAME, ao.operation, ao.state, ao.est_minutes FROM v$asm_operation ao, v$asm_diskgroup ag ORDER BY ao.est_minutes;
PROMPT
SET heading OFF
SELECT '========== ASM DISKGROUP STATUS ==========' title FROM dual;
SET heading ON
COLUMN "TOTAL GB" format 999,999.99
COLUMN "FREE GB" format 999,999.99
COLUMN "USABLE GB" format 999,999.99
COLUMN "FREE %" format 99.99
SELECT NAME
	, offline_disks
	, state
	, round(total_mb/1024,2) "TOTAL GB"
	, round(free_mb/1024,2) "FREE GB"
	, round(usable_file_mb/1024,2) "USABLE GB"
	, round(usable_file_mb*100/total_mb,2) "FREE %" 
FROM v$asm_diskgroup
WHERE NAME IN (
	SELECT substr(VALUE,2,LENGTH(VALUE))
	FROM v$spparameter
	WHERE upper(NAME) LIKE ('DB_%_FILE_DEST')
) ORDER BY 1;
PROMPT
SET heading OFF
SELECT '========== SERVICES ==========' title FROM dual;
SET heading ON
COLUMN INSTANCES format a30
SELECT NAME, listagg(inst_id,',') WITHIN GROUP (ORDER BY inst_id) INSTANCES
FROM gv$active_services
WHERE NAME NOT LIKE 'SYS%'
GROUP BY NAME
ORDER BY 1;
PROMPT
SET heading OFF
SELECT '========== BLOCKING LOCKS ==========' title FROM dual;
SET heading ON
COLUMN "BLOCKER COUNT" format 999999999
SELECT "BLOCKER COUNT" FROM(
SELECT count(
   blocker.SID
) "BLOCKER COUNT"
FROM (SELECT *
      FROM gv$lock
      WHERE BLOCK != 0
      AND TYPE = 'TX') blocker
,    gv$lock            waiting
WHERE waiting.TYPE='TX' 
AND waiting.BLOCK = 0
AND waiting.id1 = blocker.id1
);
PROMPT
SET heading OFF
SELECT '========== BLOCKING SESSIONS ==========' title FROM dual;
SET heading ON
COLUMN username format a16
SELECT
   sess.username
,  sess.osuser
,  blocker.SID blocker_sid
,  sess.sql_id
,  waiting.request
,  count(waiting.SID) waiting_sid
,  MAX(trunc(waiting.ctime/60)) max_min_waiting
FROM (SELECT *
      FROM gv$lock
      WHERE BLOCK != 0
      AND TYPE = 'TX') blocker
,    gv$lock            waiting
, gv$session sess
WHERE waiting.TYPE='TX' 
AND waiting.BLOCK = 0
AND waiting.id1 = blocker.id1
AND sess.SID=blocker.SID
GROUP BY sess.username, sess.osuser, blocker.SID, sess.sql_id, waiting.request;

SET heading OFF
SELECT '========== BLOCKING SQLS ==========' title FROM dual;
SET heading ON
SELECT DISTINCT sql_id, sql_text
FROM gv$sql
WHERE sql_id IN (
	SELECT
	   DISTINCT sess.sql_id
	FROM (SELECT *
		  FROM gv$lock
		  WHERE BLOCK != 0
		  AND TYPE = 'TX') blocker
	,    gv$lock            waiting
	, gv$session sess
	WHERE waiting.TYPE='TX' 
	AND waiting.BLOCK = 0
	AND waiting.id1 = blocker.id1
	AND sess.SID=blocker.SID
);
PROMPT
SET heading OFF
SELECT '========== LONG DB OPERATIONS ==========' title FROM dual;
SET heading ON
SELECT s.username, l.SID, l.serial#, l.opname, l.totalwork, l.sofar, round(l.sofar*100/l.totalwork) percent_complete
FROM gv$session_longops l, gv$session s
WHERE totalwork > 0
AND sofar*100/totalwork < 100
AND l.SID = s.SID
AND l.serial# = s.serial#;
PROMPT
SET heading OFF
SELECT '========== PENDING DISTRIBUTED TRANSACTIONS ==========' title FROM dual;
SET heading ON
SELECT local_tran_id, state, tran_comment,host,db_user,advice
FROM dba_2pc_pending
WHERE state='PREPARED';
PROMPT
SET heading OFF
SELECT '========== APP/USER SESSIONS ==========' title FROM dual;
COLUMN "COUNT" format a80
COLUMN machine format a30
break ON status
WITH list_view AS (
	SELECT status, username, osuser, machine, service_name, inst_id, count(1) session_count
	FROM gv$session
	WHERE status='ACTIVE'
	GROUP BY  inst_id, status, username, osuser, machine, service_name
	UNION ALL
	SELECT status, username, osuser, machine, service_name, inst_id, count(1) session_count
	FROM gv$session
	WHERE status='INACTIVE'
	GROUP BY inst_id, status, username, osuser, machine, service_name
) 
SELECT status, username, osuser, machine, service_name, listagg('INST: '||inst_id||', COUNT: '||session_count,' | ') WITHIN GROUP (ORDER BY inst_id) "COUNT"
FROM list_view
WHERE machine NOT IN (
	SELECT host_name
	FROM gv$instance
)
GROUP BY status, username, osuser, machine , service_name
ORDER BY 1,3,2,4;
PROMPT
SET heading OFF
SELECT '========== INTERNAL SESSIONS COUNT ==========' title FROM dual;
SET heading ON
SELECT 'ACTIVE SESSIONS' "SESSIONS", count(1) "COUNT"
FROM gv$session
WHERE status='ACTIVE'
AND username IN ('SYS','SYSTEM','DBSNMP')
UNION ALL
SELECT 'INACTIVE SESSIONS', count(1) "COUNT"
FROM gv$session
WHERE status='INACTIVE'
AND username IN ('SYS','SYSTEM','DBSNMP');
PROMPT
SET heading OFF
SELECT '========== OUTDATED STATS OBJECTS ==========' title FROM dual;
SET heading ON
COLUMN outdated_stats_objects FORMAT 999,000
SELECT owner, count(table_name) outdated_stats_objects
FROM dba_tables
WHERE last_analyzed < SYSDATE - 7
GROUP BY owner
ORDER BY 1;
