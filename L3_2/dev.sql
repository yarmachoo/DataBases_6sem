CREATE USER DEV IDENTIFIED BY password;
GRANT CONNECT, RESOURCE TO DEV;
ALTER SESSION SET CONTAINER=DEV;

CREATE TABLE A (
  id   NUMBER PRIMARY KEY,
  name VARCHAR2(50)
);

CREATE TABLE B (
  id          NUMBER PRIMARY KEY,
  a_id        NUMBER,
  description VARCHAR2(100),
  CONSTRAINT fk_b_a FOREIGN KEY (a_id) REFERENCES A(id)
);

CREATE TABLE C (
  id   NUMBER PRIMARY KEY,
  b_id NUMBER,
  info VARCHAR2(100),
  CONSTRAINT fk_c_b FOREIGN KEY (b_id) REFERENCES B(id)
);

CREATE TABLE X (
  id   NUMBER PRIMARY KEY,
  y_id NUMBER
);
CREATE TABLE Y (
  id   NUMBER PRIMARY KEY,
  x_id NUMBER
);
ALTER TABLE X ADD CONSTRAINT fk_x_y FOREIGN KEY (y_id) REFERENCES Y(id);
ALTER TABLE Y ADD CONSTRAINT fk_y_x FOREIGN KEY (x_id) REFERENCES X(id);

CREATE OR REPLACE PROCEDURE PROC_DEV AS
BEGIN
  DBMS_OUTPUT.PUT_LINE('DEV версия процедуры');
END;

CREATE OR REPLACE FUNCTION FUNC_DEV RETURN VARCHAR2 AS
BEGIN
  RETURN 'DEV функция';
END;

CREATE OR REPLACE PACKAGE PKG_DEV AS
  PROCEDURE pkg_proc;
END;


CREATE OR REPLACE PACKAGE BODY PKG_DEV AS
  PROCEDURE pkg_proc IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('DEV пакет: процедура');
  END;
END;

CREATE INDEX IDX_B_DESCRIPTION ON B(description);