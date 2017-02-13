CREATE TABLE spy_procedures
(procedure_id INT
,procedure_name VARCHAR2(30) NOT NULL
,procedure_type VARCHAR2(30) NOT NULL
,raw_procedure_name VARCHAR2(30) NOT NULL
,spy_procedure_name VARCHAR2(30) NOT NULL
,constraint spy_procedures_pk primary key (procedure_id)
,constraint spy_procedures_uk unique (procedure_name) 
);

CREATE SEQUENCE spy_procedures_seq;
