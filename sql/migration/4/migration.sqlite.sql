-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Update SQLite database schema to v4                                      --
-- ---------------------------------------------------------------------------

BEGIN EXCLUSIVE TRANSACTION;

-- Because SQLite doesn't have ALTER COLUMN we need to rebuild some tables
-- Recreating tables forces us to recreate triggers and indexes

-- ##################
-- Rebuild room table
-- ##################

UPDATE room set has_rows = 0 WHERE has_rows IS NULL;
ALTER TABLE room RENAME TO room_old;
CREATE TABLE room
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR NOT NULL COLLATE NOCASE,
	building INTEGER NOT NULL CONSTRAINT fk_room_building_id REFERENCES building(id),
	has_rows INTEGER NOT NULL DEFAULT 0,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);
INSERT INTO room (id, name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user)
    SELECT id, name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user
    FROM room_old;
DROP TABLE room_old;

CREATE UNIQUE INDEX room_building_unique ON room (name, building); -- ensure building and room name are together unique

-- Prevent inserts into room table unless building exists
CREATE TRIGGER fki_room_building_id
BEFORE INSERT ON room
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'insert on table "room" violates foreign key constraint "fki_room_building_id"')
	WHERE (SELECT id FROM building WHERE id = NEW.building) IS NULL;
END;

-- Prevent updates on room table unless building exists
CREATE TRIGGER fku_room_building_id
BEFORE UPDATE ON room
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'update on table "room" violates foreign key constraint "fku_room_building_id"')
    WHERE (SELECT id FROM building WHERE id = NEW.building) IS NULL;
END;

-- Prevent deletions of room used by the row table
CREATE TRIGGER fkd_row_room_id
BEFORE DELETE ON room
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "room" violates foreign key constraint "fkd_row_room_id"')
	WHERE (SELECT room FROM row WHERE room = OLD.id) IS NOT NULL;
END;


-- ##################
-- Rebuild rack table
-- ##################

UPDATE rack set size = 0 WHERE size IS NULL;
ALTER TABLE rack RENAME TO rack_old;
CREATE TABLE rack
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR NOT NULL COLLATE NOCASE,
	row INTEGER NOT NULL CONSTRAINT fk_row_id REFERENCES row(id),	
	row_pos INTEGER NOT NULL,
	hidden_rack INTEGER NOT NULL DEFAULT 0,
	size INTEGER NOT NULL,
	numbering_direction INTEGER NOT NULL DEFAULT 0,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);
INSERT INTO rack (id, name, row, row_pos, hidden_rack, size, numbering_direction, notes, meta_default_data, meta_update_time, meta_update_user)
    SELECT id, name, row, row_pos, hidden_rack, size, numbering_direction, notes, meta_default_data, meta_update_time, meta_update_user
    FROM rack_old;
DROP TABLE rack_old;

CREATE UNIQUE INDEX rack_row_unique ON rack (name, row); -- ensure row and rack name are together unique

-- Prevent inserts into rack table unless row exists
CREATE TRIGGER fki_rack_row_id
BEFORE INSERT ON rack
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'insert on table "rack" violates foreign key constraint "fki_rack_row_id"')
	WHERE (SELECT id FROM row WHERE id = NEW.row) IS NULL;
END;

-- Prevent updates on rack table unless row exists
CREATE TRIGGER fku_rack_row_id
BEFORE UPDATE ON rack
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'update on table "row" violates foreign key constraint "fku_rack_row_id"')
	WHERE (SELECT id FROM row WHERE id = NEW.row) IS NULL;
END;

-- Prevent deletions of racks referenced by the device table
CREATE TRIGGER fkd_device_rack_id
BEFORE DELETE ON rack
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "rack" violates foreign key constraint "fkd_device_rack_id"')
  WHERE (SELECT rack FROM device WHERE rack = OLD.id) IS NOT NULL;
END;


-- ####################
-- Rebuild device table
-- ####################

ALTER TABLE device RENAME TO device_old;
CREATE TABLE device
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR NOT NULL COLLATE NOCASE,
	domain INTEGER NOT NULL CONSTRAINT fk_domain_id REFERENCES domain(id),
	rack INTEGER NOT NULL CONSTRAINT fk_rack_id REFERENCES rack(id),	
	rack_pos INTEGER NOT NULL,
	hardware INTEGER NOT NULL CONSTRAINT fk_hardware_id REFERENCES hardware(id),	
	serial_no CHAR,
	asset_no CHAR,
	purchased CHAR,
	os INTEGER NOT NULL CONSTRAINT fk_os_id REFERENCES os(id),	
	os_version CHAR,
    os_licence_key CHAR,
	customer INTEGER NOT NULL CONSTRAINT fk_customer_id REFERENCES org(id),	
	service INTEGER NOT NULL CONSTRAINT fk_service_id REFERENCES service(id),	
	role INTEGER NOT NULL CONSTRAINT fk_role_id REFERENCES role(id),	
	monitored INTEGER NOT NULL DEFAULT 0,
	in_service INTEGER NOT NULL DEFAULT 0,
	primary_mac CHAR,
	install_build CHAR,
	custom_info CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);
INSERT INTO device (id, name, domain, rack, rack_pos, hardware, serial_no, asset_no, purchased, os, os_version, os_licence_key, customer, service, role, in_service, notes, meta_default_data, meta_update_time, meta_update_user)
    SELECT id, name, domain, rack, rack_pos, hardware, serial_no, asset_no, purchased, os, os_version, os_licence_key, customer, service, role, in_service, notes, meta_default_data, meta_update_time, meta_update_user
    FROM device_old;
DROP TABLE device_old;

CREATE UNIQUE INDEX device_name_unique ON device (name, domain); -- ensure name and domain are together unique

-- Prevent inserts into device table unless domain exists
CREATE TRIGGER fki_device_domain_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_domain_id"')
	WHERE (SELECT id FROM domain WHERE id = NEW.domain) IS NULL;
END;

-- Prevent updates on device table unless domain exists
CREATE TRIGGER fku_device_domain_id
BEFORE UPDATE ON device 
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_domain_id"')
	WHERE (SELECT id FROM domain WHERE id = NEW.domain) IS NULL;
END;

-- Prevent inserts into device table unless rack exists
CREATE TRIGGER fki_device_rack_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_rack_id"')
  WHERE (SELECT id FROM rack WHERE id = NEW.rack) IS NULL;
END;

-- Prevent updates on device table unless rack exists
CREATE TRIGGER fku_device_rack_id
BEFORE UPDATE ON device 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_rack_id"')
      WHERE (SELECT id FROM rack WHERE id = NEW.rack) IS NULL;
END;

-- Prevent inserts into device table unless hardware exists
CREATE TRIGGER fki_device_hardware_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_hardware_id"')
  WHERE (SELECT id FROM hardware WHERE id = NEW.hardware) IS NULL;
END;

-- Prevent updates on device table unless hardware exists
CREATE TRIGGER fku_device_hardware_id
BEFORE UPDATE ON device
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_hardware_id"')
      WHERE (SELECT id FROM hardware WHERE id = NEW.hardware) IS NULL;
END;

-- Prevent inserts into device table unless os exists
CREATE TRIGGER fki_device_os_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_os_id"')
  WHERE (SELECT id FROM os WHERE id = NEW.os) IS NULL;
END;

-- Prevent updates on device table unless os exists
CREATE TRIGGER fku_device_os_id
BEFORE UPDATE ON device 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_os_id"')
      WHERE (SELECT id FROM os WHERE id = NEW.os) IS NULL;
END;

-- Prevent inserts into device table unless customer exists
CREATE TRIGGER fki_device_customer_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_customer_id"')
  WHERE (SELECT id FROM org WHERE id = NEW.customer) IS NULL;
END;

-- Prevent updates on device table unless customer exists
CREATE TRIGGER fku_device_customer_id
BEFORE UPDATE ON device
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_customer_id"')
      WHERE (SELECT id FROM org WHERE id = NEW.customer) IS NULL;
END;

-- Prevent inserts into device table unless service level exists
CREATE TRIGGER fki_device_service_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_service_id"')
  WHERE (SELECT id FROM service WHERE id = NEW.service) IS NULL;
END;

-- Prevent updates on device table unless service level exists
CREATE TRIGGER fku_device_service_id
BEFORE UPDATE ON device 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_service_id"')
      WHERE (SELECT id FROM service WHERE id = NEW.service) IS NULL;
END;

-- Prevent inserts into device table unless role exists
CREATE TRIGGER fki_device_role_id
BEFORE INSERT ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device" violates foreign key constraint "fki_device_role_id"')
  WHERE (SELECT id FROM role WHERE id = NEW.role) IS NULL;
END;

-- Prevent updates on device table unless role exists
CREATE TRIGGER fku_device_role_id
BEFORE UPDATE ON device 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device" violates foreign key constraint "fku_device_role_id"')
      WHERE (SELECT id FROM role WHERE id = NEW.role) IS NULL;
END;

-- Prevent deletions of devices used by the device_app table
CREATE TRIGGER fkd_device_app_device_id
BEFORE DELETE ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "device" violates foreign key constraint "fkd_device_app_device_id"')
  WHERE (SELECT device FROM device_app WHERE device = OLD.id) IS NOT NULL;
END;

-- END of recreating tables

-- Ensure we don't create identical device/app relationships
CREATE UNIQUE INDEX device_app_unique ON device_app (app, device, relation); 

-- Table: device_app - recreate all triggers with clearer naming
-- Don't need to DROP TRIGGER fkd_device_id as its handled by recreating the device table (above)
DROP TRIGGER fki_app_id;
DROP TRIGGER fku_app_id;
DROP TRIGGER fkd_app_id;
DROP TRIGGER fki_device_id;
DROP TRIGGER fku_device_id;
DROP TRIGGER fki_relation_id;
DROP TRIGGER fku_relation_id;
DROP TRIGGER fkd_relation_id;

-- Prevent inserts into device_app table unless application exists
CREATE TRIGGER fki_device_app_app_id
BEFORE INSERT ON device_app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device_app" violates foreign key constraint "fki_device_app_app_id"')
  WHERE (SELECT id FROM app WHERE id = NEW.app) IS NULL;
END;

-- Prevent updates on device_app table unless application exists
CREATE TRIGGER fku_device_app_app_id
BEFORE UPDATE ON device_app 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device_app" violates foreign key constraint "fku_device_app_app_id"')
      WHERE (SELECT id FROM app WHERE id = NEW.app) IS NULL;
END;

-- Prevent deletions of apps used by the device_app table
CREATE TRIGGER fkd_device_app_app_id
BEFORE DELETE ON app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "app" violates foreign key constraint "fkd_device_app_app_id"')
  WHERE (SELECT app FROM device_app WHERE app = OLD.id) IS NOT NULL;
END;


-- Prevent inserts into device_app table unless device exists
CREATE TRIGGER fki_device_app_device_id
BEFORE INSERT ON device_app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device_app" violates foreign key constraint "fki_device_app_device_id"')
  WHERE (SELECT id FROM device WHERE id = NEW.device) IS NULL;
END;

-- Prevent updates on device_app table unless device exists
CREATE TRIGGER fku_device_app_device_id
BEFORE UPDATE ON device_app 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device_app" violates foreign key constraint "fku_device_app_device_id"')
      WHERE (SELECT id FROM device WHERE id = NEW.device) IS NULL;
END;

-- Prevent inserts into device_app table unless relation exists
CREATE TRIGGER fki_device_app_relation_id
BEFORE INSERT ON device_app
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "device_app" violates foreign key constraint "fki_device_app_relation_id"')
  WHERE (SELECT id FROM app_relation WHERE id = NEW.relation) IS NULL;
END;

-- Prevent updates on device_app table unless relation exists
CREATE TRIGGER fku_device_app_relation_id
BEFORE UPDATE ON device_app 
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "device_app" violates foreign key constraint "fku_device_app_relation_id"')
      WHERE (SELECT id FROM app_relation WHERE id = NEW.relation) IS NULL;
END;

-- Prevent deletions of relations used by the device_app table
CREATE TRIGGER fkd_device_app_relation_id
BEFORE DELETE ON app_relation
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "app_relation" violates foreign key constraint "fkd_device_app_relation_id"')
  WHERE (SELECT relation FROM device_app WHERE relation = OLD.id) IS NOT NULL;
END;

-- End of trigger changes

UPDATE rm_meta SET value='5-1' WHERE name='system_build';
UPDATE rm_meta SET value='4' WHERE name='schema_version';

COMMIT;

VACUUM;

SELECT name,value from rm_meta where name = 'schema_version';
