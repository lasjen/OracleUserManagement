CREATE OR REPLACE PACKAGE BODY user_grant AS 
   PROCEDURE log(txt_i IN varchar2) AS
   BEGIN
      dbms_output.put_line(txt_i);
   END;

   PROCEDURE grant_to_roles(obj_name_i IN varchar2, obj_type_i IN varchar2) AS 
      l_sql varchar2(200);
   BEGIN
      -- Grant to RW role
      l_sql := 'GRANT ' || case obj_type_i when 'TABLE'     then 'SELECT, INSERT, UPDATE, DELETE'
                                           when 'VIEW'      then 'SELECT'
                                           when 'SEQUENCE'  then 'SELECT'
                                                            else 'EXECUTE' end || 
                       ' ON ' || obj_name_i || ' TO ' || c_role_name_rw; 
      begin
         execute immediate l_sql;
         log('Grant towards ' || obj_name_i || ' to ' || c_role_name_rw || ' completed successfully.');
      exception when others then
         log('ERROR: Grant towards' || obj_name_i || ' to ' || c_role_name_rw || ' failed: ' || SQLERRM);
      end;

      -- Grant to RO role if table or view
      if obj_type_i in ('TABLE','VIEW') then 
         l_sql := 'GRANT SELECT ON ' || obj_name_i || ' TO ' || c_role_name_ro; 
         begin
            execute immediate l_sql;
            log('Grant towards ' || obj_name_i || ' to ' || c_role_name_ro || ' completed successfully.');
         exception when others then
            log('ERROR: Grant towards' || obj_name_i || ' to ' || c_role_name_ro || ' failed: ' || SQLERRM);
         end;
      end if;
   END;

   PROCEDURE grantToRoles is
   BEGIN 
      dbms_output.enable(1000000);
      FOR rec IN ( SELECT object_name,  object_type  FROM user_objects
                   WHERE object_type IN ('TABLE','PACKAGE','PROCEDURE','FUNCTION','SEQUENCE','VIEW','TYPE')
                     AND NOT (object_type like '%PACKAGE%' and object_name='USER_GRANT'))
      LOOP
         BEGIN
            grant_to_roles(rec.object_name, rec.object_type);
         EXCEPTION WHEN others THEN
            log('Bad object_name='  || rec.object_name);
         END;
      END LOOP;
   END;
END;
/
--------------------------------------------------------
--  DDL for Synonymn GRANTTOROLES
--------------------------------------------------------
CREATE OR REPLACE SYNONYM granttoroles FOR user_grant;