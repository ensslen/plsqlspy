CREATE OR REPLACE PACKAGE BODY spy_record AS

	FUNCTION get_next_run_id RETURN INT AS
	  id INT;
    BEGIN
      SELECT spy_runs_seq.NEXTVAL
      INTO   id
      FROM   dual;
      RETURN id;
    END get_next_run_id;

	PROCEDURE called (procedure_id IN INT, run_id OUT INT) AS
	BEGIN
	  run_id :=  get_next_run_id();
	  INSERT INTO spy_runs (procedure_id, run_id, start_timestamp)
	  	VALUES (procedure_id, run_id, SYSTIMESTAMP);
	END called;

	PROCEDURE put 
		(run_id INT
		,parameter_id INT
		,bound_value VARCHAR2) AS
	BEGIN
		INSERT INTO spy_binds (run_id, parameter_id, bound_value)
			VALUES (run_id, parameter_id, bound_value);
	END put;

	PROCEDURE done (run_id INT) AS
	BEGIN
	  UPDATE spy_runs
	  SET duration = SYSTIMESTAMP - start_timestamp
	  WHERE run_id = run_id;
	END done;
END spy_record;

