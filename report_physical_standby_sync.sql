set heading off
select '..........................   STANDBY DATABASE SYNC INFORMATION FOR '||name||' DATABASE................' from v$database;
set heading on
SET FEEDBACK OFF
set verify off
set lin 180
col "Host Name" for a14
col "Instance Name" for a15
col "Thread" for a10
col "MAIN - Archived" for a15
col "STBY - Archived" for a15
col "STBY - Applied" for a15
col "Shipping GAP (PROD -> STBY)" for a12
col "Applied GAP (STBY -> STBY)" for a11
select * from (
        select  lpad(t1,5,' ') "Thread",to_char(sysdate,'Mon dd, hh24:mi:ss') "Time",substr(Host_Name,1,15) "Host Name",substr(Instance_Name,1,13) "Instance Name",
                lpad(pricre,9,' ') "MAIN - Archived",
                lpad(stdcre,10,' ') "STBY - Archived",
                lpad(stdnapp,9,' ')  "STBY - Applied",
                lpad(pricre-stdcre,13,' ') "Shipping GAP (MAIN -> STBY)",
                lpad(stdcre-stdnapp,15,' ') "Applied GAP (STBY -> STBY)"
        from
        (select max(sequence#) stdcre, thread# t1 from v$archived_log arc, v$database dat where arc.resetlogs_change#=dat.resetlogs_change# group by thread# ) a ,
        (select max(sequence#) stdnapp, thread# t2 from v$archived_log arc, v$database_incarnation i where applied='YES' and arc.resetlogs_id=i.resetlogs_id and i.status='CURRENT' group by thread#) b,
        (select max(sequence#) pricre, thread# t3 from v$archived_log arc, v$database dat where arc.resetlogs_change#=dat.resetlogs_change# and dest_id=1 group by thread#) c ,
        (select to_char(sysdate,'Mon dd, hh24:mi:ss') "Time",host_name,instance_name,thread# t4 from gv$instance) d
        where a.t1=b.t2 and b.t2=c.t3 and c.t3=a.t1 and t4 =+ t1 and t4 =+ t2 and t4 =+ t3 union all select ' ', ' ',' ', ' ', ' ', ' ', ' ', ' ', ' '  from dual) order by 1 ;
SET HEADING OFF
prom
