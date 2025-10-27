   PROJECT : EHR Workflow Optimization
 

-- 1️⃣ Drop existing summary table if it already exists
DROP TABLE IF EXISTS dbo.EHR_Workflow_Summary;

-- 2️⃣ Create a unified summary table combining key KPIs
SELECT
    EncounterID,
    PatientID,
    ProviderID,
    Department,
    RegistrationTime,
    TriageTime,
    ProviderStartTime,
    DocumentationStartTime,
    DocumentationEndTime,
    DischargeTime,

    -- Cycle time calculations
    DATEDIFF(MINUTE, RegistrationTime, DischargeTime) AS Total_Encounter_Time,
    DATEDIFF(MINUTE, RegistrationTime, TriageTime) AS Registration_to_Triage,
    DATEDIFF(MINUTE, TriageTime, ProviderStartTime) AS Triage_to_Provider,
    DATEDIFF(MINUTE, ProviderStartTime, DocumentationStartTime) AS Provider_to_Documentation,
    DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime) AS Documentation_Duration,
    
    -- Documentation quality & compliance
    CASE 
        WHEN DocumentationEndTime <= DATEADD(HOUR, 24, DischargeTime) THEN 1 
        ELSE 0 
    END AS Documentation_Within_24h,
    CASE 
        WHEN ComplianceFlag = 'Y' THEN 1 
        ELSE 0 
    END AS Compliance_Flag,
    
    -- SLA adherence indicators
    CASE 
        WHEN DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) <= 30 THEN 1 
        ELSE 0 
    END AS SLA_Provider_Start,
    CASE 
        WHEN DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime) <= 60 THEN 1 
        ELSE 0 
    END AS SLA_Documentation_Time

INTO dbo.EHR_Workflow_Summary
FROM dbo.Patient_Encounters;

-- 3️⃣ Preview the final summary output
SELECT * 
FROM dbo.EHR_Workflow_Summary
ORDER BY Department, RegistrationTime;
