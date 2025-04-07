

SELECT SYSTIMESTAMP FROM DUAL; 

-- Удаляем студента
DELETE FROM STUDENTS WHERE ID = 31;


delete from groups where id = 50;

SELECT * FROM STUDENTS;

EXEC restore_student_data(TIMESTAMP '2025-03-14 17:22:58');

-- Проверяем, восстановился ли студент
SELECT * FROM STUDENTS;



INSERT INTO GROUPS (NAME) VALUES ('Группа 1');
INSERT INTO GROUPS (NAME) VALUES ('Группа 2');
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Студент 1', 50);
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Студент 2', 50);
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Студент 3', 49);

SELECT * FROM STUDENTS;

SELECT * FROM GROUPS;

delete from groups where id = 50;

SELECT * FROM STUDENTS;

delete from groups;
delete from STUDENTS;
