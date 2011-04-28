-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Database schema v4 for MySQL                                             --
-- ---------------------------------------------------------------------------

BEGIN;

-- Building the device resides in
CREATE TABLE building
(
	id INTEGER AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	name_short VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)
) ENGINE = InnoDB;


-- The room the device resides in
CREATE TABLE room
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	building INTEGER NOT NULL,
	has_rows INTEGER NOT NULL DEFAULT 0,
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (building) REFERENCES building(id)
) ENGINE = InnoDB;


-- The row the rack resides in
CREATE TABLE row
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	room INTEGER NOT NULL,
	room_pos INTEGER NOT NULL,
	hidden_row INTEGER NOT NULL DEFAULT 0,
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (room) REFERENCES room(id)	
) ENGINE = InnoDB;


-- The rack the device resides in
CREATE TABLE rack
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	row INTEGER NOT NULL,
	row_pos INTEGER NOT NULL,
	hidden_rack INTEGER NOT NULL DEFAULT 0,
	size INTEGER NOT NULL,
	numbering_direction INTEGER NOT NULL DEFAULT 0,
	notes TEXT,
	meta_default_data INTEGER DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (row) REFERENCES row(id)	
) ENGINE = InnoDB;


-- Organisation or department, e.g. Human Resources, IBM, MI5
CREATE TABLE org
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	account_no VARCHAR(255),
	customer INTEGER NOT NULL,
	software INTEGER NOT NULL,
	hardware INTEGER NOT NULL,
	descript VARCHAR(255),
	home_page VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)
) ENGINE = InnoDB;

-- Organisation related views
CREATE VIEW customer AS SELECT * FROM org WHERE customer = 1;
CREATE VIEW software_manufacturer AS SELECT * FROM org WHERE software = 1;
CREATE VIEW hardware_manufacturer AS SELECT * FROM org WHERE hardware = 1;


-- Service level of a device
CREATE TABLE service
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	descript VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)	
) ENGINE = InnoDB;


-- Device domain
CREATE TABLE domain
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	descript VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)	
) ENGINE = InnoDB;


-- Operating System
CREATE TABLE os
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	manufacturer INTEGER NOT NULL,
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (manufacturer) REFERENCES org(id)	
) ENGINE = InnoDB;


-- A specifc model of hardware, e.g. Sun v240, Apple Xserve 
CREATE TABLE hardware
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	manufacturer INTEGER NOT NULL,
	size INTEGER NOT NULL,
	image VARCHAR(255),
	support_url VARCHAR(255),
	spec_url VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (manufacturer) REFERENCES org(id)	
) ENGINE = InnoDB;


-- Role played by the device, e.g. web server, Oracle server, router
CREATE TABLE role
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	descript VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)	
) ENGINE = InnoDB;


-- An individual piece of hardware
CREATE TABLE device
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	domain INTEGER NOT NULL,
	rack INTEGER NOT NULL,
	rack_pos INTEGER,
	hardware INTEGER NOT NULL,
	serial_no VARCHAR(255),
	asset_no VARCHAR(255),
	purchased CHAR(10),
	os INTEGER NOT NULL,
	os_version VARCHAR(255), 
	os_licence_key VARCHAR(255), 
	customer INTEGER NOT NULL,
	service INTEGER NOT NULL,
	role INTEGER NOT NULL,
	monitored INTEGER NOT NULL DEFAULT 0,
	in_service INTEGER NOT NULL DEFAULT 0,
	primary_mac VARCHAR(255),
	install_build VARCHAR(255),
	custom_info TEXT,
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255),
	FOREIGN KEY (domain) REFERENCES domain(id),
	FOREIGN KEY (rack) REFERENCES rack(id),	
	FOREIGN KEY (hardware) REFERENCES hardware(id),
	FOREIGN KEY (os) REFERENCES os(id),
	FOREIGN KEY (customer) REFERENCES org(id),
	FOREIGN KEY (service) REFERENCES service(id),
	FOREIGN KEY (role) REFERENCES role(id)	
) ENGINE = InnoDB;


-- Applications and services provided by the device
CREATE TABLE app
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	descript VARCHAR(255),
	notes TEXT,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)	
) ENGINE = InnoDB;


-- Relationships applications can have with devices
CREATE TABLE app_relation
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR(255),
	meta_update_user VARCHAR(255)
) ENGINE = InnoDB;


-- Relates devices to apps
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


-- To log changes in RackMonkey entries
CREATE TABLE logging
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	table_changed VARCHAR(255) NOT NULL,
	id_changed INTEGER NOT NULL,
	name_changed VARCHAR(255),
	change_type VARCHAR(255),
	descript VARCHAR(255),
	update_time VARCHAR(255),
	update_user VARCHAR(255)
) ENGINE = InnoDB;


-- To store meta information about Rackmonkey database, e.g. revision.
CREATE TABLE rm_meta
(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	value VARCHAR(255) NOT NULL
) ENGINE = InnoDB;


-- Indexes
CREATE UNIQUE INDEX device_name_unique ON device (name, domain); -- ensure name and domain are together unique
CREATE UNIQUE INDEX rack_row_unique ON rack (name, row); -- ensure row and rack name are together unique
CREATE UNIQUE INDEX row_room_unique ON row (name, room); -- ensure room and row name are together unique
CREATE UNIQUE INDEX room_building_unique ON room (name, building); -- ensure building and room name are together unique
CREATE UNIQUE INDEX device_app_unique ON device_app (app, device, relation); -- ensure we don't create identical device/app relationships


-- install system information
INSERT INTO rm_meta(id, name, value) VALUES (1, 'system_version', '1.2');
INSERT INTO rm_meta(id, name, value) VALUES (2, 'system_build', '5-1');
INSERT INTO rm_meta(id, name, value) VALUES (3, 'schema_version', '4');

COMMIT;
