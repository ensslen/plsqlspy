CREATE TABLE spy_parameters
(parameter_id INT
,procedure_id INT NOT NULL
,parameter_name VARCHAR2(30) NOT NULL
,parameter_datatype VARCHAR2(30) NOT NULL
,spy_procedure_name VARCHAR2(30) NOT NULL
,constraint spy_parameters_pk primary key (parameter_id)
,constraint spy_parameters_uk unique (procedure_id, parameter_name)
,constraint spy_parameters_procedure_fk foreign key (procedure_id) references spy_procedures (procedure_id)
);

CREATE SEQUENCE spy_parameters_seq;

CREATE OR REPLACE TRIGGER spy_parameters_bir
BEFORE INSERT ON spy_parameters 
FOR EACH ROW

BEGIN
  SELECT spy_parameters_seq.NEXTVAL
  INTO   :new.parameter_id
  FROM   dual;
END;
/