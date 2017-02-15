CREATE TABLE spy_builtin_type_lengths
(data_type VARCHAR2(30) NOT NULL
,data_length INT NOT NULL
,constraint spy_builtin_type_lengths_pk PRIMARY KEY (data_type)
);

INSERT INTO spy_builtin_type_lengths VALUES ('NUMBER',38);
INSERT INTO spy_builtin_type_lengths VALUES ('CHAR',2000);
INSERT INTO spy_builtin_type_lengths VALUES ('CHAR VARYING',4000);
INSERT INTO spy_builtin_type_lengths VALUES ('VARCHAR',4000);
INSERT INTO spy_builtin_type_lengths VALUES ('VARCHAR2',4000);
