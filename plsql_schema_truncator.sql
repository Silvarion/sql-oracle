/********************
* File: plsql_schema_truncator.sql
*
* Author: Jesus Sanchez (jsanchez.consultant@gmail.com)
*
* Copyright Notice: Creative Commons Attribution-ShareAlike 4.0 International License
************************************/

set serveroutput on

DECLARE
/* Cursor for disabling constraints */
CURSOR c_const_disabler IS
	select 'alter table '||owner||'.'||table_name||' disable constraint "'||constraint_name||'" cascade;' stmnt
	from dba_constraints 
	where owner=UPPER('&&schema_name') 
	and status='ENABLED' 
	and constraint_type = 'R'
	and table_name not like 'BIN\$%';

/* Cursor for enabling constraints */
CURSOR c_const_enabler IS
	select 'alter table '||owner||'.'||table_name||' disable constraint "'||constraint_name||'" cascade;' stmnt
	from dba_constraints 
	where owner=UPPER('&&schema_name') 
	and status='DISABLED' 
	and constraint_type = 'R'
	and table_name not like 'BIN\$%';


/* Cursor for truncating tables */
CURSOR c_table_dropper IS
	select 'truncate '||object_type||' '||owner||'.'||object_name||';' stmnt
	from dba_objects 
	where owner=UPPER('&&schema_name')
	and object_type='TABLE'
	and object_name not like 'BIN$%';

BEGIN
	dbms_output.put_line('Disabling Constraints!');
	for v_sql in c_const_disabler
	loop
		dbms_output.put_line('To execute: '||v_sql.stmnt);
		--execute immediate v_sql;
	end loop;
	dbms_output.put_line('Truncating tables!');
	for v_sql in c_table_dropper
	loop
		dbms_output.put_line('To execute: '||v_sql.stmnt);
		--execute immediate v_sql.stmnt;
	end loop;
		dbms_output.put_line('Enabling Constraints!');
	for v_sql in c_const_enabler
	loop
		dbms_output.put_line('To execute: '||v_sql.stmnt);
		--execute immediate v_sql.stmnt;
	end loop;
	dbms_output.put_line('All done');
END;
/

undefine schema_name
