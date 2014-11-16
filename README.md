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
    apply := '
        alter table orders
        add constraint orders_customer_fk
        foreign key (customer_id) references customers (id)
    ',
    unapply := 'drop constraint orders_customer_fk'
);
```

`apply` and `unapply` can contain any number of statements. `unapply` and `name` are optional.

Migrations are executed in ascending order of `id`. Each migration must have a unique `id`.

Commands
--------

* Show usage: `stampede`
* List migrations and status: `stampede status`
* Apply all migrations: `stampede migrate`
* Apply the first unapplied migration: `stampede step`
* Unapply the last applied migration: `stampede back`

These commands are useful when writing and testing your migrations:

* Unapply all migrations: `stampede unapply`
* Unapply all, then apply all: `stampede stomp`
* Drop schema `public`: `stampede drop`
* Drop schema `public`, then apply all migrations: `stampede reset`
