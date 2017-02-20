/* The schema making the spies needs these grants directly, not through a role */
BEGIN
  EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE TO '||USER;
  EXECUTE IMMEDIATE 'GRANT CREATE SYNONYM TO '||USER;
END;
/

@@spy_objects.sql
@@spy_procedures.sql
@@spy_parameters.sql
@@spy_runs.sql
@@spy_binds.sql
@@spy_builtin_type_lengths.sql

@@spy_invocations.sql

@@spy_record.sql
@@spy_record_pkb.sql

@@spy_deploy.sql
@@spy_deploy_pkb.sql

