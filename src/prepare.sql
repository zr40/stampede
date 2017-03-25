\o /dev/null

\echo Stampede 1.0.1
\conninfo

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

create or replace function stampede.is_production() returns bool as $$
	select current_database() not like '%development%';
$$ language sql;

create or replace function stampede.wait_in_production() returns void as $$
	begin
		if stampede.is_production() then
			raise warning 'database contents will be destroyed. Will proceed in 5 seconds...';
			perform pg_sleep(1);
			raise warning 'database contents will be destroyed. Will proceed in 4 seconds...';
			perform pg_sleep(1);
			raise warning 'database contents will be destroyed. Will proceed in 3 seconds...';
			perform pg_sleep(1);
			raise warning 'database contents will be destroyed. Will proceed in 2 seconds...';
			perform pg_sleep(1);
			raise warning 'database contents will be destroyed. Will proceed in 1 seconds...';
			perform pg_sleep(1);
		end if;
	end
$$ language plpgsql;

create or replace function stampede.define_migration(id int, apply text, name text default '', unapply text default null) returns void as $$
	insert into pg_temp.migration (id, name, apply, unapply) values (id, name, apply, unapply);
$$ language sql;

create or replace function stampede.show_migration_status(migration pg_temp.migration) returns void as $$
begin
	if (select true from stampede.applied_migration where migration_id = migration.id) then
		if migration.name = '' then
			raise notice 'Migration % is applied', migration.id;
		else
			raise notice 'Migration % is applied (%)', migration.id, migration.name;
		end if;
	else
		if migration.name = '' then
			raise notice 'Migration % is not applied', migration.id;
		else
			raise notice 'Migration % is not applied (%)', migration.id, migration.name;
		end if;
	end if;
end
$$ language plpgsql;

create or replace function stampede.apply_migration(migration pg_temp.migration) returns void as $$
begin
	if migration.name = '' then
		raise notice 'Applying migration %...', migration.id;
	else
		raise notice 'Applying migration %: %...', migration.id, migration.name;
	end if;

	execute migration.apply;

	insert into stampede.applied_migration(migration_id, applied_on) values (migration.id, now());
end
$$ language plpgsql;

create or replace function stampede.unapply_migration(migration pg_temp.migration) returns void as $$
begin
	if migration.name = '' then
		raise notice 'Unapplying migration %...', migration.id;
	else
		raise notice 'Unapplying migration %: %...', migration.id, migration.name;
	end if;

	if migration.unapply is null then
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
	perform stampede.wait_in_production();

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
	perform stampede.wait_in_production();

	perform stampede.unapply_migration(m) from (
		select m from pg_temp.migration m
		where id in (select migration_id from stampede.applied_migration)
		order by id desc
	) m;
end
$$ language plpgsql;

create or replace function stampede.reset() returns void as $$
declare
	schema_name text;
begin
	perform stampede.wait_in_production();

	for schema_name in select nspname from pg_namespace where nspname !~ '^pg_' and nspname not in ('stampede', 'information_schema') loop
		execute format('drop schema %I cascade', schema_name);
	end loop;

	create schema public;
	truncate stampede.applied_migration;
end
$$ language plpgsql;

create or replace function stampede.clean_up() returns void as $$
	drop function stampede.apply_migration(pg_temp.migration);
	drop function stampede.back();
	drop function stampede.clean_up();
	drop function stampede.define_migration(int, text, text, text);
	drop function stampede.migrate();
	drop function stampede.reset();
	drop function stampede.show_migration_status(pg_temp.migration);
	drop function stampede.status();
	drop function stampede.step();
	drop function stampede.unapply_migration(pg_temp.migration);
	drop function stampede.unapply();
$$ language sql;

do $$
	begin
		if not stampede.is_production() then
			raise warning 'development database. Will not warn when performing destructive commands!';
		end if;
	end
$$;
\echo
