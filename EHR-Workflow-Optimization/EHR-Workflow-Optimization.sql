Project 2: EHR-Workflow-Optimization
 

-- 1️⃣ Drop existing summary table if it exists
DROP TABLE IF EXISTS dbo.EHR_Workflow_Summary;

-- 2️⃣ Create a unified summary table with enhanced KPIs
SELECT
    EncounterID,
    PatientID,
    ProviderID,
    Department,
    Shift,
    RegistrationTime,
    TriageTime,
    ProviderStartTime,
    DocumentationStartTime,
    DocumentationEndTime,
    DischargeTime,

    -- Cycle time calculations (minutes)
    DATEDIFF(MINUTE, RegistrationTime, DischargeTime) AS Total_Encounter_Time,
    DATEDIFF(MINUTE, RegistrationTime, TriageTime) AS Registration_to_Triage,
    DATEDIFF(MINUTE, TriageTime, ProviderStartTime) AS Triage_to_Provider,
    DATEDIFF(MINUTE, ProviderStartTime, DocumentationStartTime) AS Provider_to_Documentation,
    DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime) AS Documentation_Duration,

    -- SLA adherence
    CASE WHEN DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) <= 30 THEN 1 ELSE 0 END AS SLA_Provider_Start,
    CASE WHEN DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime) <= 60 THEN 1 ELSE 0 END AS SLA_Documentation_Time,

    -- Documentation quality & compliance
    CASE WHEN DocumentationEndTime <= DATEADD(HOUR, 24, DischargeTime) THEN 1 ELSE 0 END AS Documentation_Within_24h,
    CASE WHEN ComplianceFlag = 'Y' THEN 1 ELSE 0 END AS Compliance_Flag,

    -- Rework / edits tracking
    ISNULL(NumberOfEdits, 0) AS Documentation_Rework_Count,
    CASE WHEN ISNULL(NumberOfEdits, 0) > 0 THEN 1 ELSE 0 END AS Rework_Flag,

    -- Provider workload
    COUNT(EncounterID) OVER(PARTITION BY ProviderID, Shift) AS Provider_Encounter_Count,
    AVG(DATEDIFF(MINUTE, RegistrationTime, DischargeTime)) OVER(PARTITION BY ProviderID, Shift) AS Avg_Encounter_Time_Per_Provider,

    -- Patient flow efficiency
    CASE WHEN DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) <= 30 THEN 1 ELSE 0 END AS Patient_Flow_Within_Target,
    
    -- Risk tagging for critical delays
    CASE 
        WHEN TriageLevel <= 2 AND DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) > 180 THEN 1
        WHEN TriageLevel = 3 AND DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) > 200 THEN 1
        ELSE 0 
    END AS Critical_Delay_Flag

INTO dbo.EHR_Workflow_Summary
FROM dbo.Patient_Encounters;

-- 3️⃣ Preview the summary output
SELECT * 
FROM dbo.EHR_Workflow_Summary
ORDER BY Department, Shift, RegistrationTime;
