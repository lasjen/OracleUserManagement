-- ------------------------------------------------------
-- Type UM_TABLECOPY_xx
-- ------------------------------------------------------
CREATE OR REPLACE TYPE  um_tablecopy_ot FORCE AS OBJECT (
   table_name     varchar2(30),
   include_data   varchar2(1) 
);
/

CREATE OR REPLACE TYPE  um_tablecopy_ct AS TABLE OF um_tablecopy_ot;
/

-- ------------------------------------------------------
-- Type UM_BANKID_NT
-- ------------------------------------------------------
CREATE OR REPLACE TYPE um_bankid_nt IS TABLE OF varchar2(8);
/