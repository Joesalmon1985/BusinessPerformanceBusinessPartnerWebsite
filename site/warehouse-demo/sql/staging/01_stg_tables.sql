-- Staging tables with DQ flags
USE DemoRiversDWH;
GO

IF OBJECT_ID('stg.CareCallContact', 'U') IS NOT NULL DROP TABLE stg.CareCallContact;
GO

CREATE TABLE stg.CareCallContact (
    ContactId               VARCHAR(32)  NOT NULL PRIMARY KEY,
    ContactDateTime         DATETIME2    NULL,
    ContactDate             DATE         NULL,
    CreatedDateTime         DATETIME2    NULL,
    ContactType             VARCHAR(32)  NULL,
    Pathway                 VARCHAR(32)  NULL,
    Outcome                 VARCHAR(32)  NULL,
    PatientPseudoId         VARCHAR(16)  NULL,
    CareCaseCaseId          VARCHAR(32)  NULL,
    LegendaryCareReferralId VARCHAR(32)  NULL,
    LinkageScenario         VARCHAR(32)  NULL,
    AmbiguousMatchIds       VARCHAR(256) NULL,
    CallbackOfContactId     VARCHAR(32)  NULL,
    date_boundary_mismatch_flag BIT NOT NULL DEFAULT 0,
    orphan_case_id_flag     BIT NOT NULL DEFAULT 0,
    load_batch_id           VARCHAR(36)  NOT NULL,
    loaded_at_utc           DATETIME2    NOT NULL
);
GO

IF OBJECT_ID('stg.CareCase', 'U') IS NOT NULL DROP TABLE stg.CareCase;
GO

CREATE TABLE stg.CareCase (
    CaseId                  VARCHAR(32)  NOT NULL PRIMARY KEY,
    OpenedDateTime          DATETIME2    NULL,
    ClosedDateTime          DATETIME2    NULL,
    CaseStatus              VARCHAR(32)  NULL,
    PrimaryPathway          VARCHAR(32)  NULL,
    SourceContactId         VARCHAR(32)  NULL,
    PatientPseudoId         VARCHAR(16)  NULL,
    ExtractInclusionFlag    INT          NULL,
    missing_source_contact_flag BIT NOT NULL DEFAULT 0,
    is_extract_inclusion_case BIT NOT NULL DEFAULT 0,
    opened_reporting_month  CHAR(7)      NULL,
    load_batch_id           VARCHAR(36)  NOT NULL,
    loaded_at_utc           DATETIME2    NOT NULL
);
GO

IF OBJECT_ID('stg.LocalOpsUserMapping', 'U') IS NOT NULL DROP TABLE stg.LocalOpsUserMapping;
GO

CREATE TABLE stg.LocalOpsUserMapping (
    SyntheticStaffId      VARCHAR(16)  NOT NULL,
    DisplayName           VARCHAR(128) NULL,
    ValidFromDate         DATE         NULL,
    ValidToDate           DATE         NULL,
    MappingConfidence     VARCHAR(16)  NULL,
    MappingNotes          VARCHAR(512) NULL,
    load_batch_id         VARCHAR(36)  NOT NULL,
    loaded_at_utc         DATETIME2    NOT NULL
);
GO
