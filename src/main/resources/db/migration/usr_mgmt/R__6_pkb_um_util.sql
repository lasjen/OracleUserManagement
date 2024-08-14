CREATE OR REPLACE PACKAGE BODY um_util AS
-- ---------------------------------------------------------------------------------------
-- Purpose: Utility package for UM_UTIL (for instance check if user exist etc.)
-- 
-- ---------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------
-- Public procedures and functions
-- ---------------------------------------------------------------------------------------
   
  /* Description : Check if tablespace exists
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name to be checked
   * %return   boolean     If tablespace exist return true else false
   */
   FUNCTION isTablespace(name_i IN varchar2) RETURN boolean IS
      l_cnt number;
   BEGIN
      select count(*) into l_cnt from dba_tablespaces where tablespace_name=upper(name_i);

      return case when l_cnt=0 then false else true end;
   END;

  /* Description : Check if role exists
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name  to be checked
   * %return   boolean     If role exist return true else false
   */
   FUNCTION isRole(name_i IN varchar2) RETURN boolean IS
      l_cnt number;
   BEGIN
      select count(*) into l_cnt from dba_roles where role=upper(name_i);

      return case when l_cnt=0 then false else true end;
   END;

  /* Description : Check if schema exists
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name  to be checked
   * %return   boolean     If schma exist return true else false
   */
   FUNCTION isSchema(name_i IN varchar2) RETURN boolean IS
      l_cnt number;
   BEGIN
      select count(*) into l_cnt from dba_users where username=upper(name_i);

      return case when l_cnt=0 then false else true end;
   END;

  /* Description : Check if schema exists, if not raise exception
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name  to be checked
   */
   PROCEDURE isSchemaOrRaise(name_i IN varchar2) AS
   BEGIN
      if name_i IS NULL then
         raise err_api.e_parameter_null;
      elsif not isSchema(name_i) then
         raise err_api.e_schema_missing;
      end if; 
   EXCEPTION
      when err_api.e_parameter_null then
         raise_application_error(sqlcode, err_api.c_parameter_null);
      when err_api.e_schema_missing then
         raise_application_error(sqlcode, err_api.c_schema_missing);
   END;
END um_util;
/