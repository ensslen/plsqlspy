CREATE OR REPLACE PACKAGE BODY spy_deploy AS
	MAX_NAME_LENGTH CONSTANT INT := 30;

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
    
    PROCEDURE record_spy (proc_name ORA_NAME
        ,raw_name ORA_NAME
        ,spy_name ORA_NAME
        ,spy_id OUT INT) AS

    BEGIN
      SELECT procedure_id
      INTO   spy_id
      FROM   spy_procedures
      WHERE procedure_name = proc_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN

          SELECT spy_procedures_seq.NEXTVAL
          INTO   spy_id
          FROM   dual;
    
          INSERT INTO spy_procedures 
          (procedure_id, procedure_name, raw_procedure_name, spy_procedure_name)
          VALUES (spy_id, proc_name, raw_name, spy_name);

    END record_spy;

    FUNCTION get_source(object_name ora_name) RETURN VARCHAR2 AS
      src VARCHAR2(32767);
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


    PROCEDURE rename_procedure(old_name ora_name, new_name ora_name) AS
      procedure_source VARCHAR2(32767);
    BEGIN
      procedure_source := generate_rename_ddl(old_name => old_name,new_name => new_name);
      dbms_output.put_line(procedure_source);
      EXECUTE IMMEDIATE procedure_source;
      --TODO: start passing an object pointer type and use the type in the drop.
      drop_procedure(proc_name =>old_name, proc_type => 'PROCEDURE');
    END rename_procedure;

    /* growth plan
    v0.1 renames and creates synonym
    v0.2 creates empty spy
    v0.3 creates spy 
    */
	PROCEDURE set_up (procedure_name ORA_NAME) AS
      raw_name VARCHAR2(30);
      spy_name VARCHAR2(30);
      spy_id INT;
	BEGIN
      assert(check_exists(name => procedure_name));
	  raw_name := make_new_name(base_name => procedure_name, prefix => raw_prefix);
	  spy_name := make_new_name(base_name => procedure_name, prefix => spy_prefix);
      record_spy(proc_name => procedure_name
        ,raw_name => raw_name
        ,spy_name =>spy_name
        ,spy_id => spy_id);
      rename_procedure(old_name => procedure_name, new_name => raw_name);
      create_synonym(synonym_name => procedure_name, object_name => raw_name);
      --todo: create_spy_procedure(spy_name => spy_name, raw_name => raw_name);
	END set_up;
	
    FUNCTION get_spy(proc_name ora_name) RETURN spy_procedures%rowtype AS
      spy spy_procedures%rowtype;
    BEGIN
      SELECT * 
      INTO spy
      FROM spy_procedures
      WHERE procedure_name = proc_name;
      
      RETURN spy;
    END get_spy;
    
	PROCEDURE tear_down (procedure_name ORA_NAME) AS
	  spy spy_procedures%rowtype;
    BEGIN
      assert(check_exists(name => procedure_name));
	  spy := get_spy(proc_name => procedure_name);
      drop_synonym(synonym_name => spy.procedure_name);
      rename_procedure(old_name => spy.raw_procedure_name, new_name => spy.procedure_name);
	END tear_down;
	
END spy_deploy;