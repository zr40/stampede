\echo usage: stampede [command]
\echo
\echo Commands:
\echo 'status    Show applied and new migrations'
\echo 'migrate   Apply all migrations'
\echo 'step      Apply the first unapplied migration'
\echo 'back      Unapply the last applied migration'
\echo
\echo Commands for migration development:
\echo 'unapply   Unapply all migrations'
\echo 'stomp     Unapply all migrations, then apply all migrations'
\echo 'redo      Unapply the last applied migration, then apply all migrations'
\echo 'drop      Clear the database and create the `public` schema'
\echo 'reset     Clear the database, create the `public` schema, then apply all migrations'
\echo
\echo Commands for application development:
\echo 'clone DB  Clear the database, clone the DB database, then apply all migrations'
\echo
\echo 'On production databases, destructive commands will warn and wait for 10 seconds'
\echo 'before continuing. Hopefully, this will prevent disasters.'
