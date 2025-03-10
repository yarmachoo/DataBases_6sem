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
INSERT INTO STUDENTS ("NAME", "GROUP_ID") VALUES ('Doe', 1);
INSERT INTO STUDENTS (ID, "NAME", "GROUP_ID") VALUES (1, 'Doe', 1);

INSERT INTO GROUPS ("NAME", C_VAL) VALUES ('Group A', 5);
INSERT INTO GROUPS ("NAME", C_VAL) VALUES ('Group B', 5);
select * from GROUPS;

INSERT INTO GROUPS (ID, "NAME", C_VAL) VALUES (5, 'Group C', 5);

INSERT INTO GROUPS ("NAME", C_VAL) VALUES ('Group B', 5);