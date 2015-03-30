\echo 'Clearing database...'
select stampede.reset();
drop table stampede.applied_migration;
