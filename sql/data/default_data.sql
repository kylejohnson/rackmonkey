-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Default data for RackMonkey database                                     --
-- ---------------------------------------------------------------------------

-- default buildings
INSERT INTO building (name, name_short, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('unknown', 'unknown', '', 5, '1970-01-01 00:00:00', 'install');
INSERT INTO building (name, name_short, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('planned', 'plan', '', 4, '1970-01-01 00:00:00', 'install');
INSERT INTO building (name, name_short, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('on order', 'order', '', 3, '1970-01-01 00:00:00', 'install');
INSERT INTO building (name, name_short, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('being repaired', 'repair', '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO building (name, name_short, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('decommissioned', 'decom', '', 1, '1970-01-01 00:00:00', 'install');

-- default rooms
INSERT INTO room (name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('unknown', 1, 0, '', 5, '1970-01-01 00:00:00', 'install');
INSERT INTO room (name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('planned', 2, 0, '', 4, '1970-01-01 00:00:00', 'install');
INSERT INTO room (name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('on order', 3, 0, '', 3, '1970-01-01 00:00:00', 'install');
INSERT INTO room (name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('being repaired', 4, 0, '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO room (name, building, has_rows, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('decommissioned', 5, 0, '', 1, '1970-01-01 00:00:00', 'install');

-- default rows
INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('unknown', 1, 1, 1, '', 5, '1970-01-01 00:00:00', 'install');
INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('planned', 2, 1, 1, '', 4, '1970-01-01 00:00:00', 'install');
INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('on order', 3, 1, 1, '', 3, '1970-01-01 00:00:00', 'install');
INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('being repaired', 4, 1, 1, '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('decommissioned', 5, 1, 1, '', 1, '1970-01-01 00:00:00', 'install');

-- default racks
INSERT INTO rack (name, row, row_pos, hidden_rack, size, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('unknown', 1, 1, 1, 0, '', 5, '1970-01-01 00:00:00', 'install');
INSERT INTO rack (name, row, row_pos, hidden_rack, size, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('planned', 2, 1, 1, 0, '', 4, '1970-01-01 00:00:00', 'install');
INSERT INTO rack (name, row, row_pos, hidden_rack, size, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('on order', 3, 1, 1, 0, '', 3, '1970-01-01 00:00:00', 'install');
INSERT INTO rack (name, row, row_pos, hidden_rack, size, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('being repaired', 4, 1, 1, 0, '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO rack (name, row, row_pos, hidden_rack, size, notes, meta_default_data, meta_update_time, meta_update_user) VALUES ('decommissioned', 5, 1, 1, 0, '', 1, '1970-01-01 00:00:00', 'install');

-- default organisation
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('unknown', NULL, 1, 1, 1, 'Organisation not known.', NULL, '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('not applicable',	NULL, 1, 1, 1, 'Organisation not applicable.', NULL, '', 1, '1970-01-01 00:00:00', 'install');

-- default service level
INSERT INTO service (name, descript, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('unknown', 'Service level not known.', '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO service (name, descript, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('not applicable', 'Service level not applicable.', '', 1, '1970-01-01 00:00:00', 'install');

-- default domain
INSERT INTO domain (name, descript, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('unknown', 'Domain not known.', '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO domain (name, descript, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('not applicable', 'Domain not applicable.', '', 1, '1970-01-01 00:00:00', 'install');

-- default operating systems
INSERT INTO os (name, manufacturer, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('unknown', 1, '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('not applicable', 2, '', 1, '1970-01-01 00:00:00', 'install');

-- default hardware
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('unknown', 1, 1, NULL, NULL, NULL, '', 1, '1970-01-01 00:00:00', 'install');

-- default roles
INSERT INTO role (name, descript, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('unknown', 'Role not known.', '', 2, '1970-01-01 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_default_data, meta_update_time, meta_update_user) VALUES('none', 'Role not currently assigned.', '', 1, '1970-01-01 00:00:00', 'install');

-- default application relationships
INSERT INTO app_relation (name, meta_default_data, meta_update_time, meta_update_user) VALUES ('is run on', 0, '1970-01-01 00:00:00', 'install');
INSERT INTO app_relation (name, meta_default_data, meta_update_time, meta_update_user) VALUES ('is developed on', 0, '1970-01-01 00:00:00', 'install');
INSERT INTO app_relation (name, meta_default_data, meta_update_time, meta_update_user) VALUES ('is tested on', 0, '1970-01-01 00:00:00', 'install');
INSERT INTO app_relation (name, meta_default_data, meta_update_time, meta_update_user) VALUES ('is staged on', 0, '1970-01-01 00:00:00', 'install');
INSERT INTO app_relation (name, meta_default_data, meta_update_time, meta_update_user) VALUES ('is on standby on', 0, '1970-01-01 00:00:00', 'install');
INSERT INTO app_relation (name, meta_default_data, meta_update_time, meta_update_user) VALUES ('uses', 0, '1970-01-01 00:00:00', 'install');
