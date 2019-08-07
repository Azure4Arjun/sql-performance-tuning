CREATE QUEUE DeadlockQueue ;
GO
CREATE SERVICE DeadlockService
ON QUEUE DeadlockQueue
(
[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
);
GO
CREATE EVENT NOTIFICATION DeadlockNotification
ON SERVER
FOR DEADLOCK_GRAPH
TO SERVICE 'DeadlockService', 'current database';
GO
SELECT cast(message_body as xml) FROM dbo.DeadlockQueue;