CREATE PROCEDURE sp_BackupDatabases  
            @databaseName sysname = null,  
            @backupType CHAR(1),  
            @backupLocation nvarchar(200)   
AS           
 SET NOCOUNT ON;                   
    DECLARE @DBs TABLE  
    (  
        ID int IDENTITY PRIMARY KEY,  
        DBNAME nvarchar(500)  
    )  
  
    INSERT INTO @DBs (DBNAME)  
    SELECT Name FROM master.sys.databases  
    WHERE state=0  
    AND (name=@DatabaseName OR @DatabaseName IS NULL)  
    ORDER BY Name  
  
 DELETE @DBs WHERE DBNAME IN ('master','model','msdb','tempdb','Northwind','pubs','AdventureWorks')  
                     
    -- Declare variables  
    DECLARE @BackupName VARCHAR(100)  
    DECLARE @BackupFile VARCHAR(100)  
    DECLARE @DBNAME VARCHAR(300)  
    DECLARE @sqlCommand NVARCHAR(1000)   
 DECLARE @dateTime NVARCHAR(20)  
    DECLARE @Loop INT                    
                                 
    SELECT @Loop = MIN(ID) FROM @DBs  
           
 WHILE @Loop IS NOT NULL  
 BEGIN  
           
 SET @DBNAME = '['+(SELECT DBNAME FROM @DBs WHERE ID = @Loop)+']'  
           
 SET @dateTime = REPLACE(CONVERT(VARCHAR, GETDATE(),101),'/','') + '_' +  REPLACE(CONVERT(VARCHAR, GETDATE(),108),':','')    
           
 IF @backupType = 'F'  
  SET @BackupFile = @backupLocation+REPLACE(REPLACE(@DBNAME, '[',''),']','')+ '_FULL_'+ @dateTime+ '.BAK'  
 ELSE IF @backupType = 'D'  
  SET @BackupFile = @backupLocation+REPLACE(REPLACE(@DBNAME, '[',''),']','')+ '_DIFF_'+ @dateTime+ '.BAK'  
 ELSE IF @backupType = 'L'  
  SET @BackupFile = @backupLocation+REPLACE(REPLACE(@DBNAME, '[',''),']','')+ '_LOG_'+ @dateTime+ '.TRN'  
           
 IF @backupType = 'F'  
  SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') +' full backup for '+ @dateTime  
 IF @backupType = 'D'  
  SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') +' differential backup for '+ @dateTime  
 IF @backupType = 'L'  
  SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') +' log backup for '+ @dateTime  
           
 IF @backupType = 'F'   
    BEGIN  
        SET @sqlCommand = 'BACKUP DATABASE ' +@DBNAME+  ' TO DISK = '''+@BackupFile+ ''' WITH INIT, NAME= ''' +@BackupName+''', NOSKIP, NOFORMAT'  
    END  
 IF @backupType = 'D'  
    BEGIN  
        SET @sqlCommand = 'BACKUP DATABASE ' +@DBNAME+  ' TO DISK = '''+@BackupFile+ ''' WITH DIFFERENTIAL, INIT, NAME= ''' +@BackupName+''', NOSKIP, NOFORMAT'          
    END  
 IF @backupType = 'L'   
    BEGIN  
        SET @sqlCommand = 'BACKUP LOG ' +@DBNAME+  ' TO DISK = '''+@BackupFile+ ''' WITH INIT, NAME= ''' +@BackupName+''', NOSKIP, NOFORMAT'          
    END  
           
 EXEC(@sqlCommand)  
           
 SELECT @Loop = min(ID) FROM @DBs where ID>@Loop  
           
END