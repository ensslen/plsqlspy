-- Consider changing to GLOBAL TEMPORARY TABLE if performance is poor
CREATE TABLE spy_binds
(run_id INT NOT NULL
,parameter_id INT NOT NULL
,bound_value VARCHAR2(1000)
,constraint spy_binds_pk primary key (run_id, parameter_id)
,constraint spy_binds_parameter_fk foreign key (parameter_id) references spy_parameters (parameter_id)
,constraint spy_binds_run_fk foreign key (run_id) references spy_runs (run_id)
);
