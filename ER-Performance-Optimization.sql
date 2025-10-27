Project 1: Emergency Department (ER) Performance Optimization

-- 1️⃣  Drop existing summary table if it already exists
DROP TABLE IF EXISTS dbo.ER_Performance_Summary;

-- 2️⃣  Create a unified summary table combining key KPIs
SELECT
    Shift,
    ArrivalTime,
    TriageLevel,
    
    -- Core operational KPIs
    COUNT(*) AS Total_Cases,
    ROUND(AVG(WaitTime_Mins), 2) AS Avg_Wait_Time,
    
    -- Staffing metrics
    ROUND(AVG(StaffOnDuty), 2) AS Avg_Staff_On_Duty,
    ROUND(AVG(CriticalCases_OnShift), 2) AS Avg_Critical_Cases,
    
    -- Walkout analytics
    SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) AS Total_Walkouts,
    ROUND(100.0 * SUM(CASE WHEN Walkout_YN = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Walkout_Rate_Percent,
    
    -- Risk tagging logic
    SUM(CASE 
        WHEN TriageLevel <= 2 AND WaitTime_Mins > 180 THEN 1
        WHEN TriageLevel = 3 AND WaitTime_Mins > 200 THEN 1
        ELSE 0 END) AS Critical_Delay_Count,
    
    -- Efficiency indicator
    ROUND(AVG(CASE 
        WHEN WaitTime_Mins <= 150 THEN 1.0 
        ELSE 0.0 END) * 100, 2) AS Pct_Efficient_Encounters

INTO dbo.ER_Performance_Summary
FROM dbo.ER_Encounters
GROUP BY Shift, ArrivalTime, TriageLevel;

-- 3️⃣  Preview the final summary output
SELECT * FROM dbo.ER_Performance_Summary
ORDER BY Shift, ArrivalTime, TriageLevel;
