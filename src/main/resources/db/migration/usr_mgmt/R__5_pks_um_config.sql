CREATE OR REPLACE PACKAGE um_config AS
-- ---------------------------------------------------------------------------------------
-- Purpose: The purpose of this package is to generate API for UM_PROPERTIES table
-- 
-- ---------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------
-- General constants
-- ---------------------------------------------------------------------------------------
   c_package_name               CONSTANT varchar2(30) := upper($$plsql_unit);

-- ---------------------------------------------------------------------------------------
-- CONSTANTS for properties
-- ---------------------------------------------------------------------------------------
   C_PRTY_TBS_ASM_USE           CONSTANT varchar2(50) := 'tbsAsmUse';            -- 'TRUE', 'FALSE'
   C_PRTY_TBS_ASM_DISKGROUP     CONSTANT varchar2(50) := 'tbsAsmDiskGroup';      -- '+DISK_GROUP_NAME'
   C_PRTY_TBS_DIRECTORY         CONSTANT varchar2(50) := 'tbsDirectory';         -- '/path/to/db_files'
   C_PRTY_TBS_NAME_SUFFIX       CONSTANT varchar2(50) := 'tbsNameSuffix';        -- '_DATA'
   C_PRTY_TBS_DEFAULT           CONSTANT varchar2(50) := 'tbsDefault';           -- 'USERS'
   
   C_PRTY_USR_APP_CREATE        CONSTANT varchar2(50) := 'userAppCreate';        -- 'TRUE', 'FALSE'

   C_PRTY_USR_OWNER_TBS_SIZE    CONSTANT varchar2(50) := 'userOwnerTbsSize';     -- Size in 'K', 'M', 'G', 'T'
   C_PRTY_USR_OWNER_USE_SUFFIX  CONSTANT varchar2(50) := 'userOwnerUseSuffix';   -- 'TRUE', 'FALSE'

   C_PRTY_USR_BATCH_CREATE      CONSTANT varchar2(50) := 'userBatchCreate';      -- 'TRUE', 'FALSE'
   C_PRTY_USR_BATCH_TBS_SIZE    CONSTANT varchar2(50) := 'userBatchTbsSize';     -- Size in 'K', 'M', 'G', 'T'
   C_PRTY_USR_BATCH_READWRITE   CONSTANT varchar2(50) := 'userBatchReadWrite';   -- 'TRUE', 'FALSE'
   C_PRTY_USR_BATCH_DDL         CONSTANT varchar2(50) := 'userBatchDdl';         -- 'TRUE', 'FALSE'

   C_PRTY_ROLE_PASSWORD         CONSTANT varchar2(12) := 'rolePassword';         -- Password for enabling role

   C_COL_MAX_LENGTH_NAME        CONSTANT number(3)    := 50;
   C_COL_MAX_LENGTH_VALUE       CONSTANT number(3)    := 100;
   
-- ---------------------------------------------------------------------------------------
-- Public procedures and functions
-- ---------------------------------------------------------------------------------------

  /* Description : Set String/Number/Boolean value for parameter name 
   *               from UM_PROPERTIES table
   * Datachanges : Insert or update property values
   *
   * Input/Output parameters:
   * %param    name_i      Name for property lookup in UM_PROPERTIES table
   * %param    value_i     Value for property (String, Number or Boolean)
   * %param    desc_i      Default: null, Name for property lookup in UM_PROPERTIES table
   */
   PROCEDURE setProperty(name_i IN varchar2, value_i IN varchar2, desc_i IN varchar2 default null);
   PROCEDURE setProperty(name_i IN varchar2, value_i IN boolean, desc_i IN varchar2 default null);
   PROCEDURE setProperty(name_i IN varchar2, value_i IN number, desc_i IN varchar2 default null);
   
  /* Description : Get String/Number/Boolean value for parameter name 
   *               from UM_PROPERTIES table
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param property_name_i    Name for property lookup in UM_PROPERTIES table
   */
   FUNCTION getPropertyString(property_name_i IN varchar2)  RETURN varchar2;
   FUNCTION getPropertyNumber(property_name_i IN varchar2)  RETURN number;
   FUNCTION getPropertySize(property_name_i IN varchar2) RETURN number;
   FUNCTION getPropertyBoolean(property_name_i IN varchar2) RETURN boolean;

  /* Description : Check if in-parameter is legal tablespace size
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param    size_i      Given tablespace size (given by K (=KB), M (=MB), G (=GB), T (=TB))
   */
   FUNCTION isLegalTbsSize(size_i IN varchar2) RETURN boolean;

  /* Description : Find proper properties for schema tablespace
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param schema_i    Schema_name for the TBS properties.
   * %out   location_o  File location (either file PATH or ASM_DISKGROUP)
   * %out   tbsname_o   Suggested name for tablespace
   * %out   tbssize_o   Suggested size for tablespace
   */
   PROCEDURE getPropertiesTbs(schema_i IN varchar2, location_o OUT varchar2, tbsname_o OUT varchar2, tbssize_o OUT varchar2);

  /* Description : Set ASM Diskgroup for tablespaces
   * Datachanges : Update property value for c_prty_tbs_asm_diskgroup
   *
   * Input/Output parameters:
   * %param    diskgroup_i    Value for ASM diskgroup
   */
   PROCEDURE setTbsAsmDiskgroup(diskgroup_i IN varchar2);

END um_config;
/