CREATE OR REPLACE PACKAGE spy_record AS
/* This package keeps the evidence gathered by the spy_procedures.
  You probably don't want to call this package directly.  
  Use SPY_DEPLOY.SET_UP to generate spies that call this package \
*/
    /** Called records that a spy procedure was called */ 
	PROCEDURE called (procedure_id IN INT, run_id OUT INT);
    /** Put records the parameters passing through the spies */
	PROCEDURE put 
		(run_id INT
		,parameter_id INT
		,bound_value VARCHAR2);
    /** Done records that a spy procedure exitted normally */
	PROCEDURE done (run_id INT);
    /** spy_record keeps all of the data gathered in package variables
     for performance and locking (e.g. ORA-06519) reasons.  Persist writes 
     this data into tables.
     @throws ORA-00001 Calling persist more than once in a session without calling clean in between always throws*/
    PROCEDURE persist;
    /** Clean deletes all data in the package variables */
    PROCEDURE clean;
END spy_record;

