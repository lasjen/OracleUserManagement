   ----------------------------------------------------------------------------------------
-- Table: UM_PROPERTIES (UMPRO)
----------------------------------------------------------------------------------------
create sequence um_properties_seq start with 1 increment by 1 cache 20;

create table um_properties (
   id             number(19,0)         default um_properties_seq.nextval,
   name           varchar2(50 char)    constraint umpro_name_nn NOT NULL,
   value          varchar2(100 char)   constraint umpro_value_nn NOT NULL,
   description    varchar2(400 char)
);

create unique index um_properties_pk on um_properties(id);
create unique index umpro_name_uk on um_properties(name);

alter table um_properties add (
   constraint um_properties_pk primary key (id),
   constraint umpro_name_uk          unique (name)
);

insert into um_properties(name, value, description) values ('tbsAsmUse',          'TRUE',                                'Are ASM in use (TRUE or FALSE)');
insert into um_properties(name, value, description) values ('tbsAsmDiskGroup',    '+DATAC2',                             'Name of the ASM disk group in use');
insert into um_properties(name, value, description) values ('tbsDirectory',       '/u01/app/oracle/oradata/cdb12/orcl',  'Directory path for datafiles');
insert into um_properties(name, value, description) values ('tbsNameSuffix',      '_DATA',                               'Suffix for tablespace names');
insert into um_properties(name, value, description) values ('tbsDefault',         'USERS',                               'Default tablespace for users without DDL privilege');
insert into um_properties(name, value, description) values ('tbsDropWithOwner',   'FALSE',                               'Should TBS be dropped when dropping owner');

insert into um_properties(name, value, description) values ('userAppCreate',      'FALSE',                               'Should application user be created (TRUE or FALSE)');
--insert into um_properties(name, value, description) values ('userAppSuffix',      '_A',                                  'Suffix for application user');
insert into um_properties(name, value, description) values ('userOwnerTbsSize',   '1G',                                  'Initial size for owner tablespace (default M)');
insert into um_properties(name, value, description) values ('userOwnerUseSuffix', 'FALSE',                               'Should owner name use postfix C_POSTFIX_USER_OWNER');
insert into um_properties(name, value, description) values ('userOwnerDrop',      'FALSE',                               'Should owner schema be dropped when using UM_DROP package');

insert into um_properties(name, value, description) values ('userBatchCreate',    'FALSE',                               'Should batch user be created (TRUE or FALSE)');
--insert into um_properties(name, value, description) values ('userBatchSuffix',    '_B',                                  'Suffix for batch user');
insert into um_properties(name, value, description) values ('userBatchTbsSize',   '100M',                                'Initial size for batch tablespace (default M)');
insert into um_properties(name, value, description) values ('userBatchReadWrite', 'TRUE',                                'Should batch user have RW role (TRUE or FALSE)');
insert into um_properties(name, value, description) values ('userBatchDdl',       'TRUE',                                'Should batch user have DDL role (TRUE or FALSE)');

insert into um_properties(name, value, description) values ('rolePassword',       'dUzdgBGby6J7E5HN',                    'Should batch user have DDL role (TRUE or FALSE)');
commit;

-- ---------------------------------------------------------------------------------------
-- Table: um_OPERATORS (UMOPR)
-- ---------------------------------------------------------------------------------------
create sequence um_operators_seq start with 1 increment by 1 cache 20;

create table um_operators (
   id             number(19,0)   default um_operators_seq.nextval,
   userid         varchar2(30)   CONSTRAINT umopr_userid_nn NOT NULL,
   fullname       varchar2(100)  CONSTRAINT umopr_fullname_nn NOT NULL,
   ro             number(1),
   rw             number(1),
   ddl            number(1),
   description    varchar2(400)
);

comment on table um_properties is 'Shortname: UMOPR';

create unique index umopr_pk on um_operators(id);
create unique index umopr_userid_uk on um_operators(userid);

alter table um_operators add (
   constraint umopr_pk           primary key (id),
   constraint umopr_one_role_ch  check (ro+rw=1)
);

-- ---------------------------------------------------------------------------------------
-- Table: UM_USER_TYPES (UMUSRT)
-- ---------------------------------------------------------------------------------------
create table um_user_types (
   typeid         varchar2(3),   -- PK
   category       varchar2(20)   CONSTRAINT umusrt_category_nn NOT NULL,
   description    varchar2(100)  CONSTRAINT umusrt_description_nn NOT NULL
);

create unique index umusrt_pk on um_user_types(typeid);

alter table um_user_types add (
   constraint umusrt_pk primary key (typeid) using index umusrt_pk
);

insert into um_user_types values ('OWN', 'APPLICATION', 'Data owner');
insert into um_user_types values ('APP', 'APPLICATION', 'Application login usr');
insert into um_user_types values ('SUP', 'APPLICATION', 'Support user');
insert into um_user_types values ('BTC', 'APPLICATION', 'Batch user');
insert into um_user_types values ('OPR', 'PERSONAL',    'Personal Operator account');
commit;

-- ---------------------------------------------------------------------------------------
-- Table: UM_USER_TYPES (UMUSR)
-- ---------------------------------------------------------------------------------------
create table um_users (
   username       varchar2(30),     -- PK
   description    varchar2(100),
   appl_name      varchar2(30),
   typeid         varchar2(3)       CONSTRAINT umusr_typeid_nn NOT NULL,
   ro             number(1)         CONSTRAINT umusr_ro_nn NOT NULL,
   rw             number(1)         CONSTRAINT umusr_rw_nn NOT NULL,
   ddl            number(1)         CONSTRAINT umusr_ddl_nn NOT NULL
);

create unique index um_users_pk on um_users(username);

alter table um_users add (
   constraint um_users_pk primary key (username) using index um_users_pk,
   constraint umusr_umusrt_fk foreign key (typeid) references um_user_types(typeid),
   constraint umusr_one_role_ch check (ro+rw=1)
);
