CREATE OR REPLACE PACKAGE spy_deploy AS
    SUBTYPE ORA_NAME IS VARCHAR2(30) NOT NULL;
    
    SPY_PREFIX CONSTANT ORA_NAME := 'SPY__';
    RAW_PREFIX CONSTANT ORA_NAME := 'RAW__';
    
	PROCEDURE set_up (procedure_name ORA_NAME, object_type ORA_NAME);
	PROCEDURE tear_down (procedure_name ORA_NAME);
    
    FUNCTION generate_rename_ddl(old_name ORA_NAME, new_name ORA_NAME) RETURN VARCHAR2;
    
    FUNCTION generate_spy(spy spy_procedures%rowtype) RETURN VARCHAR2;
    
END spy_deploy;

