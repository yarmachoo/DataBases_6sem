DECLARE
  v_result VARCHAR2(4000);
BEGIN
  v_result := json_ddl_handler('{
    "operation": "CREATE",
    "table": "People",
    "columns": [
      {"name": "PersonId", "type": "NUMBER", "constraints": "PRIMARY KEY"},
      {"name": "PersonName", "type": "VARCHAR2(100)"}
    ]
  }');
  DBMS_OUTPUT.PUT_LINE(v_result);
END;
/


DECLARE
  v_json CLOB := '{
    "operation": "INSERT",
    "table": "People",
    "columns": ["PersonName"],
    "values": ["Kate"]
  }';
  v_result VARCHAR2(100);
BEGIN
  v_result := json_dml_handler(v_json);
  DBMS_OUTPUT.PUT_LINE(v_result);

END;
/

select * from People;

DECLARE
  v_result VARCHAR2(4000);
BEGIN
  v_result := json_ddl_handler('{
    "operation": "CREATE",
    "table": "Cats",
    "columns": [
      {"name": "PetId", "type": "NUMBER", "constraints": "PRIMARY KEY"},
      {"name": "PetName", "type": "VARCHAR2(100)"},
      {"name": "PersonId", "type": "NUMBER"}
    ],
    "foreign_keys":[
      {
        "column": "PersonId",
        "references": {"table": "People", "column": "PersonId"}
      }
    ]
  }');
  DBMS_OUTPUT.PUT_LINE(v_result);
END;
/


DECLARE
  v_json CLOB := '{
    "operation": "INSERT",
    "table": "Cats",
    "columns": ["PetId", "PetName", "PersonId"],
    "values": ["1", "Persik", "1"]
  }';
  v_result VARCHAR2(100);
BEGIN
  v_result := json_dml_handler(v_json);
  DBMS_OUTPUT.PUT_LINE(v_result);

END;
/

select * from Cats;

drop table Cats;


--тест апдейта
DECLARE
  v_json CLOB := '{
    "operation": "UPDATE",
    "table": "People",
    "set": [
      { "column": "PersonName", "value": "veronichka" }
    ],
    "where": {
      "conditions": [
        {
          "column": "PersonId",
          "operator": "=",
          "value": "1"
        }
      ],
      "logical_operator": "AND"
    }
  }';
  v_result VARCHAR2(100);
BEGIN
  v_result := json_dml_handler(v_json);
  DBMS_OUTPUT.PUT_LINE(v_result);
END;
/

--тест удаления
DECLARE
  v_json CLOB := '{
    "operation": "DELETE",
    "table": "People",
    "where": {
      "conditions": [
        {
          "column": "PersonId",
          "operator": "=",
          "value": "2"
        }
      ],
      "logical_operator": "AND"
    }
  }';
  v_result VARCHAR2(100);
BEGIN
  v_result := json_dml_handler(v_json);
  DBMS_OUTPUT.PUT_LINE(v_result);
END;
/


SELECT * FROM USER_SYS_PRIVS;

GRANT CREATE TRIGGER TO SYSTEM;
GRANT CREATE SEQUENCE TO SYSTEM;
GRANT CREATE TABLE TO SYSTEM;



-------------------------------------
--объединяет таблицы People и Cats по полю PersonId и выводит имя человека и имя кота.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["People.PersonName", "Cats.PetName"],
    "tables": ["People"],
    "joins": [
      {
        "type": "INNER JOIN",
        "table": "Cats",
        "on": "People.PersonId = Cats.PersonId"
      }
    ]
  }';
  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
  v_petname Cats.PetName%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name, v_petname;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name || ' | ' || v_petname);
  END LOOP;
  CLOSE v_cur;
END;

--PersonId встречаются в таблице Cats.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PersonName"],
    "tables": ["People"],
    "where": {
      "conditions": [
        {
          "column": "PersonId",
          "operator": "IN",
          "subquery": {
            "columns": "PersonId",
            "tables": "Cats",
            "conditions": "PetName = ''Persik''"
          }
        }
      ],
      "logical_operator": "AND"
    }
  }';

  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name);
  END LOOP;
  CLOSE v_cur;
END;

--выбираем людей, у которых нет котов с именем Persik.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PersonName"],
    "tables": ["People"],
    "where": {
      "conditions": [
        {
          "column": "PersonId",
          "operator": "NOT IN",
          "subquery": {
            "columns": "PersonId",
            "tables": "Cats",
            "conditions": "PetName = ''Persik''"
          }
        }
      ],
      "logical_operator": "AND"
    }
  }';

  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name);
  END LOOP;
  CLOSE v_cur;
END;

--людей, для которых существует кот с именем Persik.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PersonName"],
    "tables": ["People"],
    "where": {
      "conditions": [
        {
          "column": "",
          "operator": "EXISTS",
          "subquery": {
            "columns": "PersonId",
            "tables": "Cats",
            "conditions": "PetName = ''Persik'' AND Cats.PersonId = People.PersonId"
          }
        }
      ],
      "logical_operator": "AND"
    }
  }';

  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name);
  END LOOP;
  CLOSE v_cur;
END;

--у которых нет котов с именем Persik.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PersonName"],
    "tables": ["People"],
    "where": {
      "conditions": [
        {
          "column": "",
          "operator": "NOT EXISTS",
          "subquery": {
            "columns": "PersonId",
            "tables": "Cats",
            "conditions": "PetName = ''Persik'' AND Cats.PersonId = People.PersonId"
          }
        }
      ],
      "logical_operator": "AND"
    }
  }';

  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name);
  END LOOP;
  CLOSE v_cur;
END;

--Считаем количество людей с котами, сгруппировав по имени кота.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["Cats.PetName", "COUNT(People.PersonId)"],
    "tables": ["Cats"],
    "joins": [
      {
        "type": "LEFT JOIN",
        "table": "People",
        "on": "Cats.PersonId = People.PersonId"
      }
    ],
    "group_by": ["Cats.PetName"]
  }';

  v_cur SYS_REFCURSOR;
  v_petname Cats.PetName%TYPE;
  v_count NUMBER;
BEGIN
  v_cur := json_select_handler(v_json);
  DBMS_OUTPUT.PUT_LINE('Количество людей по котам:');
  LOOP
    FETCH v_cur INTO v_petname, v_count;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_petname || ' | ' || v_count);
  END LOOP;
  CLOSE v_cur;
END;

--среднее количество котов на человека.

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["People.PersonName", "COUNT(Cats.PetId)"],
    "tables": ["People"],
    "joins": [
      {
        "type": "LEFT JOIN",
        "table": "Cats",
        "on": "People.PersonId = Cats.PersonId"
      }
    ],
    "group_by": ["People.PersonName"]
  }';

  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
  v_count NUMBER;
BEGIN
  v_cur := json_select_handler(v_json);
  DBMS_OUTPUT.PUT_LINE('Количество котов у каждого человека:');
  LOOP
    FETCH v_cur INTO v_name, v_count;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name || ' | ' || v_count);
  END LOOP;
  CLOSE v_cur;
END;


DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["People.PersonName", "Cats.PetName"],
    "tables": ["People"],
    "joins": [
      {
        "type": "INNER JOIN",
        "table": "Cats",
        "on": "People.PersonId = Cats.PersonId"
      }
    ],
    "where": {
      "conditions": [
        {
          "column": "Cats.PetId",
          "operator": "BETWEEN",
          "value": "1 AND 5"
        }
      ]
    }
  }';
  
  v_cur SYS_REFCURSOR;
  v_name People.PersonName%TYPE;
  v_petname Cats.PetName%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name, v_petname;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name || ' | ' || v_petname);
  END LOOP;
  CLOSE v_cur;
END;




DECLARE
  v_result VARCHAR2(4000);
BEGIN
  v_result := json_ddl_handler('{
    "operation": "CREATE",
    "table": "Employees",
    "columns": [
      {"name": "PersonId", "type": "NUMBER", "constraints": "PRIMARY KEY"},
      {"name": "PersonName", "type": "VARCHAR2(100)"},
      {"name": "Salary", "type": "NUMBER"},
    ]
  }');
  DBMS_OUTPUT.PUT_LINE(v_result);
END;
/

DECLARE
  v_json CLOB := '{
    "operation": "INSERT",
    "table": "Employees",
    "columns": ["PersonName", "Salary"],
    "values": ["Kate", "7000"]
  }';
  v_result VARCHAR2(100);
BEGIN
  v_result := json_dml_handler(v_json);
  DBMS_OUTPUT.PUT_LINE(v_result);

END;
/

select * from Employees;


DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PersonName", "Salary"],
    "tables": ["Employees"],
    "where": {
      "conditions": [
        {
          "column": "salary",
          "operator": "BETWEEN",
          "value": "5000",
          "value2": "10000"
        }
      ]
    }
  }';
  
  v_cur SYS_REFCURSOR;
  v_name Employees.PersonName%TYPE;
  v_salary Employees.Salary%TYPE;
BEGIN
  v_cur := json_select_handler(v_json);
  LOOP
    FETCH v_cur INTO v_name, v_salary;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name || ' | ' || v_salary);
  END LOOP;
  CLOSE v_cur;
END;



---union tests

DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PersonName"],
    "tables": ["People"],
    "union": {
      "queries": [
        {
          "columns": ["PetName"],
          "tables": ["Cats"]
        }
      ]
    }
  }';
  v_cur SYS_REFCURSOR;
  v_name VARCHAR2(100);
BEGIN
  v_cur := json_select_handler_union(v_json);
  DBMS_OUTPUT.PUT_LINE('People and Cats (UNION):');
  LOOP
    FETCH v_cur INTO v_name;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name);
  END LOOP;
  CLOSE v_cur;
END;


DECLARE
  v_json CLOB := '{
    "operation": "SELECT",
    "columns": ["PetName"],
    "tables": ["Cats"],
    "union": {
      "type": "UNION ALL",
      "queries": [
        {
          "columns": ["PetName"],
          "tables": ["Cats"]
        }
      ]
    }
  }';
  v_cur SYS_REFCURSOR;
  v_catname VARCHAR2(100);
BEGIN
  v_cur := json_select_handler_union(v_json);
  DBMS_OUTPUT.PUT_LINE('Cats UNION ALL with duplicates:');
  LOOP
    FETCH v_cur INTO v_catname;
    EXIT WHEN v_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_catname);
  END LOOP;
  CLOSE v_cur;
END;
