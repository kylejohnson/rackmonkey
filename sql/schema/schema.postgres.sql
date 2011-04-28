-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Database schema v4 for Postgres                                          --
-- ---------------------------------------------------------------------------

BEGIN;

-- Building the device resides in
CREATE TABLE building
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	name_short VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR
);


-- The room the device resides in
CREATE TABLE room
(
	id SERIAL PRIMARY KEY,
	name VARCHAR NOT NULL,
	building INTEGER NOT NULL REFERENCES building,
	has_rows INTEGER NOT NULL DEFAULT 0,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- The row the rack resides in
CREATE TABLE row
(
	id SERIAL PRIMARY KEY,
	name VARCHAR NOT NULL,
	room INTEGER NOT NULL REFERENCES room,
	room_pos INTEGER NOT NULL,
	hidden_row INTEGER NOT NULL DEFAULT 0,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- The rack the device resides in
CREATE TABLE rack
(
	id SERIAL PRIMARY KEY,
	name VARCHAR NOT NULL,
	row INTEGER NOT NULL REFERENCES row,
	row_pos INTEGER NOT NULL,
	hidden_rack INTEGER NOT NULL DEFAULT 0,
	size INTEGER NOT NULL,
	numbering_direction INTEGER NOT NULL DEFAULT 0,
	notes VARCHAR,
	meta_default_data INTEGER DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Organisation or department, e.g. Human Resources, IBM, MI5
CREATE TABLE org
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	account_no VARCHAR,
	customer INTEGER NOT NULL,
	software INTEGER NOT NULL,
	hardware INTEGER NOT NULL,
	descript VARCHAR,
	home_page VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR
);

-- Organisation related views
CREATE VIEW customer AS SELECT * FROM org WHERE customer = 1;
CREATE VIEW software_manufacturer AS SELECT * FROM org WHERE software = 1;
CREATE VIEW hardware_manufacturer AS SELECT * FROM org WHERE hardware = 1;


-- Service level of a device
CREATE TABLE service
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	descript VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Device domain
CREATE TABLE domain
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	descript VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Operating System
CREATE TABLE os
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	manufacturer INTEGER NOT NULL REFERENCES org,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- A specifc model of hardware, e.g. Sun v240, Apple Xserve 
CREATE TABLE hardware
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	manufacturer INTEGER NOT NULL REFERENCES org,
	size INTEGER NOT NULL,
	image VARCHAR,
	support_url VARCHAR,
	spec_url VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Role played by the device, e.g. web server, Oracle server, router
CREATE TABLE role
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	descript VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- An individual piece of hardware
CREATE TABLE device
(
	id SERIAL PRIMARY KEY,
	name VARCHAR NOT NULL,
	domain INTEGER NOT NULL REFERENCES domain,
	rack INTEGER NOT NULL REFERENCES rack,
	rack_pos INTEGER,
	hardware INTEGER NOT NULL REFERENCES hardware,
	serial_no VARCHAR,
	asset_no VARCHAR,
	purchased CHAR(10),
	os INTEGER NOT NULL REFERENCES os,
	os_version VARCHAR,
	os_licence_key VARCHAR, 
	customer INTEGER NOT NULL REFERENCES org,
	service INTEGER NOT NULL REFERENCES service,
	role INTEGER NOT NULL REFERENCES role,
	monitored INTEGER NOT NULL DEFAULT 0,
	in_service INTEGER NOT NULL DEFAULT 0,
	primary_mac VARCHAR,
	install_build VARCHAR,
	custom_info VARCHAR, 
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Applications and services provided by the device
CREATE TABLE app
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	descript VARCHAR,
	notes VARCHAR,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Relationships applications can have with devices
CREATE TABLE app_relation
(
	id SERIAL PRIMARY KEY,
	name VARCHAR UNIQUE NOT NULL,
	meta_default_data INTEGER NOT NULL DEFAULT 0,
	meta_update_time VARCHAR,
	meta_update_user VARCHAR	
);


-- Relates devices to apps
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


-- To log changes in RackMonkey entries
CREATE TABLE logging
(
	id SERIAL PRIMARY KEY,
	table_changed VARCHAR NOT NULL,
	id_changed INTEGER NOT NULL,
	name_changed VARCHAR,
	change_type VARCHAR,
	descript VARCHAR,
	update_time VARCHAR,
	update_user VARCHAR
);


-- To store meta information about Rackmonkey database, e.g. revision.
CREATE TABLE rm_meta
(
	id SERIAL PRIMARY KEY,
	name VARCHAR NOT NULL,
	value VARCHAR NOT NULL
);


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
