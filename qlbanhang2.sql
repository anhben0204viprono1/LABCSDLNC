CREATE TABLE Mathang(
Mahang VARCHAR2(5) CONSTRAINT pk_mathang PRIMARY KEY,
Tenhang VARCHAR2(50) NOT NULL,
Soluong NUMBER(10)
);

CREATE TABLE Nhatkybanhang (
Stt NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Ngay DATE,
Nguoimua VARCHAR2(50),
Mahang VARCHAR2(5) REFERENCES Mathang(Mahang),
Soluong NUMBER(10),
Giaban NUMBER(15,2)
);

INSERT INTO Mathang VALUES ('1','Hang A', 100);
INSERT INTO Mathang VALUES ('2','Hang B', 200);
INSERT INTO Mathang VALUES ('3','Hang C', 150);

INSERT INTO Nhatkybanhang(Ngay,Nguoimua,Mahang,Soluong,Giaban)
VALUES(SYSDATE,'Tan','1',10,50000);
COMMIT;
select * from Mathang
select * from Nhatkybanhang
UPDATE Nhatkybanhang
SET Soluong = 15
WHERE Stt = 4;

CREATE OR REPLACE TRIGGER trg_nhatkybanhang_insert
AFTER INSERT ON Nhatkybanhang
FOR EACH ROW
BEGIN
    UPDATE Mathang
    SET Soluong = Soluong - :NEW.Soluong
    WHERE Mahang = :NEW.Mahang;
END;
/
INSERT INTO Nhatkybanhang(Ngay,Nguoimua,Mahang,Soluong,Giaban)
VALUES(SYSDATE,'An','1',10,50000);
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_update_soluong
BEFORE UPDATE OF Soluong ON Nhatkybanhang
FOR EACH ROW
BEGIN
    UPDATE Mathang
    SET Soluong = Soluong - (:NEW.Soluong - :OLD.Soluong)
    WHERE Mahang = :NEW.Mahang;
END;
/

CREATE OR REPLACE TRIGGER trg_insert_check_soluong
BEFORE INSERT ON Nhatkybanhang
FOR EACH ROW
DECLARE
    v_soluong NUMBER;
BEGIN

    SELECT Soluong
    INTO v_soluong
    FROM Mathang
    WHERE Mahang = :NEW.Mahang;

    IF :NEW.Soluong > v_soluong THEN
        RAISE_APPLICATION_ERROR(-20001,'So luong ban vuot ton kho');
    END IF;

    UPDATE Mathang
    SET Soluong = Soluong - :NEW.Soluong
    WHERE Mahang = :NEW.Mahang;

END;
/
INSERT INTO Nhatkybanhang(Ngay,Nguoimua,Mahang,Soluong,Giaban)
VALUES(SYSDATE,'Binh','1',500,20000);

CREATE OR REPLACE PACKAGE pkg_state AS
    g_count NUMBER := 0;
END;
/
CREATE OR REPLACE TRIGGER trg_update_control
FOR UPDATE ON Nhatkybanhang
COMPOUND TRIGGER

BEFORE STATEMENT IS
BEGIN
    pkg_state.g_count := 0;
END BEFORE STATEMENT;

BEFORE EACH ROW IS
BEGIN
    pkg_state.g_count := pkg_state.g_count + 1;

    IF pkg_state.g_count > 1 THEN
        RAISE_APPLICATION_ERROR(-20002,'Chi duoc update 1 dong');
    END IF;
END BEFORE EACH ROW;

AFTER EACH ROW IS
BEGIN
    UPDATE Mathang
    SET Soluong = Soluong - (:NEW.Soluong - :OLD.Soluong)
    WHERE Mahang = :NEW.Mahang;
END AFTER EACH ROW;

END;
/

UPDATE Nhatkybanhang
SET Soluong = 20;

CREATE OR REPLACE PACKAGE pkg_delete AS
    g_count NUMBER := 0;
END;
/
CREATE OR REPLACE TRIGGER trg_delete_control
FOR DELETE ON Nhatkybanhang
COMPOUND TRIGGER

BEFORE STATEMENT IS
BEGIN
    pkg_delete.g_count := 0;
END BEFORE STATEMENT;

BEFORE EACH ROW IS
BEGIN
    pkg_delete.g_count := pkg_delete.g_count + 1;

    IF pkg_delete.g_count > 1 THEN
        RAISE_APPLICATION_ERROR(-20003,'Chi duoc xoa 1 dong');
    END IF;
END BEFORE EACH ROW;

AFTER EACH ROW IS
BEGIN
    UPDATE Mathang
    SET Soluong = Soluong + :OLD.Soluong
    WHERE Mahang = :OLD.Mahang;
END AFTER EACH ROW;

END;
/
DELETE FROM Nhatkybanhang
WHERE Stt = 1;

CREATE OR REPLACE TRIGGER trg_update_nangcao
BEFORE UPDATE ON Nhatkybanhang
FOR EACH ROW
DECLARE
    v_soluong NUMBER;
BEGIN

    SELECT Soluong
    INTO v_soluong
    FROM Mathang
    WHERE Mahang = :NEW.Mahang;

    IF :NEW.Soluong < v_soluong THEN
        RAISE_APPLICATION_ERROR(-20004,'So luong cap nhat khong hop le');
    ELSIF :NEW.Soluong = v_soluong THEN
        DBMS_OUTPUT.PUT_LINE('Khong can cap nhat');
    ELSE
        UPDATE Mathang
        SET Soluong = Soluong - (:NEW.Soluong - :OLD.Soluong)
        WHERE Mahang = :NEW.Mahang;
    END IF;

END;
/

CREATE OR REPLACE PROCEDURE sp_xoa_mathang(
    p_mahang IN VARCHAR2
)
AS
    v_count NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_count
    FROM Mathang
    WHERE Mahang = p_mahang;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ma hang khong ton tai');
    ELSE

        DELETE FROM Nhatkybanhang
        WHERE Mahang = p_mahang;

        DELETE FROM Mathang
        WHERE Mahang = p_mahang;

        DBMS_OUTPUT.PUT_LINE('Da xoa mat hang');

    END IF;

END;
/
EXEC sp_xoa_mathang('1');
CREATE OR REPLACE FUNCTION fn_tongtien(
    p_tenhang VARCHAR2
)
RETURN NUMBER
AS
    v_tong NUMBER;
BEGIN

    SELECT SUM(nk.Soluong * nk.Giaban)
    INTO v_tong
    FROM Nhatkybanhang nk
    JOIN Mathang mh
    ON nk.Mahang = mh.Mahang
    WHERE mh.Tenhang = p_tenhang;

    RETURN NVL(v_tong,0);

END;
/
SELECT fn_tongtien('Hang A')
FROM dual;