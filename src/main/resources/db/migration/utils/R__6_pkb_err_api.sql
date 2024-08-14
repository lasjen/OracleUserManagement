CREATE OR REPLACE PACKAGE BODY err_api AS
-- ---------------------------------------------------------------------------------------
-- Purpose: The purpose of this package is to generate standarized procedures
--          for handling exceptions.
-- ---------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------
-- Public Procedures: Logging
-- ---------------------------------------------------------------------------------------

   PROCEDURE log_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i, null, params_i);
      raise_application_error(sqlcode_i, scope_i || ': ' || sqlerrm_i);
   END;

   PROCEDURE log_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i);
      raise_application_error(sqlcode_i, scope_i || ': ' || sqlerrm_i);
   END;

   PROCEDURE log(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i, null, params_i);
   END;

   PROCEDURE log(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i);
   END;

   PROCEDURE log_unknown(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error('Unknown Error: ' || sqlcode_i || ' - ' || sqlerrm_i, scope_i, null, params_i);
   END;

   PROCEDURE log_finalize_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i, null, params_i);
      mon_api.finalize(scope_i);
      raise_application_error(sqlcode_i, scope_i || ':' || sqlerrm_i);
   END;

   PROCEDURE log_and_finalize(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i, null, params_i);
      mon_api.finalize(scope_i);
   END;

   PROCEDURE log_sql_and_raise(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, sql_i IN clob, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i, sql_i, params_i);
      raise_application_error(sqlcode_i, sqlerrm_i);
   END log_sql_and_raise;

   PROCEDURE log_sql(sqlcode_i IN varchar2, sqlerrm_i IN varchar2, sql_i IN clob, scope_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      logger.log_error(sqlcode_i || ' - ' || sqlerrm_i, scope_i, sql_i, params_i);
   END log_sql;

-- ---------------------------------------------------------------------------------------
-- Public Procedures: Checks with DBMS_ASSERT
-- ---------------------------------------------------------------------------------------
   PROCEDURE check_schema_name(txt_i IN varchar2) AS
      l_schema_name varchar2(30);
   BEGIN
         l_schema_name := dbms_assert.schema_name(txt_i);
   EXCEPTION 
      when others then
         raise err_api.E_ASSERT_ILLEGAL_SCHEMA;
   END;

   PROCEDURE check_sql_name(txt_i IN varchar2) AS
      l_sql_name varchar2(30);
   BEGIN
         l_sql_name := dbms_assert.simple_sql_name(txt_i);
   EXCEPTION 
      when others then
         raise err_api.E_ASSERT_ILLEGAL_NAME;
   END;

   PROCEDURE check_enquote_literal(txt_i IN varchar2) AS
      l_sql_name varchar2(2000);
   BEGIN
         l_sql_name := dbms_assert.enquote_literal(txt_i);
   EXCEPTION 
      when others then
         raise err_api.E_ASSERT_ILLEGAL_ENQUOTE;
   END;

   PROCEDURE check_enquote_name(txt_i IN varchar2) AS
      l_name varchar2(2000);
   BEGIN
         l_name := dbms_assert.enquote_name(txt_i);
   EXCEPTION 
      when others then
         raise err_api.E_ASSERT_ILLEGAL_ENQUOTE;
   END;
   
-- ---------------------------------------------------------------------------------------
-- Public Procedures: Checks for NULL
-- ---------------------------------------------------------------------------------------
   PROCEDURE check_null_and_raise(txt_i IN varchar2) AS
   BEGIN
      if txt_i IS NULL then
         raise err_api.E_PARAMETER_NULL;
      end if;
   END;

   PROCEDURE check_null_and_raise(num_i IN number) AS
   BEGIN
      if num_i IS NULL then
         raise err_api.E_PARAMETER_NULL;
      end if;
   END;

END err_api;
/