CREATE OR REPLACE PACKAGE BODY sql_util AS

-- ---------------------------------------------------------------------------------------
-- Public: Helper procedures / Functions
-- ---------------------------------------------------------------------------------------
   FUNCTION isNumber (p_string IN VARCHAR2) return boolean IS
      v_new_num NUMBER;
   BEGIN
      v_new_num := to_number(p_string);
      return true;
   EXCEPTION WHEN value_error THEN
      return false;
   END isNumber;

END sql_util;
/