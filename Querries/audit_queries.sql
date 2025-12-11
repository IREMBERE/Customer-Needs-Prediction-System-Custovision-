-- ===========================================================
-- CustoVision Project
-- AUDIT & SECURITY QUERIES
-- Purpose: Track triggers, violations, blocked actions,
--          and ensure business rule compliance
-- ===========================================================

---------------------------------------------------------------
-- 1. View all audit logs (allowed + blocked)
---------------------------------------------------------------
SELECT
    audit_id,
    username,
    action_type,
    table_name,
    action_time,
    allowed,
    reason
FROM action_audit
ORDER BY action_time DESC;


---------------------------------------------------------------
-- 2. Show blocked actions only (policy violations)
---------------------------------------------------------------
SELECT
    username,
    action_type,
    table_name,
    action_time,
    reason
FROM action_audit
WHERE allowed = 'NO'
ORDER BY action_time DESC;


---------------------------------------------------------------
-- 3. Daily audit summary
---------------------------------------------------------------
SELECT
    TRUNC(action_time) AS audit_date,
    SUM(CASE WHEN allowed = 'YES' THEN 1 ELSE 0 END) AS allowed_actions,
    SUM(CASE WHEN allowed = 'NO'  THEN 1 ELSE 0 END) AS blocked_actions
FROM action_audit
GROUP BY TRUNC(action_time)
ORDER BY audit_date DESC;


---------------------------------------------------------------
-- 4. Check if employees attempted actions on restricted days
---------------------------------------------------------------
SELECT
    username,
    action_type,
    table_name,
    action_time,
    reason
FROM action_audit
WHERE reason LIKE '%WEEKDAY%' 
   OR reason LIKE '%HOLIDAY%'
ORDER BY action_time DESC;


---------------------------------------------------------------
-- 5. Show upcoming holidays (for system enforcement)
---------------------------------------------------------------
SELECT
    holiday_date,
    description
FROM public_holidays
WHERE holiday_date >= TRUNC(SYSDATE)
ORDER BY holiday_date;
