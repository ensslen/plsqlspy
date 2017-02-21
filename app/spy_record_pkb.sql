CREATE OR REPLACE PACKAGE BODY spy_record AS
  TYPE run_array  IS TABLE OF spy_runs%rowtype  INDEX BY PLS_INTEGER;
  TYPE bind_array IS TABLE OF spy_binds%rowtype INDEX BY PLS_INTEGER;

  pkg_runs  run_array;
  pkg_binds bind_array;

	FUNCTION get_next_run_id RETURN INT AS
	  id INT;
    BEGIN
      SELECT spy_runs_seq.NEXTVAL
      INTO   id
      FROM   dual;
      RETURN id;
    END get_next_run_id;

	PROCEDURE called (procedure_id IN INT, run_id OUT INT) AS
      this_call spy_runs%rowtype;
	BEGIN
	  run_id :=  get_next_run_id();
      this_call.run_id := run_id;
      this_call.procedure_id := procedure_id;
      this_call.start_timestamp := systimestamp;
      pkg_runs(run_id) := this_call;
	END called;

	PROCEDURE put 
		(run_id INT
		,parameter_id INT
		,bound_value VARCHAR2) AS
      this_bind spy_binds%rowtype;
	BEGIN
      this_bind.run_id := run_id;
      this_bind.parameter_id := parameter_id;
      this_bind.bound_value := bound_value;
      pkg_binds(pkg_binds.count +1) := this_bind;
	END put;

	PROCEDURE done (run_id INT) AS
	BEGIN
      pkg_runs(run_id).duration := SYSTIMESTAMP - pkg_runs(run_id).start_timestamp;
	END done;
    
    procedure persist_runs AS
     i PLS_INTEGER;
    BEGIN
      /* run_id is used as an intelligent key (to make the procedure "done" simple) 
       which means that this can't be a BULK BIND "FORALL" */
       i := pkg_runs.FIRST;
       WHILE i IS NOT NULL LOOP
    	  INSERT INTO spy_runs (procedure_id, run_id, start_timestamp, duration)
	  	    VALUES (pkg_runs(i).procedure_id
                   ,pkg_runs(i).run_id
                   ,pkg_runs(i).start_timestamp
                   ,pkg_runs(i).duration);
         i := pkg_runs.NEXT(i);
       END LOOP; 
    END persist_runs;
    
    PROCEDURE persist_binds AS
    BEGIN
      FORALL i IN pkg_binds.first..pkg_binds.last
       INSERT INTO spy_binds (run_id, parameter_id, bound_value)
			VALUES (pkg_binds(i).run_id
                   ,pkg_binds(i).parameter_id
                   ,pkg_binds(i).bound_value);
    END persist_binds;
    
    
    PROCEDURE persist AS
    BEGIN
      persist_runs;
      persist_binds; 
    END persist;
    
    PROCEDURE clean AS
    BEGIN
      pkg_runs.delete;
      pkg_binds.delete;
    END clean;
    
END spy_record;

