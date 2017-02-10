CREATE OR REPLACE PACKAGE spy_record AS
	PROCEDURE called (procedure_id IN INT, run_id OUT INT);
	PROCEDURE put 
		(run_id INT
		,parameter_id INT
		,bound_value VARCHAR2);
	PROCEDURE done (run_id INT);
END spy_record;

