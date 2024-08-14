CREATE OR REPLACE PACKAGE BODY um_drop AS

/* *****************************************************************************************
 * Local procedures
 * ***************************************************************************************** */

procedure run_sql(sql_i in varchar2, scriptonly_i IN boolean default false) as
begin
   if not scriptonly_i then
      execute immediate sql_i;
      dbms_output.put_line('SUCCESS: ' || sql_i);
   else
      dbms_output.put_line(sql_i||';');
      dbms_output.new_line;
   end if;

exception 
   when others then
      dbms_output.put_line('FAILED: ' || sql_i);
      dbms_output.put_line('----> Error: ' || SQLCODE || ' - ' || SQLERRM);
end;

procedure drop_tbs(tbs_i IN varchar2, scriptonly_i IN boolean default true) as
   l_cnt number;
begin
   select count(*) into l_cnt from dba_tablespaces where tablespace_name=tbs_i;

   if (l_cnt > 0 or scriptonly_i) then
      run_sql('drop tablespace ' || tbs_i || ' including contents and datafiles', scriptonly_i);
   end if;
end;

/* *****************************************************************************************
   Object:  dropTemplateUsers
   Type:    procedure
   Purpose: This procedure will drop the template users and roles
 
   PARAMETERS:                     
      owner_i     IN    Application base (for instance ECP_1234)
      ro_o        OUT   Name for Read-Only role
      rw_o        OUT   Name for Read-Write role
      ddl_o       OUT   Name for DDL role
   ***************************************************************************************** */


PROCEDURE dropTemplateUsers(applname_i IN varchar2, scriptonly_i IN boolean default true) AS
   l_owner     varchar2(30 char);
   l_appl      varchar2(30 char);
   l_batch     varchar2(30 char);
   l_role_rw   varchar2(30 char);
   l_role_ro   varchar2(30 char);
   l_role_ddl  varchar2(30 char);
   l_own_tbs   varchar2(30 char);
   l_btc_tbs   varchar2(30 char);
   l_tbs_suf   varchar2(10 char);
BEGIN
-- Initialize names
   l_appl  := applname_i || um_core.C_POSTFIX_USER_APPL;
   l_batch := applname_i || um_core.C_POSTFIX_USER_BATCH;
   l_owner := applname_i || case when um_config.getPropertyBoolean('userOwnerUseSuffix') 
                                 then um_core.C_POSTFIX_USER_OWNER
                                 else '' 
                            end;
   l_role_ro   := applname_i || um_core.C_POSTFIX_ROLE_RO;
   l_role_rw   := applname_i || um_core.C_POSTFIX_ROLE_RW;
   l_role_ddl  := applname_i || um_core.C_POSTFIX_ROLE_DDL;
   l_tbs_suf   := um_config.getPropertyString('tbsNameSuffix');
   l_own_tbs   := l_owner || l_tbs_suf;
   l_btc_tbs   := l_batch || l_tbs_suf;

-- Drop template users
   run_sql('drop user ' || l_batch, scriptonly_i);
   run_sql('drop user ' || l_appl, scriptonly_i);
   run_sql('drop user ' || l_owner || ' cascade', scriptonly_i);

   run_sql('drop role ' || l_role_ro, scriptonly_i);
   run_sql('drop role ' || l_role_rw, scriptonly_i);
   run_sql('drop role ' || l_role_ddl, scriptonly_i);

   if um_config.getPropertyBoolean('tbsDropWithOwner') then
      drop_tbs(l_own_tbs, scriptonly_i);
      drop_tbs(l_btc_tbs, scriptonly_i);
   end if;

END;

PROCEDURE dropTemplateUsers(applname_i IN varchar2, bankid_i IN varchar2, scriptonly_i IN boolean default true) AS
   l_appl_tmp  varchar2(30 char);
   l_owner     varchar2(30 char);
   l_appl      varchar2(30 char);
   l_batch     varchar2(30 char);
   l_role_rw   varchar2(30 char);
   l_role_ro   varchar2(30 char);
   l_role_ddl  varchar2(30 char);
   l_own_tbs   varchar2(30 char);
   l_btc_tbs   varchar2(30 char);
   l_tbs_suf   varchar2(10 char);
BEGIN
-- Initialize names
   l_appl_tmp := applname_i ||'_'||bankid_i;

   l_owner := l_appl_tmp || case when um_config.getPropertyBoolean('userOwnerUseSuffix') 
                                 then um_core.C_POSTFIX_USER_OWNER
                                 else '' 
                            end;
   l_appl  := l_appl_tmp || um_core.C_POSTFIX_USER_APPL;
   l_batch := l_appl_tmp || um_core.C_POSTFIX_USER_BATCH;
   
   l_role_ro   := l_appl_tmp || um_core.C_POSTFIX_ROLE_RO;
   l_role_rw   := l_appl_tmp || um_core.C_POSTFIX_ROLE_RW;
   l_role_ddl  := l_appl_tmp || um_core.C_POSTFIX_ROLE_DDL;
   l_tbs_suf   := um_config.getPropertyString('tbsNameSuffix');
   l_own_tbs   := l_owner || l_tbs_suf;
   l_btc_tbs   := l_batch || l_tbs_suf;

-- Drop template users
   run_sql('drop user ' || l_batch, scriptonly_i);
   run_sql('drop user ' || l_appl, scriptonly_i);
   if um_config.getPropertyBoolean('userOwnerDrop') then
      run_sql('drop user ' || l_owner || ' cascade', scriptonly_i);
   else
      dbms_output.put_line('-- INFO: "userOwnerDrop" set to FALSE (not dropped).');
      dbms_output.put_line('-- SQL: drop user ' || l_owner || ' cascade;');
   end if;
   run_sql('drop role ' || l_role_ro, scriptonly_i);
   run_sql('drop role ' || l_role_rw, scriptonly_i);
   run_sql('drop role ' || l_role_ddl, scriptonly_i);

   if um_config.getPropertyBoolean('tbsDropWithOwner') then
      drop_tbs(l_own_tbs, scriptonly_i);
      drop_tbs(l_btc_tbs, scriptonly_i);
   end if;

END;

END um_drop;
/

