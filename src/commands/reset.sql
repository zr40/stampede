\echo Clearing database...
select stampede.reset();

\echo
\echo Applying migrations...
select stampede.migrate();

\echo
\echo VACUUM ANALYZE...
select stampede.clean_up();

commit;
vacuum analyze;
begin;

create or replace function stampede.clean_up() returns void as $$
  drop function stampede.clean_up();
$$ language sql;
