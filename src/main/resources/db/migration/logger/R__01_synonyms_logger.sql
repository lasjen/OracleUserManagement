--whenever sqlerror exit sql.sqlcode

create or replace synonym logger                    for LOGRDATA.logger;
create or replace synonym logger_logs               for LOGRDATA.logger_logs;
create or replace synonym logger_logs_apex_items    for LOGRDATA.logger_logs_apex_items;
create or replace synonym logger_prefs              for LOGRDATA.logger_prefs;
create or replace synonym logger_prefs_by_client_id for LOGRDATA.logger_prefs_by_client_id;
create or replace synonym logger_logs_5_min         for LOGRDATA.logger_logs_5_min;
create or replace synonym logger_logs_60_min        for LOGRDATA.logger_logs_60_min;
create or replace synonym logger_logs_terse         for LOGRDATA.logger_logs_terse;