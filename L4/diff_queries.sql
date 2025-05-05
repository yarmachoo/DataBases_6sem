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

SELECT * FROM People;

SELECT * FROM Cats;