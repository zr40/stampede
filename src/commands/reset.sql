\echo 'Clearing database...'
select stampede.reset();

\echo

\echo Applying migrations...
select stampede.migrate();
