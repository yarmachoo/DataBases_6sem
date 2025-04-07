-- Войти в CDB (Container Database) с правами администратора
CONNECT sys/password AS SYSDBA;

-- Создание pluggable database DEV
CREATE PLUGGABLE DATABASE DEV ADMIN USER dev_admin IDENTIFIED BY password
    FILE_NAME_CONVERT = ('/opt/oracle/oradata/CDB1/pdbseed/', '/opt/oracle/oradata/CDB1/DEV/');