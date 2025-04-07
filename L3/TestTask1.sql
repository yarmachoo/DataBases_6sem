BEGIN
    DEVELOPER.compare_schemas('NON_EXISTENT_DEV', 'NON_EXISTENT_PROD');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

SELECT object_name, object_type 
FROM all_objects 
WHERE owner = 'DEVELOPER' AND object_name = 'COMPARE_SCHEMAS';

BEGIN
    compare_schemas('NON_EXISTENT_DEV', 'NON_EXISTENT_PROD');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/


CREATE USER TEST_DEV IDENTIFIED BY admin;
GRANT ALL PRIVILEGES TO TEST_DEV;

CREATE USER TEST_PROD IDENTIFIED BY admin;
GRANT ALL PRIVILEGES TO TEST_PROD;

-- Создание одинаковых таблиц в обеих схемах
CREATE TABLE TEST_DEV.example_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50)
);

CREATE TABLE TEST_PROD.example_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50)
);

-- Вызов процедуры с одинаковыми схемами
BEGIN
    compare_schemas('TEST_DEV', 'TEST_PROD');
END;
/


-- Создание тестовых данных
CREATE TABLE TEST_DEV.diff_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50)
);

CREATE TABLE TEST_PROD.diff_table (
    id NUMBER PRIMARY KEY,
    full_name VARCHAR2(50) -- Изменено имя столбца
);

-- Вызов процедуры для проверки различий
BEGIN
    compare_schemas('TEST_DEV', 'TEST_PROD');
END;
/

-- Создание таблиц с циклическими зависимостями
CREATE TABLE TEST_DEV.table_a (
    id NUMBER PRIMARY KEY,
    ref_id NUMBER,
    CONSTRAINT fk_a FOREIGN KEY (ref_id) REFERENCES TEST_DEV.table_b(id)
);

CREATE TABLE TEST_DEV.table_b (
    id NUMBER PRIMARY KEY,
    ref_id NUMBER,
    CONSTRAINT fk_b FOREIGN KEY (ref_id) REFERENCES TEST_DEV.table_a(id)
);

-- Вызов процедуры для проверки циклических зависимостей
BEGIN
    compare_schemas('TEST_DEV', 'TEST_PROD');
END;
/


DROP TABLE TEST_PROD.diff_table;

-- Вызов процедуры для проверки удаления
BEGIN
    compare_schemas('TEST_DEV', 'TEST_PROD');
END;
/