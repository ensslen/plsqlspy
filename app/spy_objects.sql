CREATE TABLE spy_objects
(object_id INT
,object_name VARCHAR2(30) NOT NULL
,object_type VARCHAR2(30) NOT NULL
,raw_object_name VARCHAR2(30) NOT NULL
,spy_object_name VARCHAR2(30) NOT NULL
,constraint spy_objects_pk primary key (object_id)
,constraint spy_objects_uk unique (object_name) 
);

COMMENT ON TABLE spy_objects IS 'Schema level object being spied upon: a package, stored procedure, or function';  

CREATE SEQUENCE spy_objects_seq;