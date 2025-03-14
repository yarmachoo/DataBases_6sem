CREATE TABLE GROUPS (
    GROUP_ID NUMBER NOT NULL,
    GROUP_NAME VARCHAR2(20) NOT NULL,
    C_VAL NUMBER DEFAULT 0 NOT NULL
);

CREATE TABLE STUDENTS (
    STUDENT_ID NUMBER NOT NULL,
    STUDENT_NAME VARCHAR2(20) NOT NULL,
    GROUP_ID NUMBER NOT NULL
);

DROP TABLE GROUPS;
DROP TABLE STUDENTS;

///////////////////////////////////////////////////////
//Task2


CREATE SEQUENCE STUDENTS_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE GROUPS_SEQ START WITH 1 INCREMENT BY 1;

DROP SEQUENCE STUDENTS_SEQ;
DROP SEQUENCE GROUPS_SEQ;

CREATE OR REPLACE TRIGGER trigger_auto_group_id
BEFORE INSERT ON groups
FOR EACH ROW
BEGIN
    IF :NEW.group_id IS NULL THEN
        :NEW.group_id := GROUPS_SEQ.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_auto_student_id
BEFORE INSERT ON students
FOR EACH ROW
BEGIN
    IF :NEW.student_id IS NULL THEN
   :NEW.student_id := STUDENTS_SEQ.NEXTVAL;
    END IF;
END;
/


CREATE OR REPLACE TRIGGER trigger_unique_group_id
BEFORE INSERT OR UPDATE ON groups
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF INSERTING THEN
        SELECT COUNT(*) INTO v_count FROM groups WHERE group_id = :NEW.group_id;
        
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'ERROR: ID of group should be unique!');
        END IF;
    END IF;
    
    IF UPDATING THEN
        NULL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_unique_student_id
BEFORE INSERT ON students
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;  
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM students WHERE student_id = :NEW.student_id;
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR: ID of student should be unique!');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_unique_group_name
AFTER INSERT OR UPDATE ON groups
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM groups 
    WHERE LOWER(group_name) = LOWER(:NEW.group_name)
    AND group_id <> :NEW.group_id; 
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002,  'ERROR: name of group should be unique!');
    END IF;
END;
/

///////////////////////////////////////////////////////
//Task 3

CREATE OR REPLACE PACKAGE global_variables AS
    is_group_delete_cascade BOOLEAN := FALSE;
END global_variables;
/

CREATE OR REPLACE TRIGGER tl_delete_group_cascade
BEFORE DELETE ON groups
FOR EACH ROW
BEGIN
    global_variables.is_group_delete_cascade := TRUE;
    
    DELETE FROM students
    WHERE group_id = :OLD.group_id;  

    global_variables.is_group_delete_cascade := FALSE;
EXCEPTION
    WHEN OTHERS THEN
        global_variables.is_group_delete_cascade := FALSE;
        RAISE;
END;
/

CREATE OR REPLACE TRIGGER trigger_check_group_exists
BEFORE INSERT OR UPDATE ON students
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM groups 
    WHERE group_id = :NEW.group_id;  

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'ERROR: Group with ID' || :NEW."GROUP_ID" || ' is not exists.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER prevent_group_id_update
BEFORE UPDATE OF group_id ON groups
FOR EACH ROW
DECLARE
    students_exist NUMBER;
BEGIN
    SELECT COUNT(*) INTO students_exist
    FROM students
    WHERE group_id = :OLD.group_id;

    IF students_exist > 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'ERROR: this group has students. You can not update ID.');
    END IF;
END;
/
///////////////////////////////////////////////////////
//Task 4

CREATE OR REPLACE PACKAGE student_ctx AS
    //array for group_id
    TYPE t_group_name_table IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
    g_group_names t_group_name_table;
    PROCEDURE load_group_name(p_group_id NUMBER, p_group_name VARCHAR2);
END student_ctx;
/

CREATE OR REPLACE PACKAGE BODY student_ctx AS
    PROCEDURE load_group_name(p_group_id NUMBER, p_group_name VARCHAR2) IS
    BEGIN
        g_group_names(p_group_id) := p_group_name;
    END load_group_name;
END student_ctx;
/

CREATE OR REPLACE TRIGGER cache_group_on_insert
AFTER INSERT OR UPDATE ON groups
FOR EACH ROW
BEGIN
    student_ctx.load_group_name(:NEW.group_id, :NEW.group_name);
END;
/

CREATE TABLE students_logs (
    LOG_ID NUMBER PRIMARY KEY,
    ACTION_TYPE VARCHAR2(10),
    OLD_ID NUMBER,
    NEW_ID NUMBER,
    OLD_NAME VARCHAR2(255),
    NEW_NAME VARCHAR2(255),
    OLD_GROUP_ID NUMBER,
    NEW_GROUP_ID NUMBER,
    OLD_GROUP_NAME VARCHAR2(255),
    NEW_GROUP_NAME VARCHAR2(255),
    ACTION_TIME TIMESTAMP
);
/

drop table students_logs;

CREATE SEQUENCE STUDENTS_LOGS_SEQ START WITH 1;
/
DROP SEQUENCE STUDENTS_LOGS_SEQ;


CREATE OR REPLACE TRIGGER log_student_changes
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO students_logs (LOG_ID, ACTION_TYPE, NEW_ID, NEW_NAME, NEW_GROUP_ID, NEW_GROUP_NAME, ACTION_TIME)
        VALUES (STUDENTS_LOGS_SEQ.NEXTVAL, 'INSERT', :NEW.student_id, :NEW.student_name, :NEW.group_id, student_ctx.g_group_names(:NEW.group_id), CURRENT_TIMESTAMP);
    ELSIF UPDATING THEN
        INSERT INTO students_logs (LOG_ID, ACTION_TYPE, OLD_ID, NEW_ID, OLD_NAME, NEW_NAME, OLD_GROUP_ID, OLD_GROUP_NAME, NEW_GROUP_ID, NEW_GROUP_NAME, ACTION_TIME)
        VALUES (STUDENTS_LOGS_SEQ.NEXTVAL, 'UPDATE', :OLD.student_id, :NEW.student_id, :OLD.student_name, :NEW.student_name, :OLD.group_id, student_ctx.g_group_names(:OLD.group_id), :NEW.group_id, student_ctx.g_group_names(:NEW.group_id), CURRENT_TIMESTAMP);
    ELSIF DELETING THEN
        INSERT INTO students_logs (LOG_ID, ACTION_TYPE, OLD_ID, OLD_NAME, OLD_GROUP_ID, OLD_GROUP_NAME, ACTION_TIME)
        VALUES (STUDENTS_LOGS_SEQ.NEXTVAL, 'DELETE', :OLD.student_id, :OLD.student_name, :OLD.group_id, student_ctx.g_group_names(:OLD.group_id), CURRENT_TIMESTAMP);
    END IF;
END;
/


///////////////////////////////////////////////////////
//TASK 5

CREATE OR REPLACE PROCEDURE restore_students_from_logs(
    p_time TIMESTAMP DEFAULT NULL,
    p_offset INTERVAL DAY TO SECOND DEFAULT NULL
) IS
    v_restore_time TIMESTAMP;
    v_group_exists NUMBER;
    v_student_exists NUMBER;
    v_count_deleted NUMBER := 0;
BEGIN
    IF p_time IS NOT NULL THEN
        v_restore_time := p_time;
    ELSIF p_offset IS NOT NULL THEN
        v_restore_time := CURRENT_TIMESTAMP - p_offset;
    ELSE
        RAISE_APPLICATION_ERROR(-20000, 'You need to send p_time or p_offset');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Restore data from ' || TO_CHAR(v_restore_time, 'DD-MM-YYYY HH24:MI:SS'));

    SELECT COUNT(*) INTO v_count_deleted
    FROM students_logs
    WHERE action_time >= v_restore_time
      AND action_type = 'DELETE';

    IF v_count_deleted = 0 THEN
        DBMS_OUTPUT.PUT_LINE('There is no DELETE records in students_logs. Restoring is not needed.');
        RETURN;
    END IF;

    FOR record IN (
        SELECT DISTINCT old_group_id, old_group_name
        FROM students_logs
        WHERE action_time >= v_restore_time
          AND old_group_id IS NOT NULL
          AND old_group_name IS NOT NULL
    ) LOOP
        SELECT COUNT(*) INTO v_group_exists
        FROM groups
        WHERE group_id = record.old_group_id;

        IF v_group_exists = 0 THEN
            INSERT INTO groups (group_id, group_name)
            VALUES (record.old_group_id, record.old_group_name);
            DBMS_OUTPUT.PUT_LINE('The group with ID ' || record.old_group_id || ' is restored');
        END IF;
    END LOOP;

    FOR record IN (
        SELECT * FROM students_logs
        WHERE action_time >= v_restore_time
          AND action_type = 'DELETE'
        ORDER BY action_time DESC
    ) LOOP
        SELECT COUNT(*) INTO v_student_exists
        FROM students
        WHERE student_id = record.old_id;

        IF v_student_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TRIGGER trigger_check_group_exists DISABLE';
            INSERT INTO students (student_id, student_name, group_id)
            VALUES (record.old_id, record.old_name, record.old_group_id);
            DBMS_OUTPUT.PUT_LINE('Student with ID ' || record.old_id || ' is restored');
            EXECUTE IMMEDIATE 'ALTER TRIGGER trigger_check_group_exists ENABLE';
        ELSE                     
            DBMS_OUTPUT.PUT_LINE('Student with ID ' || record.old_id || ' already exists.');
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Restore is end.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/

///////////////////////////////////////////////////////
//TASK 6

CREATE OR REPLACE TRIGGER trigger_update_c_val_on_insert
BEFORE INSERT ON students
FOR EACH ROW
BEGIN
    UPDATE groups
    SET c_val = c_val + 1
    WHERE group_id = :NEW.group_id;
END;
/

CREATE OR REPLACE TRIGGER trigger_update_c_val_on_delete
BEFORE DELETE ON students
FOR EACH ROW
BEGIN
    IF NOT global_variables.is_group_delete_cascade THEN
        UPDATE groups
        SET c_val = c_val - 1
        WHERE group_id = :OLD.group_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_update_c_val_on_update
BEFORE UPDATE OF group_id ON students
FOR EACH ROW
BEGIN
    IF :OLD.group_id != :NEW.group_id THEN
        UPDATE groups
        SET c_val = c_val - 1
        WHERE group_id = :OLD.group_id;
        UPDATE groups
        SET c_val = c_val + 1
        WHERE group_id = :NEW.group_id;
    END IF;
END;
/

///////////////////////////////////////////////////////////////////
//TEST 1 TASK

SELECT * FROM students;
SELECT * FROM groups;

//TEST 2 TASK 

INSERT INTO GROUPS ("GROUP_NAME") VALUES ('Group D');
INSERT INTO STUDENTS ("STUDENT_NAME", "GROUP_ID") VALUES ('John Doe', 4);
INSERT INTO GROUPS ("GROUP_ID", "GROUP_NAME") VALUES (2, 'Group B');
INSERT INTO GROUPS ("GROUP_ID", "GROUP_NAME") VALUES (3, 'Group C');
DELETE FROM GROUPS WHERE GROUP_ID = 2;

//TEST 3 Task

SELECT * FROM students;
SELECT * FROM groups;


INSERT INTO STUDENTS ("STUDENT_NAME", "GROUP_ID") VALUES ('Veronika', 2);
DELETE FROM GROUPS where GROUP_ID=3;

//TEST 4 Task

SELECT sessiontimezone, dbtimezone FROM dual;
SELECT CURRENT_TIMESTAMP FROM dual;
Delete from students where student_id=3;

SELECT * FROM students_LOGs;

//TEST 5 TASK

SELECT * FROM students;
SELECT * FROM groups;
SELECT * FROM students_LOGs;

BEGIN
    restore_students_from_logs(NULL, INTERVAL '3' MINUTE);
END;
/

BEGIN
    restore_students_from_logs(NULL, TO_DSINTERVAL('0 00:08:00'));
END;
/

BEGIN
    restore_students_from_logs(TIMESTAMP '2025-03-14 16:13:23', NULL);
END;
/

//TEST 6 TASK

SELECT * FROM students;
SELECT * FROM groups;

UPDATE STUDENTS SET group_id=2 WHERE student_id = 2;
