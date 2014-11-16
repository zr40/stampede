\echo 'Clearing `public` schema...'
select stampede.reset();
drop table stampede.applied_migration;
