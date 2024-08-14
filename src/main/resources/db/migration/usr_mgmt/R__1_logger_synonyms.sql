declare
   l_table     varchar2(30) := 'LOGGER_LOGS';
   l_privilege varchar2(30) := 'INSERT';
   l_user      varchar2(30) := 'LOGRDATA';
   
   l_cnt_user  number;
   l_cnt_logr  number;
   l_cnt_othr  number;

   l_sql       varchar2(1000);
   l_sql_pre   varchar2(100) := 'create or replace synonym logger';

   TYPE name_at IS VARRAY(8) OF VARCHAR2(30); 
   l_name_at   name_at := name_at('','_logs','_logs_apex_items','_prefs','_prefs_by_client_id','_logs_5_min','_logs_60_min','_logs_terse');

   l_owner     varchar2(30);
   l_tmp       varchar2(30);

   logger_is_local EXCEPTION;
begin
-- Check if LOGGER is installed in schema
   select count(*) into l_cnt_user from user_tables where table_name=l_table;

-- If LOGGER is local nothing needs to be done
   if (l_cnt_user > 0) then
      raise logger_is_local;
   end if;

-- Check if LOGGER exist in LOGRDATA schema
   select count(*) into l_cnt_logr from all_tables where owner=l_user and table_name=l_table;
   
-- Check if LOGGER exist anywhere else with privilege
   select count(*) into l_cnt_othr -- select t.owner 
      from all_tables t inner join (select table_name 
                                    from all_tab_privs 
                                    where table_name=l_table 
                                      and privilege=l_privilege
                                    group by grantee, table_name)  p on (t.table_name = p.table_name)
      where t.table_name=l_table;

-- Find potensial owner if LOGRDATA schema not exist
   if (l_cnt_logr = 0 and l_cnt_othr > 0) then
      select t.owner into l_tmp
         from all_tables t inner join (select table_name 
                                       from all_tab_privs 
                                       where table_name=l_table 
                                         and privilege=l_privilege 
                                         group by grantee, table_name) p on (t.table_name = p.table_name)
            where t.table_name=l_table
              and rownum <=1;
   end if;
      
-- Check if LOGGER is installed in LOGRDATA schema
   l_owner :=  case when l_cnt_logr > 0 then 'LOGRDATA'
                    when l_cnt_othr > 0 then l_tmp
                    else 'ERROR'
               end;

-- If no LOGGER exist raise
   if (l_owner = 'ERROR') then
      raise_application_error(-20000, 'LOGGER framework does not exist or no privilege granted');
   end if;
   
-- Create synonyms against LOGGER
   for i IN 1..8 loop
     l_sql := l_sql_pre || l_name_at(i) || ' for ' || l_owner || '.logger' || l_name_at(i);
     execute immediate l_sql;
     dbms_output.put_line('SUCCESS: ' || l_sql);
   end loop;
   
   --dbms_output.put_line('USER:  ' || l_cnt_user);
   --dbms_output.put_line('LOGR:  ' || l_cnt_logr);
   --dbms_output.put_line('OTHR:  ' || l_cnt_othr);
   --dbms_output.put_line('OWNER: ' || l_owner);

exception
   when logger_is_local then
      dbms_output.put_line('INFO: ' || USER || ' has LOGGER installed (locally). No synonyms required.');
end;
/