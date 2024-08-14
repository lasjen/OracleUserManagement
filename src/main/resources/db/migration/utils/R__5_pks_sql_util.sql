CREATE OR REPLACE PACKAGE sql_util AS
-- ***************************************************************************************
-- Name                 : R__5_pks_sql_util.sql
-- Script/package name  : SQL_UTIL
-- Author               : Lasse Jenssen
-- Copyright            : EVRY, FS
--
-- Project              : General Package
-- Purpose              : The purpose of this package is to define general methods 
--                        used in packages and sqls.
-- ---------------------------------------------------------------------------------------
--
--  WHEN        WHO      WHAT
--  ----------- -------- -------------------------------------------------------
--  21/09/2018  ek2046   Created
-- **************************************************************************************

-- ---------------------------------------------------------------------------------------
-- General constants
-- ---------------------------------------------------------------------------------------
   c_package_name               CONSTANT varchar2(30) := upper($$plsql_unit);
   
-- ---------------------------------------------------------------------------------------
-- Public procedures and functions
-- ---------------------------------------------------------------------------------------

   FUNCTION isNumber (p_string IN VARCHAR2) return boolean;
   
END sql_util;
/