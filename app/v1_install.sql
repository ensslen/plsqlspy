/* The schema making the spies needs these grants directly, not through a role */
GRANT CREATE PROCEDURE TO TRICKS_ADMIN;
GRANT CREATE SYNONYM TO TRICKS_ADMIN;

@@spy_procedures.sql
@@spy_parameters.sql
@@spy_runs.sql
@@spy_binds.sql

@@spy_record.sql
@@spy_record_pkb.sql

@@spy_deploy.sql
@@spy_deploy_pkb.sql

