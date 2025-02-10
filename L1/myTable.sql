CREATE TABLE MYTABLE (
    ID NUMBER PRIMARY KEY,
    VAL NUMBER
);

SELECT * FROM MYTABLE;

-- Реализовать анонимный блок для вставки 10 000 случайных значений
DECLARE
    counter NUMBER := 1;
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO MYTABLE (ID, VAL)
        VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1,100)));
    END LOOP;
    COMMIT;
END;


--Напишите собственную функцию, которая выводит TRUE 
--если четных значений val в таблице MyTable больше, 
--FALSE если больше нечетных значений и EQUAL если 
--количество четных и нечетных равно

CREATE OR REPLACE FUNCTION Task3 
RETURN VARCHAR AS
    counterOfEvenNumbers NUMBER:=0;
    counterOfOddNumbers NUMBER:=0;
BEGIN
    SELECT COUNT(*) INTO counterOfEvenNumbers FROM MYTABLE WHERE MOD(val, 2)=0;
    SELECT COUNT(*) INTO counterOfOddNumbers FROM MYTABLE WHERE MOD(val, 2)=1;

    IF counterOfEvenNumbers>counterOfOddNumbers THEN
        RETURN 'TRUE';
    ELSIF counterOfEvenNumbers<counterOfOddNumbers THEN
        RETURN 'FALSE';
    ELSE RETURN 'EQUAL';
    END IF;
END Task3;
/

SELECT TASK3 FROM DUAL;





CREATE OR REPLACE FUNCTION Task4 (myId NUMBER)
    RETURN VARCHAR AS
    myValue NUMBER;
    str VARCHAR(4000);
BEGIN
    SELECT val INTO myValue FROM MYTABLE Where id=myId;
    str:='INSERT INTO MYTABLE (id, val) VALUES(' || myId || ',' || myValue || ');';
    RETURN str;
EXCEPTION 
WHEN NO_DATA_FOUND THEN
    RETURN 'ERROR: There is no note with' || myId || ' ID'; 
END TASK4;
/


SELECT TASK4(10) FROM DUAL;

SHOW ERRORS FUNCTION TASK4;