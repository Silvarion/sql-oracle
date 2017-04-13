set heading off
select '.................. TABLESPACE USAGE AND ALLOCATION INFORMATION FOR '||db_unique_name||' DATABASE................' from v$database;
set heading on
set verify off
set line 150
col tablespace_name for a40
column " CURGB " format 9,999,990.00
column " MAXGB " format 9,999,990.00
column " TOTALUSEDGB " format  9,999,990.00
column " TOTALFREEGB " format 9,999,990.00
column " USED% " format 990.00
select a.tablespace_name,
        round(a.physical_bytes/(1024*1024*1024),0) "CURGB",
        round(a.bytes_alloc/(1024*1024*1024),0) "MAXGB",
        round(nvl(b.tot_used,0)/(1024*1024*1024),0) "TOTALUSEDGB",
        round((a.bytes_alloc/(1024*1024*1024))-nvl(b.tot_used,0)/(1024*1024*1024),0) "TOTALFREEGB",
        ROUND(((nvl(b.tot_used,0)/a.bytes_alloc)*100),2) "USED%"
from ( select tablespace_name,
       sum(bytes) physical_bytes,
       sum(decode(autoextensible,'NO',bytes,'YES',maxbytes)) bytes_alloc
       from dba_data_files
       group by tablespace_name ) a,
     ( select tablespace_name, sum(bytes) tot_used
       from dba_segments
       group by tablespace_name ) b
where a.tablespace_name = b.tablespace_name (+)
and   a.tablespace_name not in (select distinct tablespace_name from dba_temp_files)
having ROUND(((nvl(b.tot_used,0)/a.bytes_alloc)*100),2) >= 70
order by 6 DESC
prom
