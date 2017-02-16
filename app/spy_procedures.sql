CREATE TABLE spy_procedures
(object_id INT NOT NULL
,procedure_id INT
,procedure_name VARCHAR2(30) NOT NULL
,procedure_type VARCHAR2(30) NOT NULL
,constraint spy_procedures_pk primary key (procedure_id)
,constraint spy_procedures_uk unique (object_id, procedure_name)
,constraint spy_procedures_object_fk foreign key (object_id) REFERENCES spy_objects (object_id)
);

COMMENT ON TABLE spy_procedures IS 'A procedure or function that can be called. 1:1 with spy_objects for standalone procedures, many for packages';  

CREATE SEQUENCE spy_procedures_seq;


