\echo Unapplying migrations...
select stampede.unapply();
drop table stampede.applied_migrations;
