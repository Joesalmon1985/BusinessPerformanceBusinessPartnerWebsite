-- raw.CareCallContact — 1:1 land from carecall_contacts.csv
USE DemoRiversDWH;
GO

IF OBJECT_ID('raw.CareCallContact', 'U') IS NOT NULL DROP TABLE raw.CareCallContact;
GO

CREATE TABLE raw.CareCallContact (
    ContactId               VARCHAR(32)  NOT NULL,
    ContactDateTime         DATETIME2    NULL,
    ContactDate             DATE         NULL,
    ContactType             VARCHAR(32)  NULL,
    Pathway                 VARCHAR(32)  NULL,
    Outcome                 VARCHAR(32)  NULL,
    PatientPseudoId         VARCHAR(16)  NULL,
    NHSNumberDemo           VARCHAR(20)  NULL,
    CallerPhoneHash         VARCHAR(32)  NULL,
    CareCaseCaseId          VARCHAR(32)  NULL,
    LegendaryCareReferralId VARCHAR(32)  NULL,
    LegendaryCareEncounterId VARCHAR(32) NULL,
    CallbackOfContactId     VARCHAR(32)  NULL,
    LinkageScenario         VARCHAR(32)  NULL,
    AmbiguousMatchIds       VARCHAR(256) NULL,
    AgentUsername           VARCHAR(64)  NULL,
    QueueName               VARCHAR(32)  NULL,
    AbandonedFlag           CHAR(1)      NULL,
    TransferTarget          VARCHAR(64)  NULL,
    CreatedDateTime         DATETIME2    NULL,
    ExtractBatchDate        DATE         NULL,
    load_batch_id           VARCHAR(36)  NOT NULL,
    loaded_at_utc           DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Additional raw tables follow same land-as-is pattern (abbreviated in demo)
-- See staging/01_stg_tables.sql for typed staging layer
