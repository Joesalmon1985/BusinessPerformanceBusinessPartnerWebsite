-- QA views for demo validation
USE DemoRiversDWH;
GO

CREATE OR ALTER VIEW qa.OrphanCareCaseSourceContact AS
SELECT c.CaseId, c.SourceContactId, c.OpenedDateTime, c.CaseStatus
FROM stg.CareCase c
WHERE c.SourceContactId IS NOT NULL
  AND c.SourceContactId <> ''
  AND NOT EXISTS (
      SELECT 1 FROM stg.CareCallContact cc WHERE cc.ContactId = c.SourceContactId
  );
GO

CREATE OR ALTER VIEW qa.MonthlyContactCaseTrend AS
SELECT
    FORMAT(cc.ContactDate, 'yyyy-MM') AS ReportingMonth,
    SUM(CASE WHEN cc.ContactType = 'IUCS' THEN 1 ELSE 0 END) AS IUCSContactCount,
    COUNT(DISTINCT c.CaseId) AS CaseOpenedCount,
    SUM(CASE WHEN c.SourceContactId IS NULL OR c.SourceContactId = '' THEN 1 ELSE 0 END) AS CasesWithoutSourceContact
FROM stg.CareCallContact cc
FULL OUTER JOIN stg.CareCase c
    ON FORMAT(c.OpenedDateTime, 'yyyy-MM') = FORMAT(cc.ContactDate, 'yyyy-MM')
GROUP BY FORMAT(cc.ContactDate, 'yyyy-MM');
GO

CREATE OR ALTER VIEW qa.ExpiredLocalOpsMappingInUse AS
SELECT m.SyntheticStaffId, m.ValidToDate, m.MappingConfidence
FROM stg.LocalOpsUserMapping m
WHERE m.ValidToDate IS NOT NULL
  AND TRY_CAST(m.ValidToDate AS DATE) < CAST('2026-01-01' AS DATE);
GO
