CREATE OR REPLACE PACKAGE um_drop AS
-- ***************************************************************************************
-- Name                 : R__pkg_um_drop.sql
-- Script/package name  : um_drop
-- Author               : Lasse Jenssen
-- Copyright            : EVRY, FS
--
-- Project              : ECP User and Roles (GDPR)
-- Purpose              : Library package for dropping users and roles
-- 
-- --------------------------------------------------------------------------------------
-- WARNING! NOT TO BE INSTALLED IN PRODUCTION
-- --------------------------------------------------------------------------------------
--
--  WHEN        WHO      WHAT
--  ----------- -------- -------------------------------------------------------
--  21/09/2018  ek2046   Created
-- **************************************************************************************

-- ---------------------------------------------------------------------------------------
-- General constants
-- ---------------------------------------------------------------------------------------
   C_PACKAGE_NAME               CONSTANT varchar2(30) := upper($$plsql_unit);

/* *****************************************************************************************
   Object : dropTemplateUsers
   Purpose: This procedure will drop the data owner, application user and optionally
            the batch user. If data owner exist - this will be kept.

   Depends on constants (UM_CORE package):
   - c_postfix_user_appl, c_postfix_user_batch

   Depends on properties (UM_PROPERTIES): 
   - tbsAsmUse, tbsAsmDiskGroup, tbsDirectory, tbsNameSuffix, 
   - userAppCreate, userAppTbsSize, 
   - userBatchCreate, userBatchTbsSize, userBatchReadWrite, userBatchDdl
 
   PARAMETERS:                     
      applname_i:    Prefix for template users

   ***************************************************************************************** */
   PROCEDURE dropTemplateUsers(applname_i IN varchar2, scriptonly_i IN boolean default true);
   PROCEDURE dropTemplateUsers(applname_i IN varchar2, bankid_i IN varchar2, scriptonly_i IN boolean default true);

END um_drop;
/

