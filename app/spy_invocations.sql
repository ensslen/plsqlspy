CREATE OR REPLACE VIEW spy_invocations AS
    SELECT procedure_id 
        ,'('|| listagg(parameter_name||' '||in_out||' '||data_type,',') WITHIN GROUP (ORDER BY parameter_position) ||')' declaration
        ,listagg(CASE in_out WHEN 'OUT' THEN '' ELSE 'spy_record.put(run_id => run_id, parameter_id =>'|| parameter_id||', bound_value =>'||parameter_name||');' END, chr(10)) 
            WITHIN GROUP (ORDER BY parameter_position) inputs
        ,listagg(CASE in_out WHEN 'IN' THEN '' ELSE 'spy_record.put(run_id => run_id, parameter_id =>'|| parameter_id||', bound_value =>'||parameter_name||');' END, chr(10)) 
            WITHIN GROUP (ORDER BY parameter_position) outputs
        ,listagg(parameter_name||' => '|| parameter_name,',') WITHIN GROUP (ORDER BY parameter_position) invocation
    FROM spy_parameters 
    GROUP BY procedure_id;



