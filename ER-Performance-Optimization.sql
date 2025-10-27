🚑 Project 1: Emergency Department (ER) Performance Optimization
Goal: Reduce ER wait times, minimize walkouts, and optimize staffing efficiency.

/* =============================================
   Query 1: Wait Time and Walkout Rate by Shift
   Purpose: Identify performance variation across shifts
   ============================================= */

SELECT 
    Shift,
    ROUND(AVG(WaitTime_Mins), 2) AS Avg_Wait_Time,
    ROUND(100.0 * SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Walkout_Rate_Percent,
    COUNT(*) AS Total_Cases
FROM dbo.ER_Encounters
GROUP BY Shift
ORDER BY Avg_Wait_Time DESC;

/* =============================================
   Query 2: Staffing Correlation with Wait Time
   Purpose: Identify bottlenecks and under-resourced shifts
   ============================================= */

SELECT
    TriageLevel,
    AVG(StaffOnDuty) AS Avg_Staff_On_Duty,
    ROUND(AVG(WaitTime_Mins), 2) AS Avg_Wait_Time
FROM dbo.ER_Encounters
GROUP BY TriageLevel
ORDER BY Avg_Wait_Time DESC;

/* =============================================
   Query 3: Arrival Time Performance Analysis
   Purpose: Identify peak arrival periods impacting wait time
   ============================================= */

SELECT
    ArrivalTimePeriod,
    COUNT(*) AS Total_Cases,
    ROUND(AVG(WaitTime_Mins), 2) AS Avg_Wait_Time,
    ROUND(100.0 * SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Walkout_Rate_Percent
FROM dbo.ER_Encounters
GROUP BY ArrivalTimePeriod
ORDER BY Avg_Wait_Time DESC;


/* =============================================
   Query 4: KPI Dashboard View
   Purpose: Generate summary for Power BI 
   ============================================= */

CREATE OR ALTER VIEW vw_ER_Performance AS
SELECT
    Shift,
    COUNT(*) AS Total_Cases,
    ROUND(AVG(WaitTime_Mins), 2) AS Avg_Wait_Time,
    ROUND(AVG(CriticalCases_OnShift), 2) AS Avg_Critical_Cases,
    ROUND(AVG(StaffOnDuty), 2) AS Avg_Staff_On_Duty,
    ROUND(100.0 * SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Walkout_Rate_Percent
FROM dbo.ER_Encounters
GROUP BY Shift;
GO

-- Validate
SELECT * FROM vw_ER_Performance ORDER BY Avg_Wait_Time DESC;


/* =============================================
   Query 5: High-Risk Encounter Identification
   Purpose: Flag critical cases exceeding safe wait thresholds
   ============================================= */

SELECT
    CaseID,
    Shift,
    TriageLevel,
    WaitTime_Mins,
    StaffOnDuty,
    Walkout_YN,
    CASE 
        WHEN TriageLevel <= 2 AND WaitTime_Mins > 180 THEN 'Critical Delay'
        WHEN TriageLevel = 3 AND WaitTime_Mins > 200 THEN 'Potential Bottleneck'
        ELSE 'Normal'
    END AS Risk_Category
FROM dbo.ER_Encounters
ORDER BY WaitTime_Mins DESC;
