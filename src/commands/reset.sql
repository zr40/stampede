\echo 'Clearing `public` schema...'
select stampede.reset();

\echo

\echo Applying migrations...
select stampede.migrate();
