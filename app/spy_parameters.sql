CREATE TABLE spy_parameters
(parameter_id INT
,procedure_id INT NOT NULL
,parameter_position INT NOT NULL
,parameter_name VARCHAR2(30) NOT NULL
,data_type VARCHAR2(30) NOT NULL
,in_out VARCHAR2(5) NOT NULL 
,constraint spy_parameters_pk primary key (parameter_id)
,constraint spy_parameters_uk unique (procedure_id, parameter_name)
,constraint spy_parameters_position_uk unique (procedure_id, parameter_position)
,constraint spy_parameters_procedure_fk foreign key (procedure_id) references spy_procedures (procedure_id)
);

CREATE SEQUENCE spy_parameters_seq;
