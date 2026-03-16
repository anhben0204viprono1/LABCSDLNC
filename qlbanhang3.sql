CREATE TABLE Lophoc(
Malop VARCHAR2(10) PRIMARY KEY,
Tenlop VARCHAR2(50),
Sisotoida NUMBER,
Sisohientai NUMBER
);

CREATE TABLE Dangky(
Madk NUMBER PRIMARY KEY,
Masv VARCHAR2(10),
Malop VARCHAR2(10),
Ngaydangky DATE,
FOREIGN KEY (Malop) REFERENCES Lophoc(Malop)
);
CREATE OR REPLACE TRIGGER trg_dangky_insert
BEFORE INSERT ON Dangky
FOR EACH ROW
DECLARE
v_count NUMBER;
v_siso NUMBER;
v_max NUMBER;
BEGIN

SELECT COUNT(*) INTO v_count
FROM Lophoc
WHERE Malop = :NEW.Malop;

IF v_count = 0 THEN
RAISE_APPLICATION_ERROR(-20001,'Lop khong ton tai');
END IF;

SELECT COUNT(*) INTO v_count
FROM Dangky
WHERE Masv = :NEW.Masv
AND Malop = :NEW.Malop;

IF v_count > 0 THEN
RAISE_APPLICATION_ERROR(-20002,'Sinh vien da dang ky lop nay');
END IF;

SELECT Sisohientai, Sisotoida
INTO v_siso, v_max
FROM Lophoc
WHERE Malop = :NEW.Malop;

IF v_siso >= v_max THEN
RAISE_APPLICATION_ERROR(-20003,'Lop da day');
END IF;

UPDATE Lophoc
SET Sisohientai = Sisohientai + 1
WHERE Malop = :NEW.Malop;

END;
/
INSERT INTO Dangky
VALUES(1,'SV01','L01',SYSDATE);
CREATE OR REPLACE TRIGGER trg_dangky_delete
AFTER DELETE ON Dangky
FOR EACH ROW
BEGIN

UPDATE Lophoc
SET Sisohientai = Sisohientai - 1
WHERE Malop = :OLD.Malop;

END;
/
DELETE FROM Dangky
WHERE Madk = 1;
CREATE OR REPLACE TRIGGER trg_dangky_update
BEFORE UPDATE OF Malop ON Dangky
FOR EACH ROW
DECLARE
v_count NUMBER;
v_siso NUMBER;
v_max NUMBER;
BEGIN

SELECT COUNT(*) INTO v_count
FROM Lophoc
WHERE Malop = :NEW.Malop;

IF v_count = 0 THEN
RAISE_APPLICATION_ERROR(-20004,'Lop moi khong ton tai');
END IF;

SELECT COUNT(*) INTO v_count
FROM Dangky
WHERE Masv = :NEW.Masv
AND Malop = :NEW.Malop;

IF v_count > 0 THEN
RAISE_APPLICATION_ERROR(-20005,'Sinh vien da ton tai lop moi');
END IF;

SELECT Sisohientai, Sisotoida
INTO v_siso, v_max
FROM Lophoc
WHERE Malop = :NEW.Malop;

IF v_siso >= v_max THEN
RAISE_APPLICATION_ERROR(-20006,'Lop moi da day');
END IF;

UPDATE Lophoc
SET Sisohientai = Sisohientai - 1
WHERE Malop = :OLD.Malop;

UPDATE Lophoc
SET Sisohientai = Sisohientai + 1
WHERE Malop = :NEW.Malop;

END;
/

