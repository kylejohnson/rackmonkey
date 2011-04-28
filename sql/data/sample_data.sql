-- ---------------------------------------------------------------------------
-- RackMonkey - Know Your Racks - http://www.rackmonkey.org                 --
-- Version 1.2.5-1                                                          --
-- (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                --
-- Sample content for RackMonkey database                                   --
-- ---------------------------------------------------------------------------

-- The inclusion of a company or product in this file does not consitute an endorement by the author. 
-- All trademarks are the property of their respective owners.

-- sample organisations
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Apple', 		NULL, 0, 1, 1, 'Apple', 'http://www.apple.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Canonical', 	NULL, 0, 1, 0, 'Canonical', 'http://www.canonical.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('CentOS', 		NULL, 0, 1, 0, 'CentOS Project', 'http://www.centos.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Cisco', 		NULL, 0, 1, 1, 'Cisco Systems', 'http://www.cisco.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Debian', 		NULL, 0, 1, 0, 'Debian Project', 'http://www.debian.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Dell', 		NULL, 0, 0, 1, 'Dell', 'http://www.dell.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Foundry', 		NULL, 0, 0, 1, 'Foundry Networks', 'http://www.foundrynet.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('FreeBSD', 		NULL, 0, 1, 0, 'FreeBSD Project', 'http://www.freebsd.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Gentoo', 		NULL, 0, 1, 0, 'Gentoo Foundation', 'http://www.gentoo.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('HP', 			NULL, 0, 1, 1, 'Hewlett Packard', 'http://www.hp.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('IBM', 			NULL, 0, 1, 1, 'International Business Machines', 'http://www.ibm.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Juniper', 		NULL, 0, 1, 1, 'Juniper Networks', 'http://www.juniper.net', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Lantronix', 	NULL, 0, 0, 1, 'Lantronix', 'http://www.lantronix.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Lenovo', 		NULL, 0, 0, 1, 'Lenovo', 'http://www.lenovo.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Microsoft', 	NULL, 0, 1, 0, 'Microsoft', 'http://www.microsoft.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('NetApp', 		NULL, 0, 0, 1, 'NetApp', 'http://www.netapp.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('NetBSD', 		NULL, 0, 1, 0, 'NetBSD Foundation', 'http://www.netbsd.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Novell', 		NULL, 0, 1, 0, 'Novell', 'http://www.novell.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('OpenBSD', 		NULL, 0, 1, 0, 'OpenBSD Project', 'http://www.openbsd.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Red Hat', 		NULL, 0, 1, 0, 'Red Hat', 'http://www.redhat.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Slackware',	NULL, 0, 1, 0, 'Slackware Linux Project', 'http://www.slackware.org', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('Sun', 			NULL, 0, 1, 1, 'Sun Microsystems', 'http://www.sun.com', '', '1985-07-24 00:00:00', 'install');
INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES('VMWare', 		NULL, 0, 1, 0, 'VMWare', 'http://www.vmware.com', '', '1985-07-24 00:00:00', 'install');


-- sample operating systems
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('AIX', 						13, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('CentOS', 					5, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Data ONTAP', 				18, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Debian', 					7, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Fedora',      				22, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('FreeBSD', 					10, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Gentoo Linux', 				11, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('HP-UX', 						12, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('IOS', 						6, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('JUNOS', 						14, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Mac OS X Server',			3, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('NetBSD', 					19, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('OpenBSD',					21, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('OpenSolaris', 				24, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Red Hat Enterprise Linux', 	22, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Slackware Linux',			23, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Solaris', 					24, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('SUSE Linux', 				20, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Ubuntu',		 				4, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('ESX', 						25, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('ESXi', 						25, '', '1985-07-24 00:00:00', 'install');
INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES('Windows Server', 			17, '', '1985-07-24 00:00:00', 'install');

-- sample hardware
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('Catalyst 3560', 		6, 1, NULL, 'http://www.cisco.com/en/US/products/hw/switches/ps5528/tsd_products_support_series_home.html', 'http://www.cisco.com/en/US/products/hw/switches/ps5528/products_data_sheet09186a00801f3d7d.html', '', '1985-07-24 00:00:00', 'install');
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('PowerEdge 2850', 		8, 2, NULL, 'http://support.dell.com/support/edocs/systems/pe2850/en/', NULL, '', '1985-07-24 00:00:00', 'install');
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('ProLiant DL365 G5', 	12, 1, NULL, 'http://h20000.www2.hp.com/bizsupport/TechSupport/Home.jsp?lang=en&cc=us&prodTypeId=15351&prodSeriesId=3546421&lang=en&cc=us', 'http://h18004.www1.hp.com/products/quickspecs/12799_div/12799_div.html', '', '1985-07-24 00:00:00', 'install');
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('System p5 510Q', 		13, 2, NULL, 'http://www.ibm.com/servers/support/p/', 'http://www-03.ibm.com/systems/p/hardware/entry/510q/specs.html', '', '1985-07-24 00:00:00', 'install');
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('FAS3170', 	            18, 6, NULL, 'http://now.netapp.com', 'http://www.netapp.com/us/products/storage-systems/fas3100/fas3100-tech-specs.html', '', '1985-07-24 00:00:00', 'install');
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('Fire T2000', 			24, 2, NULL, 'http://sunsolve.sun.com/handbook_pub/Systems/SunFireT2000_R/SunFireT2000_R.html', 'http://sunsolve.sun.com/handbook_pub/Systems/SunFireT2000_R/spec.html', '', '1985-07-24 00:00:00', 'install');
INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES('Fire x4600',           24, 4, NULL, 'http://sunsolve.sun.com/handbook_pub/Systems/SunFireX4600_M2/SunFireX4600_M2.html', 'http://sunsolve.sun.com/handbook_pub/Systems/SunFireX4600_M2/spec.html', '', '1988-02-15 00:00:00', 'rackmonkey');

-- sample roles
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('App Server', 			'Application Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('AV Encoder', 			'Audio/Video Encoder', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('AV Streaming', 		'Audio/Video Streaming Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Data Backup', 			'Data Backup', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Data Storage', 		'Data Storage', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('DB Server', 			'Database Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Dev Server', 			'Development Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Disk Array', 			'Disk Array', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('FC Switch', 			'Fibre Channel Switch', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('File Server', 			'File Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('General Server', 		'General Purpose Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Human Interface', 		'Monitor, Keyboard etc.', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('KVM', 					'KVM Switch', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Monitoring', 			'Systems Monitoring', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Patch Panel', 			'Patch Panel', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Physical Storage', 	'Storage for Physical Items', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Power', 				'Electrical Power Infrastructure', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Router', 				'Network Router', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Switch', 				'Network Switch', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Tape Drive',			'Tape Drive or Library', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Terminal Server',		'Terminal Server', '', '1985-07-24 00:00:00', 'install');
INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES('Web Server',			'Web Server', '', '1985-07-24 00:00:00', 'install');

-- sample building, room, row and rack
INSERT INTO building (name, name_short, notes, meta_update_time, meta_update_user) VALUES('Acme Data Centre', 'ADC', '', '1985-07-24 00:00:00', 'install');
INSERT INTO room (name, building, has_rows, notes, meta_update_time, meta_update_user) VALUES('101', 6, 0, '', '1985-07-24 00:00:00', 'install');
INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_update_time, meta_update_user) VALUES('-', 6, 0, 1, '', '1985-07-24 00:00:00', 'install');
INSERT INTO rack (name, row, row_pos, hidden_rack, size, notes, meta_update_time, meta_update_user) VALUES('A1', 6, 0, 0, 42, '', '1985-07-24 00:00:00', 'install');
