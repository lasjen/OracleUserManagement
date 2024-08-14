
CREATE OR REPLACE PACKAGE err_api AS
-- ***************************************************************************************
-- Name                 : R__5_pks_err_api.sql
-- Script/package name  : ERR_API
-- Author               : Lasse Jenssen
-- Copyright            : EVRY, FS
--
-- Project              : General Package
-- Purpose              : The purpose of this package is to generate standarized exceptions
--                        for the other ECP packages.
-- ---------------------------------------------------------------------------------------
--
--  WHEN        WHO      WHAT
--  ----------- -------- -------------------------------------------------------
--  21/09/2018  ek2046   Created
--  25/01/2020  ek2046   Refactored with additonal exceptions and error messages
-- **************************************************************************************

-- ---------------------------------------------------------------------------------------
-- General constants
-- ---------------------------------------------------------------------------------------
   c_package_name                CONSTANT varchar2(30) := upper($$plsql_unit);

-- ---------------------------------------------------------------------------------------
-- ECP_CLEAN: Constants Error Numbers, error text and Exceptions
-- ---------------------------------------------------------------------------------------
   N_OUTSIDE_CLEAN_WINDOW        CONSTANT number(5) := -20801;
   N_ILLEGAL_BANKID              CONSTANT number(5) := -20802;

   C_OUTSIDE_CLEAN_WINDOW        CONSTANT varchar2(100) := 'ECP_CLEAN terminated because outside window (see table ECP_CLEAN_PREFS)';
   C_ILLEGAL_BANKID              CONSTANT varchar2(100) := 'Bankid needs to be 4 digits between 0000 and 9999';

   E_OUTSIDE_CLEAN_WINDOW        exception;
   E_ILLEGAL_BANKID              exception;

-- ---------------------------------------------------------------------------------------
-- USR_MGMT: Constants Error Numbers, error text and Exceptions
-- ---------------------------------------------------------------------------------------
   N_ILLEGAL_TBS_SIZE            CONSTANT number(5) := -20901;
   N_ILLEGAL_DISKGROUP           CONSTANT number(5) := -20902;
   N_PROPERTY_NOT_FOUND          CONSTANT number(5) := -20903;
   N_NOT_BOOLEAN                 CONSTANT number(5) := -20904;
   N_NOT_NUMBER                  CONSTANT number(5) := -20905;
   N_PARAMETER_NULL              CONSTANT number(5) := -20906;
   N_SCHEMA_MISSING              CONSTANT number(5) := -20907;
   N_ASSERT_ILLEGAL_SCHEMA       CONSTANT number(5) := -20908;
   N_ASSERT_ILLEGAL_NAME         CONSTANT number(5) := -20909;
   N_ASSERT_ILLEGAL_ENQUOTE      CONSTANT number(5) := -20910;
   N_VALUE_TOO_LARGE_FOR_COLUMN  CONSTANT number(5) := -20911;
   N_FAILURE_IN_FORALL           CONSTANT number(5) := -24381;

   C_ILLEGAL_TBS_SIZE            CONSTANT varchar2(100) := 'Illegal TBS size (Use Subfix: K, M, G, T)';
   C_ILLEGAL_DISKGROUP           CONSTANT varchar2(100) := 'Illegal DiskGroup name. Must start with letter and only contain a-z, A-Z, 0-9 and _';
   C_PROPERTY_NOT_FOUND          CONSTANT varchar2(100) := 'Property not set in USR_MGMT_PROPERTIES';
   C_NOT_BOOLEAN                 CONSTANT varchar2(100) := 'This property (in USR_MGMT_PROPERTIES) must be a boolean string (TRUE or FALSE)';
   C_NOT_NUMBER                  CONSTANT varchar2(100) := 'This property (in USR_MGMT_PROPERTIES) must be of type NUMBER';
   C_PARAMETER_NULL              CONSTANT varchar2(100) := 'Illegal NULL value in parameter';
   C_SCHEMA_MISSING              CONSTANT varchar2(100) := 'Schema does not exist';
   C_ASSERT_ILLEGAL_SCHEMA       CONSTANT varchar2(100) := 'Check by dbms_assert.schema_name failed';
   C_ASSERT_ILLEGAL_NAME         CONSTANT varchar2(100) := 'Check by dbms_assert.simple_sql_name failed';
   C_ASSERT_ILLEGAL_ENQUOTE      CONSTANT varchar2(100) := 'Check by dbms_assert.enquote_literal failed';
   C_VALUE_TOO_LARGE_FOR_COLUMN  CONSTANT varchar2(100) := 'Value too large for column';
   C_FAILURE_IN_FORALL           CONSTANT varchar2(100) := 'Exception in FORALL statement'; 

   E_ILLEGAL_TBS_SIZE            exception;
   E_ILLEGAL_DISKGROUP           exception;
   E_PROPERTY_NOT_FOUND          exception; 
   E_NOT_BOOLEAN                 exception;
   E_NOT_NUMBER                  exception;
   E_PARAMETER_NULL              exception;
   E_SCHEMA_MISSING              exception;
   E_ASSERT_ILLEGAL_SCHEMA       exception;
   E_ASSERT_ILLEGAL_NAME         exception;
   E_ASSERT_ILLEGAL_ENQUOTE      exception;
   E_VALUE_TOO_LARGE_FOR_COLUMN  exception;
   E_FAILURE_IN_FORALL           exception;



-- ---------------------------------------------------------------------------------------
-- ECP_CLEAN: PRAGMA exception_init (binding exception and sqlcode)
-- ---------------------------------------------------------------------------------------
   PRAGMA exception_init(e_outside_clean_window,         -20801);
   PRAGMA exception_init(e_illegal_bankid,               -20802);

-- ---------------------------------------------------------------------------------------
-- USR_MGMT: PRAGMA exception_init (binding exception and sqlcode)
-- ---------------------------------------------------------------------------------------
   PRAGMA exception_init(e_illegal_tbs_size,             -20901);
   PRAGMA exception_init(e_illegal_diskgroup,            -20902);
   PRAGMA exception_init(e_property_not_found,           -20903);
   PRAGMA exception_init(e_not_boolean,                  -20904);
   PRAGMA exception_init(e_not_number,                   -20905);
   PRAGMA exception_init(e_parameter_null,               -20906);
   PRAGMA exception_init(e_schema_missing,               -20907);
   PRAGMA exception_init(e_assert_illegal_schema,        -20908);
   PRAGMA exception_init(e_assert_illegal_name,          -20909);
   PRAGMA exception_init(e_assert_illegal_enquote,       -20910);
   PRAGMA exception_init(e_value_too_large_for_column,   -20911);

   PRAGMA exception_init(e_failure_in_forall,            -24381);
-- ---------------------------------------------------------------------------------------
-- Exception for failure in DBMS_ASSERT.SCHEMA_NAME
-- ---------------------------------------------------------------------------------------
   -- Example:
   -- when err_api.e_assert_illegal_schema then
   --    err_api.known_error_log_and_raise('ERROR: Illegal parameters - ' || upper(l_scope), l_scope);
   --PRAGMA exception_init (e_assert_illegal_schema,    -44001);

-- ---------------------------------------------------------------------------------------
-- Exception for failure in DBMS_ASSERT.SIMPLE_SQL_NAME
-- ---------------------------------------------------------------------------------------
   --PRAGMA exception_init (e_assert_illegal_name,      -44003);

   -- when err_api.e_assert_illegal_name then
   --    err_api.known_error_log_and_raise('Illegal parameters', l_scope);
   
-- ---------------------------------------------------------------------------------------
-- Exception for failure in FORALL
-- ---------------------------------------------------------------------------------------
   --PRAGMA EXCEPTION_INIT (e_failure_in_forall,        -24381);  

-- ---------------------------------------------------------------------------------------
-- Public Procedures - Handling Errors
-- ---------------------------------------------------------------------------------------
   PROCEDURE log_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param);
   PROCEDURE log_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2);
   PROCEDURE log(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param);
   PROCEDURE log(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2);
   PROCEDURE log_unknown(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param);

   PROCEDURE log_finalize_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param);
   PROCEDURE log_and_finalize(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param);
   
   -- Old log procedures
   PROCEDURE log_sql_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, sql_i IN clob, scope_i IN varchar2, params_i IN logger.tab_param);
   PROCEDURE log_sql(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, sql_i IN clob, scope_i IN varchar2, params_i IN logger.tab_param);

-- ---------------------------------------------------------------------------------------
-- Public Procedures: Checks with DBMS_ASSERT
-- ---------------------------------------------------------------------------------------
   PROCEDURE check_schema_name(txt_i IN varchar2);
   PROCEDURE check_sql_name(txt_i IN varchar2);
   PROCEDURE check_enquote_literal(txt_i IN varchar2);
   PROCEDURE check_enquote_name(txt_i IN varchar2);

-- ---------------------------------------------------------------------------------------
-- Public Procedures: Checks for NULL
-- ---------------------------------------------------------------------------------------
   PROCEDURE check_null_and_raise(txt_i IN varchar2);
   PROCEDURE check_null_and_raise(num_i IN number);

END err_api;
/