-- Project 1: Emergency Department (ER) Performance Optimization

-- 1️⃣ Drop existing summary table if it exists
DROP TABLE IF EXISTS dbo.ER_Performance_Summary;

-- 2️⃣ Create a unified summary table
SELECT
    Shift,
    FORMAT(ArrivalTime, 'h:mm tt') AS ArrivalTime,  -- Formats to 8:00 AM, 1:00 PM, etc.
    TriageLevel,

    -- Core operational KPIs
    COUNT(*) AS Total_Cases,
    ROUND(AVG(WaitTime_Mins), 2) AS Avg_Wait_Time,
    ROUND(MIN(WaitTime_Mins), 2) AS Min_Wait_Time,
    ROUND(MAX(WaitTime_Mins), 2) AS Max_Wait_Time,

    -- Staffing metrics
    SUM(StaffOnDuty) AS Total_Staff_On_Duty,
    ROUND(AVG(CriticalCases_OnShift), 2) AS Avg_Critical_Cases,
    
    -- Walkout analytics
    SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) AS Total_Walkouts,
    ROUND(100.0 * SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Walkout_Rate_Percent,
    
    -- Critical Delay Detection
    SUM(CASE 
        WHEN TriageLevel IN (1,2) AND WaitTime_Mins > 180 THEN 1
        WHEN TriageLevel = 3 AND WaitTime_Mins > 200 THEN 1
        ELSE 0 END) AS Critical_Delay_Count,
    
    -- Efficiency metric (encounters under 150 mins wait)
    ROUND(100.0 * SUM(CASE WHEN WaitTime_Mins <= 150 THEN 1 ELSE 0 END) / COUNT(*), 2) AS Pct_Efficient_Encounters,

    -- Workload metric
    ROUND(1.0 * COUNT(*) / NULLIF(SUM(StaffOnDuty),0), 2) AS Workload_Per_Staff,

    -- For staffing-to-demand correlation in Power BI
    COUNT(*) * 1.0 AS Demand_For_Shift  

INTO dbo.ER_Performance_Summary
FROM dbo.ER_Encounters
GROUP BY
    Shift,
    ArrivalTime,
    TriageLevel
ORDER BY
    Shift,
    ArrivalTime,
    TriageLevel;

-- 3️⃣ Preview the summary table
SELECT * 
FROM dbo.ER_Performance_Summary
ORDER BY Shift, ArrivalTime, TriageLevel;
