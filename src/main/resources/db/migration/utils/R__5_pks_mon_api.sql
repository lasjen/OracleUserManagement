CREATE OR REPLACE PACKAGE mon_api AS
-- ***************************************************************************************
-- Name                 : R__5_pks_mon_api.sql
-- Script/package name  : MON_API
-- Author               : Lasse Jenssen
-- Copyright            : EVRY, FS
--
-- Project              : General Package
-- Purpose              : The purpose of this package is to define methods to 
--                        set end-to-end metrics, and initialize methods.
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
   c_package_name               CONSTANT varchar2(30) := upper($$plsql_unit);
   
-- ---------------------------------------------------------------------------------------
-- Public procedures and functions
-- ---------------------------------------------------------------------------------------
   PROCEDURE setMetrics(module_i IN varchar2, action_i IN varchar2);
   PROCEDURE resetMetrics;

   PROCEDURE initialize(module_i IN varchar2, action_i IN varchar2, params_i IN logger.tab_param);
   PROCEDURE finalize(scope_i IN varchar2);
   
END mon_api;
/