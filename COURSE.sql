CREATE TABLE course (
    courseno NUMBER PRIMARY KEY,
    description VARCHAR2(100),
    cost NUMBER,
    prerequisite NUMBER,
    created_by VARCHAR2(30),
    created_date DATE,
    modified_by VARCHAR2(30),
    modified_date DATE,
    CONSTRAINT fk_course_pre FOREIGN KEY (prerequisite)
        REFERENCES course(courseno)
);

CREATE TABLE instructor (
    instructorid NUMBER PRIMARY KEY,
    firstname VARCHAR2(50),
    lastname VARCHAR2(50),
    created_by VARCHAR2(30),
    created_date DATE,
    modified_by VARCHAR2(30),
    modified_date DATE
);

CREATE TABLE student (
    studentid NUMBER PRIMARY KEY,
    firstname VARCHAR2(50),
    lastname VARCHAR2(50),
    address VARCHAR2(100),
    registrationdate DATE,
    createdby VARCHAR2(30),
    createddate DATE,
    modifiedby VARCHAR2(30),
    modifieddate DATE
);

CREATE TABLE class (
    classid NUMBER PRIMARY KEY,
    courseno NUMBER,
    classno NUMBER,
    startdatetime DATE,
    instructorid NUMBER,
    capacity NUMBER,
    created_by VARCHAR2(30),
    created_date DATE,
    modified_by VARCHAR2(30),
    modified_date DATE,
    FOREIGN KEY (courseno) REFERENCES course(courseno),
    FOREIGN KEY (instructorid) REFERENCES instructor(instructorid)
);

CREATE TABLE enrollment (
    studentid NUMBER,
    classid NUMBER,
    enrolldate DATE,
    finalgrade NUMBER,
    createdby VARCHAR2(30),
    createddate DATE,
    modifiedby VARCHAR2(30),
    modifieddate DATE,
    PRIMARY KEY (studentid, classid),
    FOREIGN KEY (studentid) REFERENCES student(studentid),
    FOREIGN KEY (classid) REFERENCES class(classid)
);

CREATE TABLE grade (
    studentid NUMBER,
    classid NUMBER,
    grade NUMBER,
    comments VARCHAR2(200),
    created_by VARCHAR2(30),
    created_date DATE,
    modified_by VARCHAR2(30),
    modified_date DATE,
    PRIMARY KEY (studentid, classid),
    FOREIGN KEY (studentid, classid)
        REFERENCES enrollment(studentid, classid)
);
CREATE OR REPLACE VIEW vw_course_summary AS 
SELECT co.courseno, 
 co.description, 
 co.cost, 
 COUNT(DISTINCT cl.classid) AS so_lop, 
 COUNT(e.studentid) AS tong_sv
FROM course co 
 LEFT JOIN class cl ON co.courseno = cl.courseno 
 LEFT JOIN enrollment e ON cl.classid = e.classid 
GROUP BY co.courseno, co.description, co.cost 
ORDER BY tong_sv DESC; 

SELECT * FROM vw_course_summary; 

CREATE OR REPLACE VIEW vw_student_status AS 
SELECT s.studentid, 
 s.firstname || ' ' || s.lastname AS ho_ten, 
 COUNT(e.classid) AS so_lop_hoc, 
 NVL(SUM(co.cost), 0) AS tong_hoc_phi, 
 ROUND(AVG(e.finalgrade), 2) AS diem_tb 
FROM student s 
 JOIN enrollment e ON s.studentid = e.studentid 
 JOIN class cl ON e.classid = cl.classid 
 JOIN course co ON cl.courseno = co.courseno 
GROUP BY s.studentid, s.firstname, s.lastname 
HAVING COUNT(e.classid) >= 1 
ORDER BY s.studentid; 

SELECT * FROM vw_student_status;

CREATE OR REPLACE VIEW vw_class_availability AS 
SELECT cl.classid, 
cl.courseno, 
co.description, 
i.firstname || ' ' || i.lastname AS ten_giao_vien, 
cl.capacity, 
COUNT(e.studentid) AS so_da_dk, 
cl.capacity - COUNT(e.studentid) AS cho_trong, 
CASE 
WHEN cl.capacity - COUNT(e.studentid) > 0 THEN 'Con cho'  ELSE 'Het cho' 
END AS trang_thai 
FROM class cl 
JOIN course co ON cl.courseno = co.courseno 
JOIN instructor i ON cl.instructorid = i.instructorid 
LEFT JOIN enrollment e ON cl.classid = e.classid 
GROUP BY cl.classid, cl.courseno, co.description, 
i.firstname, i.lastname, cl.capacity 
HAVING cl.capacity - COUNT(e.studentid) > 0 
ORDER BY cl.classid; 

SELECT * FROM vw_class_availability; 

CREATE OR REPLACE VIEW vw_top_courses AS 
SELECT courseno, description, cost, tong_dk, hang 
FROM ( 
 SELECT co.courseno, 
 co.description, 
 co.cost, 
 COUNT(e.studentid) AS tong_dk, 
 RANK() OVER (ORDER BY COUNT(e.studentid) DESC) AS hang  FROM course co 
 LEFT JOIN class cl ON co.courseno = cl.courseno 
 LEFT JOIN enrollment e ON cl.classid = e.classid 
 GROUP BY co.courseno, co.description, co.cost 
) 
WHERE hang <= 5 
ORDER BY hang 
WITH READ ONLY; 
SELECT * FROM vw_top_courses; 


CREATE OR REPLACE VIEW vw_pending_enrollment AS 
SELECT studentid, classid, enrolldate, finalgrade, 
 createdby, createddate, modifiedby, modifieddate 
FROM enrollment 
WHERE finalgrade IS NULL 
WITH CHECK OPTION; 

SELECT * FROM vw_pending_enrollment; 

CREATE OR REPLACE PROCEDURE enroll_student 
 (p_studentid IN NUMBER, 
 p_classid IN NUMBER) 
IS 
 v_check NUMBER; 
 v_capacity NUMBER; 
 v_enrolled NUMBER; 
BEGIN 
 -- DK1: Sinh vien phai ton tai 
 SELECT COUNT(*) INTO v_check FROM student WHERE studentid =  p_studentid; 
 IF v_check = 0 THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien ' || p_studentid || ' khong  ton tai!'); 
 RETURN; 
 END IF; 
 -- DK2: Lop hoc phai ton tai 
 SELECT COUNT(*) INTO v_check FROM class WHERE classid =  p_classid; 
 IF v_check = 0 THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Lop hoc ' || p_classid || ' khong ton  tai!'); 
 RETURN; 
 END IF;
-- DK3: Kiem tra con cho trong 
 SELECT capacity INTO v_capacity FROM class WHERE classid =  p_classid; 
 SELECT COUNT(*) INTO v_enrolled FROM enrollment WHERE classid =  p_classid; 
 IF v_enrolled >= v_capacity THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Lop ' || p_classid || ' da day! ('  || v_enrolled || '/' || v_capacity || ')'); 
 RETURN; 
 END IF; 
 -- DK4: Sinh vien chua dang ky lop nay 
 SELECT COUNT(*) INTO v_check FROM enrollment 
 WHERE studentid = p_studentid AND classid = p_classid;  IF v_check > 0 THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien da dang ky lop nay roi!');  RETURN; 
 END IF; 
 -- DK5: Sinh vien chua qua 3 lop 
 SELECT COUNT(*) INTO v_check FROM enrollment WHERE studentid =  p_studentid; 
 IF v_check >= 3 THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien da dang ky du 3 lop!');  RETURN; 
 END IF; 
 -- Tat ca OK: INSERT 
 INSERT INTO enrollment 
 (studentid, classid, enrolldate, createdby, createddate, 
 modifiedby, modifieddate)
 values
 (p_studentid, p_classid, SYSDATE, USER, SYSDATE, USER,  SYSDATE); 
 COMMIT; 
 DBMS_OUTPUT.PUT_LINE('[OK] Dang ky thanh cong! SV ' || p_studentid  || ' -> Lop ' || p_classid); 
EXCEPTION 
 WHEN OTHERS THEN 
 ROLLBACK; 
 DBMS_OUTPUT.PUT_LINE('[LOI HE THONG] ' || SQLERRM); END enroll_student; 
/ 
BEGIN
  enroll_student(102, 3);
END;
/
select *from class

CREATE OR REPLACE PROCEDURE update_final_grade 
 (p_studentid IN NUMBER, 
  p_classid IN NUMBER, 
  p_grade IN NUMBER) 
IS 
 v_check NUMBER; 
 v_old_grade NUMBER; 
BEGIN 

 -- Kiem tra diem hop le 
 IF p_grade < 0 OR p_grade > 100 THEN 
   DBMS_OUTPUT.PUT_LINE('[LOI] Diem khong hop le!'); 
   RETURN; 
 END IF; 

 -- Kiem tra ton tai enrollment 
 SELECT COUNT(*) 
 INTO v_check 
 FROM enrollment 
 WHERE studentid = p_studentid 
 AND classid = p_classid; 

 IF v_check = 0 THEN 
   DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien chua dang ky lop nay!'); 
   RETURN; 
 END IF; 

 -- Luu diem cu (quan trọng: phải đảm bảo 1 dòng)
 SELECT NVL(finalgrade, NULL)
 INTO v_old_grade 
 FROM enrollment 
 WHERE studentid = p_studentid 
 AND classid = p_classid; 

 -- UPDATE enrollment
 UPDATE enrollment 
 SET finalgrade = p_grade, 
     modifiedby = USER, 
     modifieddate = SYSDATE 
 WHERE studentid = p_studentid 
 AND classid = p_classid; 

 -- MERGE GRADE
MERGE INTO grade g 
USING (SELECT p_studentid sid, p_classid cid FROM dual) src 
ON (g.studentid = src.sid AND g.classid = src.cid) 
WHEN MATCHED THEN 
  UPDATE SET g.grade = p_grade, 
             g.modified_by = USER, 
             g.modified_date = SYSDATE 
WHEN NOT MATCHED THEN 
  INSERT (studentid, classid, grade, created_by, created_date,
          modified_by, modified_date)
  VALUES (p_studentid, p_classid, p_grade,
          USER, SYSDATE, USER, SYSDATE);

 COMMIT; 

 DBMS_OUTPUT.PUT_LINE('[OK] Cap nhat diem thanh cong');

EXCEPTION 
 WHEN OTHERS THEN 
   ROLLBACK; 
   DBMS_OUTPUT.PUT_LINE('[LOI] ' || SQLERRM); 

END update_final_grade;
/

BEGIN 
 update_final_grade(999, 2, 80); -- lỗi studentEND;
END;
/
BEGIN
  update_final_grade(102, 3, 85);
END;
/

SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE transfer_student 
 (p_studentid IN NUMBER, 
 p_old_classid IN NUMBER, 
 p_new_classid IN NUMBER) 
IS 
 v_check NUMBER; 
 v_capacity NUMBER; 
 v_enrolled NUMBER; 
BEGIN 
 -- DK1: Sinh vien dang hoc o lop cu 
 SELECT COUNT(*) INTO v_check FROM enrollment 
 WHERE studentid = p_studentid AND classid = p_old_classid;  IF v_check = 0 THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien khong dang hoc lop ' ||  p_old_classid); 
 RETURN; 
 END IF; 
 -- DK2: Lop moi con cho trong 
 SELECT capacity INTO v_capacity FROM class WHERE classid =  p_new_classid; 
 SELECT COUNT(*) INTO v_enrolled FROM enrollment WHERE classid =  p_new_classid; 
 IF v_enrolled >= v_capacity THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Lop moi ' || p_new_classid || ' da  day!'); 
 RETURN; 
 END IF;
-- DK3: Sinh vien chua dang ky lop moi 
 SELECT COUNT(*) INTO v_check FROM enrollment  WHERE studentid = p_studentid AND classid = p_new_classid;  IF v_check > 0 THEN 
 DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien da o trong lop moi roi!');  RETURN; 
 END IF; 
 -- Tat ca OK: thuc hien chuyen lop 
 SAVEPOINT sp_truoc_chuyen; 
 -- Buoc 1: Xoa khoi lop cu 
 DELETE FROM enrollment 
 WHERE studentid = p_studentid AND classid = p_old_classid;  SAVEPOINT sp_sau_xoa; 
 -- Buoc 2: Them vao lop moi 
 INSERT INTO enrollment 
 (studentid, classid, enrolldate, createdby, createddate,  modifiedby, modifieddate) 
 VALUES 
 (p_studentid, p_new_classid, SYSDATE, USER, SYSDATE, USER,  SYSDATE); 
 COMMIT; 
 DBMS_OUTPUT.PUT_LINE('[OK] Da chuyen SV ' || p_studentid  || ' tu lop ' || p_old_classid 
 || ' sang lop ' || p_new_classid); 
EXCEPTION
WHEN OTHERS THEN 
 ROLLBACK TO sp_truoc_chuyen; 
 DBMS_OUTPUT.PUT_LINE('[LOI] Chuyen lop that bai: ' || SQLERRM);  DBMS_OUTPUT.PUT_LINE('Da rollback ve trang thai ban dau.'); END transfer_student; 
/ 
BEGIN
  transfer_student(104, 1, 5);
END;
/

select *from student

CREATE OR REPLACE PROCEDURE report_class_detail 
(p_classid IN NUMBER)
IS 
    v_check NUMBER;
    v_course VARCHAR2(100);
    v_courseno NUMBER;
    v_gv VARCHAR2(100);
    v_loc VARCHAR2(50);
    v_cap NUMBER;

    v_stt NUMBER := 0;
    v_tong NUMBER := 0;
    v_sum_d NUMBER := 0;
    v_co_d NUMBER := 0;
    v_grade_txt VARCHAR2(20);
BEGIN
    -- 1. Kiểm tra lớp tồn tại
    SELECT COUNT(*) 
    INTO v_check 
    FROM class 
    WHERE classid = p_classid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Lop hoc ' || p_classid || ' khong ton tai!');
        RETURN;
    END IF;

    -- 2. Lấy thông tin lớp (KHÔNG dùng location nếu không có cột)
    SELECT co.description,
           co.courseno,
           i.firstname || ' ' || i.lastname,
           cl.capacity
    INTO v_course, v_courseno, v_gv, v_cap
    FROM class cl
    JOIN course co ON cl.courseno = co.courseno
    JOIN instructor i ON cl.instructorid = i.instructorid
    WHERE cl.classid = p_classid;

    -- nếu bạn KHÔNG có cột location thì để NULL an toàn
    v_loc := 'Chua xep phong';

    -- 3. Header
    DBMS_OUTPUT.PUT_LINE('=== BAO CAO LOP HOC: ' || p_classid || ' ===');
    DBMS_OUTPUT.PUT_LINE('Mon hoc : ' || v_courseno || ' - ' || v_course);
    DBMS_OUTPUT.PUT_LINE('Giao vien: ' || v_gv);
    DBMS_OUTPUT.PUT_LINE('Phong hoc: ' || v_loc);
    DBMS_OUTPUT.PUT_LINE('Suc chua : ' || v_cap);
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    DBMS_OUTPUT.PUT_LINE('STT | HO TEN               | DIEM   | XEP LOAI');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    -- 4. Cursor danh sách sinh viên
    FOR rec IN (
        SELECT s.firstname || ' ' || s.lastname AS ho_ten,
               e.finalgrade
        FROM enrollment e
        JOIN student s ON e.studentid = s.studentid
        WHERE e.classid = p_classid
        ORDER BY s.lastname, s.firstname
    ) LOOP

        v_stt := v_stt + 1;
        v_tong := v_tong + 1;

        -- 5. Xếp loại
        IF rec.finalgrade IS NULL THEN
            v_grade_txt := 'Chua co diem';

        ELSIF rec.finalgrade >= 90 THEN
            v_grade_txt := 'A';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;

        ELSIF rec.finalgrade >= 80 THEN
            v_grade_txt := 'B';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;

        ELSIF rec.finalgrade >= 70 THEN
            v_grade_txt := 'C';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;

        ELSIF rec.finalgrade >= 50 THEN
            v_grade_txt := 'D';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;

        ELSE
            v_grade_txt := 'F';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;
        END IF;

        -- 6. In dòng
        DBMS_OUTPUT.PUT_LINE(
            LPAD(v_stt, 3) || ' | ' ||
            RPAD(rec.ho_ten, 20) || ' | ' ||
            LPAD(NVL(TO_CHAR(rec.finalgrade), 'NULL'), 6) || ' | ' ||
            v_grade_txt
        );

    END LOOP;

    -- 7. Footer
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    DBMS_OUTPUT.PUT_LINE('Tong sinh vien: ' || v_tong);

    IF v_co_d > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Diem trung binh: ' || ROUND(v_sum_d / v_co_d, 2));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Diem trung binh: Chua co diem');
    END IF;

END;
/

BEGIN
  report_class_detail(1);
END;
/

CREATE OR REPLACE PROCEDURE sync_grade_from_enrollment AS
v_check NUMBER; 
 v_dem_insert NUMBER := 0; 
 v_dem_update NUMBER := 0; 
BEGIN 
 FOR rec IN ( 
 SELECT studentid, classid, finalgrade 
 FROM enrollment 
 WHERE finalgrade IS NOT NULL 
 ) LOOP 
 -- Kiem tra trong GRADE da co chua 
 SELECT COUNT(*) INTO v_check FROM grade 
 WHERE studentid = rec.studentid AND classid = rec.classid; 
 IF v_check = 0 THEN 
 -- Chua co -> INSERT moi 
INSERT INTO grade 
(studentid, classid, grade, created_by, created_date,
 modified_by, modified_date)
VALUES 
(rec.studentid, rec.classid, rec.finalgrade,
 USER, SYSDATE, USER, SYSDATE); 
 v_dem_insert := v_dem_insert + 1;
 ELSE 
 -- Da co -> UPDATE 
UPDATE grade
SET grade = rec.finalgrade,
    modified_by = USER,
    modified_date = SYSDATE
WHERE studentid = rec.studentid
  AND classid = rec.classid;
 END IF; 
 END LOOP; 
 COMMIT; 
 DBMS_OUTPUT.PUT_LINE('[OK] Dong bo hoan tat!'); 
 DBMS_OUTPUT.PUT_LINE(' So ban ghi INSERT moi : ' ||  v_dem_insert); 
 DBMS_OUTPUT.PUT_LINE(' So ban ghi UPDATE : ' ||  
v_dem_update); 
EXCEPTION 
 WHEN OTHERS THEN 
 ROLLBACK; 
 DBMS_OUTPUT.PUT_LINE('[LOI] ' || SQLERRM); 
END sync_grade_from_enrollment; 
/ 
BEGIN sync_grade_from_enrollment; 
END;
/

CREATE OR REPLACE TRIGGER trg_check_capacity 
 BEFORE INSERT ON enrollment 
 FOR EACH ROW 
DECLARE 
 v_capacity NUMBER; 
 v_enrolled NUMBER; 
BEGIN 
 -- Lay suc chua lop hoc 
 SELECT capacity INTO v_capacity 
 FROM class WHERE classid = :NEW.classid; 
 -- Dem so SV hien da dang ky 
 SELECT COUNT(*) INTO v_enrolled 
 FROM enrollment WHERE classid = :NEW.classid; 
 -- Tu choi neu lop da day 
 IF v_enrolled >= v_capacity THEN 
 RAISE_APPLICATION_ERROR( 
 -20010, 
 'LOI: Lop ' || :NEW.classid || ' da day! (' 
 || v_enrolled || '/' || v_capacity || ' cho)' 
 ); 
 END IF; 
END trg_check_capacity; 
/
-- Kiem tra trigger (dang ky vao lop da day): 
INSERT INTO enrollment 
 (studentid, classid, enrolldate, createdby, createddate, 
 modifiedby, modifieddate) 
VALUES (999, 1, SYSDATE, USER, SYSDATE, USER, SYSDATE); 

CREATE TABLE grade_audit_log ( 
 log_id NUMBER GENERATED ALWAYS AS IDENTITY,  studentid NUMBER(8), 
 classid NUMBER(8), 
 grade_cu NUMBER(3), 
 grade_moi NUMBER(3), 
 nguoi_sua VARCHAR2(30), 
 thoi_gian DATE 
); 
/ 
CREATE OR REPLACE TRIGGER trg_grade_audit_log 
 AFTER UPDATE OF finalgrade ON enrollment 
 FOR EACH ROW 
BEGIN 
 -- Chi ghi log khi diem THUC SU thay doi 
 IF (:OLD.finalgrade IS NULL AND :NEW.finalgrade IS NOT NULL)  OR (:OLD.finalgrade IS NOT NULL AND :NEW.finalgrade IS NULL)
OR (:OLD.finalgrade != :NEW.finalgrade) 
 THEN 
 INSERT INTO grade_audit_log 
 (studentid, classid, grade_cu, grade_moi, nguoi_sua, thoi_gian)  VALUES 
 (:OLD.studentid, :OLD.classid, :OLD.finalgrade, 
 :NEW.finalgrade, USER, SYSDATE); 
 END IF; 
END trg_grade_audit_log; 
/ 
-- Kiem tra trigger: 
UPDATE enrollment SET finalgrade = 85 
WHERE studentid = 101 AND classid = 1; 
COMMIT; 

SELECT * FROM grade_audit_log; 

CREATE OR REPLACE TRIGGER trg_prevent_course_delete 
 BEFORE DELETE ON course 
 FOR EACH ROW 
DECLARE 
 v_so_lop NUMBER; 
BEGIN
SELECT COUNT(*) INTO v_so_lop 
 FROM class WHERE courseno = :OLD.courseno; 
 IF v_so_lop > 0 THEN 
 RAISE_APPLICATION_ERROR( 
 -20020, 
 'Khong the xoa mon hoc ' || :OLD.courseno || 
 ' (' || :OLD.description || ') ' || 
 'vi con ' || v_so_lop || ' lop hoc dang ton tai!' 
 ); 
 END IF; 
 -- Neu v_so_lop = 0: trigger ket thuc binh thuong, Oracle tien hanh xoa 
 END trg_prevent_course_delete; 
/ 
-- Kiem tra: xoa mon co lop (se bao loi) 
DELETE FROM course WHERE courseno = 1; 
-- Kiem tra: xoa mon khong co lop (thanh cong) 
DELETE FROM course WHERE courseno = 999; 

CREATE TABLE class_grade_summary ( 
 classid NUMBER(8) PRIMARY KEY, 
 so_sv NUMBER, 
 diem_tb NUMBER(5,2),
 diem_cao_nhat NUMBER(3), 
 diem_thap_nhat NUMBER(3), 
 cap_nhat_luc DATE 
); 
CREATE OR REPLACE TRIGGER trg_update_grade_summary
FOR INSERT OR UPDATE OR DELETE ON enrollment
COMPOUND TRIGGER

    TYPE t_class_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    g_classes t_class_tab;
    g_index PLS_INTEGER := 0;

BEFORE EACH ROW IS
BEGIN
    g_index := g_index + 1;

    IF INSERTING OR UPDATING THEN
        g_classes(g_index) := :NEW.classid;
    ELSE
        g_classes(g_index) := :OLD.classid;
    END IF;
END BEFORE EACH ROW;

AFTER STATEMENT IS
    v_classid NUMBER;
    v_so_sv NUMBER;
    v_diem_tb NUMBER;
    v_max_d NUMBER;
    v_min_d NUMBER;
BEGIN
    FOR i IN 1..g_index LOOP

        v_classid := g_classes(i);

        SELECT COUNT(finalgrade),
               ROUND(NVL(AVG(finalgrade),0),2),
               NVL(MAX(finalgrade),0),
               NVL(MIN(finalgrade),0)
        INTO v_so_sv, v_diem_tb, v_max_d, v_min_d
        FROM enrollment
        WHERE classid = v_classid
          AND finalgrade IS NOT NULL;

        MERGE INTO class_grade_summary cgs
        USING (
            SELECT v_classid classid,
                   v_so_sv so_sv,
                   v_diem_tb diem_tb,
                   v_max_d diem_cao_nhat,
                   v_min_d diem_thap_nhat
            FROM dual
        ) src
        ON (cgs.classid = src.classid)
        WHEN MATCHED THEN UPDATE SET
            cgs.so_sv = src.so_sv,
            cgs.diem_tb = src.diem_tb,
            cgs.diem_cao_nhat = src.diem_cao_nhat,
            cgs.diem_thap_nhat = src.diem_thap_nhat,
            cgs.cap_nhat_luc = SYSDATE
        WHEN NOT MATCHED THEN INSERT (
            classid, so_sv, diem_tb, diem_cao_nhat, diem_thap_nhat, cap_nhat_luc
        ) VALUES (
            src.classid, src.so_sv, src.diem_tb,
            src.diem_cao_nhat, src.diem_thap_nhat, SYSDATE
        );

    END LOOP;
END AFTER STATEMENT;

END;
/

UPDATE enrollment SET finalgrade = 90 WHERE studentid=101 AND  classid=1;
select *from enrollment

CREATE OR REPLACE VIEW vw_instructor_workload AS 
SELECT 
    i.instructorid, 
    i.firstname || ' ' || i.lastname AS ho_ten, 
    COUNT(DISTINCT cl.classid) AS so_lop, 
    COUNT(e.studentid) AS tong_sv, 
    ROUND(AVG(e.finalgrade), 2) AS diem_tb_chung,
    CASE 
        WHEN COUNT(DISTINCT cl.classid) >= 3 THEN 'Ban nhieu'  
        WHEN COUNT(DISTINCT cl.classid) = 2 THEN 'Binh thuong'  
        ELSE 'Nhe nhang' 
    END AS muc_ban 
FROM instructor i 
LEFT JOIN class cl ON i.instructorid = cl.instructorid 
LEFT JOIN enrollment e ON cl.classid = e.classid 
GROUP BY i.instructorid, i.firstname, i.lastname;

SELECT * FROM vw_instructor_workload; 
CREATE OR REPLACE VIEW vw_top_courses AS
SELECT 
    co.description,
    COUNT(e.studentid) AS tong_dk,
    DENSE_RANK() OVER (ORDER BY COUNT(e.studentid) DESC) AS hang
FROM course co
JOIN class c ON co.courseno = c.courseno
JOIN enrollment e ON c.classid = e.classid
GROUP BY co.description;
CREATE OR REPLACE PROCEDURE print_system_report 
IS 
    v_so_mon NUMBER; 
    v_so_lop NUMBER;
    v_so_sv NUMBER; 
    v_so_gv NUMBER; 
BEGIN 

    SELECT COUNT(*) INTO v_so_mon FROM course; 
    SELECT COUNT(*) INTO v_so_lop FROM class; 
    SELECT COUNT(*) INTO v_so_sv FROM student; 
    SELECT COUNT(*) INTO v_so_gv FROM instructor; 

    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('      BAO CAO TOAN HE THONG KHOA HOC');
    DBMS_OUTPUT.PUT_LINE('==========================================');

    DBMS_OUTPUT.PUT_LINE('Tong so mon hoc : ' || v_so_mon);  
    DBMS_OUTPUT.PUT_LINE('Tong so lop hoc : ' || v_so_lop);  
    DBMS_OUTPUT.PUT_LINE('Tong so sinh vien: ' || v_so_sv);  
    DBMS_OUTPUT.PUT_LINE('Tong so giao vien: ' || v_so_gv);  

    DBMS_OUTPUT.PUT_LINE(RPAD('-',50,'-')); 

    DBMS_OUTPUT.PUT_LINE('THONG KE GIAO VIEN:');  

    FOR rec IN (SELECT * FROM vw_instructor_workload) LOOP  
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.ho_ten, 25) 
            || ' | ' || rec.so_lop
            || ' | SV: ' || rec.tong_sv
            || ' | DTB: ' || NVL(TO_CHAR(rec.diem_tb_chung),'--')
        ); 
    END LOOP;  

    DBMS_OUTPUT.PUT_LINE(RPAD('-',50,'-')); 

    DBMS_OUTPUT.PUT_LINE('TOP 3 MON HOC:'); 

    FOR rec IN (SELECT * FROM vw_top_courses WHERE hang <= 3) LOOP  
        DBMS_OUTPUT.PUT_LINE(
            rec.hang || '. ' 
            || rec.description 
            || ' - ' || rec.tong_dk
        ); 
    END LOOP;  

    DBMS_OUTPUT.PUT_LINE('==========================================');

END;
/
-- Chay bao cao: 
SET SERVEROUTPUT ON SIZE 1000000; 
BEGIN print_system_report; END; 
/
SELECT view_name, status 
FROM user_objects 
WHERE object_type = 'VIEW';