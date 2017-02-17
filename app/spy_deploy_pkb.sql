create or replace PACKAGE BODY spy_deploy AS
	MAX_NAME_LENGTH CONSTANT INT := 30;
    SUBTYPE VARCHAR_MAX IS VARCHAR2(32767); 

   Procedure Assert (invariant BOOLEAN
   , message In Varchar2 default 'Assertion Failed') Is
   Begin
      If (not invariant) Then
        Raise_Application_Error(-20001, message);
      End If;
   End Assert;

    -- Might need a version that checks object_types too
	FUNCTION check_exists (name ORA_NAME) RETURN BOOLEAN AS
	  v_exists INT;
	BEGIN
		SELECT count(*)
		INTO v_exists
		FROM user_objects
		WHERE object_name = name;

		RETURN (v_exists = 1);
	END check_exists;

	FUNCTION make_new_name (base_name ORA_NAME, prefix ORA_NAME) RETURN ORA_NAME AS
	  candidate ORA_NAME := 'SPY_DEPLOY'; -- initialise with a name known to exist
	BEGIN
	  IF length(prefix||base_name) <= MAX_NAME_LENGTH THEN
	    candidate := prefix || base_name;
	  END IF;
	  WHILE check_exists(name => candidate) LOOP
        /* Build a name from the template
        , the seconds and millseconds of the current time
        , and whatever of the name fits */
	    candidate := prefix 
            || substr(base_name,1,MAX_NAME_LENGTH - length(prefix) - 8)
            || extract(second from systimestamp)* 1E6; 
	  END LOOP;
	  RETURN candidate;
	END make_new_name;

    PROCEDURE create_synonym (synonym_name ORA_NAME
        , object_name ORA_NAME) AS
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SYNONYM "'|| synonym_name ||'" FOR "'|| object_name ||'"';
    END create_synonym;

    PROCEDURE drop_synonym (synonym_name ORA_NAME) AS
    BEGIN
      EXECUTE IMMEDIATE 'DROP SYNONYM "'|| synonym_name ||'"';
    END drop_synonym;

    PROCEDURE track_arguments(spy IN spy_objects%ROWTYPE, spy_proc IN spy_procedures%ROWTYPE) AS
    BEGIN
      MERGE INTO spy_parameters t
        USING (
            /* The RETURN value of a function has no name. */ 
            SELECT coalesce(argument_name,'RETURN_VALUE') argument_name
                ,in_out
                ,pls_type data_type
                ,position
            FROM user_arguments
            WHERE object_name = spy_proc.procedure_name
            AND (package_name = spy.object_name OR spy.object_type <> 'PACKAGE')
        ) s
        ON (t.parameter_name = s.argument_name
            AND t.procedure_id = spy_proc.procedure_id)
        WHEN NOT MATCHED THEN INSERT
        (
             parameter_id
            ,procedure_id
            ,parameter_position
            ,parameter_name
            ,data_type
            ,in_out
        ) VALUES (
            spy_parameters_seq.nextval
            ,spy_proc.procedure_id
            ,s.position
            ,s.argument_name
            ,s.data_type
            ,s.in_out
        );
   END track_arguments;

   PROCEDURE track_procedure (spy IN spy_objects%rowtype, spy_proc IN OUT spy_procedures%rowtype) AS
        
    BEGIN
      SELECT *
      INTO   spy_proc
      FROM   spy_procedures
      WHERE procedure_name = spy_proc.procedure_name
      AND   object_id = spy_proc.object_id;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN

          SELECT spy_procedures_seq.NEXTVAL
          INTO   spy_proc.procedure_id
          FROM   dual;

          INSERT INTO spy_procedures VALUES spy_proc;
   
         track_arguments(spy => spy, spy_proc => spy_proc);

    END track_procedure;
   

   PROCEDURE track_procedures (spy IN spy_objects%ROWTYPE) AS
        spy_proc spy_procedures%rowtype;
    BEGIN
        spy_proc.object_id := spy.object_id;
        CASE spy.object_type 
            WHEN 'PACKAGE' THEN
                FOR subprocedure IN (
                    SELECT name
                        ,type 
                    FROM user_identifiers ui
                    WHERE type in ('PROCEDURE', 'FUNCTION')
                    AND object_type = 'PACKAGE'
                    AND object_name = spy.object_name
                    ORDER BY usage_id
                ) LOOP
                    spy_proc.procedure_name := subprocedure.name;
                    spy_proc.procedure_type := subprocedure.type;
                    track_procedure(spy => spy, spy_proc => spy_proc);
                END LOOP;
            ELSE
                spy_proc.procedure_name := spy.object_name;
                spy_proc.procedure_type := spy.object_type;
                track_procedure(spy => spy, spy_proc => spy_proc);
        END CASE;
    END track_procedures;
    

    PROCEDURE track_spy (spy IN OUT spy_objects%ROWTYPE) AS

    BEGIN
      SELECT *
      INTO   spy
      FROM   spy_objects
      WHERE object_name = spy.object_name;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN

          SELECT spy_objects_seq.NEXTVAL
          INTO   spy.object_id
          FROM   dual;

          INSERT INTO spy_objects VALUES spy;
   
         track_procedures(spy => spy);

    END track_spy;
    

    FUNCTION get_source(object_name ora_name) RETURN VARCHAR2 AS
      src VARCHAR_MAX;
    BEGIN
      SELECT listagg(text,CHR(10)) WITHIN GROUP (ORDER BY line) 
      INTO src
      FROM user_source
      WHERE name = object_name;
      RETURN src;
    END get_source;

    FUNCTION replace_word(subject VARCHAR2, find VARCHAR2, replace VARCHAR2) RETURN VARCHAR2 AS
      whole_string CONSTANT INT := 1;
      replace_all CONSTANT INT := 0;
      case_insensitive CONSTANT CHAR(1) := 'i';
      match_expression   VARCHAR2(512);
      replace_expression VARCHAR2(512);
    BEGIN
        /* This expression matches "find" when immediately proceded and followed by whitespace or punctuation or newlines
        The () are match groups. ^ means start of line, $ end of line, and | means or.
        Note: that this won't work if regex characters are in "find". Particularly ORA-00955 is triggered later if there are $ in "find"
        Note: that Oracle does not implment "\b" so if the subject includes find repeatedly seperated by a single character it is only replaced every other time.
        See: http://stackoverflow.com/questions/7567700/oracle-regexp-like-and-word-boundaries */
      match_expression := '(^|[[:space:]]|[[:punct:]])'|| find ||'($|[[:space:]]|[[:punct:]])';

      /* \1 is the first match group from match_expression, and \2 the second. So this returns exactly the characters found */
      replace_expression := '\1'||replace||'\2';

      return regexp_replace(srcstr => subject
        ,pattern => match_expression
        ,replacestr => replace_expression
        ,position => whole_string
        ,occurrence => replace_all
        ,modifier => case_insensitive);
    END replace_word;


    FUNCTION generate_rename_ddl(old_name ora_name, new_name ora_name) RETURN VARCHAR2 AS
    BEGIN
      RETURN 'CREATE '|| replace_word(subject => get_source(object_name => old_name)
        ,find => old_name
        ,replace => new_name);
     END generate_rename_ddl;

    PROCEDURE drop_procedure(proc_name ora_name, proc_type ora_name) AS
    BEGIN
      EXECUTE IMMEDIATE 'DROP '||proc_type||' '|| proc_name;
    END drop_procedure;


    PROCEDURE rename_procedure(old_name ora_name, new_name ora_name, object_type ora_name) AS
      procedure_source VARCHAR_MAX;
    BEGIN
      procedure_source := generate_rename_ddl(old_name => old_name,new_name => new_name);
      EXECUTE IMMEDIATE procedure_source;
      drop_procedure(proc_name =>old_name, proc_type => object_type);
    END rename_procedure;

    FUNCTION generate_spy_procs (spy spy_objects%ROWTYPE) RETURN VARCHAR2 AS
      spy_source    VARCHAR_MAX;
      subprocedure_name VARCHAR2(30);
    BEGIN
    
      FOR spy_proc IN (
        SELECT p.procedure_id 
            ,p.procedure_name
            ,p.procedure_type
            ,return_type
            ,return_length
            /* procedures with no parameters have no row = null for these */
            ,coalesce(i.declaration,'') declaration
            ,coalesce(i.inputs,'') inputs
            ,coalesce(i.invocation,'') invocation
            ,coalesce(i.outputs,'') outputs
        FROM spy_procedures p
        LEFT OUTER JOIN spy_invocations i ON p.procedure_id = i.procedure_id
        WHERE p.object_id = spy.object_id
      ) LOOP

          IF spy.object_type = 'PACKAGE' THEN
            subprocedure_name := spy_proc.procedure_name;
          ELSE
            subprocedure_name := spy.spy_object_name;
          END IF;
    
          CASE spy_proc.procedure_type 
            WHEN  'FUNCTION' THEN
              spy_source := spy_source ||' FUNCTION '|| subprocedure_name || spy_proc.declaration||' RETURN '||spy_proc.return_type||' AS
                PRAGMA AUTONOMOUS_TRANSACTION;
                return_value '||spy_proc.return_type||coalesce('('||spy_proc.return_length||')','')||';
                run_id INT; 
              BEGIN 
                /* This function was generated by plsqlspy at '|| to_char(sysdate,'YYYY-MON-DD HH24:MI') ||'
                   Please edit the generator, plsqlspy, if changes to this function are desired. */
                spy_record.called('||spy_proc.procedure_id||', run_id);
                '|| spy_proc.inputs || '
                SELECT '|| spy.raw_object_name ||'('||spy_proc.invocation||') INTO return_value FROM dual;
                '|| spy_proc.outputs || '
                spy_record.done(run_Id => run_id);
                COMMIT; /* Required to avoid ORA-06519: active autonomous transaction detected and rolled back */
                RETURN return_value;
          END '|| subprocedure_name||';'||chr(10);
            
            WHEN 'PROCEDURE' THEN
              spy_source := ' PROCEDURE '|| subprocedure_name || spy_proc.declaration||' AS
                run_id INT; 
              BEGIN 
                /* This procedure was generated by plsqlspy at '|| to_char(sysdate,'YYYY-MON-DD HH24:MI') ||'
                   Please edit the generator, plsqlspy, if changes to this function are desired. */
                spy_record.called('||spy_proc.procedure_id||', run_id);
                '|| spy_proc.inputs || '
                '|| spy.raw_object_name ||'('||spy_proc.invocation||');
                '|| spy_proc.outputs || '
                spy_record.done(run_Id => run_id);
              END '|| subprocedure_name||';'||chr(10);
          END CASE;
      
      END LOOP;
      
      RETURN spy_source;
    END generate_spy_procs;


    FUNCTION generate_spy_package_spec (spy spy_objects%ROWTYPE) RETURN VARCHAR2 AS
     spy_source    VARCHAR_MAX;
    BEGIN
        RETURN 'UNIMPLEMENTED';
    END generate_spy_package_spec;

    PROCEDURE create_spy (spy spy_objects%ROWTYPE) AS
      spy_source VARCHAR_MAX;
    BEGIN
      IF spy.object_type = 'PACKAGE' THEN
        NULL;
      ELSE /* Not a package */
          spy_source := 'CREATE '|| generate_spy_procs (spy => spy);
          execute immediate spy_source;        
      END IF;
    END create_spy;


	PROCEDURE set_up (procedure_name ora_name, object_type ora_name) AS
      spy spy_objects%ROWTYPE;
	BEGIN
      assert(check_exists(name => procedure_name));
	  spy.object_name := procedure_name;
      spy.object_type := object_type;
      spy.raw_object_name := make_new_name(base_name => procedure_name, prefix => raw_prefix);
	  spy.spy_object_name := make_new_name(base_name => procedure_name, prefix => spy_prefix);
      track_spy(spy => spy);
      rename_procedure(old_name => procedure_name, new_name => spy.raw_object_name, object_type => spy.object_type);
      create_spy(spy => spy);
      create_synonym(synonym_name => procedure_name, object_name => spy.spy_object_name);
	END set_up;

    FUNCTION get_spy(proc_name ora_name) RETURN spy_objects%ROWTYPE AS
      spy spy_objects%ROWTYPE;
    BEGIN
      SELECT * 
      INTO spy
      FROM spy_objects
      WHERE object_name = proc_name;

      RETURN spy;
    END get_spy;

	PROCEDURE tear_down (procedure_name ORA_NAME) AS
	  spy spy_objects%ROWTYPE;
    BEGIN
      assert(check_exists(name => procedure_name));
	  spy := get_spy(proc_name => procedure_name);
      drop_procedure(proc_name => spy.spy_object_name, proc_type => spy.object_type );
      drop_synonym(synonym_name => spy.object_name);
      rename_procedure(old_name => spy.raw_object_name, new_name => spy.object_name,object_type => spy.object_type);
	END tear_down;

END spy_deploy;