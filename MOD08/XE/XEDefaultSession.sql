SELECT * 
FROM sys.dm_xe_sessions;

SELECT CAST(xet.target_data AS XML) AS XMLDATA
--INTO #SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
	JOIN sys.dm_xe_sessions xe
	ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health';

DECLARE @x XML = 
(SELECT CAST(xet.target_data as xml) FROM sys.dm_xe_session_targets xet 
JOIN sys.dm_xe_sessions xe 
ON (xe.address = xet.event_session_address) 
WHERE xe.name = 'system_health' AND target_name = 'ring_buffer')
SELECT t.e.value('@name', 'varchar(50)') AS EventName
 ,t.e.value('@timestamp', 'datetime') AS DateAndTime
 ,t.e.value('(data[@name="error"]/value)[1]', 'int') AS ErrNo
 ,t.e.value('(data[@name="severity"]/value)[1]', 'int') AS Severity
 ,t.e.value('(data[@name="message"]/value)[1]', 'varchar(max)') AS ErrMsg
 ,t.e.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS sql_text
FROM @x.nodes('//RingBufferTarget/event') AS t(e)
WHERE t.e.value('@name', 'varchar(50)') = 'error_reported';

SELECT CAST(XEventData.XEvent.value('(data/value)[1]', 'varchar(max)') AS XML) AS Deadlock
FROM
(SELECT CAST(target_data AS XML) AS TargetData
from sys.dm_xe_session_targets st
join sys.dm_xe_sessions s on s.address = st.event_session_address
where name = 'system_health') AS Data
CROSS APPLY TargetData.nodes ('//RingBufferTarget/event') AS XEventData (XEvent)
where XEventData.XEvent.value('@name', 'varchar(4000)') = 'xml_deadlock_report'
