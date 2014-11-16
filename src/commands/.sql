\echo usage: stampede [command]
\echo
\echo Commands:
\echo 'migrate   Apply all migrations'
\echo 'step      Apply the first unapplied migration'
\echo 'back      Unapply the last applied migration'
\echo
\echo Commands for migration development:
\echo 'unapply   Unapply all migrations'
\echo 'stomp     Unapply all migrations, then apply all migrations'
\echo 'drop      Clear contents of the `public` schema'
\echo 'reset     Clear contents of the `public` schema, then apply all migrations'
