-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Update MySQL database schema to v4                                       --
-- ---------------------------------------------------------------------------

BEGIN;

UPDATE room SET has_rows=0 WHERE has_rows IS NULL;
ALTER TABLE room MODIFY COLUMN has_rows INTEGER NOT NULL DEFAULT 0;

UPDATE rack SET size=1 WHERE size IS NULL;
ALTER TABLE rack MODIFY COLUMN size INTEGER NOT NULL;
UPDATE rack SET numbering_direction=0 WHERE numbering_direction IS NULL;
ALTER TABLE rack MODIFY COLUMN numbering_direction INTEGER NOT NULL DEFAULT 0;

UPDATE device SET monitored=0 WHERE monitored IS NULL;
ALTER TABLE device MODIFY COLUMN monitored INTEGER NOT NULL DEFAULT 0;
UPDATE device SET in_service=0 WHERE in_service IS NULL;
ALTER TABLE device MODIFY COLUMN in_service INTEGER NOT NULL DEFAULT 0;

-- Use TEXT column type to allow more than 255 chars for notes
ALTER TABLE building MODIFY COLUMN notes TEXT;
ALTER TABLE room MODIFY COLUMN notes TEXT;
ALTER TABLE row MODIFY COLUMN notes TEXT;
ALTER TABLE rack MODIFY COLUMN notes TEXT;
ALTER TABLE org MODIFY COLUMN notes TEXT;
ALTER TABLE service MODIFY COLUMN notes TEXT;
ALTER TABLE domain MODIFY COLUMN notes TEXT;
ALTER TABLE os MODIFY COLUMN notes TEXT;
ALTER TABLE hardware MODIFY COLUMN notes TEXT;
ALTER TABLE role MODIFY COLUMN notes TEXT;
ALTER TABLE device MODIFY COLUMN notes TEXT;
ALTER TABLE app MODIFY COLUMN notes TEXT;

ALTER TABLE device ADD COLUMN primary_mac VARCHAR(255);
ALTER TABLE device ADD COLUMN install_build VARCHAR(255);
ALTER TABLE device ADD COLUMN custom_info TEXT;

-- Ensure we don't create identical device/app relationships
CREATE UNIQUE INDEX device_app_unique ON device_app (app, device, relation);

UPDATE rm_meta SET value='5-1' WHERE name='system_build';
UPDATE rm_meta SET value='4' WHERE name='schema_version';

COMMIT;

SELECT name,value from rm_meta where name = 'schema_version';
