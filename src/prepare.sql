\o /dev/null

\pset border 1
\echo Stampede 0.0.0-dev
\conninfo
\echo

set client_min_messages to warning;

create schema if not exists stampede;

create table if not exists stampede.applied_migrations (
	migration_id int primary key,
	applied_on timestamptz default now()
);

set client_min_messages to notice;

create temporary table pg_temp.migrations (
	id int primary key,
	name text not null,
	apply text not null,
	unapply text
) on commit drop;

create or replace function stampede.define_migration(id int, apply text, name text default '', unapply text default null) returns void as $$
insert into pg_temp.migrations (id, name, apply, unapply) values (id, name, apply, unapply);
$$ language sql;

create or replace function stampede.apply_migration(migration pg_temp.migrations) returns void as $$
declare
	missing_dependency text;
begin
	raise notice 'Applying migration %...', case when migration.name = '' then migration.id::text else migration.id || ': ' || migration.name end;

	execute migration.apply;

	insert into stampede.applied_migrations(migration_id, applied_on) values (migration.id, now());
end
$$ language plpgsql;

create or replace function stampede.unapply_migration(migration pg_temp.migrations) returns void as $$
declare
	missing_dependency text;
begin
	raise notice 'Unapplying migration %...', case when migration.name = '' then migration.id::text else migration.id || ': ' || migration.name end;

	if migration.unapply is null
	then
		raise exception 'Migration % has no unapply statements', migration.id;
	end if;

	execute migration.unapply;

	delete from stampede.applied_migrations where migration_id = migration.id;
end
$$ language plpgsql;


-- commands

create or replace function stampede.migrate() returns void as $$
begin
	perform stampede.apply_migration(m) from (
		select m from pg_temp.migrations m
		where id not in (select migration_id from stampede.applied_migrations)
		order by id
	) m;
end
$$ language plpgsql;

create or replace function stampede.unapply() returns void as $$
begin
	perform stampede.unapply_migration(m) from (
		select m from pg_temp.migrations m
		where id in (select migration_id from stampede.applied_migrations)
		order by id desc
	) m;
end
$$ language plpgsql;

create or replace function stampede.reset() returns void as $$
	drop schema if exists public cascade;
	create schema public;
	delete from stampede.applied_migrations;
$$ language sql;


create or replace function stampede.clean_up() returns void as $$
	drop function stampede.define_migration(int, text, text, text);
	drop function stampede.migrate();
	drop function stampede.unapply();
	drop function stampede.reset();
	drop function stampede.apply_migration(pg_temp.migrations);
	drop function stampede.unapply_migration(pg_temp.migrations);
	drop function stampede.clean_up();
$$ language sql;
