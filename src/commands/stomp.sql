\echo Unapplying migrations...
select stampede.unapply();

\echo

\echo Applying migrations...
select stampede.migrate();
