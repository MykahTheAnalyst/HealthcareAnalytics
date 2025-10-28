-- 1️⃣ Drop existing summary table if it exists
DROP TABLE IF EXISTS dbo.EHR_Workflow_Summary_Aggregate;

-- 2️⃣ Create aggregated summary table
SELECT
    Department,
    Shift,
    
    -- Overall encounter counts
    COUNT(*) AS Total_Encounters,
    
    -- Cycle time metrics (minutes)
    ROUND(AVG(DATEDIFF(MINUTE, RegistrationTime, DischargeTime)), 2) AS Avg_Total_Encounter_Time,
    ROUND(MIN(DATEDIFF(MINUTE, RegistrationTime, DischargeTime)), 2) AS Min_Total_Encounter_Time,
    ROUND(MAX(DATEDIFF(MINUTE, RegistrationTime, DischargeTime)), 2) AS Max_Total_Encounter_Time,
    
    ROUND(AVG(DATEDIFF(MINUTE, RegistrationTime, TriageTime)), 2) AS Avg_Registration_to_Triage,
    ROUND(AVG(DATEDIFF(MINUTE, TriageTime, ProviderStartTime)), 2) AS Avg_Triage_to_Provider,
    ROUND(AVG(DATEDIFF(MINUTE, ProviderStartTime, DocumentationStartTime)), 2) AS Avg_Provider_to_Documentation,
    ROUND(AVG(DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime)), 2) AS Avg_Documentation_Duration,
    
    -- SLA adherence
    SUM(CASE WHEN DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) <= 30 THEN 1 ELSE 0 END) AS SLA_Provider_Start_Count,
    ROUND(100.0 * SUM(CASE WHEN DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) <= 30 THEN 1 ELSE 0 END)/COUNT(*), 2) AS SLA_Provider_Start_Percent,
    
    SUM(CASE WHEN DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime) <= 60 THEN 1 ELSE 0 END) AS SLA_Documentation_Count,
    ROUND(100.0 * SUM(CASE WHEN DATEDIFF(MINUTE, DocumentationStartTime, DocumentationEndTime) <= 60 THEN 1 ELSE 0 END)/COUNT(*), 2) AS SLA_Documentation_Percent,
    
    -- Documentation quality & rework
    SUM(CASE WHEN DocumentationEndTime <= DATEADD(HOUR, 24, DischargeTime) THEN 1 ELSE 0 END) AS Docs_Within_24h_Count,
    ROUND(100.0 * SUM(CASE WHEN DocumentationEndTime <= DATEADD(HOUR, 24, DischargeTime) THEN 1 ELSE 0 END)/COUNT(*), 2) AS Docs_Within_24h_Percent,
    
    SUM(CASE WHEN ISNULL(NumberOfEdits, 0) > 0 THEN 1 ELSE 0 END) AS Rework_Encounters,
    ROUND(100.0 * SUM(CASE WHEN ISNULL(NumberOfEdits, 0) > 0 THEN 1 ELSE 0 END)/COUNT(*), 2) AS Rework_Percent,
    
    -- Critical delay tracking
    SUM(CASE 
        WHEN TriageLevel <= 2 AND DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) > 180 THEN 1
        WHEN TriageLevel = 3 AND DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) > 200 THEN 1
        ELSE 0 
    END) AS Critical_Delay_Count,
    ROUND(100.0 * SUM(CASE 
        WHEN TriageLevel <= 2 AND DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) > 180 THEN 1
        WHEN TriageLevel = 3 AND DATEDIFF(MINUTE, RegistrationTime, ProviderStartTime) > 200 THEN 1
        ELSE 0 
    END)/COUNT(*), 2) AS Critical_Delay_Percent,
    
    -- Provider workload
    ROUND(AVG(Provider_Encounter_Count), 2) AS Avg_Encounters_Per_Provider,
    ROUND(AVG(Avg_Encounter_Time_Per_Provider), 2) AS Avg_Encounter_Time_Per_Provider

INTO dbo.EHR_Workflow_Summary_Aggregate
FROM dbo.EHR_Workflow_Summary
GROUP BY
    Department,
    Shift
ORDER BY
    Department,
    Shift;

-- 3️⃣ Preview the aggregated summary table
SELECT * 
FROM dbo.EHR_Workflow_Summary_Aggregate;
