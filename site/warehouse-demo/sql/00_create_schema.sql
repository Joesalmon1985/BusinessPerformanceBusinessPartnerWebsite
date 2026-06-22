-- Demo Rivers Health warehouse — schema bootstrap
-- Azure SQL demonstration artefact only. Not deployed to live Azure.

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'DemoRiversDWH')
BEGIN
    CREATE DATABASE DemoRiversDWH;
END
GO

USE DemoRiversDWH;
GO

CREATE SCHEMA raw;
GO
CREATE SCHEMA stg;
GO
CREATE SCHEMA dwh;
GO
CREATE SCHEMA mart;
GO
CREATE SCHEMA qa;
GO
