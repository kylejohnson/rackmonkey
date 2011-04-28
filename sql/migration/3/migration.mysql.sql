-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Update MySQL database schema to v3                                       --
-- ---------------------------------------------------------------------------

BEGIN;

ALTER TABLE rack ADD COLUMN numbering_direction INTEGER NOT NULL DEFAULT 0;
ALTER TABLE device ADD COLUMN os_licence_key VARCHAR(255);
ALTER TABLE app_relation ADD COLUMN meta_default_data INTEGER NOT NULL DEFAULT 0;
ALTER TABLE app_relation ADD COLUMN meta_update_time VARCHAR(255);
ALTER TABLE app_relation ADD COLUMN meta_update_user VARCHAR(255);

-- Replace device_app table: it's not been used yet so we can safely drop
DROP TABLE device_app;
CREATE TABLE device_app
(
    id INT AUTO_INCREMENT PRIMARY KEY,
	app INTEGER NOT NULL,
	device INTEGER NOT NULL,
	relation INTEGER NOT NULL,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (app) REFERENCES app(id),
	FOREIGN KEY (device) REFERENCES device(id),
	FOREIGN KEY (relation) REFERENCES app_relation(id)			
) ENGINE = InnoDB;

UPDATE rm_meta SET value='5-1' WHERE name='system_build';
UPDATE rm_meta SET value='3' WHERE name='schema_version';

COMMIT;

SELECT name,value from rm_meta where name = 'schema_version';
