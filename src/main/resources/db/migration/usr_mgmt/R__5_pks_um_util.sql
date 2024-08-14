CREATE OR REPLACE PACKAGE um_util AS
-- ---------------------------------------------------------------------------------------
-- Purpose: Utility package for USR_MGMT (for instance check if user exist etc.)
-- 
-- ---------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------
-- General constants
-- ---------------------------------------------------------------------------------------
   C_PACKAGE_NAME               CONSTANT varchar2(30) := upper($$plsql_unit);

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
   FUNCTION isTablespace(name_i IN varchar2) RETURN boolean;

  /* Description : Check if role exists
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name  to be checked
   * %return   boolean     If role exist return true else false
   */
   FUNCTION isRole(name_i IN varchar2) RETURN boolean;

  /* Description : Check if schema exists
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name  to be checked
   * %return   boolean     If schma exist return true else false
   */
   FUNCTION isSchema(name_i IN varchar2) RETURN boolean;

  /* Description : Check if schema exists, if not raise exception
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    name_i      Name  to be checked
   */
   PROCEDURE isSchemaOrRaise(name_i IN varchar2);

END um_util;
/