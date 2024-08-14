-- ---------------------------------------------------------------------------------------
-- Grant privileges for new objects
-- ---------------------------------------------------------------------------------------
exec user_grant.grantToRoles;

-- ---------------------------------------------------------------------------------------
-- Run Unit-Tests
-- ---------------------------------------------------------------------------------------
--BEGIN
--   ut.run('ut_usr_mgmt_config');
--   ut.run('ut_usr_mgmt_util');
--END;
--/

-- ---------------------------------------------------------------------------------------
-- Initialize USR_MGMT pacakage
-- ---------------------------------------------------------------------------------------
--begin
--   usr_mgmt.packageInitialization;
--exception when others then
--   logger.log_error('PackageInit: Initialization of USR_MGMT package failed');
--end;
--/
--
--grant execute on usr_mgmt to mgmt_rw;
