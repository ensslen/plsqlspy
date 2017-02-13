-- Consider chaging to GLOBAL TEMPORARY TABLE if performance is poor.
CREATE TABLE spy_runs
(run_id INT
,procedure_id INT NOT NULL
-- WITH LOCAL TIME ZONE vastly simplifies the code for the interval, don't really care about Time zone
,start_timestamp TIMESTAMP with local time zone
,duration INTERVAL DAY TO SECOND
,constraint spy_runs_pk primary key (run_id)
,constraint spy_runs_procedure_fk foreign key (procedure_id) references spy_procedures (procedure_id)
);

CREATE SEQUENCE spy_runs_seq;