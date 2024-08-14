CREATE OR REPLACE PACKAGE um_core AS
-- ***************************************************************************************
-- Name                 : R__pkg_um_core.sql
-- Script/package name  : um_core
-- Author               : Lasse Jenssen
-- Copyright            : EVRY, FS
--
-- Project              : ECP User and Roles (GDPR)
-- Purpose              : Library package for creating aditional/missing users and roles
--
--  WHEN        WHO      WHAT
--  ----------- -------- -------------------------------------------------------
--  21/09/2018  ek2046   Created
-- **************************************************************************************

-- ---------------------------------------------------------------------------------------
-- General constants
-- ---------------------------------------------------------------------------------------
   C_PACKAGE_NAME               CONSTANT varchar2(30) := upper($$plsql_unit);

-- ---------------------------------------------------------------------------------------
-- CONSTANTS for user and roles prefix and postfixes
-- ---------------------------------------------------------------------------------------
   C_POSTFIX_USER_OWNER         CONSTANT varchar2(2)  := '_O';
   C_POSTFIX_USER_APPL          CONSTANT varchar2(2)  := '_A';
   C_POSTFIX_USER_BATCH         CONSTANT varchar2(2)  := '_B';

   C_POSTFIX_ROLE_RO            CONSTANT varchar2(3)  := '_RO';
   C_POSTFIX_ROLE_RW            CONSTANT varchar2(3)  := '_RW';
   C_POSTFIX_ROLE_DDL           CONSTANT varchar2(4)  := '_DDL';  

   C_PREFIX_OPERATOR_ROLE       CONSTANT varchar2(20) := 'OPERATOR';

   C_USER_TYPE_OWNER            CONSTANT varchar2(3)  := 'OWN';
   C_USER_TYPE_APPLICATION      CONSTANT varchar2(3)  := 'APP';
   C_USER_TYPE_SUPPORT          CONSTANT varchar2(3)  := 'SUP';
   C_USER_TYPE_BATCH            CONSTANT varchar2(3)  := 'BTC';
   C_USER_TYPE_OPERATOR         CONSTANT varchar2(3)  := 'OPR';

-- ---------------------------------------------------------------------------------------
-- CONSTANTS for others
-- ---------------------------------------------------------------------------------------
   C_PREFIX_TRG_LOGIN           CONSTANT varchar2(20) := 'SET_CUR_SCH_';
   C_DEFAULT_TBS_SIZE           CONSTANT varchar2(10) := '100M';

   C_OWNER_PRIVILEGES           CONSTANT varchar2(1000) := 'create table, create view, create sequence, create procedure, create type, create trigger, create synonym';


/* *****************************************************************************************
   Object:  getSchemaNames
   Type:    procedure
   Purpose: This procedure will get the schema names for a user template (based on config)
 
   PARAMETERS:                     
      owner_i        IN    Application base (for instance ECP_1234)
      withPostfix_i  IN    (boolean) true = Add postfix to owner name
      owner_o        OUT   Name for owner schema
      appl_o         OUT   Name for application login schema
      batch_o        OUT   Name for batch login schema
   ***************************************************************************************** */

   PROCEDURE getSchemaNames(applname_i IN varchar2, owner_o OUT varchar2, appl_o OUT varchar2, batch_o OUT varchar2);

/* *****************************************************************************************
   Object:  getRoleNames
   Type:    procedure
   Purpose: This procedure will get the role names for a user template (based on config)
 
   PARAMETERS:                     
      owner_i     IN    Application base (for instance ECP_1234)
      ro_o        OUT   Name for Read-Only role
      rw_o        OUT   Name for Read-Write role
      ddl_o       OUT   Name for DDL role
   ***************************************************************************************** */

   PROCEDURE getRoleNames(applname_i IN varchar2, ro_o OUT varchar2, rw_o OUT varchar2, ddl_o OUT varchar2);

/* *****************************************************************************************
   Object:  createOperator
   Type:    procedure
   Purpose: This procedure will create an operational user.
            Note! The operational roles must be created before creating user.
                  For ECP -> ECP_OPERATOR_RW, ECP_OPERATOR_RO
 
   PARAMETERS:                     
      userid_i:         EVRY identifier
      fullname_i:       Full name for user
      readwrite_i:      false (default) -> RO role, true -> RW role
      dll_i:            false (default) -> If yes able to do ANY DDL
   ***************************************************************************************** */

   PROCEDURE createOperator(schema_i      IN varchar2, 
                            fullname_i    IN varchar2,
                            ddl_i         IN boolean,
                            readwrite_i   IN boolean default false,
                            scriptonly_i  IN boolean default false
                            );

/* *****************************************************************************************
   Object:  dropOperator
   Type:    procedure
   Purpose: This procedure will drop an operational user/ schema.
 
   PARAMETERS:                     
      schema_i:         Identifier for operator (EVRY identifier)
   ***************************************************************************************** */
   PROCEDURE dropOperator(schema_i IN varchar2, scriptonly_i IN boolean default false);

/* *****************************************************************************************
   Object : createTemplateUsers
   Purpose: This procedure will create the data owner, application user and optionally
            the batch user. If data owner exist - this will be kept.

   Depends on constants (UM_CORE package):
   - c_postfix_user_appl, c_postfix_user_batch

   Depends on properties (UM_PROPERTIES): 
   - tbsAsmUse, tbsAsmDiskGroup, tbsDirectory, tbsNameSuffix, 
   - userAppCreate, userAppTbsSize, 
   - userBatchCreate, userBatchTbsSize, userBatchReadWrite, userBatchDdl
 
   PARAMETERS:                     
      owner_i:       Name of data owner (new or existing data owner)
      withPrefix_i:  If true, then create owner with defined prefix (ex. ECP_1234_O), 
                     else as APP name (ex. ECP_1234)

      Note! Get logs by running:
      SELECT * FROM logger_logs WHERE client_info=usr_mgmt.last_logger_uuid;
   ***************************************************************************************** */
   PROCEDURE createTemplateUsers(applname_i IN varchar2, scriptonly_i IN boolean default false);
   PROCEDURE createTemplateUsers(applname_i IN varchar2, bankid_i IN varchar2, scriptonly_i IN boolean default false);
   PROCEDURE createTemplateUsers(applname_i IN varchar2, bankids_i IN um_bankid_nt, scriptonly_i IN boolean default false);
   
/* *****************************************************************************************
   Object : grantRolesToOperatorRoles
   Type   : procedure
   Purpose: Procdure to GRANT <SCHEMA>-roles to <OPERATOR>-roles
 
   ***************************************************************************************** */
   PROCEDURE grantRolesToOperatorRoles(scriptonly_i IN boolean default false);

/* *****************************************************************************************
   Object: package_initialization
   Type   : procedure
   Purpose: Dummy procedure to load package into memory (called after creation)
 
   ***************************************************************************************** */
   PROCEDURE packageInitialization;

END um_core;
/

