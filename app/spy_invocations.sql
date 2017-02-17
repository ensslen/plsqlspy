CREATE OR REPLACE VIEW spy_invocations AS
    SELECT procedure_id 
        ,listagg( CASE WHEN parameter_position > 0 THEN parameter_name||' '||in_out||' '||sp.data_type ELSE NULL END,',') WITHIN GROUP (ORDER BY parameter_position) declaration
        ,listagg(CASE in_out WHEN 
        'OUT' THEN '' ELSE 'spy_record.put(run_id => run_id, parameter_id =>'|| parameter_id||', bound_value =>'||parameter_name||');' END, chr(10)) 
            WITHIN GROUP (ORDER BY parameter_position) inputs
        ,listagg(CASE in_out WHEN 'IN' THEN '' ELSE 'spy_record.put(run_id => run_id, parameter_id =>'|| parameter_id||', bound_value =>'||parameter_name||');' END, chr(10)) 
            WITHIN GROUP (ORDER BY parameter_position) outputs
        ,listagg(CASE WHEN parameter_position > 0 THEN parameter_name||' => '|| parameter_name ELSE NULL END,',') WITHIN GROUP (ORDER BY parameter_position) invocation
        ,max(CASE parameter_position WHEN 0 THEN sp.data_type ELSE NULL END) return_type
        ,max(CASE parameter_position WHEN 0 THEN btl.data_length ELSE NULL END) return_length
    FROM spy_parameters sp
    LEFT OUTER JOIN spy_builtin_type_lengths btl ON sp.data_type = btl.data_type 
    GROUP BY procedure_id;



