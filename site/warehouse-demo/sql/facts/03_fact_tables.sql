-- Fact tables
USE DemoRiversDWH;
GO

IF OBJECT_ID('dwh.FactCareCallContact', 'U') IS NOT NULL DROP TABLE dwh.FactCareCallContact;
GO
CREATE TABLE dwh.FactCareCallContact (
    ContactKey              BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContactId               VARCHAR(32) NOT NULL,
    ContactDateKey          INT NULL,
    CreatedDateKey          INT NULL,
    PatientKey              INT NULL,
    ContactType             VARCHAR(32) NULL,
    LinkageScenario         VARCHAR(32) NULL,
    CallbackOfContactId     VARCHAR(32) NULL,
    date_boundary_mismatch_flag BIT NOT NULL DEFAULT 0,
    orphan_case_id_flag     BIT NOT NULL DEFAULT 0
);
GO

IF OBJECT_ID('dwh.FactCareCase', 'U') IS NOT NULL DROP TABLE dwh.FactCareCase;
GO
CREATE TABLE dwh.FactCareCase (
    CaseKey                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    CaseId                  VARCHAR(32) NOT NULL,
    OpenedDateKey           INT NULL,
    PatientKey              INT NULL,
    SourceContactId         VARCHAR(32) NULL,
    CaseStatus              VARCHAR(32) NULL,
    is_extract_inclusion_case BIT NOT NULL DEFAULT 0,
    missing_source_contact_flag BIT NOT NULL DEFAULT 0
);
GO

IF OBJECT_ID('dwh.BridgeCareCallReferralCandidate', 'U') IS NOT NULL DROP TABLE dwh.BridgeCareCallReferralCandidate;
GO
CREATE TABLE dwh.BridgeCareCallReferralCandidate (
    BridgeKey       BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContactId       VARCHAR(32) NOT NULL,
    ReferralId      VARCHAR(32) NOT NULL,
    CandidateRank   INT NULL
);
GO

IF OBJECT_ID('dwh.BridgeCareCallInferredCase', 'U') IS NOT NULL DROP TABLE dwh.BridgeCareCallInferredCase;
GO
CREATE TABLE dwh.BridgeCareCallInferredCase (
    BridgeKey       BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContactId       VARCHAR(32) NOT NULL,
    CaseId          VARCHAR(32) NOT NULL,
    inference_rule_id VARCHAR(32) NULL,
    confidence_score DECIMAL(5,2) NULL
);
GO
