-- Provider-month mart
USE DemoRiversDWH;
GO

IF OBJECT_ID('mart.ProviderMonthUrgentCare', 'U') IS NOT NULL DROP TABLE mart.ProviderMonthUrgentCare;
GO
CREATE TABLE mart.ProviderMonthUrgentCare (
    ProviderCode            VARCHAR(8) NOT NULL,
    ReportingMonth          CHAR(7) NOT NULL,
    IUCSContactCount        INT NULL,
    CaseOpenedCount         INT NULL,
    OperationalCaseOpenedCount INT NULL,
    InferredLinkageCount    INT NULL,
    AgencyNursingSpendGBP   DECIMAL(18,2) NULL,
    _synthetic              BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ProviderMonthUrgentCare PRIMARY KEY (ProviderCode, ReportingMonth)
);
GO
