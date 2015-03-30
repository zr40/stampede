\o /dev/null

\echo Stampede 1.0.0
\conninfo
\echo

set client_min_messages to warning;

create schema if not exists stampede;

create table if not exists stampede.applied_migration (
	migration_id int primary key,
	applied_on timestamptz default now()
);

set client_min_messages to notice;

create temporary table pg_temp.migration (
	id int primary key,
	name text not null,
	apply text not null,
	unapply text
) on commit drop;

create or replace function stampede.define_migration(id int, apply text, name text default '', unapply text default null) returns void as $$
	insert into pg_temp.migration (id, name, apply, unapply) values (id, name, apply, unapply);
$$ language sql;

create or replace function stampede.show_migration_status(migration pg_temp.migration) returns void as $$
begin
	if (select true from stampede.applied_migration where migration_id = migration.id)
	then
		raise notice 'Migration % is applied (%)', migration.id, migration.name;
	else
		raise notice 'Migration % is not applied (%)', migration.id, migration.name;
	end if;
end
$$ language plpgsql;

create or replace function stampede.apply_migration(migration pg_temp.migration) returns void as $$
begin
	raise notice 'Applying migration %...', case when migration.name = '' then migration.id::text else migration.id || ': ' || migration.name end;

	execute migration.apply;

	insert into stampede.applied_migration(migration_id, applied_on) values (migration.id, now());
end
$$ language plpgsql;

create or replace function stampede.unapply_migration(migration pg_temp.migration) returns void as $$
begin
	raise notice 'Unapplying migration %...', case when migration.name = '' then migration.id::text else migration.id || ': ' || migration.name end;

	if migration.unapply is null
	then
		raise exception 'Migration % has no unapply statements', migration.id;
	end if;

	execute migration.unapply;

	delete from stampede.applied_migration where migration_id = migration.id;
end
$$ language plpgsql;


-- commands

create or replace function stampede.status() returns void as $$
begin
	raise notice 'Current migration status:';

	perform stampede.show_migration_status(m) from (
		select m from pg_temp.migration m
		order by id
	) m;
end
$$ language plpgsql;

create or replace function stampede.migrate() returns void as $$
begin
	perform stampede.apply_migration(m) from (
		select m from pg_temp.migration m
		where id not in (select migration_id from stampede.applied_migration)
		order by id
	) m;
end
$$ language plpgsql;

create or replace function stampede.step() returns void as $$
begin
	perform stampede.apply_migration(m) from (
		select m from pg_temp.migration m
		where id not in (select migration_id from stampede.applied_migration)
		order by id
		limit 1
	) m;
end
$$ language plpgsql;

create or replace function stampede.back() returns void as $$
begin
	perform stampede.unapply_migration(m) from (
		select m from pg_temp.migration m
		where id in (select migration_id from stampede.applied_migration)
		order by id desc
		limit 1
	) m;
end
$$ language plpgsql;

create or replace function stampede.unapply() returns void as $$
begin
	perform stampede.unapply_migration(m) from (
		select m from pg_temp.migration m
		where id in (select migration_id from stampede.applied_migration)
		order by id desc
	) m;
end
$$ language plpgsql;

create or replace function stampede.reset() returns void as $$
	drop schema if exists public cascade;
	create schema public;
	truncate stampede.applied_migration;
$$ language sql;


create or replace function stampede.clean_up() returns void as $$
	drop function stampede.define_migration(int, text, text, text);
	drop function stampede.show_migration_status(pg_temp.migration);
	drop function stampede.status();
	drop function stampede.migrate();
	drop function stampede.step();
	drop function stampede.back();
	drop function stampede.unapply();
	drop function stampede.reset();
	drop function stampede.apply_migration(pg_temp.migration);
	drop function stampede.unapply_migration(pg_temp.migration);
	drop function stampede.clean_up();
$$ language sql;
