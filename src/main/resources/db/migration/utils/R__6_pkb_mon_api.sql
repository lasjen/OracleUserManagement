CREATE OR REPLACE PACKAGE BODY mon_api AS
-- ---------------------------------------------------------------------------------------
-- Private procedures and functions
-- ---------------------------------------------------------------------------------------
   PROCEDURE setGuid AS
      l_guid varchar2(32);   
   BEGIN
      l_guid := SYS_GUID();
      dbms_application_info.set_client_info(l_guid);
      dbms_session.set_identifier(l_guid);
   END;

   PROCEDURE resetGuid AS
   BEGIN
      dbms_application_info.set_client_info('');
      dbms_session.set_identifier('');
   END;
   
-- ---------------------------------------------------------------------------------------
-- Public: Oracle End-to-end Metrics
-- ---------------------------------------------------------------------------------------
   PROCEDURE setMetrics(module_i IN varchar2, action_i IN varchar2) AS
   BEGIN
      setGuid;
      dbms_application_info.set_module(module_name => module_i, action_name => action_i);
   END;

   PROCEDURE resetMetrics AS
   BEGIN
      resetGuid;
      dbms_application_info.set_module(module_name => '', action_name => '');
   END;

-- ---------------------------------------------------------------------------------------
-- Public: Initialize and finalize public procedures / functions
-- ---------------------------------------------------------------------------------------
   PROCEDURE initialize(module_i IN varchar2, action_i IN varchar2, params_i IN logger.tab_param) AS
   BEGIN
      setMetrics(module_i, action_i);
      logger.time_reset;
      logger.log_info('START ' || module_i, module_i, null, params_i); 
      logger.time_start(module_i);
   END initialize; 

   PROCEDURE finalize(scope_i IN varchar2) AS
   BEGIN
      logger.time_stop(scope_i);   
      logger.log_info('END:' || scope_i, scope_i); 
      resetMetrics;
   END finalize;
   
END mon_api;
/
