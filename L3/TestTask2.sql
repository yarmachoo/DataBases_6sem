BEGIN
    GENERATE_SYNC_SCRIPT('NON_EXISTENT_DEV', 'NON_EXISTENT_PROD');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Создание тестовых данных в схеме Dev
CREATE OR REPLACE PROCEDURE TEST_DEV.test_proc AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello from Dev!');
END;
/

CREATE OR REPLACE PROCEDURE TEST_DEV.test_proc_updated AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello from Updated Dev!');
END;
/

-- Создание тестовых данных в схеме Prod
CREATE OR REPLACE PROCEDURE TEST_PROD.test_proc AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello from Prod!');
END;
/

-- Создание процедуры, которая отсутствует в Dev
CREATE OR REPLACE PROCEDURE TEST_PROD.test_proc_removed AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('This procedure is removed from Dev!');
END;
/

BEGIN
    GENERATE_SYNC_SCRIPT('TEST_DEV', 'TEST_PROD');
END;
/


BEGIN
    GENERATE_SYNC_SCRIPT('DEVELOPER', 'PRODUCTION');
END;
/

BEGIN
    compare_schemas('DEVELOPER', 'PRODUCTION');
END;
/