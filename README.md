Stampede is a PostgreSQL database migration utility.

Features
========

* Write migrations in SQL: no special language needed.
* Atomic execution: on failure or cancel, the entire transaction is rolled back.
* Unapply migrations: optionally, if you add unapply statements to your migrations, you can tell Stampede to unapply migrations.

Usage
=====

Set the `PGDATABASE`, `PGHOST`, `PGPORT` and `PGUSER` environment variables, then execute `src/stampede migrate`. You'll probably want to wrap this in a shell script or a Makefile.

Stampede will look for migrations in files in `./migrations/`, ending with `.sql`. Example:

```sql
select stampede.define_migration(
    id := 42,
    name := 'Add customer_id foreign key'
    apply := ('
        alter table orders
        add constraint orders_customer_fk
        foreign key (customer_id) references customers (id)
    '),
    unapply := ('drop constraint orders_customer_fk')
);
```

`apply` and `unapply` can contain any number of statements. `unapply` is optional.

Migrations are executed in ascending order of `id`. Each migration must have a unique `id`, and the sequence of migration `id`s should start at 0.

Commands
--------

Show usage: `stampede`

Apply all migrations: `stampede migrate`

Unapply all migrations: `stampede drop`

Unapply all, then apply all: `stampede stomp`

TODO
----

List migrations and status: `stampede status`

Apply a single migration: `stampede step`

Unapply a migration: `stampede back`

Test unapply cycle: `stampede test`
