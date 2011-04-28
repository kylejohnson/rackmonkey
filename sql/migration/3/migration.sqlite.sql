-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Update SQLite database schema to v3                                      --
-- ---------------------------------------------------------------------------

BEGIN EXCLUSIVE TRANSACTION;

ALTER TABLE rack ADD COLUMN numbering_direction INTEGER NOT NULL DEFAULT 0;
ALTER TABLE device ADD COLUMN os_licence_key CHAR;
ALTER TABLE app_relation ADD COLUMN meta_default_data INTEGER NOT NULL DEFAULT 0;
ALTER TABLE app_relation ADD COLUMN meta_update_time CHAR;
ALTER TABLE app_relation ADD COLUMN meta_update_user CHAR;

-- Need to drop device_app so we can add primary key id: it's not been used yet so we can safely drop
DROP TABLE device_app;
CREATE TABLE device_app
(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    app INTEGER NOT NULL
        CONSTRAINT fk_app_id REFERENCES app(id),
    device INTEGER NOT NULL
        CONSTRAINT fk_device_id REFERENCES device(id),
    relation INTEGER NOT NULL
        CONSTRAINT fk_app_relation_id REFERENCES app_relation(id),
    meta_default_data INTEGER NOT NULL DEFAULT 0,	
    meta_update_time CHAR,
    meta_update_user CHAR
);

-- Dropping table necessitates recreation of fk triggers
CREATE TRIGGER fki_app_id
BEFORE INSERT ON device_app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device_app" violates foreign key constraint "fki_app_id"')
  WHERE (SELECT id FROM app WHERE id = NEW.app) IS NULL;
END;
CREATE TRIGGER fku_app_id
BEFORE UPDATE ON device_app 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device_app" violates foreign key constraint "fku_app_id"')
      WHERE (SELECT id FROM app WHERE id = NEW.app) IS NULL;
END;
CREATE TRIGGER fki_device_id
BEFORE INSERT ON device_app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device_app" violates foreign key constraint "fki_device_id"')
  WHERE (SELECT id FROM device WHERE id = NEW.device) IS NULL;
END;
CREATE TRIGGER fku_device_id
BEFORE UPDATE ON device_app 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device_app" violates foreign key constraint "fku_device_id"')
      WHERE (SELECT id FROM device WHERE id = NEW.device) IS NULL;
END;
CREATE TRIGGER fki_relation_id
BEFORE INSERT ON device_app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device_app" violates foreign key constraint "fki_relation_id"')
  WHERE (SELECT id FROM app_relation WHERE id = NEW.relation) IS NULL;
END;
CREATE TRIGGER fku_relation_id
BEFORE UPDATE ON device_app 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device_app" violates foreign key constraint "fku_relation_id"')
      WHERE (SELECT id FROM app_relation WHERE id = NEW.relation) IS NULL;
END;

UPDATE rm_meta SET value='5-1' WHERE name='system_build';
UPDATE rm_meta SET value='3' WHERE name='schema_version';

COMMIT;

VACUUM;

SELECT name,value from rm_meta where name = 'schema_version';
