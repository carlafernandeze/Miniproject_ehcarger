-- LEVEL 1

-- Question 1: Number of users with sessions
SELECT COUNT(DISTINCT s.user_id) AS number_users
FROM sessions AS s
JOIN users AS u ON s.user_id = u.id;

-- Question 2: Number of chargers used by user with id 1
SELECT s.user_id, COUNT(DISTINCT s.charger_id) AS number_of_chargers
FROM sessions AS s
JOIN chargers AS c ON s.charger_id = c.id
WHERE s.user_id = 1;

-- LEVEL 2

-- Question 3: Number of sessions per charger type (AC/DC):
SELECT c.type, COUNT(s.id) AS number_of_sessions
FROM sessions AS s
JOIN chargers AS c ON s.charger_id = c.id
GROUP BY c.type;


-- Question 4: Chargers being used by more than one user
SELECT s.charger_id, COUNT(DISTINCT s.user_id) AS number_of_users
FROM sessions AS s
GROUP BY s.charger_id
HAVING COUNT(DISTINCT s.user_id) > 1;

-- Question 5: Average session time per charger
SELECT s.charger_id, 
ROUND(AVG((JULIANDAY(s.end_time) - JULIANDAY(s.start_time)) * 24 * 60),2) AS AVG_SESSION_MINUTES
FROM sessions AS s
GROUP BY s.charger_id;


-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)
SELECT DISTINCT u.name || ' ' || u.surname AS full_username
FROM sessions AS s
JOIN users AS u ON s.user_id = u.id
GROUP BY u.id, DATE(s.start_time)
HAVING COUNT(DISTINCT s.charger_id) > 1;

-- Question 7: Top 3 chargers with longer sessions
SELECT s.charger_id, 
ROUND(SUM((julianday(s.end_time) - julianday(s.start_time)) * 24 * 60), 2) AS total_duration
FROM sessions AS s
GROUP BY s.charger_id
ORDER BY total_duration DESC
LIMIT 3;

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)
SELECT AVG(user_count) AS average_users_per_charger
FROM (
SELECT COUNT(DISTINCT s.user_id) AS user_count
FROM sessions s
GROUP BY s.charger_id) AS charger_user_counts;

-- Question 9: Top 3 users with more chargers being used
SELECT s.user_id, COUNT(DISTINCT s.charger_id) AS charger_count
FROM sessions AS s
GROUP BY s.user_id
ORDER BY charger_count DESC
LIMIT 3;

-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both
SELECT 
SUM(CASE WHEN charger_type = 'AC' THEN user_id END) AS only_as_users,
SUM(CASE WHEN charger_type = 'DC' THEN user_id END) AS only_dc_users,
SUM(CASE WHEN charger_type = 'Both' THEN user_id END) AS both_type_users
FROM (
SELECT s.user_id,
CASE
WHEN COUNT(DISTINCT c.type) = 1 and MAX(c.type) = 'AC' THEN 'AC'
WHEN COUNT(DISTINCT c.type) = 1 and MAX(c.type) = 'DC' THEN 'DC'
ELSE 'Both'
END AS charger_type
FROM sessions AS s
JOIN chargers AS c ON s.charger_id = c.id
GROUP BY s.user_id) AS user_charger_types;

-- Question 11: Monthly average number of users per charger

SELECT 
c.id AS charger_id,
AVG(monthly_user_count) AS monthly_average_users
FROM (
SELECT s.charger_id,
COUNT(DISTINCT s.user_id) AS monthly_user_count,
strftime('%Y-%m', s.start_time) AS month
FROM sessions s
GROUP BY s.charger_id, strftime('%Y-%m', s.start_time)) AS user_counts
RIGHT JOIN chargers AS c ON c.id = user_counts.charger_id
GROUP BY c.id
ORDER BY c.id;

-- Question 12: Top 3 users per charger (for each charger, number of sessions)

SELECT user_id, charger_id, session_count
FROM (
SELECT user_id, charger_id, 
COUNT(*) AS session_count,
ROW_NUMBER() OVER (PARTITION BY charger_id ORDER BY COUNT(*) DESC) AS rank
FROM (
SELECT user_id, charger_id
FROM sessions) AS session_data
GROUP BY user_id, charger_id) AS ranked_users
WHERE rank <= 3
ORDER BY charger_id, session_count DESC;


-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)

WITH session_durations AS (
SELECT 
s.user_id,
strftime('%Y-%m', s.start_time) AS month,
SUM(julianday(s.end_time) - julianday(s.start_time)) AS total_duration
FROM sessions AS s
GROUP BY s.user_id, month)
SELECT 
month,
user_id,
total_duration
FROM session_durations
ORDER BY month, total_duration DESC
LIMIT 3;

-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)

SELECT 
    s.charger_id,
    strftime('%Y-%m', s.start_time) AS month,
    ROUND(AVG(julianday(s.start_time) - julianday(s2.start_time)), 2) AS average_time_between_sessions
FROM 
    sessions AS s
JOIN 
    sessions AS s2 ON s.charger_id = s2.charger_id AND s.start_time > s2.start_time
GROUP BY 
    s.charger_id, month
HAVING 
    COUNT(*) > 1
ORDER BY 
    s.charger_id, month;
