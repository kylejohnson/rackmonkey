-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Database schema v4 for SQLite                                            --
-- ---------------------------------------------------------------------------

BEGIN EXCLUSIVE TRANSACTION;

-- Building the device resides in
CREATE TABLE building
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	name_short CHAR COLLATE NOCASE,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR		
);


-- The room the device resides in
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


-- The row the rack resides in
CREATE TABLE row
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR NOT NULL COLLATE NOCASE,
	room INTEGER NOT NULL CONSTRAINT fk_room_id REFERENCES room(id),
	room_pos INTEGER NOT NULL,
	hidden_row INTEGER NOT NULL DEFAULT 0,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- The rack the device resides in
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


-- Organisation or department, e.g. Human Resources, IBM, MI5
CREATE TABLE org
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	account_no CHAR,
	customer INTEGER NOT NULL,
	software INTEGER NOT NULL,
	hardware INTEGER NOT NULL,
	descript CHAR,
	home_page CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);

-- Organisation related views
CREATE VIEW customer AS SELECT * FROM org WHERE customer = 1;
CREATE VIEW software_manufacturer AS SELECT * FROM org WHERE software = 1;
CREATE VIEW hardware_manufacturer AS SELECT * FROM org WHERE hardware = 1;


-- Service level of a device
CREATE TABLE service
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	descript CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- Device domain
CREATE TABLE domain
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	descript CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- Operating System
CREATE TABLE os
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	manufacturer INTEGER NOT NULL CONSTRAINT fk_manufacturer_id REFERENCES org(id),	
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- A specifc model of hardware, e.g. Sun v240, Apple Xserve 
CREATE TABLE hardware
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	manufacturer INTEGER NOT NULL CONSTRAINT fk_manufacturer_id REFERENCES org(id),	
	size INTEGER NOT NULL,
	image CHAR,
	support_url CHAR,
	spec_url CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- Role played by the device, e.g. web server, Oracle server, router
CREATE TABLE role
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	descript CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- An individual piece of hardware
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


-- Applications and services provided by the device
CREATE TABLE app
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	descript CHAR,
	notes CHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- Relationships applications can have with devices
CREATE TABLE app_relation
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR UNIQUE NOT NULL COLLATE NOCASE,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time CHAR,
	meta_update_user CHAR
);


-- Relates devices to apps
CREATE TABLE device_app
(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	app INTEGER NOT NULL CONSTRAINT fk_app_id REFERENCES app(id),
	device INTEGER NOT NULL CONSTRAINT fk_device_id REFERENCES device(id),
	relation INTEGER NOT NULL CONSTRAINT fk_app_relation_id REFERENCES app_relation(id),
	meta_default_data INTEGER NOT NULL DEFAULT 0,	
    meta_update_time CHAR,
    meta_update_user CHAR
);


-- To log changes in RackMonkey entries
CREATE TABLE logging
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	table_changed CHAR NOT NULL COLLATE NOCASE,
	id_changed INTEGER NOT NULL,
	name_changed CHAR COLLATE NOCASE,
	change_type CHAR COLLATE NOCASE,
	descript CHAR COLLATE NOCASE,
	update_time CHAR,
	update_user CHAR
);


-- To store meta information about RackMonkey database, e.g. revision.
CREATE TABLE rm_meta
(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name CHAR NOT NULL COLLATE NOCASE,
	value CHAR COLLATE NOCASE
);


-- Indexes
CREATE UNIQUE INDEX device_name_unique ON device (name, domain); -- ensure name and domain are together unique
CREATE UNIQUE INDEX rack_row_unique ON rack (name, row); -- ensure row and rack name are together unique
CREATE UNIQUE INDEX row_room_unique ON row (name, room); -- ensure room and row name are together unique
CREATE UNIQUE INDEX room_building_unique ON room (name, building); -- ensure building and room name are together unique
CREATE UNIQUE INDEX device_app_unique ON device_app (app, device, relation); -- ensure we don't create identical device/app relationships


------------------------------------------------------------------------------
-- Foreign Key Constraints
--
-- Because SQLite does not enforce foreign key constraints, 
-- it is necessery to use triggers to enforce them.
-- Thanks to http://www.sqlite.org/cvstrac/wiki?p=ForeignKeyTriggers
------------------------------------------------------------------------------

--
-- Table: room
--

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

-- Prevent deletions of buildings used by the room table
CREATE TRIGGER fkd_room_building_id
BEFORE DELETE ON building
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "building" violates foreign key constraint "fkd_room_building_id"')
	WHERE (SELECT building FROM room WHERE building = OLD.id) IS NOT NULL;
END;


--
-- Table: row
--

-- Prevent inserts into row table unless room exists
CREATE TRIGGER fki_row_room_id
BEFORE INSERT ON row
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'insert on table "row" violates foreign key constraint "fki_row_room_id"')
	WHERE (SELECT id FROM room WHERE id = NEW.room) IS NULL;
END;

-- Prevent updates on row table unless room exists
CREATE TRIGGER fku_row_room_id
BEFORE UPDATE ON row
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'update on table "row" violates foreign key constraint "fku_row_room_id"')
	WHERE (SELECT id FROM room WHERE id = NEW.room) IS NULL;
END;

-- Prevent deletions of room used by the row table
CREATE TRIGGER fkd_row_room_id
BEFORE DELETE ON room
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "room" violates foreign key constraint "fkd_row_room_id"')
	WHERE (SELECT room FROM row WHERE room = OLD.id) IS NOT NULL;
END;


--
-- Table: rack
--

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

-- Prevent deletions of rows used by the rack table
CREATE TRIGGER fkd_rack_row_id
BEFORE DELETE ON row
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "row" violates foreign key constraint "fkd_rack_row_id"')
	WHERE (SELECT row FROM rack WHERE row = OLD.id) IS NOT NULL;
END;


--
-- Table: os
--

-- Prevent inserts into os table unless manufacturer exists
CREATE TRIGGER fki_os_manufacturer_id
BEFORE INSERT ON os
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'insert on table "os" violates foreign key constraint "fki_os_manufacturer_id"')
	WHERE (SELECT id FROM org WHERE id = NEW.manufacturer) IS NULL;
END;

-- Prevent updates on os table unless manufacturer exists
CREATE TRIGGER fku_os_manufacturer_id
BEFORE UPDATE ON os
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'update on table "os" violates foreign key constraint "fku_os_manufacturer_id"')
	WHERE (SELECT id FROM org WHERE id = NEW.manufacturer) IS NULL;
END;

-- Prevent deletions of manufacturers (org) used by the os table
CREATE TRIGGER fkd_os_manufacturer_id
BEFORE DELETE ON org
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "org" violates foreign key constraint "fkd_os_manufacturer_id"')
	WHERE (SELECT manufacturer FROM os WHERE manufacturer = OLD.id) IS NOT NULL;
END;


--
-- Table: hardware
--

-- Prevent inserts into hardware table unless manufacturer exists
CREATE TRIGGER fki_hardware_manufacturer_id
BEFORE INSERT ON hardware
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'insert on table "hardware" violates foreign key constraint "fki_hardware_manufacturer_id"')
 	WHERE (SELECT id FROM org WHERE id = NEW.manufacturer) IS NULL;
END;

-- Prevent updates on hardware table unless manufacturer exists
CREATE TRIGGER fku_hardware_manufacturer_id
BEFORE UPDATE ON hardware
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'update on table "hardware" violates foreign key constraint "fku_hardware_manufacturer_id"')
	WHERE (SELECT id FROM org WHERE id = NEW.manufacturer) IS NULL;
END;

-- Prevent deletions of manufacturers (org) used by the hardware table
CREATE TRIGGER fkd_hardware_manufacturer_id
BEFORE DELETE ON org
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "org" violates foreign key constraint "fkd_hardware_manufacturer_id"')
	WHERE (SELECT manufacturer FROM hardware WHERE manufacturer = OLD.id) IS NOT NULL;
END;


--
-- Table: device
--

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

-- Prevent deletions of domains referenced by the device table
CREATE TRIGGER fkd_device_domain_id
BEFORE DELETE ON domain
FOR EACH ROW BEGIN
	SELECT RAISE(ROLLBACK, 'delete on table "domain" violates foreign key constraint "fkd_device_domain_id"')	
	WHERE (SELECT domain FROM device WHERE domain = OLD.id) IS NOT NULL;
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

-- Prevent deletions of racks referenced by the device table
CREATE TRIGGER fkd_device_rack_id
BEFORE DELETE ON rack
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "rack" violates foreign key constraint "fkd_device_rack_id"')
  WHERE (SELECT rack FROM device WHERE rack = OLD.id) IS NOT NULL;
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

-- Prevent deletions of hardware referenced by the device table
CREATE TRIGGER fkd_device_hardware_id
BEFORE DELETE ON hardware
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "hardware" violates foreign key constraint "fkd_device_hardware_id"')
  WHERE (SELECT hardware FROM device WHERE hardware = OLD.id) IS NOT NULL;
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

-- Prevent deletions of os referenced by the device table
CREATE TRIGGER fkd_device_os_id
BEFORE DELETE ON os
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "os" violates foreign key constraint "fkd_device_os_id"')
  WHERE (SELECT os FROM device WHERE os = OLD.id) IS NOT NULL;
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

-- Prevent deletions of customers referenced by the device table
CREATE TRIGGER fkd_device_customer_id
BEFORE DELETE ON org
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "org" violates foreign key constraint "fkd_device_customer_id"')
  WHERE (SELECT customer FROM device WHERE customer = OLD.id) IS NOT NULL;
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

-- Prevent deletions of servive levels referenced by the device table
CREATE TRIGGER fkd_device_service_id
BEFORE DELETE ON service
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "service" violates foreign key constraint "fkd_device_service_id"')
  WHERE (SELECT service FROM device WHERE service = OLD.id) IS NOT NULL;
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

-- Prevent deletions of roles referenced by the device table
CREATE TRIGGER fkd_device_role_id
BEFORE DELETE ON role
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "role" violates foreign key constraint "fkd_device_role_id"')
  WHERE (SELECT role FROM device WHERE role = OLD.id) IS NOT NULL;
END;


--
-- Table: device_app
--

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

-- Prevent deletions of devices used by the device_app table
CREATE TRIGGER fkd_device_app_device_id
BEFORE DELETE ON device
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "device" violates foreign key constraint "fkd_device_app_device_id"')
  WHERE (SELECT device FROM device_app WHERE device = OLD.id) IS NOT NULL;
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


-- install system information
INSERT INTO rm_meta(id, name, value) VALUES (1, 'system_version', '1.2');
INSERT INTO rm_meta(id, name, value) VALUES (2, 'system_build', '5-1');
INSERT INTO rm_meta(id, name, value) VALUES (3, 'schema_version', '4');

COMMIT;
