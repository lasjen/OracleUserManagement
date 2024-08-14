CREATE OR REPLACE PACKAGE user_grant AS
   c_package_name               CONSTANT varchar2(30) := upper($$plsql_unit);

   c_app_name       CONSTANT  varchar2(25) := 'MGMT';
   c_supp_usr       CONSTANT  varchar2(30) := 'MGMTS';
   c_data_usr       CONSTANT  varchar2(30) := 'MGMTO';
   c_role_name_rw   CONSTANT  varchar2(30) := 'MGMT_RW';
   c_role_name_ro   CONSTANT  varchar2(30) := 'MGMT_RO';

   procedure grantToRoles;
END;
/