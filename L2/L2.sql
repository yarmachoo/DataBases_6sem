CREATE TABLE STUDENTS (
    ID NUMBER PRIMARY KEY,
    "NAME" VARCHAR2(100),
    "GROUP_ID" NUMBER
);

select * from STUDENTS;


CREATE TABLE GROUPS (
    ID NUMBER PRIMARY KEY,
    "NAME" VARCHAR2 (100),
    C_VAL NUMBER
);

SELECT * FROM GROUPS;

//2. Реализовать триггеры для таблиц 
//задания 1 
//1 - проверку целостности (проверка на уникальность полей ID),
//2 - генерацию автоинкрементного ключа и 
//3 - проверку уникальности для поля GROUP.NAME

//1

create or replace trigger trigger_unique_group_id
before insert on GROUPS
for each ROW
declare
    v_count NUMBER;
BEGIN
    select count(*) INTO v_count from groups where ID=:New.ID;

    if v_count >0 THEN
        Raise_Application_Error(-20001, 'ERROR: ID of group should be unique!');
    END IF;
End;

create or replace trigger trigger_unique_student_id
before insert on STUDENTS
for each ROW
declare
    v_count NUMBER;
BEGIN
    select count(*) INTO v_count from STUDENTS where ID=:New.ID;

    if v_count >0 THEN
        Raise_Application_Error(-20001, 'ERROR: ID of student should be unique!');
    END IF;
End;

//2
//последовательность для автоинкрементов
CREATE SEQUENCE STUDENTS_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE GROUPS_SEQ START WITH 1 INCREMENT BY 1;

create or replace trigger trigger_auto_student_id
before insert on STUDENTS
for each ROW
begin 
    if :NEW.ID is NULL THEN
        :NEW.ID:=STUDENTS_SEQ.NEXTVAL;
    END IF;
END;
/

create or replace trigger students_auto_stident_id
before insert on GROUPS
for each ROW
begin
    if :NEW.ID is NULL THEN
     :New.ID:=GROUPS_SEQ.NEXTVAL;
    END If;
End;

//3
create or replace trigger trigger_unique_group_name
before insert or update on GROUPS
for each ROW
declare
    v_count NUMBER;
BEGIN
    select COUNT(*) into v_count
    from GROUPS
    WHERE LOWER("NAME")=LOWER(:NEW."NAME")
    AND (ID <> :NEW.ID OR :NEW.ID IS NULL);

    IF v_count >0 THEN
        Raise_Application_Error(-20002,  'ERROR: name of group should be unique!');
    END IF;
END;


//check triggers
INSERT INTO STUDENTS ("NAME", "GROUP_ID") VALUES ('John Doe', 1);

select * from STUDENTS;
INSERT INTO STUDENTS ("NAME", "GROUP_ID") VALUES ('Doe', 5);
INSERT INTO STUDENTS (ID, "NAME", "GROUP_ID") VALUES (1, 'Doe', 1);

INSERT INTO GROUPS ("NAME", C_VAL) VALUES ('Group A', 5);
INSERT INTO GROUPS ("NAME", C_VAL) VALUES ('Group B', 5);
select * from GROUPS;

INSERT INTO GROUPS (ID, "NAME", C_VAL) VALUES (5, 'Group C', 5);

INSERT INTO GROUPS ("NAME", C_VAL) VALUES ('Group B', 5);


//////////////////////////////////////////////////////////////////

//cascade delete:

CREATE OR REPLACE PACKAGE global_variables AS
    is_group_delete_cascade BOOLEAN := FALSE;
END global_variables;
/

create or replace trigger trigger_delete_group_cascade
before delete on GROUPS
for each ROW
BEGIN
    global_variables.is_group_delete_cascade:=true;

    delete from STUDENTS
    WHERE "GROUP_ID" = :OLD.ID;

    global_variables.is_group_delete_cascade := FALSE;
EXCEPTION
    WHEN OTHERS THEN
        global_variables.is_group_delete_cascade := FALSE;
        RAISE;
END;

create or replace trigger trigger_chack_group_exists
before insert or update on STUDENTS
for each ROW
DECLARE
v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    from GROUPS
    WHERE ID = :New."GROUP_ID";

    IF v_count = 0 THEN
        Raise_Application_Error(-20000, 'ERROR: Group with ID' || :NEW."GROUP_ID" || ' is not exists.');
    END IF;

END;

create or replace trigger trigger_prevent_group_id_update
before update of "GROUP_ID" on STUDENTS
FOR EACH ROW
DECLARE 
    students_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO students_exists
    FROM STUDENTS
    WHERE "GROUP_ID" = :OLD."GROUP_ID";

    IF students_exists = 0 THEN
        Raise_Application_Error(-20000, 'ERROR: this group has students. You can not update ID.');
    END IF;
END;

select * from GROUPS
select * from STUDENTS

DELETE FROM GROUPS WHERE "NAME"='Group A'


////////////////////////////////////////////////////
//task4
CREATE TABLE STUDENTS_LOGS (
    LOG_ID NUMBER PRIMARY KEY,
    ACTION_TYPE VARCHAR2(10),     
    STUDENT_ID NUMBER,            
    STUDENT_NAME VARCHAR2(100),    
    GROUP_ID NUMBER,              
    ACTION_TIMESTAMP TIMESTAMP,    
    ACTION_BY VARCHAR2(100)       
);

CREATE OR REPLACE TRIGGER trigger_insert_student_log
AFTER INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    INSERT INTO STUDENTS_LOGS (LOG_ID, ACTION_TYPE, STUDENT_ID, STUDENT_NAME, GROUP_ID, ACTION_TIMESTAMP, ACTION_BY)
    VALUES (STUDENTS_LOGS_SEQ.NEXTVAL, 'INSERT', :NEW.ID, :NEW."NAME", :NEW."GROUP_ID", SYSTIMESTAMP, USER);
END;
/

CREATE OR REPLACE TRIGGER trigger_update_student_log
AFTER UPDATE ON STUDENTS
FOR EACH ROW
BEGIN
    INSERT INTO STUDENTS_LOGS (LOG_ID, ACTION_TYPE, STUDENT_ID, STUDENT_NAME, GROUP_ID, ACTION_TIMESTAMP, ACTION_BY)
    VALUES (STUDENTS_LOGS_SEQ.NEXTVAL, 'UPDATE', :NEW.ID, :NEW."NAME", :NEW."GROUP_ID", SYSTIMESTAMP, USER);
END;
/

CREATE OR REPLACE TRIGGER trigger_delete_student_log
AFTER DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    INSERT INTO STUDENTS_LOGS (LOG_ID, ACTION_TYPE, STUDENT_ID, STUDENT_NAME, GROUP_ID, ACTION_TIMESTAMP, ACTION_BY)
    VALUES (STUDENTS_LOGS_SEQ.NEXTVAL, 'DELETE', :OLD.ID, :OLD."NAME", :OLD."GROUP_ID", SYSTIMESTAMP, USER);
END;
/

CREATE SEQUENCE STUDENTS_LOGS_SEQ
START WITH 1 INCREMENT BY 1;

INSERT INTO STUDENTS ("NAME", "GROUP_ID") VALUES ('John Doe', 5);
UPDATE STUDENTS SET "NAME" = 'John Smith' WHERE "NAME" = 'John Doe';
DELETE FROM STUDENTS WHERE "NAME" = 'John Smith';
SELECT * FROM STUDENTS_LOGS;

/////////////////////////////////////////////////////////
//Task 5
 
 create or replace procedure restore_students_from_logs(
    p_time TIMESTAMP DEFAULT NULL,
    p_offset INTERVAL DAY TO SECOND DEFAULT NULL
 ) IS
    v_restore_time TIMESTAMP;
    v_group_exists NUMBER;
    v_student_exists NUMBER;
begin
    if p_time is not null THEN
        v_restore_time:=p_time;
    ELSIF p_offset is not null THEN
        v_restore_time:=SYSTIMESTAMP - p_offset;
    ELSE 
        Raise_Application_Error(-20000, 'You need to send p_time or p_offset');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Restore data from ' || TO_CHAR(v_restore_time, 'DD-MM-YYYY HH24:MI:SS'));
    FOR record IN (
        SELECT DISTINCT STUDENT_ID, STUDENT_NAME, GROUP_ID
        FROM STUDENTS_LOGS
        WHERE ACTION_TIMESTAMP >= v_restore_time
          AND ACTION_TYPE = 'DELETE'
    ) LOOP
        SELECT COUNT(*) INTO v_group_exists
        FROM GROUPS
        WHERE ID = record.GROUP_ID;

        IF v_group_exists = 0 THEN
            INSERT INTO GROUPS (ID, "NAME")
            VALUES (record.GROUP_ID, 'Group ' || record.GROUP_ID);
            DBMS_OUTPUT.PUT_LINE('The group with ID ' || record.GROUP_ID || ' is restored');
        END IF;
    END LOOP;

    FOR record IN (
        SELECT * FROM STUDENTS_LOGS
        WHERE ACTION_TIMESTAMP >= v_restore_time
          AND ACTION_TYPE = 'DELETE'
        ORDER BY ACTION_TIMESTAMP DESC
    ) LOOP
        SELECT COUNT(*) INTO v_student_exists
        FROM STUDENTS
        WHERE ID = record.STUDENT_ID;

        IF v_student_exists = 0 THEN
            INSERT INTO STUDENTS (ID, "NAME", GROUP_ID)
            VALUES (record.STUDENT_ID, record.STUDENT_NAME, record.GROUP_ID);
            DBMS_OUTPUT.PUT_LINE('Student with ID ' || record.STUDENT_ID || ' is restored');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Student with ID ' || record.STUDENT_ID || ' already exists, skip.');
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Restore was end.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/
INSERT INTO STUDENTS ("NAME", "GROUP_ID") VALUES ('Veronika', 5);
select * from STUDENTS
select * from GROUPS
select * from STUDENTS_

delete from groups where ID = 5;
delete from students where ID = 4;

BEGIN
    restore_students_from_logs(TIMESTAMP '2025-03-10 17:00:00', NULL);
END;
/

BEGIN
    restore_students_from_logs(NULL, INTERVAL '10' MINUTE);
END;
/
