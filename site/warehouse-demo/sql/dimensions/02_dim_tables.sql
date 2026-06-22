-- Dimension tables
USE DemoRiversDWH;
GO

IF OBJECT_ID('dwh.DimDate', 'U') IS NOT NULL DROP TABLE dwh.DimDate;
GO
CREATE TABLE dwh.DimDate (
    DateKey         INT NOT NULL PRIMARY KEY,
    CalendarDate    DATE NOT NULL,
    ReportingMonth  CHAR(7) NOT NULL,
    MonthName       VARCHAR(16) NULL,
    Year            INT NOT NULL
);
GO

IF OBJECT_ID('dwh.DimPatient', 'U') IS NOT NULL DROP TABLE dwh.DimPatient;
GO
CREATE TABLE dwh.DimPatient (
    PatientKey      INT IDENTITY(1,1) PRIMARY KEY,
    PatientPseudoId VARCHAR(16) NOT NULL UNIQUE,
    NHSNumberDemo   VARCHAR(20) NULL,
    DateOfBirth     DATE NULL,
    Sex             CHAR(1) NULL
);
GO

IF OBJECT_ID('dwh.DimStaff', 'U') IS NOT NULL DROP TABLE dwh.DimStaff;
GO
CREATE TABLE dwh.DimStaff (
    StaffKey              INT IDENTITY(1,1) PRIMARY KEY,
    SyntheticStaffId      VARCHAR(16) NOT NULL,
    DisplayName           VARCHAR(128) NULL,
    CareCallUsername      VARCHAR(64) NULL,
    CareCaseUsername      VARCHAR(64) NULL,
    MappingConfidence     VARCHAR(16) NULL,
    mapping_expired_flag  BIT NOT NULL DEFAULT 0
);
GO

IF OBJECT_ID('dwh.DimTeam', 'U') IS NOT NULL DROP TABLE dwh.DimTeam;
GO
CREATE TABLE dwh.DimTeam (
    TeamKey           INT IDENTITY(1,1) PRIMARY KEY,
    TeamCode          VARCHAR(16) NOT NULL,
    LocalTeamName     VARCHAR(64) NULL,
    RosterFlowTeamName VARCHAR(64) NULL,
    CostCentreCode    VARCHAR(16) NULL
);
GO
