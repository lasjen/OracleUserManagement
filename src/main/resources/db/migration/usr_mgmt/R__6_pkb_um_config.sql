CREATE OR REPLACE PACKAGE BODY um_config AS
-- ---------------------------------------------------------------------------------------
-- Purpose: The purpose of this package is to generate API for UM_PROPERTIES table
-- 
-- ---------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------
-- Local procedures and functions
-- ---------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------
-- Public procedures and functions
-- ---------------------------------------------------------------------------------------
  /* Description : Set or update property in UM_PROPERTIES table
   * Datachanges : Upsert row given by name=name_i
   *
   * Input/Output parameters:
   * %param    name_i      Name of property to be upserted
   * %param    value_i     New value for paramter
   * %param    desc_i      Text description of parameter
   */
   PROCEDURE setProperty(name_i IN varchar2, value_i IN varchar2, desc_i IN varchar2 default null) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.setProperty';
      l_params       logger.tab_param;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'name_i',   nvl(name_i,  'null'));
      logger.append_param(l_params, 'value_i',  nvl(value_i, 'null'));
      logger.append_param(l_params, 'desc_i',   nvl(desc_i,  'null'));

      -- Check parameters
      if (name_i IS NULL or value_i IS NULL) then
         raise err_api.e_parameter_null;
      elsif length(name_i) > C_COL_MAX_LENGTH_NAME or length(value_i) > C_COL_MAX_LENGTH_VALUE then
         raise err_api.e_value_too_large_for_column;
      end if;

      -- Merge properties
      merge into um_properties p using (select name_i name, value_i value, desc_i descr from dual) o on (p.name=o.name)
         when matched then 
            update set value=o.value, description=o.descr
         when not matched then
            insert (name, value, description) values (o.name, o.value, o.descr);

      logger.log('PROPERTY SET: ' || name_i || ' = ' || value_i || ' (see table UM_PROPERTIES)', l_scope);

   EXCEPTION
      when err_api.e_parameter_null then
         err_api.log_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when err_api.e_value_too_large_for_column then
         err_api.log_and_raise(sqlcode, err_api.C_VALUE_TOO_LARGE_FOR_COLUMN, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END setProperty;

  /* Description : Set boolean property in USR_MTMT_PROPERTIES table
   * Datachanges : Insert or update value for property
   *
   * Input/Output parameters:
   * %param    name_i      Property name
   * %param    value_i     Boolean value
   * %param    desc_i      Description of property 
   */
   PROCEDURE setProperty(name_i IN varchar2, value_i IN boolean, desc_i IN varchar2 default null)  AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.setProperty(boolean)';
      l_params       logger.tab_param;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'name_i',   nvl(name_i,'null'));
      logger.append_param(l_params, 'value_i',  case when value_i then 'TRUE' else 'FALSE' end);
      logger.append_param(l_params, 'desc_i',   nvl(desc_i, 'null'));
      
      -- Check for NULL values (NAME_I and VALUE_I)
      if (name_i IS NULL or value_i IS NULL) then
         raise err_api.e_parameter_null;
      end if;

      setProperty(name_i, case when value_i then 'TRUE' else 'FALSE' end, desc_i);

   EXCEPTION
      when err_api.e_parameter_null then
         err_api.log_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END setProperty;

  /* Description : Set number property in USR_MTMT_PROPERTIES table
   * Datachanges : Insert or update value for property
   *
   * Input/Output parameters:
   * %param    name_i      Property name
   * %param    value_i     Number value
   * %param    desc_i      Description of property 
   */
   PROCEDURE setProperty(name_i IN varchar2, value_i IN number, desc_i IN varchar2 default null)  AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.setProperty(number)';
      l_params       logger.tab_param;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'name_i',   nvl(name_i,  'null'));
      logger.append_param(l_params, 'value_i',  nvl(to_char(value_i), 'null'));
      logger.append_param(l_params, 'desc_i',   nvl(desc_i,  'null'));

      -- Check for NULL values (NAME_I and VALUE_I)
      if (name_i IS NULL or value_i IS NULL) then
         raise err_api.e_parameter_null;
      end if;

      setProperty(name_i, to_char(value_i), desc_i);

   EXCEPTION
      when err_api.e_parameter_null then
         err_api.log_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END setProperty;


  /* Description : Get string value for parameter name from UM_PROPERTIES table
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param property_name_i    Name for property lookup in UM_PROPERTIES table
   */
   FUNCTION getPropertyString(property_name_i IN varchar2) RETURN varchar2 IS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getPropertyString(' || property_name_i || ')';
      l_params       logger.tab_param;

      l_value        varchar2(1000);
   BEGIN
      -- Initialize 
      logger.append_param(l_params, 'property_name_i', nvl(property_name_i,'null'));

      -- Check for NULL values (NAME_I and VALUE_I)
      if (property_name_i IS NULL) then
         raise err_api.e_parameter_null;
      end if;

      -- Main
      begin
         select value into l_value from um_properties where name = property_name_i;
      exception
         when no_data_found then
            raise err_api.e_property_not_found;
      end;

      return l_value;

   EXCEPTION
      when err_api.e_property_not_found then
         err_api.log_and_raise(sqlcode, err_api.C_PROPERTY_NOT_FOUND, l_scope, l_params);
      when err_api.e_parameter_null then
         err_api.log_and_raise(sqlcode, err_api.C_PARAMETER_NULL, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getPropertyString;

  /* Description : Get number value for parameter name from UM_PROPERTIES table
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param property_name_i    Name for property lookup in UM_PROPERTIES table
   */
   FUNCTION getPropertyNumber(property_name_i IN varchar2) RETURN number IS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getPropertyNumber(' || property_name_i || ')';
      l_params       logger.tab_param;

      l_value        number(10);
   BEGIN
      -- Initialize 
      logger.append_param(l_params, 'property_name_i', property_name_i);

      -- Main
      begin
         select to_number(value) into l_value from um_properties where name = property_name_i;
      exception
         when no_data_found then
            raise err_api.e_property_not_found;
         when invalid_number then
            raise err_api.e_not_number;
      end;

      return l_value;

   EXCEPTION
      when err_api.e_property_not_found then
         err_api.log_and_raise(sqlcode, err_api.C_PROPERTY_NOT_FOUND, l_scope, l_params);
      when err_api.e_not_number then
         err_api.log_and_raise(sqlcode, err_api.C_NOT_NUMBER, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getPropertyNumber;

  /* Description : Get number value for size parameter name from UM_PROPERTIES table
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param property_name_i    Name for property lookup in UM_PROPERTIES table
   */
   FUNCTION getPropertySize(property_name_i IN varchar2) RETURN number IS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getPropertySize';
      l_params       logger.tab_param;

      l_dummy        number;
      l_value        um_properties.value%type;
   BEGIN
      -- Initialize 
      logger.append_param(l_params, 'property_name_i', property_name_i);

      -- Main
      begin
         select to_number(substr(value,1,length(value)-1)), value into l_dummy, l_value 
            from um_properties where name = property_name_i;
         
      exception 
         when no_data_found then
            raise err_api.e_property_not_found;
         when invalid_number then
            raise err_api.e_not_number;
      end;

      if not isLegalTbsSize(l_value) then
            raise err_api.e_illegal_tbs_size;
      end if;

      return l_value;

   EXCEPTION
      when err_api.e_illegal_tbs_size then
         err_api.log_and_raise(sqlcode, err_api.C_ILLEGAL_TBS_SIZE, l_scope, l_params);
      when err_api.e_property_not_found then
         err_api.log_and_raise(sqlcode, err_api.C_PROPERTY_NOT_FOUND, l_scope, l_params);
      when err_api.e_not_number then
         err_api.log_and_raise(sqlcode, err_api.C_NOT_NUMBER, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getPropertySize;

  /* Description : Get boolean value for parameter name from UM_PROPERTIES table
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param property_name_i    Name for property lookup in UM_PROPERTIES table
   */
   FUNCTION getPropertyBoolean(property_name_i IN varchar2) RETURN boolean IS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.getPropertyBoolean(' || property_name_i || ')';
      l_params       logger.tab_param;
      l_value        varchar2(1000);
   BEGIN
      -- Initialize 
      logger.append_param(l_params, 'property_name_i', property_name_i);

      -- Main
      begin
         select value into l_value from um_properties where name = property_name_i;
      exception when no_data_found then
         raise err_api.e_property_not_found;
      end;

      if upper(l_value) not in ('TRUE','FALSE') then
         raise err_api.e_not_boolean;
      end if;

      return case when upper(l_value)='TRUE' then true else false end;

   EXCEPTION
      when err_api.e_property_not_found then
         err_api.log_and_raise(sqlcode, err_api.C_PROPERTY_NOT_FOUND, l_scope, l_params);
      when err_api.e_not_boolean then
         err_api.log_and_raise(sqlcode, err_api.C_NOT_BOOLEAN, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getPropertyBoolean;
   
  /* Description : Check if in-parameter is legal tablespace size
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param size_i            Given tablespace size (given by K (=KB), M (=MB), G (=GB), T (=TB))
   */
   FUNCTION isLegalTbsSize(size_i IN varchar2) RETURN boolean IS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.isLegalTbsSize';
      l_params       logger.tab_param;

      l_size_suf varchar2(1); -- Legal values: K, M, G, T
      l_size_num varchar2(30);
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'size_i ', size_i );

      -- Main
      l_size_num := case when sql_util.isNumber(size_i) then size_i || 'M' else size_i end;
         
      l_size_suf := substr(trim(l_size_num),-1,1); -- in ('K','M','G','T') then substr(size_i,-1,1) else 'M';
      l_size_num := substr(trim(l_size_num), 1,length(size_i)-1);

      return case when l_size_suf not in ('K','M','G','T')  then false
                  when not sql_util.isNumber(l_size_num)    then false
                  else true
             end;

   EXCEPTION 
      WHEN others THEN
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END isLegalTbsSize;

  /* Description : Find proper properties for schema tablespace
   * Datachanges : None
   *
   * Input/Output parameters:
   * %param schema_i    Schema_name for the TBS properties.
   * %out   location_o  File location (either file PATH or ASM_DISKGROUP)
   * %out   tbsname_o   Suggested name for tablespace
   * %out   tbssize_o   Suggested size for tablespace
   */
   PROCEDURE getPropertiesTbs(schema_i IN varchar2, location_o OUT varchar2, tbsname_o OUT varchar2, tbssize_o OUT varchar2) AS
      l_scope           logger_logs.scope%type := C_PACKAGE_NAME || '.getPropertiesTbs';
      l_params          logger.tab_param;

      l_location        varchar2(1000);
      l_tbsname         varchar2(30);

      l_prop_asm_use    boolean;
      l_prop_asm_dg     um_properties.VALUE%TYPE;
      l_prop_tbs_dir    um_properties.VALUE%TYPE;
      l_prop_tbs_suf    um_properties.VALUE%TYPE;
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'schema_i', nvl(schema_i, '<NULL>'));

      -- SQL Injection Check
      err_api.check_sql_name(schema_i);

      -- Main
      l_prop_asm_use    := getPropertyBoolean(C_PRTY_TBS_ASM_USE);
      l_prop_asm_dg     := getPropertyString(C_PRTY_TBS_ASM_DISKGROUP);
      l_prop_tbs_dir    := getPropertyString(C_PRTY_TBS_DIRECTORY);
      l_prop_tbs_suf    := getPropertyString(C_PRTY_TBS_NAME_SUFFIX);

      --------------------------------------------------------------------------------
      -- Find Location
      --------------------------------------------------------------------------------
      location_o := case 
                        when l_prop_asm_use then l_prop_asm_dg 
                                       else l_prop_tbs_dir || '/' || lower(schema_i) || '_' || lower(l_prop_tbs_suf) || '01.dbf' 
                    end;

      logger.log('TBS_LOCATION: ' || location_o, l_scope);
      
      --------------------------------------------------------------------------------
      -- Find Tablespace name
      --------------------------------------------------------------------------------
      tbsname_o := schema_i || l_prop_tbs_suf;

      logger.log('TBS_NAME: ' || tbsname_o, l_scope);

      --------------------------------------------------------------------------------
      -- Find Tablespace Size
      -- If username ends with POSTFIX_USER_BATCH then get TBS for BATCH
      --------------------------------------------------------------------------------
      tbssize_o := case when substr(schema_i, -length(um_core.C_POSTFIX_USER_BATCH)) = um_core.C_POSTFIX_USER_BATCH 
                           then getPropertyString(C_PRTY_USR_BATCH_TBS_SIZE)
                           else getPropertyString(C_PRTY_USR_OWNER_TBS_SIZE)
                   end;
      logger.log('TBS_SIZE: ' || tbssize_o, l_scope);

   EXCEPTION
      when err_api.e_property_not_found then
         err_api.log_and_raise(sqlcode, err_api.C_PROPERTY_NOT_FOUND, l_scope, l_params);
      when err_api.e_not_boolean then
         err_api.log_and_raise(sqlcode, err_api.C_NOT_BOOLEAN, l_scope, l_params);
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END getPropertiesTbs;

  /* Description : Set ASM Diskgroup for tablespaces
   * Datachanges : Update property value for c_prty_tbs_asm_diskgroup
   *
   * Input/Output parameters:
   * %param    diskgroup_i    Value for ASM diskgroup
   */
   PROCEDURE setTbsAsmDiskgroup(diskgroup_i IN varchar2) AS
      l_scope        logger_logs.scope%type := C_PACKAGE_NAME || '.setTbsAsmDiskgroup';
      l_params       logger.tab_param;

      l_dg  varchar2(100);
   BEGIN
      -- Initializing
      logger.append_param(l_params, 'diskgroup_i',    diskgroup_i);
      
      -- Remove Pluss sign infront (if any)
      l_dg  := ltrim(diskgroup_i,'+');

      -- SQL Injection check
      err_api.check_sql_name(l_dg);

      -- Check first character is letter
      if regexp_like (substr(l_dg,1,1), '[^A-Za-z]') or regexp_like (l_dg, '[^A-Za-z0-9_]') then
         raise err_api.e_illegal_diskgroup;
      end if;

      -- Add Pluss sign again
      l_dg := '+' || l_dg;
      setProperty(C_PRTY_TBS_ASM_DISKGROUP, l_dg);

   EXCEPTION
      when err_api.e_assert_illegal_name then
         err_api.log_and_raise(sqlcode, err_api.C_ASSERT_ILLEGAL_NAME, l_scope, l_params);
      when err_api.e_illegal_diskgroup then
         err_api.log_and_raise(sqlcode, err_api.C_ILLEGAL_DISKGROUP, l_scope, l_params);
      when others then
         err_api.log(sqlcode, sqlerrm, l_scope, l_params);
         raise;
   END setTbsAsmDiskgroup;

END um_config;
/