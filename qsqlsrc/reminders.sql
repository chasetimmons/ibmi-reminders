-- create reminders table
--  timestamp is updated when changed

create or replace table cmtlib.reminders
(
 rem_nbr int check (rem_nbr > 0) not null generated always as identity,
 rem_dat date not null,
 rem_tim time not null,
 rem_txt char(50) not null,
 rem_us1 char(10) not null,
 rem_us2 char(10),
 rem_eml char(1),
 rem_com char(1)
) rcdfmt rrem
  on replace preserve rows ;

-- add primary key
--alter table cmtlib.reminders
 --add primary key(rem_nbr) ;

-- add table label (object text description)
label on table cmtlib.reminders is 'Reminders' ;

-- add column labels
label on column cmtlib.reminders
(
 rem_nbr is 'Reminder #',
 rem_dat is 'Date',
 rem_tim is 'Time',
 rem_txt is 'Text',
 rem_us1 is 'User 1',
 rem_us2 is 'User 2',
 rem_eml is 'Email?',
 rem_com is 'Completed?'
 ) ;

-- add field text
label on column cmtlib.reminders
(
 rem_nbr text is 'Reminder #',
 rem_dat text is 'Date',
 rem_tim text is 'Time',
 rem_txt text is 'Text',
 rem_us1 text is 'User 1',
 rem_us2 text is 'User 2',
 rem_eml text is 'Email?',
 rem_com text is 'Completed?'
 ) ;
