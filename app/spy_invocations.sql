CREATE OR REPLACE VIEW spy_invocations AS
        SELECT procedure_id 
            ,'('|| listagg(parameter_name||' '||in_out||' '||data_type,',') WITHIN GROUP (ORDER BY parameter_position) ||')' declaration
            ,listagg('spy_record.put(run_id => run_id, parameter_id =>'|| parameter_id||', bound_value =>'||parameter_name||');', chr(10)) WITHIN GROUP (ORDER BY parameter_position) spying
            ,listagg(parameter_name||' => '|| parameter_name,',') WITHIN GROUP (ORDER BY parameter_position) invocation
        FROM spy_parameters 
        GROUP BY procedure_id;



