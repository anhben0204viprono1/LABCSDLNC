CREATE TABLE Hang(
    Mahang VARCHAR2(10) PRIMARY KEY,
    Tenhang VARCHAR2(50),
    Soluong NUMBER,
    Giaban NUMBER
);
CREATE TABLE Hoadon(
    Mahd VARCHAR2(10) PRIMARY KEY,
    Mahang VARCHAR2(10),
    Soluongban NUMBER,
    Ngayban DATE
);
CREATE OR REPLACE TRIGGER trg_insert_hoadon
BEFORE INSERT ON Hoadon
FOR EACH ROW
DECLARE
    v_soluong Hang.Soluong%TYPE;
BEGIN

    SELECT Soluong
    INTO v_soluong
    FROM Hang
    WHERE Mahang = :NEW.Mahang;

    IF :NEW.Soluongban > v_soluong THEN
        RAISE_APPLICATION_ERROR(-20001,'So luong ban vuot qua ton kho');
    END IF;

    UPDATE Hang
    SET Soluong = Soluong - :NEW.Soluongban
    WHERE Mahang = :NEW.Mahang;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002,'Ma hang khong ton tai');

END;
/
INSERT INTO Hoadon
VALUES('HD02','H02',100,SYSDATE);

select * from Hang

CREATE OR REPLACE TRIGGER trg_delete_hoadon
AFTER DELETE ON Hoadon
FOR EACH ROW
BEGIN

    UPDATE Hang
    SET Soluong = Soluong + :OLD.Soluongban
    WHERE Mahang = :OLD.Mahang;

END;
/
DELETE FROM Hoadon
WHERE Mahd = 'HD01';
CREATE OR REPLACE TRIGGER trg_update_hoadon
BEFORE UPDATE ON Hoadon
FOR EACH ROW
BEGIN

    UPDATE Hang
    SET Soluong = Soluong - (:NEW.Soluongban - :OLD.Soluongban)
    WHERE Mahang = :NEW.Mahang;

END;
/
UPDATE Hoadon
SET Soluongban = 5
WHERE Mahd = 'HD02';
INSERT INTO Hang VALUES('H01','Laptop',50,20000);
INSERT INTO Hang VALUES('H02','Mouse',100,200);

INSERT INTO Hoadon VALUES('HD01','H01',5,SYSDATE);

select * from Hoadon
select * from Hang













