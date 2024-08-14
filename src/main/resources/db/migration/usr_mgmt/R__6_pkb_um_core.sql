CREATE OR REPLACE PACKAGE BODY um_core AS
   -- ************************************************************************
   -- Change History
   -- Date        Procedure/Function         Reason for Change (JIRA)
   -- ----------- -------------------------- ---------------------------------
   -- 01 NOV 2018 Initialized (ALL)          Initial Code
   --
   -- ************************************************************************

   -- -------------------------------
   -- Local procedures and functions
   -- -------------------------------
   PROCEDURE runSql(sql_i IN varchar2, log_i IN boolean default true);
   PROCEDURE runSql(sql_i IN varchar2, scope_i IN varchar2, log_i IN boolean default true);
   PROCEDURE runSqlText(sql_i IN varchar2, text_i IN varchar2, scope_i IN varchar2);
   
   PROCEDURE createTablespace(schema_i IN varchar2, tbsname_o OUT varchar2, scriptonly_i IN boolean default false);
   PROCEDURE createLogonTrigger(schema_i IN varchar2, owner_i IN varchar2, scriptonly_i IN boolean default false);
   PROCEDURE createRole(role_i IN varchar2, pw_i IN boolean default false, scriptonly_i IN boolean default false);
   PROCEDURE createAppRoles(applname_i IN varchar2, scriptonly_i IN boolean default false);
   PROCEDURE createSchema(schema_i IN varchar2, applname_i IN varchar2, type_i IN varchar2, rw_i IN boolean, ddl_i IN boolean, scriptonly_i IN boolean default false);
   PROCEDURE grantTo(role_i IN varchar2, schema_i IN varchar2, scriptonly_i IN boolean default false);
   FUNCTION  getDbGrantSpec(owner_i IN varchar2) RETURN varchar2;
   FUNCTION  getDbGrantBody(owner_i IN varchar2) RETURN varchar2;

   PROCEDURE saveUserDetails(schema_i IN varchar2, descr_i IN varchar2, applname_i IN varchar2,
                             type_i IN varchar2, readwrite_i IN boolean, ddl_i IN boolean);
   PROCEDURE saveOperatorDetails(userid_i IN varchar2, fullname_i IN varchar2, 
                          readwrite_i IN boolean, ddl_i IN boolean);

   -- ------------------------
   -- PROCEDURES - General
   -- ------------------------
   PROCEDURE runSql(sql_i IN varchar2, log_i IN boolean default true) AS
   BEGIN
      execute immediate sql_i;
      if log_i then
         logger.log('SUCCESS: ' || sql_i);
      end if;
   EXCEPTION 
      when others then
         logger.log_error('Failed SQL: ' || sqlcode || ' - ' || sqlerrm, null, sql_i);
         raise;
   END runSql;

   PROCEDURE runSql(sql_i IN varchar2, scope_i IN varchar2, log_i IN boolean default true) AS
   BEGIN
      execute immediate sql_i;
      if log_i then
         logger.log('SUCCESS: ' || sql_i, scope_i);
      end if;

   EXCEPTION 
      when others then
         logger.log_error('Failed SQL: ' || sqlcode || ' - ' || sqlerrm, scope_i, sql_i);
         raise;
   END runSql;

   PROCEDURE runSqlText(sql_i IN varchar2, text_i IN varchar2, scope_i IN varchar2) AS
   BEGIN
      execute immediate sql_i;
      logger.log('SUCCESS: ' || text_i, scope_i);
      
   EXCEPTION 
      when others then
         logger.log_error('Failed SQL: ' || sqlcode || ' - ' || sqlerrm || ':' || text_i, scope_i, sql_i);
         raise;
   END;

   -- ------------------------
   -- PROCEDURES - API utils
   -- ------------------------
   PROCEDURE getOperatorRoleNames(ro_o OUT varchar2, rw_o OUT varchar2, ddl_o OUT varchar2) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getOperatorRoleNames';
   BEGIN
      ro_o  := C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_RO;
      rw_o  := C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_RW; 
      ddl_o := C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_DDL;
   EXCEPTION 
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope);
         raise;
   END getOperatorRoleNames;

   PROCEDURE createLogonTrigger(schema_i IN varchar2, owner_i IN varchar2, scriptonly_i IN boolean default false) as
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createLogonTrigger';
      l_params       logger.tab_param;

      l_sql          varchar2(2000):= 'Not set';
      l_name         varchar2(30);
      l_dummy        varchar2(30);
   begin
      -- Initializing
      logger.append_param(l_params, 'schema_i ', nvl(schema_i, 'null'));
      logger.append_param(l_params, 'owner_i ',  nvl(owner_i, 'null'));
      
      l_name := C_PREFIX_TRG_LOGIN || schema_i;
      -- Main
      l_sql := 'CREATE OR REPLACE TRIGGER ' || l_name ||  chr(10) ||
               '    AFTER LOGON ON '|| schema_i || '.SCHEMA' || chr(10) ||  
               'BEGIN ' || chr(10) ||
               '   EXECUTE IMMEDIATE ''ALTER SESSION SET current_schema=' || 
                     owner_i || '''; ' || chr(10) ||
               'END;';

      if (not scriptonly_i) then
         l_dummy := dbms_assert.schema_name(schema_i);
         l_dummy := dbms_assert.simple_sql_name(l_name);
         l_dummy := dbms_assert.schema_name(owner_i);
         runSqlText(l_sql, 'Creating trigger ' || upper(l_name) , l_scope);
      else
         dbms_output.put_line(l_sql); 
         dbms_output.put_line('/');
         dbms_output.new_line;
      end if;
   
   EXCEPTION 
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END createLogonTrigger;

   PROCEDURE createRole(role_i IN varchar2, pw_i IN boolean default false, scriptonly_i IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createRole' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_sql          varchar2(1000);
   BEGIN
   -- Initializing
      logger.append_param(l_params, 'role_i', nvl(role_i,'null'));
      logger.append_param(l_params, 'pw_i',         case when pw_i then 'true' else 'false' end);
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

      l_sql := 'CREATE ROLE ' || lower(role_i) || 
                     case when pw_i then ' IDENTIFIED BY ' || um_config.getPropertyString(um_config.C_PRTY_ROLE_PASSWORD) 
                          else ''
                     end; 

   -- Check if scriptonly or role exist
      if (scriptonly_i) then
         dbms_output.put_line(l_sql||';'); dbms_output.put_line('/'); dbms_output.new_line;
         return;
      elsif (um_util.isRole(dbms_assert.simple_sql_name(role_i))) then
         logger.log('Role exists: ' || upper(role_i), l_scope);
         return;
      end if;
   
   -- SQL Injection Check
      err_api.check_sql_name(role_i);

   -- Create role
      runSqlText(l_sql, 'Creating role ' || upper(role_i), l_scope);
      
   EXCEPTION
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createAppRoles(applname_i IN varchar2, scriptonly_i IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createAppRoles' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_role_ro   varchar2(30);
      l_role_rw   varchar2(30);
      l_role_ddl  varchar2(30);
   BEGIN
   -- Initializing
      logger.append_param(l_params, 'applname_i', nvl(applname_i, '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

   -- Main
      getRoleNames(applname_i, l_role_ro, l_role_rw, l_role_ddl);

      createRole(l_role_rw, false, scriptonly_i);
      createRole(l_role_ro, false, scriptonly_i);
      createRole(l_role_ddl, false, scriptonly_i);

      grantTo('create session, alter session', l_role_rw, scriptonly_i);
      grantTo('create session, alter session', l_role_ro, scriptonly_i);
   
   EXCEPTION
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END createAppRoles;

   PROCEDURE createOperatorRoles(scriptonly_i IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createOperatorRoles'  || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_role_rw   varchar2(30);
      l_role_ro   varchar2(30);
      l_role_ddl  varchar2(30);
   BEGIN
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

      getOperatorRoleNames(l_role_ro, l_role_rw, l_role_ddl);

      createRole(l_role_rw, false, scriptonly_i);
      createRole(l_role_ro, false, scriptonly_i);
      createRole(l_role_ddl, true, scriptonly_i); -- set role identified by

      grantTo('create session, alter session', l_role_rw, scriptonly_i);
      grantTo('create session, alter session', l_role_ro, scriptonly_i);

   EXCEPTION
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope);
         raise;
   END createOperatorRoles;

   PROCEDURE revokeOperatorRolesFrom(schema_i IN varchar2) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.revokeOperatorRolesFrom';
      l_params       logger.tab_param;

      l_role_rw   varchar2(30);
      l_role_ro   varchar2(30);
      l_role_ddl  varchar2(30);

      procedure ifRoleExistRevoke(role_i IN varchar2, revokee_i IN varchar2) as
         -- Note! Probably not needed anywhere else, so not defined in ERR_API
         e_role_not_granted_1924 exception;
         pragma exception_init(e_role_not_granted_1924, -1924);

         e_role_not_granted_1951 exception;
         pragma exception_init(e_role_not_granted_1951, -1951);
      begin
         if um_util.isRole(role_i) then
            runSql('revoke ' || role_i || ' from ' || revokee_i);
         end if;
      exception
         when e_role_not_granted_1924 then null;
         when e_role_not_granted_1951 then null;
      end;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i', nvl(schema_i,'null'));

      -- Main
      getOperatorRoleNames(l_role_ro, l_role_rw, l_role_ddl);

      ifRoleExistRevoke(l_role_ro,  dbms_assert.schema_name(schema_i));
      ifRoleExistRevoke(l_role_rw,  schema_i);
      ifRoleExistRevoke(l_role_ddl, schema_i);

   EXCEPTION
      when err_api.e_assert_illegal_schema then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_SCHEMA, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createSchema(schema_i        IN varchar2, 
                          applname_i      IN varchar2, 
                          type_i          IN varchar2, 
                          rw_i            IN boolean, 
                          ddl_i           IN boolean,
                          scriptonly_i    IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createSchema' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_cnt          number;
      l_sql          varchar2(1000);
      l_tbs_default  varchar2(30);
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i',     nvl(schema_i, '<NULL>'));
      logger.append_param(l_params, 'applname_i',   nvl(schema_i, '<NULL>'));
      logger.append_param(l_params, 'type_i',       nvl(type_i,   '<NULL>'));
      logger.append_param(l_params, 'rw_i',         case when rw_i then 'true' else 'false' end);
      logger.append_param(l_params, 'ddl_i',        case when ddl_i then 'true' else 'false' end);
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

      l_tbs_default := um_config.getPropertyString(um_config.C_PRTY_TBS_DEFAULT);

      l_sql := 'CREATE USER ' || lower(schema_i) || ' IDENTIFIED BY ' || lower(schema_i) || 
                     ' DEFAULT TABLESPACE ' || l_tbs_default;

      if scriptonly_i then
         dbms_output.put_line(l_sql||';');
         dbms_output.new_line;
      elsif not um_util.isSchema(schema_i) then 
      -- SQL Injection Check
         err_api.check_sql_name(schema_i); 
         err_api.check_sql_name(applname_i); 
         err_api.check_sql_name(type_i);
      -- Create user
         runSqlText(l_sql, 'Creating schema ' || schema_i, l_scope);
      else
         logger.log('User exists: ' || schema_i, l_scope);
      end if;

      -- Save to UM_USERS
      if not scriptonly_i then
         saveUserDetails(schema_i, null, applname_i, type_i, readwrite_i=>rw_i, ddl_i=>ddl_i);
      end if;

   EXCEPTION
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE dropOperatorSchema(schema_i IN varchar2, scriptonly_i    IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.dropOperatorSchema' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_sql          varchar2(1000);
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i', schema_i);
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

      -- Check parameters (null + SQL Injection)
      err_api.check_schema_name(schema_i);

      -- Drop Schema
      l_sql := 'DROP USER ' || lower(schema_i) || ' CASCADE';
      if (scriptonly_i) then
         dbms_output.put_line(l_sql||';');
         dbms_output.new_line;
      else
         runSqlText(l_sql, 'Schema ' || upper(schema_i) || ' dropped', l_scope);
      end if;

   EXCEPTION
      when err_api.e_assert_illegal_schema then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_SCHEMA, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE deleteOperatorDetails(schema_i IN varchar2) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.deleteOperatorDetails';
      l_params       logger.tab_param;

      pragma autonomous_transaction;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i', schema_i);

      -- Check parameters (null + SQL Injection)
      err_api.check_null_and_raise(schema_i);
      err_api.check_sql_name(schema_i);

      -- Delete operator from UM_OPERATORS
      delete from um_operators where userid = upper(schema_i);
      commit;
      
   EXCEPTION
      when err_api.e_parameter_null then
         err_api.log_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createBatchSchema(schema_i      IN varchar2, 
                               owner_i       IN varchar2, 
                               applname_i    IN varchar2,
                               scriptonly_i  IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createBatchSchema' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_tbs_name     varchar2(30);
      l_rol_rw       varchar2(30);
      l_rol_ro       varchar2(30);
      l_rol_ddl      varchar2(30);
      l_btc_rw       boolean;
      l_btc_ddl      boolean;

      l_sql          varchar2(1000);
   BEGIN
      -- Initialize
      logger.append_param(l_params, 'schema_i',  nvl(schema_i, '<NULL>'));
      logger.append_param(l_params, 'owner_i',   nvl(owner_i , '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

      l_btc_rw    := um_config.getPropertyBoolean(um_config.C_PRTY_USR_BATCH_READWRITE);
      l_btc_ddl   := um_config.getPropertyBoolean(um_config.C_PRTY_USR_BATCH_DDL);
      
      getRoleNames(applname_i, l_rol_ro, l_rol_rw, l_rol_ddl);
      
      createSchema(schema_i, applname_i, C_USER_TYPE_BATCH, rw_i=>l_btc_rw, ddl_i=> l_btc_ddl, scriptonly_i=> scriptonly_i);
      grantTo(case when l_btc_rw then l_rol_rw else l_rol_ro end, owner_i, scriptonly_i);
            
      createLogonTrigger(schema_i, owner_i, scriptonly_i);

      if l_btc_ddl then
         createTablespace(schema_i, l_tbs_name, scriptonly_i); -- out param: l_tbs_name
         l_sql := 'ALTER USER ' || schema_i || ' DEFAULT TABLESPACE ' || l_tbs_name ||' QUOTA UNLIMITED ON '|| l_tbs_name;

         if scriptonly_i then
            dbms_output.put_line(l_sql||';');
            dbms_output.new_line;
         else
            runSqlText(
                    l_sql,
                    'Setting default tablespace and quota for ' || schema_i || ' on ' || upper(l_tbs_name),
                    l_scope);
         end if;
      end if;
   
   EXCEPTION          
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createOwnerSchema(owner_i IN varchar2, applname_i IN varchar2, scriptonly_i boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createOwnerSchema' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      e_user_exist   exception;
      l_sql          varchar2(2000);
      l_sql_g1       varchar2(2000);
      l_sql_g2       varchar2(2000);
      l_sql_pks      varchar2(4000);
      l_sql_pkb      varchar2(32000);
      l_tbs_name     varchar2(30);
      l_cnt          number;

      l_owner        varchar2(30);
   BEGIN
   -- Initialize
      logger.append_param(l_params, 'owner_i',    nvl(owner_i,    '<NULL>'));
      logger.append_param(l_params, 'applname_i', nvl(applname_i, '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

   -- Create tablespace
      createTablespace(applname_i, l_tbs_name, scriptonly_i); -- l_tbs_name is OUT parameter

   -- Initiate SQLs
      l_sql     := 'CREATE USER ' || owner_i ||' IDENTIFIED BY ' || lower(owner_i) || 
                     ' DEFAULT TABLESPACE ' || l_tbs_name ||' TEMPORARY TABLESPACE temp ' ||
                     ' QUOTA UNLIMITED ON '|| l_tbs_name;
      l_sql_g1  := 'GRANT create session, alter session TO ' || owner_i;
      l_sql_g2  := 'GRANT ' || C_OWNER_PRIVILEGES || ' TO ' || owner_i; 
      l_sql_pks := getDbGrantSpec(owner_i);
      l_sql_pkb := getDbGrantBody(owner_i);

   -- If Schema exist return
      if (scriptonly_i) then
         dbms_output.put_line(l_sql     || ';'); dbms_output.new_line;
         dbms_output.put_line(l_sql_g1  || ';'); dbms_output.new_line;
         dbms_output.put_line(l_sql_g2  || ';'); dbms_output.new_line;
         dbms_output.put_line(l_sql_pks); dbms_output.put_line('/'); dbms_output.new_line;
         dbms_output.put_line(l_sql_pkb); dbms_output.put_line('/'); dbms_output.new_line;
         return;
      elsif (um_util.isSchema(owner_i)) then
         logger.log('OWNER EXIST: No attempt to create new schema' || owner_i, l_scope);
         return;
      end if;
         
   -- Main creating owner      
      runSql(l_sql,'Creating owner ' || owner_i);
      saveUserDetails(owner_i, null, applname_i, C_USER_TYPE_OWNER   , readwrite_i=>true, ddl_i=>true );

      runSqlText(l_sql_g1, 'Granting CREATE SESSION, ALTER SESSION to ' || owner_i, l_scope);
      runSqlText(l_sql_g2, 'Granting DDL privileges to ' || owner_i, l_scope);

      runSqlText(l_sql_pks, 'Creating DB_GRANT specification in ' || owner_i, l_scope);
      runSqlText(l_sql_pkb, 'Creating DB_GRANT body in ' || owner_i, l_scope);

   EXCEPTION          
      WHEN others THEN
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE grantTo(role_i IN varchar2, schema_i IN varchar2, scriptonly_i IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.grantTo' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_sql    varchar2(1000);
   BEGIN
   -- Initialize
      logger.append_param(l_params, 'role_i',   nvl(role_i,'<null>'));
      logger.append_param(l_params, 'schema_i', nvl(schema_i,'<null>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

   -- Check Null and SQL Injection
      err_api.check_enquote_name(role_i);
      err_api.check_sql_name(schema_i);

   -- Main
      l_sql := 'grant ' || role_i || ' to ' || schema_i;
   
      if (not scriptonly_i) then
         runSql(l_sql, l_scope, true);
      else
         dbms_output.put_line(l_sql||';');
         dbms_output.new_line;
      end if;
      
   exception 
      when err_api.e_assert_illegal_schema then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_SCHEMA, l_scope, l_params);
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then 
         err_api.log_sql(sqlcode, sqlerrm, to_clob(l_sql), l_scope, l_params);
         raise;
   END;

   PROCEDURE grantRolesToOperatorRoles(scriptonly_i IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.grantRolesToOperatorRoles' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_cnt       number;
      l_role_rw   varchar2(30);
      l_role_ro   varchar2(30);
      l_role_ddl  varchar2(30);
   BEGIN
      -- Initialize
      l_role_rw  := C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_RW;
      l_role_ro  := C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_RO;
      l_role_ddl := C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_DDL;

      -- Check if operator role exist if not create it
      select count(*) into l_cnt from dba_roles where role in (l_role_rw, l_role_ro, l_role_ddl);
      if l_cnt <> 3 then
         createOperatorRoles(scriptonly_i);
      end if;

      -- Loop through all owners registered
      for rec in (select * from um_users where typeid='OWN') loop
         grantTo(rec.appl_name || C_POSTFIX_ROLE_RW,  C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_RW,  scriptonly_i);
         grantTo(rec.appl_name || C_POSTFIX_ROLE_RO,  C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_RO,  scriptonly_i);
         grantTo(rec.appl_name || C_POSTFIX_ROLE_DDL, C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_DDL, scriptonly_i);
      end loop;
      
      logger.log('SUCCESS: Granting application roles to operator roles.', l_scope);

   EXCEPTION
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope);
         raise;
   END;

   FUNCTION getDbGrantSpec(owner_i IN varchar2) RETURN varchar2 AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getDbGrantSpec';
      l_params       logger.tab_param;

      l_dummy           varchar2(30);
   BEGIN
  
      -- Creating PACKAGE
      return 'CREATE OR REPLACE PACKAGE ' || owner_i || '.DB_GRANT AS ' || chr(10) ||
               '   USR_BCH       CONSTANT  varchar2(30) :=''' || upper(owner_i || C_POSTFIX_USER_BATCH) || ''';' || chr(10) ||
               '   USR_APP       CONSTANT  varchar2(30) :=''' || upper(owner_i || C_POSTFIX_USER_APPL)  || ''';' || chr(10) ||
               '   USR_OWN       CONSTANT  varchar2(30) :=''' || upper(owner_i)                         || ''';' || chr(10) ||
               '   ROLE_NAME_RW  CONSTANT  varchar2(30) :=''' || upper(owner_i || C_POSTFIX_ROLE_RW)    || ''';' || chr(10) ||
               '   ROLE_NAME_RO  CONSTANT  varchar2(30) :=''' || upper(owner_i || C_POSTFIX_ROLE_RO)    || ''';' || chr(10) || 
               '   ROLE_NAME_DDL CONSTANT  varchar2(30) :=''' || upper(owner_i || C_POSTFIX_ROLE_RO)    || ''';' || chr(10) || chr(10) ||
               '   procedure grantToRoles;' || chr(10) ||
               'END;';
   
   exception
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getDbGrantSpec;

   FUNCTION getDbGrantBody(owner_i IN varchar2) RETURN varchar2 AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getDbGrantBody';
      l_params       logger.tab_param;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'owner_i',   nvl(owner_i,'<null>'));

      return 'CREATE OR REPLACE PACKAGE BODY ' || owner_i || '.DB_GRANT AS ' || chr(10) ||
               '    PROCEDURE log(txt_i IN varchar2) AS'                       || chr(10) ||
               '    BEGIN'                                                     || chr(10) ||
               '       dbms_output.put_line(txt_i);'                           || chr(10) ||
               '    END;'                                                      || chr(10) || chr(10) ||
               '    PROCEDURE grant_to_roles(obj_name_i IN varchar2, obj_type_i IN varchar2) AS ' || chr(10) ||
               '       p_sql varchar2(200);' || chr(10) ||
               '    BEGIN' || chr(10) ||
               '       -- Grant to RW role' || chr(10) ||
               '       p_sql := ''GRANT '' || case obj_type_i when ''TABLE''     then ''SELECT, INSERT, UPDATE, DELETE''' || chr(10) ||
               '                                            when ''VIEW''      then ''SELECT''' || chr(10) ||
               '                                            when ''SEQUENCE''  then ''SELECT''' || chr(10) ||
               '                                                             else ''EXECUTE'' end || ' || chr(10) ||
               '                        '' ON '' || obj_name_i || '' TO '' || ROLE_NAME_RW; ' || chr(10) ||
               '       begin' || chr(10) ||      
               '          execute immediate p_sql;' || chr(10) ||
               '          log(''Grant towards '' || obj_name_i || '' to '' || ROLE_NAME_RW || '' completed successfully.'');' || chr(10) || 
               '       exception when others then' || chr(10) ||
               '          log(''ERROR: Grant towards'' || obj_name_i || '' to '' || ROLE_NAME_RW || '' failed: '' || SQLERRM);' || chr(10) ||
               '       end;' || chr(10) || chr(10) ||
               '       -- Grant to RO role if table or view' || chr(10) ||
               '       if obj_type_i in (''TABLE'',''VIEW'') then ' || chr(10) ||
               '          p_sql := ''GRANT SELECT ON '' || obj_name_i || '' TO '' || ROLE_NAME_RO; '|| chr(10) ||
               '          begin' || chr(10) ||
               '             execute immediate p_sql;' || chr(10) ||
               '             log(''Grant towards '' || obj_name_i || '' to '' || ROLE_NAME_RO || '' completed successfully.'');' || chr(10) ||
               '          exception when others then' || chr(10) ||
               '             log(''ERROR: Grant towards'' || obj_name_i || '' to '' || ROLE_NAME_RO || '' failed: '' || SQLERRM);' || chr(10) ||
               '          end;' || chr(10) ||
               '       end if;' || chr(10) ||
               '    END;' || chr(10) || chr(10) ||
               '    PROCEDURE grantToRoles is' || chr(10) ||
               '    BEGIN ' || chr(10) ||
               '       dbms_output.enable(1000000);' || chr(10) ||
               '       FOR rec IN ( SELECT object_name,  object_type  FROM user_objects' || chr(10) ||
               '                    WHERE object_type IN (''TABLE'',''PACKAGE'',''PROCEDURE'',''FUNCTION'',''SEQUENCE'',''VIEW'',''TYPE'')' || chr(10) ||
               '                      AND NOT (object_type like ''%PACKAGE%'' and object_name=''DB_GRANT''))' || chr(10) ||
               '       LOOP' || chr(10) ||
               '          BEGIN' || chr(10) ||
               '             grant_to_roles(rec.object_name, rec.object_type);' || chr(10) ||
               '          EXCEPTION WHEN others THEN' || chr(10) ||
               '             dbms_output.put_line(''Bad object_name=''  || rec.object_name);' || chr(10) ||
               '          END;' || chr(10) ||
               '       END LOOP;' || chr(10) ||
               '    END;' || chr(10) ||
               'END;';

   exception
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getDbGrantBody;

   PROCEDURE createTablespace(schema_i IN varchar2, tbsname_o OUT varchar2, scriptonly_i IN boolean default false) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createTablespace' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_tbs_dir      varchar2(1000);
      l_tbs_size     varchar2(30);
      l_file         varchar2(1000);
      l_sql          varchar2(1000);
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i',     nvl(schema_i,'<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);

      -- Check (Null + SQL injection)
      err_api.check_sql_name(schema_i);

      -- Find datafile location and eventually name (SQL Injection check)
      um_config.getPropertiesTbs(schema_i, l_file, tbsname_o, l_tbs_size);
      
      if l_tbs_size is null or l_tbs_size = '' then
         l_tbs_size := C_DEFAULT_TBS_SIZE;
      end if;

      if not um_config.isLegalTbsSize(l_tbs_size) then
         raise err_api.e_illegal_tbs_size;
      end if;

   -- Tablespace
      l_sql := 'CREATE TABLESPACE ' || lower(tbsname_o) || 
                        ' DATAFILE ''' || l_file || ''' size ' || l_tbs_size;
      -- ScriptOnly
      if (scriptonly_i) then 
         dbms_output.put_line(l_sql||';');
      -- Check if tablespace exists
      elsif (not um_util.isTablespace(tbsname_o)) then
         runSqlText(l_sql, 'Creating tablespace ' || upper(tbsname_o), l_scope);  
      -- If exist log this
      else
         logger.log('Tablespace exists: ' || upper(tbsname_o), l_scope);
      end if;

   exception
      when err_api.e_illegal_tbs_size then
         err_api.log_and_raise(sqlcode, err_api.C_ILLEGAL_TBS_SIZE, l_scope, l_params);
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_SCHEMA, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END createTablespace;

   PROCEDURE saveOperatorDetails(userid_i IN varchar2, fullname_i IN varchar2, readwrite_i IN boolean, ddl_i IN boolean) AS
   /* Description : Operator is a resource working with maintenence, often identified by an ident (such as EK2046)
    * Datachanges : Insert or update row in UM_OPERATORS
    *
    * Input/Output parameters:
    * %param    userid_i      Username (company ident) for operator
    * %param    fullname_i    Operator's full name
    * %param    readwrite_i   (boolean) true = operator given RW privileges, false = RO privileges
    * %param    ddl_i         (boolean) true = operator given DDL privileges, false = no DDL privileges
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.saveOperatorDetails';
      l_params       logger.tab_param;

      l_rw   number;
      l_ro   number;
      l_ddl  number;
   BEGIN
      logger.append_param(l_params, 'userid_i',    nvl(userid_i,  '<NULL>'));
      logger.append_param(l_params, 'fullname_i',  nvl(fullname_i,'<NULL>'));
      logger.append_param(l_params, 'readwrite_i', case when readwrite_i then 'true' else 'false' end);
      logger.append_param(l_params, 'ddl_i',       case when ddl_i       then 'true' else 'false' end);

      l_rw  := case when readwrite_i then 1 else 0 end;
      l_ro  := case when readwrite_i then 0 else 1 end;
      l_ddl := case when ddl_i then 1 else 0 end;

      merge into um_operators o1
         using (select userid_i userid from dual) o2
            on (o1.userid = o2.userid)
         when matched then
            update set
               o1.fullname = fullname_i, o1.rw = l_rw, o1.ro = l_ro, o1.ddl = l_ddl
         when not matched then
            insert (userid, fullname, rw, ro, ddl) values (userid_i, fullname_i, l_rw, l_ro, l_ddl);

      logger.log('User ' || upper(userid_i) || ' registered in UM_OPERATORS table', l_scope);

   EXCEPTION 
      WHEN others THEN
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE saveUserDetails(schema_i IN varchar2, descr_i IN varchar2, applname_i IN varchar2, 
                             type_i IN varchar2, readwrite_i IN boolean, ddl_i IN boolean) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.saveUserDetails';
      l_params       logger.tab_param;

      l_rw   number;
      l_ro   number;
      l_ddl  number;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i',    nvl(schema_i,    '<NULL>'));
      logger.append_param(l_params, 'descr_i',     nvl(descr_i,     '<NULL>'));
      logger.append_param(l_params, 'applname_i',  nvl(applname_i,  '<NULL>'));
      logger.append_param(l_params, 'type_i',      nvl(type_i,      '<NULL>'));
      logger.append_param(l_params, 'readwrite_i', case when readwrite_i then 'true' else 'false' end);
      logger.append_param(l_params, 'ddl_i',       case when ddl_i       then 'true' else 'false' end);

      -- Main
      l_rw  := case when readwrite_i then 1 else 0 end;
      l_ro  := case when readwrite_i then 0 else 1 end;
      l_ddl := case when ddl_i then 1 else 0 end;

      merge into um_users u1
         using (select schema_i schema_name from dual) u2
            on (u1.username = u2.schema_name)
         when matched then
            update set u1.appl_name = applname_i, u1.description = descr_i, 
                       u1.typeid = type_i, u1.rw = l_rw, u1.ro = l_ro, u1.ddl = l_ddl
         when not matched then
            insert    (username, description, appl_name,  typeid, rw,   ro,   ddl) 
               values (schema_i, descr_i    , applname_i, type_i, l_rw, l_ro, l_ddl);

      logger.log('User ' || upper(schema_i) || ' registered in UM_USERS table', l_scope);

   EXCEPTION 
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;


   -- -----------------------------------------------------------------
   -- Public procedures and functions
   -- -----------------------------------------------------------------
   PROCEDURE createOperator(schema_i      IN varchar2, 
                            fullname_i    IN varchar2,
                            ddl_i         IN boolean, 
                            readwrite_i   IN boolean default false, 
                            scriptonly_i  IN boolean default false) AS
   /* Description : Create and register operator user for maintainance resource (ident)
    * Datachanges : Insert or update row in UM_OPERATORS
    *
    * Input/Output parameters:
    * %param    schema_i      Username (company ident) for operator
    * %param    fullname_i    Operator's full name
    * %param    readwrite_i   (boolean) true = operator given RW privileges, false = RO privileges
    * %param    ddl_i         (boolean) true = operator given DDL privileges, false = no DDL privileges
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createOperator'||case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_role            varchar2(30);
      l_role_ddl        varchar2(30);

      l_sql             varchar2(1000);

      l_schema          um_operators.userid%TYPE;
   BEGIN
      -- -----------------------------------------
      -- Initializing
      -- -----------------------------------------
      logger.append_param(l_params, 'schema_i',     nvl(schema_i,  '<NULL>'));
      logger.append_param(l_params, 'fullname_i',   nvl(fullname_i,'<NULL>'));
      logger.append_param(l_params, 'ddl_i',        case when ddl_i        then 'true' else 'false' end);
      logger.append_param(l_params, 'readwrite_i',  case when readwrite_i  then 'true' else 'false' end);
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);
      mon_api.initialize(l_scope, schema_i, l_params);

      -- -----------------------------------------
      -- Check parameters (NULL + SQL Injection Check)
      -- -----------------------------------------
      err_api.check_null_and_raise(schema_i);
      err_api.check_null_and_raise(fullname_i);
      err_api.check_sql_name(schema_i);
      err_api.check_enquote_literal(fullname_i);
      
      -- -----------------------------------------
      -- Create Operator (if not exist)
      -- -----------------------------------------
      l_sql := 'CREATE USER ' || schema_i || ' IDENTIFIED BY ' || schema_i;

      if scriptonly_i then
         dbms_output.put_line(l_sql||';');
         dbms_output.new_line;
      elsif not um_util.isSchema(schema_i) then
         runSql(l_sql, l_scope, true);
         saveOperatorDetails(schema_i, fullname_i, readwrite_i, ddl_i);
      else
         logger.log('OperatorExist: Changing settings for operator ' || schema_i , l_scope);
         --revokeOperatorRolesFrom(schema_i);
      end if;

      -- -----------------------------------------
      -- Check if OperatorRoles exist
      -- -----------------------------------------
      l_role     := C_PREFIX_OPERATOR_ROLE || case when readwrite_i then C_POSTFIX_ROLE_RW else C_POSTFIX_ROLE_RO end;

      if (scriptonly_i) then
         createOperatorRoles(scriptonly_i=>true);
      elsif not um_util.isRole(l_role) then
         createOperatorRoles;
      else 
         logger.log('OperatorRoles: Exist for schema ' || schema_i , l_scope);
      end if;
   
      -- -----------------------------------------
      -- Grants To Roles
      -- -----------------------------------------
      grantTo(l_role, schema_i, scriptonly_i); -- Grant RO or RW role

      if ddl_i then              -- Grant DDL role (if set)
         grantTo(C_PREFIX_OPERATOR_ROLE || C_POSTFIX_ROLE_DDL, schema_i, scriptonly_i);
      end if;
      
      grantRolesToOperatorRoles(scriptonly_i);

      -- Finalize
      mon_api.finalize(l_scope);

   EXCEPTION
      when err_api.e_parameter_null then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when err_api.e_assert_illegal_name then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log_and_finalize(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE dropOperator(schema_i IN varchar2, scriptonly_i IN boolean default false) as
   /* Description : Drop and deregister template users based on userid
    * Datachanges : Drop schema and delete row in UM_OPERATORS
    *
    * Input/Output parameters:
    * %param   schema_i    Name for existing schema to create template users
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.dropOperator' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;
   BEGIN
      -- Initializing monitoring
      logger.append_param(l_params, 'schema_i',  nvl(schema_i, '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i',  case when scriptonly_i then 'true' else 'false' end);
      mon_api.initialize(l_scope, nvl(schema_i,'null'), l_params);

      -- Parameter checks (null + sql injection)
      err_api.check_enquote_literal(schema_i);
      err_api.check_sql_name(schema_i); 

      -- Drop schema
      dropOperatorSchema(schema_i, scriptonly_i);

      -- Delete operator details
      if (not scriptonly_i) then
         deleteOperatorDetails(schema_i);
      end if;

      -- Finalize monitoring
      mon_api.finalize(l_scope);

   EXCEPTION
      when err_api.e_parameter_null then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when err_api.e_assert_illegal_name then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log_and_finalize(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createTemplateUsers(applname_i IN varchar2, scriptonly_i IN boolean default false) AS
   /* Description : Create and register template users based on owner
    * Datachanges : Create schemas, roles and tablespaces. Insert or update row in UM_USERS.
    *
    * Input/Output parameters:
    * %param   applname_i     Name for existing schema to create template users
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createTemplateUsers' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_usr_own      varchar2(30);
      l_usr_app      varchar2(30);
      l_usr_bch      varchar2(30);

      l_rol_ro       varchar2(30);
      l_rol_rw       varchar2(30);
      l_rol_ddl      varchar2(30);
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'applname_i',   nvl(applname_i, '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);
      mon_api.initialize(l_scope, applname_i, l_params);

      -- Check parameters
      err_api.check_sql_name(applname_i);

      -- Initialize Roles and Users creation
      getSchemaNames(applname_i, l_usr_own, l_usr_app , l_usr_bch);
      getRoleNames(applname_i, l_rol_ro, l_rol_rw, l_rol_ddl);

      -- Create owner and SQL Injection Check
      createOwnerSchema(l_usr_own, applname_i, scriptonly_i);

      -- Create Owner Roles
      createAppRoles(applname_i, scriptonly_i);
      grantTo('create session, alter session', l_rol_rw, scriptonly_i);
      grantTo('create session, alter session', l_rol_ro, scriptonly_i);

      -- Create Application user
      if um_config.getPropertyBoolean(um_config.C_PRTY_USR_APP_CREATE) then
         createSchema(l_usr_app, applname_i, C_USER_TYPE_APPLICATION, true, false, scriptonly_i);
         grantTo(l_rol_rw, l_usr_app, scriptonly_i);
         createLogonTrigger(l_usr_app, l_usr_own, scriptonly_i);
      end if;
      
      -- Create Batch user
      if um_config.getPropertyBoolean(um_config.C_PRTY_USR_BATCH_CREATE) then
         createBatchSchema(l_usr_bch, l_usr_own, applname_i, scriptonly_i);
      end if;      
      
      grantRolesToOperatorRoles(scriptonly_i);
      
      -- Finalize
      mon_api.finalize(l_scope);

   EXCEPTION
      when err_api.e_assert_illegal_name then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log_and_finalize(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createTemplateUsers(applname_i IN varchar2, bankid_i IN varchar2, scriptonly_i IN boolean default false) AS
   /* Description : Create and register template users based on owner
    * Datachanges : Create schemas, roles and tablespaces. Insert or update row in UM_USERS.
    *
    * Input/Output parameters:
    * %param   applname_i     Name for existing schema to create template users
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createTemplateUsers' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_usr_own      varchar2(30);
      l_usr_app      varchar2(30);
      l_usr_bch      varchar2(30);
      l_tmp_app      varchar2(30);

      l_rol_ro       varchar2(30);
      l_rol_rw       varchar2(30);
      l_rol_ddl      varchar2(30);
   BEGIN
   -- Initializing
      logger.append_param(l_params, 'applname_i',  nvl(applname_i, '<NULL>'));
      logger.append_param(l_params, 'bankid_i',    nvl(bankid_i,   '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);
      mon_api.initialize(l_scope, applname_i, l_params);

   -- Loop on bankids
      l_tmp_app := applname_i || '_' || bankid_i;
   
   -- Check parameters
      err_api.check_sql_name(l_tmp_app);

   -- Initialize Roles and Users creation
      getSchemaNames(l_tmp_app, l_usr_own, l_usr_app , l_usr_bch);
      getRoleNames(l_tmp_app, l_rol_ro, l_rol_rw, l_rol_ddl);

   -- Create owner and SQL Injection Check
      createOwnerSchema(l_usr_own, l_tmp_app, scriptonly_i);

   -- Create Owner Roles
      createAppRoles(l_tmp_app, scriptonly_i);
      grantTo('create session, alter session', l_rol_rw, scriptonly_i);
      grantTo('create session, alter session', l_rol_ro, scriptonly_i);

   -- Create Application user
      if um_config.getPropertyBoolean(um_config.C_PRTY_USR_APP_CREATE) then
         createSchema(l_usr_app, l_tmp_app, C_USER_TYPE_APPLICATION, true, false, scriptonly_i);
         grantTo(l_rol_rw, l_usr_app, scriptonly_i);
         createLogonTrigger(l_usr_app, l_usr_own, scriptonly_i);
      end if;
   
   -- Create Batch user
      if um_config.getPropertyBoolean(um_config.C_PRTY_USR_BATCH_CREATE) then
         createBatchSchema(l_usr_bch, l_usr_own, l_tmp_app, scriptonly_i);
      end if;

      grantRolesToOperatorRoles(scriptonly_i);
      
      -- Finalize
      mon_api.finalize(l_scope);

   EXCEPTION
      when err_api.e_assert_illegal_name then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log_and_finalize(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE createTemplateUsers(applname_i IN varchar2, bankids_i IN um_bankid_nt, scriptonly_i IN boolean default false) AS
   /* Description : Create and register template users based on owner
    * Datachanges : Create schemas, roles and tablespaces. Insert or update row in UM_USERS.
    *
    * Input/Output parameters:
    * %param   applname_i     Name for existing schema to create template users
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.createTemplateUsers' || case when scriptonly_i then '(SCRIPTONLY)' else '' end;
      l_params       logger.tab_param;

      l_usr_own      varchar2(30);
      l_usr_app      varchar2(30);
      l_usr_bch      varchar2(30);
      l_tmp_app      varchar2(30);

      l_rol_ro       varchar2(30);
      l_rol_rw       varchar2(30);
      l_rol_ddl      varchar2(30);
      l_bankids      varchar2(1000) := ' ';

   BEGIN
   -- Initializing
      for rec in (select column_value bankid from table(bankids_i))
      loop
         l_bankids := l_bankids || rec.bankid || ',';
      end loop;
      logger.append_param(l_params, 'applname_i',  nvl(applname_i, '<NULL>'));
      logger.append_param(l_params, 'bankids_i', nvl(l_bankids, '<NULL>'));
      logger.append_param(l_params, 'scriptonly_i', case when scriptonly_i then 'true' else 'false' end);
      mon_api.initialize(l_scope, applname_i, l_params);

-- Check parameters
      err_api.check_sql_name(applname_i);

   -- Loop on bankids
      for b in (select column_value bankid from table(bankids_i))
      loop
      -- Create bank user name
         l_tmp_app := applname_i || '_' || b.bankid;
      
      -- Check parameters
         err_api.check_sql_name(l_tmp_app);

      -- Initialize Roles and Users creation
         getSchemaNames(l_tmp_app, l_usr_own, l_usr_app , l_usr_bch);
         getRoleNames(l_tmp_app, l_rol_ro, l_rol_rw, l_rol_ddl);

      -- Create owner and SQL Injection Check
         createOwnerSchema(l_usr_own, l_tmp_app, scriptonly_i);

      -- Create Owner Roles
         createAppRoles(l_tmp_app, scriptonly_i);
         grantTo('create session, alter session', l_rol_rw, scriptonly_i);
         grantTo('create session, alter session', l_rol_ro, scriptonly_i);

      -- Create Application user
         if um_config.getPropertyBoolean(um_config.C_PRTY_USR_APP_CREATE) then
            createSchema(l_usr_app, l_tmp_app, C_USER_TYPE_APPLICATION, true, false, scriptonly_i);
            grantTo(l_rol_rw, l_usr_app, scriptonly_i);
            createLogonTrigger(l_usr_app, l_usr_own, scriptonly_i);
         end if;
      
      -- Create Batch user
         if um_config.getPropertyBoolean(um_config.C_PRTY_USR_BATCH_CREATE) then
            createBatchSchema(l_usr_bch, l_usr_own, l_tmp_app, scriptonly_i);
         end if;      

      end loop;

      grantRolesToOperatorRoles(scriptonly_i);
      
      -- Finalize
      mon_api.finalize(l_scope);

   EXCEPTION
      when err_api.e_assert_illegal_name then
         err_api.log_finalize_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log_and_finalize(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END;

   PROCEDURE getSchemaNames(applname_i IN varchar2, owner_o OUT varchar2, appl_o OUT varchar2, batch_o OUT varchar2) AS
   /* Description : Generate schema names for template based on UM_PROPERTIES.
    * Datachanges : None.
    *
    * Input/Output parameters:
    * %param   applname_i     Name for application (for instance ECP_1234)
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getSchemaNames';
      l_params       logger.tab_param;
      l_use_suffix   boolean;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'applname_i ',       nvl(applname_i, '<NULL>'));

      -- Main
      l_use_suffix := um_config.getPropertyBoolean(um_config.C_PRTY_USR_OWNER_USE_SUFFIX);
      owner_o := upper(applname_i) || case when l_use_suffix then C_POSTFIX_USER_OWNER else '' end;
      appl_o  := upper(applname_i) || case when l_use_suffix then '' else C_POSTFIX_USER_APPL end;
      batch_o := upper(applname_i) || C_POSTFIX_USER_BATCH; 

   EXCEPTION 
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getSchemaNames;

   PROCEDURE getRoleNames(applname_i IN varchar2, ro_o OUT varchar2, rw_o OUT varchar2, ddl_o OUT varchar2) AS
   /* Description : Generate role names for template based on UM_PROPERTIES.
    * Datachanges : None.
    *
    * Input/Output parameters:
    * %param   applname_i     Name for application (for instance ECP_1234)
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getRoleNames';
      l_params       logger.tab_param;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'applname_i ', nvl(applname_i, '<NULL>'));

      -- Main
      ro_o  := upper(applname_i) || C_POSTFIX_ROLE_RO;
      rw_o  := upper(applname_i) || C_POSTFIX_ROLE_RW; 
      ddl_o := upper(applname_i) || C_POSTFIX_ROLE_DDL;

   EXCEPTION 
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getRoleNames;

   PROCEDURE packageInitialization AS
   /* Description : Run after package creation to automatically create operator roles at startup
    * Datachanges : Create and register operator roles
    */
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.packageInitialization';
      l_client_id    varchar2(50);
   BEGIN
      createOperatorRoles;

   EXCEPTION 
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope);
         raise;
   END;
   
END um_core;