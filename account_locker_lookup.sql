SELECT das.os_username
	, das.username
	, das.userhost
	, das.TIMESTAMP
	, das.returncode
FROM edbs_audit.dba_audit_session das, dba_users du
WHERE das.username = du.username
	AND (das.username LIKE '%ACCOUNT_PATTERN%'
		OR du.account_status LIKE 'LOCKED%')
	AND das.action_name='LOGON'
	AND trunc(das.TIMESTAMP) > trunc(SYSDATE-1)
	AND das.returncode <> 0
ORDER BY TIMESTAMP;
