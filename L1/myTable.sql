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