-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Update Postgres database schema to v4                                    --
-- ---------------------------------------------------------------------------

BEGIN;

ALTER TABLE device ADD COLUMN primary_mac VARCHAR;
ALTER TABLE device ADD COLUMN install_build VARCHAR;
ALTER TABLE device ADD COLUMN custom_info VARCHAR;

UPDATE room SET has_rows = 0 WHERE has_rows IS NULL;
ALTER TABLE room ALTER COLUMN has_rows SET DEFAULT 0;
ALTER TABLE room ALTER COLUMN has_rows SET NOT NULL;

UPDATE rack SET size = 1 WHERE size IS NULL;
ALTER TABLE rack ALTER COLUMN size SET NOT NULL;

-- If we're coming from Preview 2 we need to fix numbering_direction
UPDATE rack SET numbering_direction = 0 WHERE numbering_direction IS NULL;
ALTER TABLE rack ALTER COLUMN numbering_direction SET NOT NULL;

UPDATE device SET monitored = 0 WHERE monitored IS NULL;
ALTER TABLE device ALTER COLUMN monitored SET DEFAULT 0;
ALTER TABLE device ALTER COLUMN monitored SET NOT NULL;

UPDATE device SET in_service = 0 WHERE in_service IS NULL;
ALTER TABLE device ALTER COLUMN in_service SET DEFAULT 0;
ALTER TABLE device ALTER COLUMN in_service SET NOT NULL;

-- Ensure we don't create identical device/app relationships
CREATE UNIQUE INDEX device_app_unique ON device_app (app, device, relation);

UPDATE rm_meta SET value='5-1' WHERE name='system_build';
UPDATE rm_meta SET value='4' WHERE name='schema_version';

COMMIT;

VACUUM;

SELECT name,value from rm_meta where name = 'schema_version';
