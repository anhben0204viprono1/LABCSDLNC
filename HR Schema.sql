CREATE TABLE EMPLOYEES AS SELECT * FROM HR.EMPLOYEES;
CREATE TABLE DEPARTMENTS AS SELECT * FROM HR.DEPARTMENTS;
CREATE TABLE JOBS AS SELECT * FROM HR.JOBS;
CREATE TABLE JOB_HISTORY AS SELECT * FROM HR.JOB_HISTORY;
CREATE TABLE LOCATIONS AS SELECT * FROM HR.LOCATIONS;
CREATE TABLE COUNTRIES AS SELECT * FROM HR.COUNTRIES;
CREATE TABLE REGIONS AS SELECT * FROM HR.REGIONS;

-- 1
SELECT last_name, salary 
FROM employees 
WHERE salary > 12000;

-- 2
SELECT last_name, salary 
FROM employees 
WHERE salary < 5000 OR salary > 12000;

-- 3
SELECT last_name, job_id, hire_date 
FROM employees 
WHERE hire_date BETWEEN TO_DATE('20/02/1998', 'DD/MM/YYYY') 
                AND TO_DATE('01/05/1998', 'DD/MM/YYYY')
ORDER BY hire_date ASC;

-- 4
SELECT last_name, department_id 
FROM employees 
WHERE department_id IN (20, 50) 
ORDER BY last_name ASC;

-- 5
SELECT last_name, hire_date 
FROM employees 
WHERE TO_CHAR(hire_date, 'YYYY') = '1994';

-- 6
SELECT last_name, job_id 
FROM employees 
WHERE manager_id IS NULL;

-- 7
SELECT last_name, salary, commission_pct 
FROM employees 
WHERE commission_pct IS NOT NULL 
ORDER BY salary DESC, commission_pct DESC;

-- 8
SELECT last_name 
FROM employees 
WHERE last_name LIKE '__a%';

-- 9
SELECT last_name 
FROM employees 
WHERE last_name LIKE '%a%' AND last_name LIKE '%e%';

-- 10

SELECT last_name, job_id, salary 
FROM employees 
WHERE job_id IN ('SA_REP', 'ST_CLERK') 
  AND salary NOT IN (2500, 3500, 7000);

-- 11
SELECT employee_id, last_name, ROUND(salary * 1.15, 0) AS "New Salary" 
FROM employees;

-- 12
SELECT INITCAP(last_name) AS "Name", LENGTH(last_name) AS "Length" 
FROM employees 
WHERE SUBSTR(UPPER(last_name), 1, 1) IN ('J', 'A', 'L', 'M') 
ORDER BY last_name ASC;

-- 13
SELECT last_name, ROUND(MONTHS_BETWEEN(SYSDATE, hire_date), 0) AS "Months Worked" 
FROM employees 
ORDER BY "Months Worked" ASC;

-- 14
SELECT last_name || ' earns ' || salary || ' monthly but wants ' || (salary * 3) AS "Dream Salaries" 
FROM employees;

-- 15
SELECT last_name, NVL(TO_CHAR(commission_pct), 'No commission') AS "Commission" 
FROM employees;

-- 16
SELECT job_id, 
       CASE job_id 
            WHEN 'AD_PRES'  THEN 'A'
            WHEN 'ST_MAN'   THEN 'B'
            WHEN 'IT_PROG'  THEN 'C'
            WHEN 'SA_REP'   THEN 'D'
            WHEN 'ST_CLERK' THEN 'E'
            ELSE '0' 
       END AS GRADE
FROM employees;

-- 17
SELECT e.last_name, e.department_id, d.department_name 
FROM employees e 
JOIN departments d ON e.department_id = d.department_id 
JOIN locations l ON d.location_id = l.location_id 
WHERE l.city = 'Toronto';

-- 18
SELECT e.employee_id AS "Emp ID", e.last_name AS "Employee", 
       m.employee_id AS "Mgr ID", m.last_name AS "Manager" 
FROM employees e 
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- 19
SELECT department_id, last_name 
FROM employees 
WHERE department_id IS NOT NULL
ORDER BY department_id;

-- 20
SELECT last_name, hire_date 
FROM employees 
WHERE hire_date > (SELECT hire_date FROM employees WHERE last_name = 'Davies');

-- 21
SELECT e.last_name AS "Employee", e.hire_date AS "Emp Hire Date", 
       m.last_name AS "Manager", m.hire_date AS "Mgr Hire Date"
FROM employees e 
JOIN employees m ON e.manager_id = m.employee_id 
WHERE e.hire_date < m.hire_date;

-- 22
SELECT job_id, MIN(salary), MAX(salary), ROUND(AVG(salary), 2), SUM(salary) 
FROM employees 
GROUP BY job_id;

-- 23
SELECT d.department_id, d.department_name, COUNT(e.employee_id) AS "Total Employees" 
FROM departments d 
LEFT JOIN employees e ON d.department_id = e.department_id 
GROUP BY d.department_id, d.department_name;

-- 24
-- Thong ke tuyen dung theo nam 1995, 1996, 1997, 1998
SELECT COUNT(*) AS "Total",
       SUM(DECODE(TO_CHAR(hire_date, 'YYYY'), '1995', 1, 0)) AS "1995",
       SUM(DECODE(TO_CHAR(hire_date, 'YYYY'), '1996', 1, 0)) AS "1996",
       SUM(DECODE(TO_CHAR(hire_date, 'YYYY'), '1997', 1, 0)) AS "1997",
       SUM(DECODE(TO_CHAR(hire_date, 'YYYY'), '1998', 1, 0)) AS "1998"
FROM employees;

-- 25
SELECT last_name, hire_date 
FROM employees 
WHERE department_id = (SELECT department_id FROM employees WHERE last_name = 'Zlotkey')
  AND last_name <> 'Zlotkey';

-- 26
SELECT last_name, department_id, job_id 
FROM employees 
WHERE department_id IN (SELECT department_id FROM departments WHERE location_id = 1700);

-- 27
SELECT last_name, manager_id 
FROM employees 
WHERE manager_id IN (SELECT employee_id FROM employees WHERE last_name = 'King');

-- 28
SELECT last_name, salary, department_id 
FROM employees 
WHERE salary > (SELECT AVG(salary) FROM employees) 
  AND department_id IN (SELECT department_id FROM employees WHERE last_name LIKE '%n');

-- 29
SELECT d.department_id, d.department_name 
FROM departments d 
JOIN employees e ON d.department_id = e.department_id 
GROUP BY d.department_id, d.department_name 
HAVING COUNT(e.employee_id) < 3;

-- 30
SELECT * FROM (
    SELECT department_id, COUNT(*) as cnt FROM employees GROUP BY department_id ORDER BY cnt DESC
) WHERE ROWNUM = 1
UNION
SELECT * FROM (
    SELECT department_id, COUNT(*) as cnt FROM employees GROUP BY department_id ORDER BY cnt ASC
) WHERE ROWNUM = 1;

-- 31
SELECT last_name, hire_date 
FROM employees 
WHERE TO_CHAR(hire_date, 'Day') = (
    SELECT TO_CHAR(hire_date, 'Day') 
    FROM employees 
    GROUP BY TO_CHAR(hire_date, 'Day') 
    ORDER BY COUNT(*) DESC 
    FETCH FIRST 1 ROWS ONLY
);

-- 32
SELECT last_name, salary 
FROM (SELECT last_name, salary FROM employees ORDER BY salary DESC) 
WHERE ROWNUM <= 3;

-- 33
SELECT e.last_name 
FROM employees e 
JOIN departments d ON e.department_id = d.department_id 
JOIN locations l ON d.location_id = l.location_id 
WHERE l.state_province = 'California';

-- 34.
UPDATE employees SET last_name = 'Drexler' WHERE employee_id = 103; 

-- 35. 
SELECT last_name, salary, department_id 
FROM employees eout 
WHERE salary < (SELECT AVG(salary) FROM employees ein WHERE ein.department_id = eout.department_id);

-- 36
UPDATE employees SET salary = salary + 100 WHERE salary < 900;

-- 37
DELETE FROM departments WHERE department_id = 500;

-- 38
DELETE FROM departments 
WHERE department_id NOT IN (SELECT DISTINCT department_id FROM employees WHERE department_id IS NOT NULL);

