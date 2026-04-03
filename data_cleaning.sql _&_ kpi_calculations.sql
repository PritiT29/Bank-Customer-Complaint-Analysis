/* Project: Bank Customer Complaint Analysis
   Purpose: This script transforms raw CFPB data into the structured 
            format required for the Tableau Dashboard.
*/
--Data Cleaning & Preparation
--It ensures the data is uniform, handles null values in geographic fields, and filters out incomplete records.

-- Create a Cleaned View of the Bank Complaints
CREATE OR REPLACE VIEW `bank_analytics.cleaned_complaints` AS
SELECT 
    complaint_id,
    date_received,
    -- Standardizing Product/Issue categories
    COALESCE(product, 'General Banking') AS product_category,
    COALESCE(issue, 'Other') AS issue_type,
    -- Cleaning State/Geo data
    UPPER(state) AS state_code,
    -- Converting Boolean-style text to actual flags
    CASE WHEN timely_response = 'Yes' THEN 1 ELSE 0 END AS is_timely,
    CASE WHEN consumer_disputed = 'Yes' THEN 1 ELSE 0 END AS is_disputed,
    -- Defining 'In Progress' status
    CASE WHEN company_response = 'In progress' THEN 1 ELSE 0 END AS is_in_progress,
    submitted_via,
    company_response
FROM 
    `bank_analytics.raw_complaints`
WHERE 
    date_received IS NOT NULL;


--KPI Calculations
--These queries generate the specific numbers shown in dashboard's top "Hero Cards."

--A. Total & Rolling 12-Month Complaints
--Calculates the "86,893" and "20,202" figures seen in your "Total Complaints" card.

SELECT 
    COUNT(complaint_id) AS total_complaints,
    -- Calculating complaints from the last 12 months from a fixed point (June 2016 based on your dashboard)
    COUNT(CASE WHEN date_received >= '2015-06-01' AND date_received <= '2016-06-30' THEN 1 END) AS rolling_12_months
FROM `bank_analytics.cleaned_complaints`;

--B. Timely Response & In Progress Rates
--Calculates the "98.90%" and "0.38%" metrics.

SELECT 
    -- Timely Response %
    ROUND(SUM(is_timely) * 100.0 / COUNT(*), 2) AS timely_response_rate,
    
    -- In Progress Count & %
    SUM(is_in_progress) AS total_in_progress,
    ROUND(SUM(is_in_progress) * 100.0 / COUNT(*), 2) AS in_progress_rate
FROM `bank_analytics.cleaned_complaints`;

--C. Submission Channel Breakdown
--Powers the "Submitted Via" green bar chart on the right of  dashboard.

SELECT 
    submitted_via,
    COUNT(*) AS volume,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM `bank_analytics.cleaned_complaints`
GROUP BY 1
ORDER BY volume DESC;


--3. Advanced Analysis: Company Response Breakdown
--Powers the "Company Response" table in the center of dashboard.

SELECT 
    company_response,
    COUNT(*) AS total_cases,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS response_percentage
FROM `bank_analytics.cleaned_complaints`
GROUP BY 1
ORDER BY total_cases DESC;
