-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Update Postgres database schema to v3                                    --
-- ---------------------------------------------------------------------------

BEGIN;

-- Set NOT NULL for all foreign key constraints, this was missed in the RackMonkey 1.2.3 schema
-- Because there wasn't an automated migration from RackMonkey 1.2.3 to 1.2.4 this may also be needed for 1.2.4 users
ALTER TABLE room ALTER COLUMN building SET NOT NULL;
ALTER TABLE row ALTER COLUMN room SET NOT NULL;
ALTER TABLE rack ALTER COLUMN row SET NOT NULL;
ALTER TABLE os ALTER COLUMN manufacturer SET NOT NULL;
ALTER TABLE hardware ALTER COLUMN manufacturer SET NOT NULL;
ALTER TABLE device ALTER COLUMN domain SET NOT NULL;
ALTER TABLE device ALTER COLUMN rack SET NOT NULL;
ALTER TABLE device ALTER COLUMN hardware SET NOT NULL;
ALTER TABLE device ALTER COLUMN os SET NOT NULL;
ALTER TABLE device ALTER COLUMN customer SET NOT NULL;
ALTER TABLE device ALTER COLUMN service SET NOT NULL;
ALTER TABLE device ALTER COLUMN role SET NOT NULL;
-- NOT NULL is set for the device_app table when it's created below

-- Add additional columns
ALTER TABLE rack ADD COLUMN numbering_direction INTEGER;
UPDATE rack SET numbering_direction = 0 WHERE numbering_direction IS NULL;
ALTER TABLE rack ALTER COLUMN numbering_direction SET DEFAULT 0;
ALTER TABLE rack ALTER COLUMN numbering_direction SET NOT NULL;

ALTER TABLE device ADD COLUMN os_licence_key VARCHAR;

ALTER TABLE app_relation ADD COLUMN meta_default_data INTEGER;
UPDATE app_relation SET meta_default_data = 0 WHERE meta_default_data IS NULL;
ALTER TABLE app_relation ALTER COLUMN meta_default_data SET DEFAULT 0;
ALTER TABLE app_relation ALTER COLUMN meta_default_data SET NOT NULL;

ALTER TABLE app_relation ADD COLUMN meta_update_time VARCHAR;
ALTER TABLE app_relation ADD COLUMN meta_update_user VARCHAR;

-- Replace device_app table: it's not been used yet so we can safely drop
DROP TABLE device_app;
CREATE TABLE device_app
(
    id SERIAL PRIMARY KEY,
	app INTEGER NOT NULL REFERENCES app,
	device INTEGER NOT NULL REFERENCES device,
	relation INTEGER NOT NULL REFERENCES app_relation,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR
);

UPDATE rm_meta SET value='5-1' WHERE name='system_build';
UPDATE rm_meta SET value='3' WHERE name='schema_version';

COMMIT;

VACUUM;

SELECT name,value from rm_meta where name = 'schema_version';
