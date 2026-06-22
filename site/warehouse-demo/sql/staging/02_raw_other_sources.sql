-- Additional raw land tables (minimal demo DDL)
USE DemoRiversDWH;
GO

IF OBJECT_ID('raw.CareCase', 'U') IS NOT NULL DROP TABLE raw.CareCase;
GO
CREATE TABLE raw.CareCase (
    CaseId VARCHAR(32) NOT NULL,
    OpenedDateTime DATETIME2 NULL,
    SourceContactId VARCHAR(32) NULL,
    PatientPseudoId VARCHAR(16) NULL,
    CaseStatus VARCHAR(32) NULL,
    ExtractInclusionFlag INT NULL,
    load_batch_id VARCHAR(36) NOT NULL,
    loaded_at_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('raw.LegendaryReferral', 'U') IS NOT NULL DROP TABLE raw.LegendaryReferral;
GO
CREATE TABLE raw.LegendaryReferral (
    ReferralId VARCHAR(32) NOT NULL,
    PatientPseudoId VARCHAR(16) NULL,
    ReferralDateTime DATETIME2 NULL,
    Status VARCHAR(32) NULL,
    load_batch_id VARCHAR(36) NOT NULL,
    loaded_at_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('raw.RosterFlowShift', 'U') IS NOT NULL DROP TABLE raw.RosterFlowShift;
GO
CREATE TABLE raw.RosterFlowShift (
    ShiftId VARCHAR(32) NOT NULL,
    SyntheticStaffId VARCHAR(16) NULL,
    ShiftDate DATE NULL,
    IsBankShift CHAR(1) NULL,
    UrgentCareFlag CHAR(1) NULL,
    load_batch_id VARCHAR(36) NOT NULL,
    loaded_at_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('raw.LedgerPosting', 'U') IS NOT NULL DROP TABLE raw.LedgerPosting;
GO
CREATE TABLE raw.LedgerPosting (
    LedgerLineId VARCHAR(32) NOT NULL,
    PostingDate DATE NULL,
    FinancialMonth CHAR(7) NULL,
    CostCentreCode VARCHAR(16) NULL,
    AccountCode VARCHAR(16) NULL,
    AmountGBP DECIMAL(18,2) NULL,
    load_batch_id VARCHAR(36) NOT NULL,
    loaded_at_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
