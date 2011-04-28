package RackMonkey::Engine;
##############################################################################
# RackMonkey - Know Your Racks - http://www.rackmonkey.org                   #
# Version 1.2.5-1                                                            #
# (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                  #
# DBI Engine for Rackmonkey                                                  #
##############################################################################

use strict;
use warnings;

use 5.006_001;

use Carp;
use DBI;
use Time::Local;

use RackMonkey::Conf;

our $VERSION = '1.2.5-1';
our $AUTHOR  = 'Will Green (wgreen at users.sourceforge.net)';

##############################################################################
# Common Methods                                                             #
##############################################################################

sub new
{
    my ($className) = @_;
    my $conf = RackMonkey::Conf->new;
    croak "RM_ENGINE: No database specified in configuration file. Check value of 'dbconnect' in " . $$conf{'configpath'} . '.' unless ($$conf{'dbconnect'});

    # The sys hash contains basic system profile information (should be altered to use the DBI DSN parse method?)
    my ($dbDriver, $dbDataSource) = $$conf{'dbconnect'} =~ /dbi:(.*?):(.*)/;
    my $sys = {
        'db_driver'                 => "DBD::$dbDriver",
        'os'                        => $^O,
        'perl_version'              => $],
        'rackmonkey_engine_version' => $VERSION
    };
    $$conf{'db_data_source'} = $dbDataSource;

    my $currentDriver = $$sys{'db_driver'};
    unless ($$conf{'bypass_db_driver_checks'})
    {
        # Check we're using SQLite, Postgres or MySQL
        unless (($currentDriver eq 'DBD::SQLite') || ($currentDriver eq 'DBD::Pg') || ($currentDriver eq 'DBD::mysql'))
        {
            croak "RM_ENGINE: You tried to use an unsupported database driver '$currentDriver'. RackMonkey supports SQLite (DBD::SQLite), Postgres (DBD::Pg) or MySQL (DBD::mysql). Please check you typed the driver name correctly (names are case sensitive). Consult the installation and troubleshooting documents for more information.";
        }
    }

    # If using SQLite only connect if database file exists, don't create it
    if ($$sys{'db_driver'} eq 'DBD::SQLite')
    {
        my ($databasePath) = $$conf{'db_data_source'} =~ /dbname=(.*)/;
        croak "RM_ENGINE: SQLite database '$databasePath' does not exist. Check the 'dbconnect' path in rackmonkey.conf and that you have created a RackMonkey database as per the install guide."
          unless (-e $databasePath);
    }

    # To get DB server information and do remaining driver checks we need to load the driver
    my $dbh = DBI->connect($$conf{'dbconnect'}, $$conf{'dbuser'}, $$conf{'dbpass'}, {'AutoCommit' => 0, 'RaiseError' => 1, 'PrintError' => 0, 'ShowErrorStatement' => 1});

    # Get information on the database server
    if ($currentDriver eq 'DBD::SQLite')
    {
        $$sys{'db_server_version'}     = 'not applicable';
        $$sys{'db_driver_lib_version'} = $dbh->{'sqlite_version'};
    }
    elsif ($currentDriver eq 'DBD::Pg')
    {
        $$sys{'db_server_version'}     = $dbh->{'pg_server_version'};
        $$sys{'db_driver_lib_version'} = $dbh->{'pg_lib_version'};
    }
    elsif ($currentDriver eq 'DBD::mysql')
    {
        $$sys{'db_server_version'}     = $dbh->{'mysql_serverinfo'};
        $$sys{'db_driver_lib_version'} = 'not available';
    }

    unless ($$conf{'bypass_db_driver_checks'})
    {
        # Checks that the DBI version and DBD driver are supported
        my $driverVersion = eval("\$${currentDriver}::VERSION");
        my $DBIVersion    = eval("\$DBI::VERSION");
        $$sys{'db_driver_version'} = $driverVersion;
        $$sys{'dbi_version'}       = $DBIVersion;

        # All users now tequire DBI 1.45 or higher (due to last insert ID issues)
        if ($DBIVersion < 1.45)
        {
            croak "RM_ENGINE: You tried to use an unsupported version of the DBI database interface. You need to use DBI version 1.45 or higher. You are using DBI v$DBIVersion. Please consult the installation and troubleshooting documents.";
        }

        # SQLite users require DBD::SQLite 1.12 or higher (this equates to SQLite 3.3.5)
        if (($currentDriver eq 'DBD::SQLite') && ($driverVersion < 1.12))
        {
            croak "RM_ENGINE: You tried to use an unsupported database driver. RackMonkey requires DBD::SQLite 1.12 or higher. You are using DBD::SQLite $driverVersion. Please consult the installation and troubleshooting documents.";
        }

        # Postgres users require DBD::Pg 1.48 or higher
        if (($currentDriver eq 'DBD::Pg') && ($driverVersion < 1.48))
        {
            croak "RM_ENGINE: You tried to use an unsupported database driver. RackMonkey requires DBD::Pg 1.48 or higher. You are using DBD::Pg $driverVersion. Please consult the installation and troubleshooting documents.";
        }

        # MySQL users require DBD::mysql 3.0002 or higher
        if (($currentDriver eq 'DBD::mysql') && ($driverVersion < 3.0002))
        {
            croak "RM_ENGINE: You tried to use an unsupported database driver. RackMonkey requires DBD::mysql 3.0002 or higher. You are using DBD::mysql $driverVersion. Please consult the installation and troubleshooting documents.";
        }

        # MySQL users require server version 5 or higher (5.0.22 is earliest tested release, but we allow any release 5.0 or above here)
        if (($currentDriver eq 'DBD::mysql') && (substr($$sys{'db_server_version'}, 0, 1) < 5))
        {
            croak "RM_ENGINE: You tried to use an unsupported MySQL server version. RackMonkey requires MySQL 5 or higher. You are using MySQL " . $$sys{'db_server_version'} . ". Please consult the installation and troubleshooting documents.";
        }
    }

    my $self = {'dbh' => $dbh, 'conf' => $conf, 'sys' => $sys};
    bless $self, $className;
}

sub getConf
{
    my ($self, $key) = @_;
    return $self->{'conf'}{$key};
}

sub getConfHash
{
    my $self = shift;
    return $self->{'conf'}
}

sub dbh
{
    my $self = shift;
    return $self->{'dbh'};
}

sub simpleItem
{
    my ($self, $id, $table) = @_;
    croak 'RM_ENGINE: Not a valid table.' unless $self->_checkTableName($table);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT id, name 
		FROM $table 
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $entry = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such entry '$id' in table '$table'." unless defined($$entry{'id'});
    return $entry;
}

sub simpleList
{
    my ($self, $table, $all) = @_;
    $all ||= 0;
    croak "RM_ENGINE: Not a valid table." unless $self->_checkTableName($table);
    my $sth;

    unless ($all)
    {
        $sth = $self->dbh->prepare(
            qq!
    		SELECT 
    			id, 
    			name,
    			meta_default_data 
    		FROM $table 
    		WHERE meta_default_data = 0
    		ORDER BY 
    		    meta_default_data DESC,
    			name
    	!
        );
    }
    else
    {
        $sth = $self->dbh->prepare(
            qq!
    		SELECT 
    			id, 
    			name,
    			meta_default_data
    		FROM $table 
    		ORDER BY
    		    meta_default_data DESC,
    			name
    	!
        );
    }

    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub itemCount
{
    my ($self, $table) = @_;
    croak "RM_ENGINE: Not a valid table" unless $self->_checkTableName($table);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT count(*) 
		FROM $table  
		WHERE meta_default_data = 0
	!
    );
    $sth->execute;
    return ($sth->fetchrow_array)[0];
}

sub performAct
{
    my ($self, $type, $act, $updateUser, $record) = @_;
    unless ($type =~ /^(?:app|building|device|deviceApp|domain|hardware|org|os|rack|report|role|room|row|service)$/)
    {
        croak "RM_ENGINE: '$type' is not a recognised type. Recognised types are app, building, device, deviceApp, domain, hardware, org, os, rack, report, role, room, row and service";
    }
    my $actStr  = $act;
    my $typeStr = $type;
    $act = 'update' if ($act eq 'insert');
    croak "RM_ENGINE: '$act is not a recognised act. This error should not occur, did you manually type this URL?" unless $act =~ /^(?:update|delete)$/;

    # check username for update is valid
    croak "RM_ENGINE: User update names must be less than " . $self->getConf('maxstring') . " characters."
      unless (length($updateUser) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: You cannot use the username 'install', it's reserved for use by Rackmonkey."    if (lc($updateUser) eq 'install');
    croak "RM_ENGINE: You cannot use the username 'rackmonkey', it's reserved for use by Rackmonkey." if (lc($updateUser) eq 'rackmonkey');

    # calculate update time (always GMT)
    my ($sec, $min, $hour, $day, $month, $year) = (gmtime)[0, 1, 2, 3, 4, 5];
    my $updateTime = sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year+1900, $month+1, $day, $hour, $min, $sec); # perl months begin at 0 and perl years at 1900

    $type = $act . ucfirst($type);
    my $lastId = $self->$type($updateTime, $updateUser, $record);

    # log change (currently only provides basic logging)
    my $sth = $self->dbh->prepare(qq!INSERT INTO logging (table_changed, id_changed, name_changed, change_type, descript, update_time, update_user) VALUES(?, ?, ?, ?, ?, ?, ?)!);
    $sth->execute($typeStr, $lastId, $$record{'name'}, $actStr, '', $updateTime, $updateUser);

    $self->dbh->commit();    # if everything was successful we commit
    return $lastId;
}

sub _lastInsertId
{
    my ($self, $table) = @_;
    return $self->dbh->last_insert_id(undef, undef, $table, undef);
}

sub _checkName
{
    my ($self, $name) = @_;
    croak "RM_ENGINE: You must specify a name." unless defined $name;
    unless ($name =~ /^\S+/)
    {
        croak "RM_ENGINE: You must specify a valid name. Names may not begin with white space.";
    }
    unless (length($name) <= $self->getConf('maxstring'))
    {
        croak "RM_ENGINE: Names cannot exceed " . $self->getConf('maxstring') . " characters.";
    }
}

sub _checkNotes
{
    my ($self, $notes) = @_;
    return unless defined $notes;
    unless (length($notes) <= $self->getConf('maxnote'))
    {
        croak "RM_ENGINE: Notes cannot exceed " . $self->getConf('maxnote') . " characters.";
    }
}

sub _checkDate
{
    my ($self, $date) = @_;
    return unless $date;
    croak "RM_ENGINE: Date not in valid format (YYYY-MM-DD)." unless $date =~ /^\d{4}-\d\d?-\d\d?$/;
    my ($year, $month, $day) = split '-', $date;
    eval { timelocal(0, 0, 12, $day, $month - 1, $year - 1900); };    # perl months begin at 0 and perl years at 1900
    croak "RM_ENGINE: $year-$month-$day is not a valid date of the form YYYY-MM-DD. Check that the date exists. NB. Date validation currently only accepts years 1970 - 2038.\n$@"
      if ($@);
    return sprintf("%04d-%02d-%02d", $year, $month, $day);
}

sub _checkTableName
{
    my ($self, $table) = @_;
    return ($table =~ /^[a-z_]+$/) ? 1: 0;
}

sub _checkOrderBy
{
    my ($self, $orderBy) = @_;
    return ($orderBy =~ /^[a-z_]+\.[a-z_]+$/) ? 1: 0;
}

sub _httpFixer
{
    my ($self, $url) = @_;
    return '' unless defined $url;
    return '' unless (length($url));                                  # Don't add to empty strings
    unless ($url =~ /^\w+:\/\//)                                      # Does URL begin with a protocol?
    {
        $url = "http://$url";
    }
    return $url;
}


##############################################################################
# Application Methods                                                        #
##############################################################################

sub app
{
    my ($self, $id) = @_;
    croak "RM_ENGINE: Unable to retrieve app. No app id specified." unless ($id);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT app.* 
		FROM app 
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $app = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such app id." unless defined($$app{'id'});
    return $app;
}

sub appList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'app.name' unless $self->_checkOrderBy($orderBy);
    $orderBy = $orderBy . ', app.name' unless $orderBy eq 'app.name';    # default second ordering is name
    my $sth = $self->dbh->prepare(
        qq!
		SELECT app.* 
		FROM app
		WHERE meta_default_data = 0
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub appDevicesUsedList
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
		    device_app.id               AS device_app_id,
			device.id			        AS device_id,
		 	device.name			        AS device_name, 
			app.name			        AS app_name,
			app_relation.id 	        AS app_relation_id,
			app_relation.name 	        AS app_relation_name,
			domain.name			        AS domain_name,
			domain.meta_default_data	AS domain_meta_default_data
		FROM
			device, app_relation, device_app, app, domain 
		WHERE
		 	device_app.app = app.id AND 
			device_app.device = device.id AND 
			device_app.relation = app_relation.id AND
			device.domain = domain.id AND 
			app.id = ?
	!
    );
    $sth->execute($id);
    return $sth->fetchall_arrayref({});
}

sub appOnDeviceList
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
		    device_app.id       AS device_app_id,
		    app_relation.name   AS app_relation_name,
			app.id				AS app_id,
			app.name			AS app_name
		FROM
			device, app_relation, device_app, app 
		WHERE
		 	device_app.app = app.id AND 
			device_app.device = device.id AND 
			device_app.relation = app_relation.id AND
			device.id = ?
		ORDER BY
			app.name
	!
    );
    $sth->execute($id);
    return $sth->fetchall_arrayref({});
}

sub updateApp
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update app. No app record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE app SET name = ?, descript = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateAppUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This app may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO app (name, descript, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateAppUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('app');
    }
    return $newId || $$record{'id'};
}

sub deleteApp
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No app id specified." unless ($deleteId);

    # delete app with associated device relationships
    my $sth = $self->dbh->prepare(qq!DELETE FROM device_app WHERE app = ?!);
    my $ret = $sth->execute($deleteId);                                        # this return value isn't currently used
    $sth = $self->dbh->prepare(qq!DELETE FROM app WHERE id = ?!);
    $ret = $sth->execute($deleteId);

    croak "RM_ENGINE: Delete failed. This app does not currently exist, it may have been removed already." if ($ret eq '0E0');

    return $deleteId;
}

sub _validateAppUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate app. No app record specified." unless ($record);
    $self->_checkName($$record{'name'});
    $self->_checkNotes($$record{'notes'});
    return ($$record{'name'}, $$record{'descript'}, $$record{'notes'});
}


##############################################################################
# Building Methods                                                           #
##############################################################################

sub building
{
    my ($self, $id) = @_;
    croak "RM_ENGINE: Unable to retrieve building. No building id specified." unless ($id);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT building.* 
		FROM building 
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $building = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such building id." unless defined($$building{'id'});
    return $building;
}

sub buildingList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'building.name' unless $self->_checkOrderBy($orderBy);
    $orderBy = $orderBy . ', building.name' unless $orderBy eq 'building.name';    # default second ordering is name
    my $sth = $self->dbh->prepare(
        qq!
		SELECT building.* 
		FROM building
		WHERE meta_default_data = 0
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateBuilding
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update building. No building record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE building SET name = ?, name_short = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateBuildingUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This building may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO building (name, name_short, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateBuildingUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('building');
    }
    return $newId || $$record{'id'};
}

sub deleteBuilding
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No building id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM building WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This building does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateBuildingUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate building. No building record specified." unless ($record);
    $self->_checkName($$record{'name'});

    if (defined $$record{'name_short'})
    {
        # check short name isn't too long - should be moved to a more general _checkName
        unless (length($$record{'name_short'}) <= $self->getConf('maxstring'))
        {
            croak "RM_ENGINE: Names cannot exceed " . $self->getConf('maxstring') . " characters.";
        }
    }

    $self->_checkNotes($$record{'notes'});
    return ($$record{'name'}, $$record{'name_short'}, $$record{'notes'});
}


##############################################################################
# Device Methods                                                             #
##############################################################################

sub device
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			device.*, 
			rack.name 					AS rack_name,
			row.name					AS row_name,
			row.id						AS row_id,
			room.name					AS room_name,
			room.id						AS room_id,
			building.name				AS building_name,
			building.name_short			AS building_name_short,			
			building.id					AS building_id,	
			building.meta_default_data	AS building_meta_default_data,
			hardware.name 				AS hardware_name,
			hardware.size 				AS hardware_size,
			hardware.meta_default_data	AS hardware_meta_default_data,
			hardware_manufacturer.id	AS hardware_manufacturer_id,
			hardware_manufacturer.name	AS hardware_manufacturer_name,
			hardware_manufacturer.meta_default_data AS hardware_manufacturer_meta_default_data,
			role.name 					AS role_name, 
			role.meta_default_data		AS role_meta_default_data,
			os.name 					AS os_name,
			os.meta_default_data		AS os_meta_default_data,
			customer.name 				AS customer_name,
			customer.meta_default_data	AS customer_meta_default_data,
			service.name 				AS service_name,
			service.meta_default_data	AS service_meta_default_data,
			domain.name					AS domain_name,
			domain.meta_default_data	AS domain_meta_default_data
		FROM device, rack, row, room, building, hardware, org hardware_manufacturer, role, os, org customer, service, domain 
		WHERE 
			device.rack = rack.id AND 
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id AND			
			device.hardware = hardware.id AND 
			hardware.manufacturer = hardware_manufacturer.id AND
			device.role = role.id AND
			device.os = os.id AND
			device.customer = customer.id AND
			device.domain = domain.id AND
			device.service = service.id AND
			device.id = ?
	!
    );
    $sth->execute($id);
    my $device = $sth->fetchrow_hashref('NAME_lc');
    croak 'RM_ENGINE: No such device id.' unless defined($$device{'id'});
    return $device;
}

sub deviceList
{
    my $self         = shift;
    my $orderBy      = shift || '';
    my $filters      = shift || {};
    my $filterBy     = '';
    my $deviceSearch = shift || '';
    $deviceSearch = lc($deviceSearch);    # searching is case insensitive

    for my $f (keys %$filters)
    {
        $filterBy .= " AND $f=" . $$filters{"$f"};
    }

    $deviceSearch = "AND ( lower(device.name) LIKE '%$deviceSearch%' OR lower(device.serial_no) LIKE '%$deviceSearch%' OR lower(device.asset_no) LIKE '%$deviceSearch%' )"
      if ($deviceSearch);
    $orderBy = 'device.name' unless $self->_checkOrderBy($orderBy);

    # ensure meta_default entries appear last - need a better way to do this
    $orderBy = 'room.meta_default_data, ' . $orderBy                                 if ($orderBy =~ /^room.name/);
    $orderBy = 'rack.meta_default_data, ' . $orderBy . ', device.rack_pos'           if ($orderBy =~ /^rack.name/);
    $orderBy = 'role.meta_default_data, ' . $orderBy                                 if ($orderBy =~ /^role.name/);
    $orderBy = 'hardware.meta_default_data, hardware_manufacturer.name, ' . $orderBy if ($orderBy =~ /^hardware.name/);
    $orderBy = 'os.meta_default_data, ' . $orderBy . ', device.os_version'           if ($orderBy =~ /^os.name/);
    $orderBy = 'customer.meta_default_data, ' . $orderBy                             if ($orderBy =~ /^customer.name/);
    $orderBy = 'service.meta_default_data, ' . $orderBy                              if ($orderBy =~ /^service.name/);

    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			device.*, 
			rack.name 					AS rack_name,
			row.name					AS row_name,
			row.id						AS row_id,
			room.name					AS room_name,
			room.id						AS room_id,
			building.name				AS building_name,
			building.name_short			AS building_name_short,			
			building.id					AS building_id,	
			building.meta_default_data	AS building_meta_default_data,
			hardware.name 				AS hardware_name,
			hardware.size 				AS hardware_size,
			hardware.meta_default_data	AS hardware_meta_default_data,
			hardware_manufacturer.id	AS hardware_manufacturer_id,
			hardware_manufacturer.name	AS hardware_manufacturer_name,
			hardware_manufacturer.meta_default_data	AS hardware_manufacturer_meta_default_data,
			role.name 					AS role_name, 
			os.name 					AS os_name, 
			customer.name 				AS customer_name,
			service.name 				AS service_name,
			domain.name					AS domain_name,
			domain.meta_default_data	AS domain_meta_default_data
		FROM device, rack, row, room, building, hardware, org hardware_manufacturer, role, os, org customer, service, domain 
		WHERE 
			device.meta_default_data = 0 AND
			device.rack = rack.id AND 
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id AND			
			device.hardware = hardware.id AND 
			hardware.manufacturer = hardware_manufacturer.id AND
			device.role = role.id AND
			device.os = os.id AND
			device.customer = customer.id AND
			device.domain = domain.id AND
			device.service = service.id
			$filterBy
			$deviceSearch
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub deviceListInRack
{
    my ($self, $rack) = @_;
    $rack += 0;    # force rack to be numerical

    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			device.*,
			rack.name 					AS rack_name,
			rack.id						AS rack_id,
			building.meta_default_data	AS building_meta_default_data,
			hardware.name 				AS hardware_name,
			hardware.meta_default_data	AS hardware_meta_default_data,
			hardware_manufacturer.id	AS hardware_manufacturer_id,
			hardware_manufacturer.name	AS hardware_manufacturer_name,
			hardware_manufacturer.meta_default_data	AS hardware_manufacturer_meta_default_data,
			hardware.size				AS hardware_size,
			domain.name					AS domain_name,
			domain.meta_default_data	AS domain_meta_default_data,
			role.name 					AS role_name, 
			customer.name 				AS customer_name
		FROM
			device, rack, row, room, building, hardware, org hardware_manufacturer, domain, role, org customer
		WHERE
			device.meta_default_data = 0 AND
			device.rack = rack.id AND 
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id AND				
			device.hardware = hardware.id AND
			hardware.manufacturer = hardware_manufacturer.id AND
			device.domain = domain.id AND
			device.role = role.id AND
			device.customer = customer.id AND
			rack.id = ?
		ORDER BY rack.row_pos
	!
    );

    $sth->execute($rack);
    return $sth->fetchall_arrayref({});
}

sub deviceListUnracked    # consider merging this with existing device method (they have a great deal in common)
{
    my $self     = shift;
    my $orderBy  = shift || '';
    my $filters  = shift || {};
    my $filterBy = '';

    for my $f (keys %$filters)
    {
        $filterBy .= " AND $f=" . $$filters{"$f"};
    }

    $orderBy = 'device.name' unless $self->_checkOrderBy($orderBy);

    # ensure meta_default entries appear last - need a better way to do this
    $orderBy = 'rack.meta_default_data, ' . $orderBy . ', device.rack_pos'           if ($orderBy =~ /^rack.name/);
    $orderBy = 'role.meta_default_data, ' . $orderBy                                 if ($orderBy =~ /^role.name/);
    $orderBy = 'hardware.meta_default_data, hardware_manufacturer.name, ' . $orderBy if ($orderBy =~ /^hardware.name/);
    $orderBy = 'os.meta_default_data, ' . $orderBy . ', device.os_version'           if ($orderBy =~ /^os.name/);

    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			device.*,
			rack.name 					AS rack_name,
			building.meta_default_data	AS building_meta_default_data,
			hardware.name 				AS hardware_name,
			hardware.meta_default_data	AS hardware_meta_default_data,
			hardware_manufacturer.id	AS hardware_manufacturer_id,
			hardware_manufacturer.name	AS hardware_manufacturer_name,
			hardware_manufacturer.meta_default_data	AS hardware_manufacturer_meta_default_data,
			hardware.size				AS hardware_size,
			domain.name					AS domain_name,
			domain.meta_default_data	AS domain_meta_default_data,
			role.name 					AS role_name,
			os.name 					AS os_name,
			customer.name 				AS customer_name
			FROM
			device, rack, row, room, building, hardware, org hardware_manufacturer, org customer, domain, role, os
		WHERE
			device.meta_default_data = 0 AND
			building.meta_default_data <> 0 AND
			device.rack = rack.id AND 
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id AND				
			device.hardware = hardware.id AND
			hardware.manufacturer = hardware_manufacturer.id AND
			device.domain = domain.id AND
			device.role = role.id AND
			device.os = os.id AND
			device.customer = customer.id
			$filterBy
		ORDER BY $orderBy
	!
    );

    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub deviceCountUnracked
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT count(*) 
		FROM device, rack, row, room, building  
		WHERE building.meta_default_data <> 0 AND
		device.rack = rack.id AND 
		rack.row = row.id AND
		row.room = room.id AND
		room.building = building.id AND
		device.meta_default_data = 0
	!
    );
    $sth->execute;
    return ($sth->fetchrow_array)[0];
}

sub updateDevice
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update device. No building device specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE device SET name = ?, domain = ?, rack = ?, rack_pos = ?, hardware = ?, serial_no = ?, asset_no = ?, purchased = ?, os = ?, os_version = ?, os_licence_key = ?, customer = ?, service = ?, role = ?, in_service = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateDeviceInput($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This device may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO device (name, domain, rack, rack_pos, hardware, serial_no, asset_no, purchased, os, os_version, os_licence_key, customer, service, role, in_service, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateDeviceInput($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('device');
    }
    return $newId || $$record{'id'};
}

sub deleteDevice
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No device id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM device WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This device does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateDeviceInput
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate device. No device record specified." unless ($record);
    $self->_checkName($$record{'name'});
    $self->_checkNotes($$record{'notes'});
    $$record{'purchased'} = $self->_checkDate($$record{'purchased'});    # check date and coerce to YYYY-MM-DD format

    # normalise in service value so it can be stored as an integer
    $$record{'in_service'} = $$record{'in_service'} ? 1 : 0;

    # If role is 'none' (id=2) then always set in service to false - this is a magic number, should find way to remove this
    $$record{'in_service'} = 0 if ($$record{'role'} == 2);

    # If location is meta_default then also set in service to false - this is a magic number, should find way to remove this
    $$record{'in_service'} = 0 if ($$record{'rack'} <= 5);

    # Check strings are valid
    unless (length($$record{'serial_no'}) <= $self->getConf('maxstring'))
    {
        croak "RM_ENGINE: Serial numbers cannot exceed " . $self->getConf('maxstring') . " characters.";
    }
    unless (length($$record{'asset_no'}) <= $self->getConf('maxstring'))
    {
        croak "RM_ENGINE: Asset numbers cannot exceed " . $self->getConf('maxstring') . " characters.";
    }
    unless (length($$record{'os_licence_key'}) <= $self->getConf('maxstring'))
    {
        croak "RM_ENGINE: OS licence keys cannot exceed " . $self->getConf('maxstring') . " characters.";
    }
    if (defined $$record{'primary_mac'}) # Not in UI by default: check defined to avoid warning message, should really be extended to all checks
    {
        unless (length($$record{'primary_mac'}) <= $self->getConf('maxstring'))
        {
            croak "RM_ENGINE: Primary MACs cannot exceed " . $self->getConf('maxstring') . " characters.";
        }
    }
    if (defined $$record{'install_build'}) # Not in UI by default: check defined to avoid warning message, should really be extended to all checks
    {
        unless (length($$record{'install_build'}) <= $self->getConf('maxstring'))
        {
            croak "RM_ENGINE: Install build names cannot exceed " . $self->getConf('maxstring') . " characters.";
        }
    }
    # check if we have a meta default location if so set rack position to zero, otherwise check we have a valid rack position
    my $rack = $self->rack($$record{'rack'});
    if ($$rack{'meta_default_data'})
    {
        $$record{'rack_pos'} = '0';
    }
    else    # location is in a real rack
    {
        # check we have a position and make sure it's an integer
        croak "RM_ENGINE: You need to specify a Rack Position." unless (length($$record{'rack_pos'}) > 0);
        $$record{'rack_pos'} = int($$record{'rack_pos'} + 0.5);

        # get the size of this hardware
        my $hardware     = $self->hardware($$record{'hardware_model'});
        my $hardwareSize = $$hardware{'size'};

        unless ($$record{'rack_pos'} > 0 and $$record{'rack_pos'} + $$hardware{'size'} - 1 <= $$rack{'size'})
        {
            croak "RM_ENGINE: The device '" . $$record{'name'} . "' cannot fit at that location. This rack is " . $$rack{'size'} . " U in height. This device is $hardwareSize U and you placed it at position " . $$record{'rack_pos'} . ".";
        }

        # ensure the location doesn't overlap any other devices in this rack
        # get the layout of this rack
        my $rackLayout = $self->rackPhysical($$record{'rack'}, undef, 1);

        # quick and dirty check for overlap, consider each position occupied by the new device and check it's empty
        # doesn't assume the rackPhyiscal method returns in a particular order
        my $devId = $$record{'id'} || 0;    # id of device if it already exists (so it can ignore clashes with itself)
        for ($$record{'rack_pos'} .. $$record{'rack_pos'} + $hardwareSize - 1)
        {
            my $pos = $_;
            for my $r (@$rackLayout)
            {
                croak "RM_ENGINE: Cannot put the device '" . $$record{'name'} . "' here (position " . $$record{'rack_location'} . " in rack " . $$rack{'name'} . ") because it overlaps with the device '" . $$r{'name'} . "'."
                  if ($$r{'rack_location'} == $pos and $$r{'name'} and ($$r{'id'} ne $devId));
            }
        }
    }

    # Check if OS is meta_default, if so set version to empty string
    my $os = $self->os($$record{'os'});
    if ($$os{'meta_default_data'})
    {
        $$record{'os_version'} = '';
    }

    return ($$record{'name'}, $$record{'domain'}, $$record{'rack'}, $$record{'rack_pos'}, $$record{'hardware_model'}, $$record{'serial_no'}, $$record{'asset_no'}, $$record{'purchased'}, $$record{'os'}, $$record{'os_version'}, $$record{'os_licence_key'}, $$record{'customer'}, $$record{'service'}, $$record{'role'}, $$record{'in_service'}, $$record{'notes'});
}

sub totalSizeDevice
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT COALESCE(SUM(hardware.size), 0) 
		FROM hardware, device, rack, row, room, building
		WHERE device.hardware = hardware.id AND
		building.meta_default_data = 0 AND
		device.rack = rack.id AND 
		rack.row = row.id AND
		row.room = room.id AND
		room.building = building.id AND
		device.meta_default_data = 0
	!
    );
    $sth->execute;
    return ($sth->fetchrow_array)[0];
}

sub duplicateSerials
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!    
        SELECT 
            device.name, 
            device.id, 
            device.serial_no,
            device.hardware,
            hardware.name AS hardware_name,
			hardware_manufacturer.name AS hardware_manufacturer_name,
			hardware_manufacturer.meta_default_data	AS hardware_manufacturer_meta_default_data
        FROM device, hardware, org hardware_manufacturer
        WHERE
            device.hardware = hardware.id AND
            hardware.manufacturer = hardware_manufacturer.id AND        
            length(device.serial_no) > 0 AND
            device.serial_no IN (SELECT device.serial_no FROM device GROUP BY device.serial_no HAVING count(*) > 1)
        ORDER BY
            device.serial_no,
            device.name
    !
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub duplicateAssets
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!    
        SELECT 
            device.name, 
            device.id, 
            device.asset_no,
            device.hardware,
            hardware.name AS hardware_name,
			hardware_manufacturer.name AS hardware_manufacturer_name,
			hardware_manufacturer.meta_default_data	AS hardware_manufacturer_meta_default_data
        FROM device, hardware, org hardware_manufacturer
        WHERE
            device.hardware = hardware.id AND
            hardware.manufacturer = hardware_manufacturer.id AND
            length(device.asset_no) > 0 AND
            device.asset_no IN (SELECT device.asset_no FROM device GROUP BY device.asset_no HAVING count(*) > 1)
        ORDER BY
            device.asset_no,
            device.name
    !
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub duplicateOSLicenceKey
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!    
        SELECT 
            device.name, 
            device.id, 
            device.os_licence_key,
            device.os,
            os.name AS os_name
        FROM device, os 
        WHERE 
            device.os = os.id AND
            length(device.os_licence_key) > 0 AND
            device.os_licence_key IN (SELECT device.os_licence_key FROM device GROUP BY device.os_licence_key HAVING count(*) > 1)
        ORDER BY
            device.os_licence_key,
            device.name
    !
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}


##############################################################################
# Device/Application Methods                                                 #
##############################################################################

sub updateDeviceApp
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update device app relation. No record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE device_app SET app = ?, device = ?, relation = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateDeviceAppUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. Objects may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO device_app (app, device, relation, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateDeviceAppUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('device_app');
    }
    return $newId || $$record{'id'};
}

sub deleteDeviceApp
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No device_app id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM device_app WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This device_app does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateDeviceAppUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate device app relation. No record specified." unless ($record);
    croak "RM_ENGINE: You need to choose a relationship between the app and the device." unless ($$record{'relation_id'});
    croak "RM_ENGINE: You need to choose a device to associate the app with." unless ($$record{'device_id'});
    
    # protected by fk, so no detailed validation required
    return ($$record{'app_id'}, $$record{'device_id'}, $$record{'relation_id'});
}


##############################################################################
# Domain Methods                                                             #
##############################################################################

sub domain
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT domain.*
		FROM domain
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $domain = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such domain id." unless defined($$domain{'id'});
    return $domain;
}

sub domainList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'domain.name' unless $self->_checkOrderBy($orderBy);

    my $sth = $self->dbh->prepare(
        qq!
		SELECT domain.*
		FROM domain 
		WHERE domain.meta_default_data = 0
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateDomain
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update domain. No domain record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE domain SET name = ?, descript = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateDomainUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This domain may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO domain (name, descript, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateDomainUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('domain');
    }
    return $newId || $$record{'id'};
}

sub deleteDomain
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No domain id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM domain WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This domain does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateDomainUpdate    # Should we remove or warn on domains beginning with . ?
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: You must specify a name for the domain." unless (length($$record{'name'}) > 1);
    croak "RM_ENGINE: Names must be less than " . $self->getConf('maxstring') . " characters." unless (length($$record{'name'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Descriptions cannot exceed " . $self->getConf('maxstring') . " characters."
      unless (length($$record{'descript'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Notes cannot exceed " . $self->getConf('maxnote') . " characters." unless (length($$record{'notes'}) <= $self->getConf('maxnote'));
    return ($$record{'name'}, $$record{'descript'}, $$record{'notes'});
}


##############################################################################
# Hardware Methods                                                           #
##############################################################################

sub hardware
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
			hardware.*,
			org.name 				AS manufacturer_name,
			org.meta_default_data	As manufacturer_meta_default_data
		FROM hardware, org
		WHERE 
			hardware.manufacturer = org.id AND
			hardware.id = ?
	!
    );

    $sth->execute($id);
    my $hardware = $sth->fetchrow_hashref();
    croak "RM_ENGINE: No such hardware id. This item of hardware may have been deleted.\nError at" unless defined($$hardware{'id'});
    return $hardware;
}

sub hardwareList
{
    my $self         = shift;
    my $orderBy      = shift || '';
    my $manufacturer = shift || 0;

    my $sth;
    unless ($manufacturer)
    {
        $orderBy = 'org.name, hardware.name' unless $self->_checkOrderBy($orderBy);
        $orderBy = 'org.meta_default_data, ' . $orderBy if ($orderBy =~ /^org.name/);

        $sth = $self->dbh->prepare(
            qq!
    		SELECT
    			hardware.*,
    			org.name 				AS manufacturer_name
    		FROM hardware, org
    		WHERE
    			hardware.meta_default_data = 0 AND
    			hardware.manufacturer = org.id
    		ORDER BY $orderBy
    	!
        );
    }
    else
    {
        $orderBy = 'hardware.name' unless $self->_checkOrderBy($orderBy);
        $orderBy = 'hardware.meta_default_data DESC, ' . $orderBy;
        $sth     = $self->dbh->prepare(
            qq!
    		SELECT
    			hardware.*
    	    FROM hardware
    		WHERE
    			hardware.manufacturer = $manufacturer
    		ORDER BY $orderBy
    	!
        );
    }

    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub hardwareByManufacturer
{
    my $self    = shift;
    my $orderBy = 'hardware.name';
    my @hardwareModels;

    my $manufacturers = $self->simpleList('hardware_manufacturer', 1);

    for my $manu (@$manufacturers)
    {
        push @hardwareModels, {'maufacturer_id' => $$manu{'id'}, 'maufacturer_name' => $$manu{'name'}, 'models' => $self->hardwareList('name', $$manu{'id'})};
    }
    return \@hardwareModels;
}

sub hardwareListBasic
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			hardware.id,
			hardware.name,
			hardware.meta_default_data,
			org.name 				AS manufacturer_name,
			org.meta_default_data	As manufacturer_meta_default_data
		FROM hardware, org
		WHERE hardware.manufacturer = org.id
		ORDER BY 
			hardware.meta_default_data DESC,
			manufacturer_name,
			hardware.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateHardware
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update hardware. No hardware record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE hardware SET name = ?, manufacturer =?, size = ?, image = ?, support_url = ?, spec_url = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateHardwareUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This hardware may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO hardware (name, manufacturer, size, image, support_url, spec_url, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateHardwareUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('hardware');
    }
    return $newId || $$record{'id'};
}

sub deleteHardware
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No hardware id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM hardware WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This hardware does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateHardwareUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate hardware. No hardware record specified." unless ($record);

    $$record{'support_url'} = $self->_httpFixer($$record{'support_url'});
    $$record{'spec_url'}    = $self->_httpFixer($$record{'spec_url'});

    croak "RM_ENGINE: You must specify a name for the hardware." unless (length($$record{'name'}) > 1);
    croak "RM_ENGINE: Names must be less than " . $self->getConf('maxstring') . " characters." unless (length($$record{'name'}) <= $self->getConf('maxstring'));

    # no validation for $$record{'manufacturer_id'} - foreign key constraints will catch
    croak "RM_ENGINE: You must specify a size for your hardware model." unless $$record{'size'};
    $$record{'size'} = int($$record{'size'} + 0.5);  # Only integer U supported, force size to be an integer
    croak "RM_ENGINE: Size must be between 1 and " . $self->getConf('maxracksize') . " units."
      unless (($$record{'size'} > 0) && ($$record{'size'} <= $self->getConf('maxracksize')));
    croak "RM_ENGINE: Image filenames must be between 0 and " . $self->getConf('maxstring') . " characters."
      unless ((length($$record{'image'}) >= 0) && (length($$record{'image'}) <= $self->getConf('maxstring')));
    croak "RM_ENGINE: Support URLs must be between 0 and " . $self->getConf('maxstring') . " characters."
      unless ((length($$record{'support_url'}) >= 0) && (length($$record{'support_url'}) <= $self->getConf('maxstring')));
    croak "RM_ENGINE: Specification URLs must be between 0 and " . $self->getConf('maxstring') . " characters."
      unless ((length($$record{'spec_url'}) >= 0) && (length($$record{'spec_url'}) <= $self->getConf('maxstring')));
    croak "RM_ENGINE: Notes cannot exceed " . $self->getConf('maxnote') . " characters." unless (length($$record{'notes'}) <= $self->getConf('maxnote'));

    return ($$record{'name'}, $$record{'manufacturer_id'}, $$record{'size'}, $$record{'image'}, $$record{'support_url'}, $$record{'spec_url'}, $$record{'notes'});
}

sub hardwareDeviceCount
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			hardware.id AS id, 
			hardware.name AS hardware, 
			org.name AS manufacturer,
			COUNT(device.id) AS num_devices,
			hardware.meta_default_data AS hardware_meta_default_data,
			org.meta_default_data AS hardware_manufacturer_meta_default_data,
			SUM(hardware.size) AS space_used			
		FROM device, hardware, org 
		WHERE 
			device.hardware = hardware.id AND
			hardware.manufacturer = org.id 
		GROUP BY hardware.id, hardware.name, org.name, hardware.meta_default_data, org.meta_default_data
		ORDER BY num_devices DESC
		LIMIT 10;
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub hardwareWithDevice
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			DISTINCT hardware.id, hardware.name, hardware.meta_default_data
		FROM 
			device, hardware
		WHERE 
			device.hardware = hardware.id
		ORDER BY
		 	hardware.meta_default_data DESC,
			hardware.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}


##############################################################################
# Organisation Methods                                                       #
##############################################################################

sub org
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT org.*
		FROM org 
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $org = $sth->fetchrow_hashref('NAME_lc');
    croak 'RM_ENGINE: No such organisation id.' unless defined($$org{'id'});
    return $org;
}

sub orgList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'org.name' unless $self->_checkOrderBy($orderBy);
    $orderBy .= ' DESC' if ($orderBy eq 'org.customer' or $orderBy eq 'org.hardware' or $orderBy eq 'org.software');    # yeses appear first
    my $sth = $self->dbh->prepare(
        qq!
		SELECT org.*
		FROM org
		WHERE org.meta_default_data = 0
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub manufacturerWithHardwareList
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT DISTINCT 
		    hardware.manufacturer AS id,
		    hardware_manufacturer.name AS name,
		    hardware_manufacturer.meta_default_data 
		FROM hardware, hardware_manufacturer
		WHERE 
		    hardware.manufacturer = hardware_manufacturer.id
		ORDER BY 
		    hardware_manufacturer.meta_default_data DESC,
		    hardware_manufacturer.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateOrg
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update org. No org record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE org SET name = ?, account_no = ?, customer = ?, software = ?, hardware = ?, descript = ?, home_page = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateOrgUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This org may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO org (name, account_no, customer, software, hardware, descript, home_page, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateOrgUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('org');
    }
    return $newId || $$record{'id'};
}

sub deleteOrg
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No org id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM org WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This org does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateOrgUpdate
{
    my ($self, $record) = @_;

    $$record{'home_page'} = $self->_httpFixer($$record{'home_page'});

    croak "RM_ENGINE: You must specify a name for the organisation." unless (length($$record{'name'}) > 1);
    croak "RM_ENGINE: Names must be less than " . $self->getConf('maxstring') . " characters." unless (length($$record{'name'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Account numbers must be less than " . $self->getConf('maxstring') . " characters."
      unless (length($$record{'account_no'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Descriptions cannot exceed " . $self->getConf('maxnote') . " characters."
      unless (length($$record{'descript'}) <= $self->getConf('maxnote'));
    croak "RM_ENGINE: Home page URLs cannot exceed " . $self->getConf('maxstring') . " characters."
      unless (length($$record{'home_page'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Notes cannot exceed " . $self->getConf('maxnote') . " characters." unless (length($$record{'notes'}) <= $self->getConf('maxnote'));

    # normalise input for boolean values
    $$record{'customer'} = $$record{'customer'} ? 1 : 0;
    $$record{'software'} = $$record{'software'} ? 1 : 0;
    $$record{'hardware'} = $$record{'hardware'} ? 1 : 0;

    return ($$record{'name'}, $$record{'account_no'}, $$record{'customer'}, $$record{'software'}, $$record{'hardware'}, $$record{'descript'}, $$record{'home_page'}, $$record{'notes'});
}

sub customerDeviceCount
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			org.id AS id, 
			org.name AS customer,
			COUNT(device.id) AS num_devices,
			SUM(hardware.size) AS space_used
		FROM device, org, hardware 
		WHERE 
			device.customer = org.id AND
			device.hardware = hardware.id
		GROUP BY org.id, org.name 
		ORDER BY num_devices DESC
		LIMIT 10;
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub customerWithDevice
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			DISTINCT org.id, org.name, org.meta_default_data
		FROM 
			org, device
		WHERE 
			device.customer = org.id
		ORDER BY 
			org.meta_default_data DESC,
			org.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}


##############################################################################
# Operating System Methods                                                   #
##############################################################################

sub os
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			os.*,
			org.name 				AS manufacturer_name,
			org.meta_default_data	As manufacturer_meta_default_data
		FROM os, org 
		WHERE 
			os.manufacturer = org.id AND
			os.id = ?
	!
    );

    $sth->execute($id);
    my $os = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such operating system id. This operating system may have been deleted." unless defined($$os{'id'});
    return $os;
}

sub osList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'os.name' unless $self->_checkOrderBy($orderBy);
    $orderBy = 'org.meta_default_data, ' . $orderBy if ($orderBy =~ /^org.name/);

    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			os.*,
			org.name 				AS manufacturer_name
		FROM os, org 
		WHERE 
			os.meta_default_data = 0 AND
			os.manufacturer = org.id
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateOs
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update OS. No OS record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE os SET name = ?, manufacturer = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateOsUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This OS may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO os (name, manufacturer, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateOsUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('os');
    }
    return $newId || $$record{'id'};
}

sub deleteOs
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No OS id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM os WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This OS does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateOsUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: You must specify a name for the operating system." unless (length($$record{'name'}) > 1);
    croak "RM_ENGINE: Names must be less than " . $self->getConf('maxstring') . " characters." unless (length($$record{'name'}) <= $self->getConf('maxstring'));

    # no validation for $$record{'manufacturer_id'} - foreign key constraints will catch
    croak "RM_ENGINE: Notes cannot exceed '.$self->getConf('maxnote').' characters." unless (length($$record{'notes'}) <= $self->getConf('maxnote'));
    return ($$record{'name'}, $$record{'manufacturer_id'}, $$record{'notes'});
}

sub osDeviceCount
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT 
			os.id AS id,
			os.name AS os, 
			device.os_version AS version,
			COUNT(device.id) AS num_devices,
			os.meta_default_data AS os_meta_default_data,
			SUM(hardware.size) AS space_used
		FROM device, os, org, hardware
		WHERE 
			device.os = os.id AND
			os.manufacturer = org.id AND
			device.hardware = hardware.id
		GROUP BY os.id, os.name, device.os_version, os.meta_default_data
		ORDER BY num_devices DESC
		LIMIT 10;
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub osWithDevice
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			DISTINCT os.id, os.name, os.meta_default_data
		FROM 
			os, device
		WHERE 
			device.os = os.id
		ORDER BY 
			os.meta_default_data DESC,
			os.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}


##############################################################################
# Rack Methods                                                               #
##############################################################################

sub rack
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			rack.*,
			row.name			AS row_name,
			row.hidden_row		AS row_hidden,
			room.id				AS room,
			room.name			AS room_name,
			building.name		AS building_name,
			building.name_short	AS building_name_short,
			count(device.id)	AS device_count,
			rack.size - COALESCE(SUM(hardware.size), 0)	AS free_space
		FROM row, room, building, rack
		LEFT OUTER JOIN device ON
			(rack.id = device.rack)
		LEFT OUTER JOIN hardware ON
			(device.hardware = hardware.id)
		WHERE
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id AND
			rack.id = ?
		GROUP BY rack.id, rack.name, rack.row, rack.row_pos, rack.hidden_rack, rack.numbering_direction, rack.size, rack.notes, rack.meta_default_data, rack.meta_update_time, rack.meta_update_user, row.name, row.hidden_row, room.id, room.name, building.name, building.name_short
	!
    );
    $sth->execute($id);
    my $rack = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such rack id." unless defined($$rack{'id'});
    return $rack;
}

sub rackList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'building.name, room.name, row.name, rack.row_pos'
      unless $orderBy =~ /^[a-z_]+[\._][a-z_]+$/;    # by default, order by building name and room name first
    $orderBy = $orderBy . ', rack.row_pos, rack.name'
      unless ($orderBy eq 'rack.row_pos, rack.name' or $orderBy eq 'rack.name');    # default third ordering is rack name
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			rack.*,
			row.name			AS row_name,
			row.hidden_row		AS row_hidden,
			room.id				AS room,
			room.name			AS room_name,
			building.name		AS building_name,
			building.name_short	AS building_name_short,
			count(device.id)	AS device_count,
			rack.size - COALESCE(SUM(hardware.size), 0)	AS free_space
		FROM row, room, building, rack
		LEFT OUTER JOIN device ON
			(rack.id = device.rack)
		LEFT OUTER JOIN hardware ON
			(device.hardware = hardware.id)
		WHERE
			rack.meta_default_data = 0 AND
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id
		GROUP BY rack.id, rack.name, rack.row, rack.row_pos, rack.hidden_rack, rack.size, rack.numbering_direction, rack.notes, rack.meta_default_data, rack.meta_update_time, rack.meta_update_user, row.name, row.hidden_row, room.id, room.name, building.name, building.name_short
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub rackListInRoom
{
    my ($self, $room) = @_;
    $room += 0;    # force room to be numeric
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			rack.*,
			row.name			AS row_name,
			row.hidden_row		AS row_hidden,
			room.id				AS room,
			room.name			AS room_name,
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM rack, row, room, building 
		WHERE
			rack.meta_default_data = 0 AND
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id AND
			row.room = ?
		ORDER BY rack.row, rack.row_pos
	!
    );
    $sth->execute($room);
    return $sth->fetchall_arrayref({});
}

sub rackListBasic
{
    my ($self, $noMeta) = @_;

    my $meta = '';
    $meta = 'AND  rack.meta_default_data = 0' if ($noMeta);

    my $sth = $self->dbh->prepare(
        qq!
		SELECT
			rack.id,
			rack.name,
			rack.meta_default_data,
			room.name		AS room_name, 
			building.name	AS building_name,
			building.name_short	AS building_name_short
		FROM rack, row, room, building 
		WHERE
			rack.row = row.id AND
			row.room = room.id AND
			room.building = building.id
			$meta
		ORDER BY 
			rack.meta_default_data DESC,
			building.name,
			room.name,
			row.room_pos,
			rack.row_pos
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub rackPhysical
{
    my ($self, $rackid, $selectDev, $tableFormat) = @_;
    my $devices = $self->deviceListInRack($rackid);
    $selectDev   ||= -1;    # not zero so we don't select empty positions
    $tableFormat ||= 0;

    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			rack.*
		FROM rack
		WHERE rack.id = ?
	!
    );
    $sth->execute($rackid);
    my $rack = $sth->fetchrow_hashref('NAME_lc');

    my @rackLayout = (1 .. $$rack{'size'});    # populate the rack positions

    # insert each device into the rack layout
    for my $dev (@$devices)
    {
        my $sizeCount = $$dev{'hardware_size'};
        my $position  = $$dev{'rack_pos'};

        # select (highlight) device if requested
        $$dev{'is_selected'} = ($$dev{'id'} == $selectDev);

        while ($sizeCount > 0)
        {
            # make a copy of the device so we can adjust it independently of it's other appearances
            my %devEntry = %$dev;
            $devEntry{'rack_location'} = $rackLayout[$position - 1];
            $rackLayout[$position - 1] = \%devEntry;
            $sizeCount--;
            $position++;
        }
    }

    if ($tableFormat)
    {
        # unless numbering from the top of the rack we need to reverse the rack positions
        @rackLayout = reverse @rackLayout unless ($$rack{'numbering_direction'});

        # iterate over every position and replace multiple unit sized entries with one entry and placeholders
        my $position = 0;
        my %seenIds;

        while ($position < $$rack{'size'})
        {
            if (ref $rackLayout[$position] eq 'HASH')
            {
                my $dev = $rackLayout[$position];
                
                # if we've seen this device before put in a placeholder entry for this position
                if (defined($seenIds{$$dev{'id'}}) and $seenIds{$$dev{'id'}} == 1)  
                {
                    $rackLayout[$position] = 
                    {
                        'rack_pos'      => $position,
                        'rack_location' => $$dev{'rack_location'},
                        'id'            => $$dev{'id'},
                        'name'          => $$dev{'name'},
                        'hardware_size' => 0
                    };
                }
                $seenIds{$$dev{'id'}} = 1;
            }
            else # an empty position
            {
                $rackLayout[$position] = 
                {
                    'rack_id' => $$rack{'id'}, 
                    'rack_location' => $rackLayout[$position], 
                    'id' => 0, 
                    'name' => '', 
                    'hardware_size' => '1'
                };
            }
            $position++;
        }
    }
    return \@rackLayout;
}

sub updateRack
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update rack. No rack record specified." unless ($record);

    my ($sth, $newId);

    # if no row is specified we need to use the default one for the room (lowest id)
    unless (defined $$record{'row'})
    {
        $sth = $self->dbh->prepare(qq!SELECT id FROM row WHERE room = ? ORDER BY id LIMIT 1!);
        $sth->execute($$record{'room'});
        $$record{'row'} = ($sth->fetchrow_array)[0];
        croak "RM_ENGINE: Unable to update rack. Couldn't determine room or row for rack. Did you specify a row or room? If you did choose a row or room it may have been deleted by another user."
          unless $$record{'row'};
    }

    # force row_pos to 0 until rows are supported
    $$record{'row_pos'} = 0 unless (defined $$record{'row_pos'});

    # hidden racks can't be created directly
    $$record{'hidden_rack'} = 0;

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE rack SET name = ?, row = ?, row_pos = ?, hidden_rack = ?, size = ?, numbering_direction = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateRackUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This rack may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO rack (name, row, row_pos, hidden_rack, size, numbering_direction, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateRackUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('rack');
    }
    return $newId || $$record{'id'};
}

sub deleteRack
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No rack id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM rack WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This rack does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateRackUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate rack. No rack record specified." unless ($record);
    $self->_checkName($$record{'name'});
    $self->_checkNotes($$record{'notes'});
    
    # check we have a size, make sure it's an integer and in the allowed range
    croak "RM_ENGINE: You must specify a size for your rack." unless $$record{'size'};
    $$record{'size'} = int($$record{'size'} + 0.5);
    croak "RM_ENGINE: Rack sizes must be between 1 and " . $self->getConf('maxracksize') . " units."
      unless (($$record{'size'} > 0) && ($$record{'size'} <= $self->getConf('maxracksize')));
      
    $$record{'numbering_direction'} = $$record{'numbering_direction'} ? 1 : 0;
    my $highestPos = $self->_highestUsedInRack($$record{'id'}) || 0;

    if ($highestPos > $$record{'size'})
    {
        croak "RM_ENGINE: You cannot reduce the rack size to $$record{'size'} U as there is a device at position $highestPos.";
    }
    return ($$record{'name'}, $$record{'row'}, $$record{'row_pos'}, $$record{'hidden_rack'}, $$record{'size'}, $$record{'numbering_direction'}, $$record{'notes'});
}

sub _highestUsedInRack
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			MAX(device.rack_pos + hardware.size - 1)
		FROM device, rack, hardware
		WHERE 
			device.rack = rack.id AND
			device.hardware = hardware.id AND
			rack.id = ?
	!
    );
    $sth->execute($id);
    return ($sth->fetchrow_array)[0];
}

sub totalSizeRack
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT COALESCE(SUM(size), 0) 
		FROM rack; 
	!
    );
    $sth->execute;
    return ($sth->fetchrow_array)[0];
}


##############################################################################
# Role Methods                                                               #
##############################################################################

sub role
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT role.*
		FROM role 
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $role = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such role id." unless defined($$role{'id'});
    return $role;
}

sub roleList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'role.name' unless $self->_checkOrderBy($orderBy);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT role.* 
		FROM role 
		WHERE role.meta_default_data = 0
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateRole
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update role. No role record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})    # if id is supplied peform an update
    {
        $sth = $self->dbh->prepare(qq!UPDATE role SET name = ?, descript = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateRoleUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This role may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO role (name, descript, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateDomainUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('role');
    }
    return $newId || $$record{'id'};
}

sub deleteRole
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No role id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM role WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This role does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateRoleUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: You must specify a name for the role." unless (length($$record{'name'}) > 1);
    croak "RM_ENGINE: Names must be less than " . $self->getConf('maxstring') . " characters." unless (length($$record{'name'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Descriptions cannot exceed " . $self->getConf('maxstring') . " characters."
      unless (length($$record{'descript'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Notes cannot exceed " . $self->getConf('maxnote') . " characters." unless (length($$record{'notes'}) <= $self->getConf('maxnote'));
    return ($$record{'name'}, $$record{'descript'}, $$record{'notes'});
}

sub roleDeviceCount
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			role.id AS id, 
		 	role.name AS role, 
			COUNT(device.id) AS num_devices,
			SUM(hardware.size) AS space_used 
		FROM device, role, hardware 
		WHERE 
			device.role = role.id AND
			device.hardware = hardware.id
		GROUP BY role.id, role.name 
		ORDER BY num_devices DESC
		LIMIT 10;
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub roleWithDevice
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        qq!
		SELECT
			DISTINCT role.id, role.name, role.meta_default_data
		FROM 
			role, device
		WHERE 
			device.role = role.id
		ORDER BY 
			role.meta_default_data DESC,
			role.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}


##############################################################################
# Room Methods                                                               #
##############################################################################

sub room
{
    my ($self, $id) = @_;
    croak "RM_ENGINE: Unable to retrieve room. No room id specified." unless ($id);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			room.*, 
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM room, building 
		WHERE
			room.building = building.id AND
			room.id = ?
	!
    );
    $sth->execute($id);
    my $room = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such room id." unless defined($$room{'id'});
    return $room;
}

sub roomList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'building.name' unless $self->_checkOrderBy($orderBy);    # by default, order by building name first
    $orderBy = $orderBy . ', room.name' unless $orderBy eq 'room.name';    # default second ordering is room name
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
			room.*,
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM room, building
		WHERE
			room.meta_default_data = 0 AND
			room.building = building.id
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub roomListInBuilding
{
    my $self     = shift;
    my $building = shift;
    $building += 0;    # force building to be numeric
    my $orderBy = shift || '';
    $orderBy = 'building.name' unless $self->_checkOrderBy($orderBy);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
			room.*,
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM room, building
		WHERE
			room.meta_default_data = 0 AND
			room.building = building.id AND
			room.building = ?
		ORDER BY $orderBy
	!
    );
    $sth->execute($building);
    return $sth->fetchall_arrayref({});
}

sub roomListBasic
{
    my $self = shift;
    my $sth  = $self->dbh->prepare(
        q!
		SELECT 
			room.id, 
			room.name, 
			building.name AS building_name,
			building.name_short	AS building_name_short
		FROM room, building 
		WHERE 
			room.meta_default_data = 0 AND
			room.building = building.id 
		ORDER BY 
			room.meta_default_data DESC,
			building.name,
			room.name
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateRoom
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update room. No room record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE room SET name = ?, building =?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateRoomUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This room may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO room (name, building, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateRoomUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('room');
        my $hiddenRow = {'name' => '-', 'room' => "$newId", 'room_pos' => 0, 'hidden_row' => 1, 'notes' => ''};
        $self->updateRow($updateTime, $updateUser, $hiddenRow);
    }
    return $newId || $$record{'id'};
}

sub deleteRoom
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No room id specified." unless ($deleteId);

    my ($ret, $sth);
    $sth = $self->dbh->prepare(qq!DELETE FROM row WHERE hidden_row = 1 AND room = ?!);
    $sth->execute($deleteId);
    $sth = $self->dbh->prepare(qq!DELETE FROM room WHERE id = ?!);
    $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: This room does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateRoomUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate room. No room record specified." unless ($record);
    $self->_checkName($$record{'name'});
    $self->_checkNotes($$record{'notes'});
    return ($$record{'name'}, $$record{'building_id'}, $$record{'notes'});
}


##############################################################################
# Row Methods                                                                #
##############################################################################

sub row
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			row.*,
			room.name			AS room_name,
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM row, room, building 
		WHERE
			row.room = room.id AND
			room.building = building.id AND
			row.id = ?
	!
    );
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such row id." unless defined($$row{'id'});
    return $row;
}

sub rowList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'building.name, room.name' unless $self->_checkOrderBy($orderBy);    # by default, order by building name and room name first
    $orderBy = $orderBy . ', row.name' unless $orderBy eq 'row.name';                 # default third ordering is row name
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			row.*,
			room.name			AS room_name,
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM row, room, building 
		WHERE
			row.meta_default_data = 0 AND
			row.room = room.id AND
			room.building = building.id
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub rowListInRoom
{
    my ($self, $room) = @_;
    $room += 0;    # force room to be numeric
    my $sth = $self->dbh->prepare(
        qq!
		SELECT 
			row.*,
			room.name			AS room_name,
			building.name		AS building_name,
			building.name_short	AS building_name_short
		FROM row, room, building 
		WHERE
			row.meta_default_data = 0 AND
			row.room = room.id AND
			room.building = building.id AND
			row.room = ?
		ORDER BY row.room_pos
	!
    );
    $sth->execute($room);
    return $sth->fetchall_arrayref({});
}

sub rowListInRoomBasic
{
    my ($self, $room) = @_;
    $room += 0;    # force room to be numeric
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
			row.id,
			row.name
		FROM row
		WHERE
			row.meta_default_data = 0 AND
			row.room = ?
		ORDER BY row.name
	!
    );
    $sth->execute($room);
    return $sth->fetchall_arrayref({});
}

sub rowCountInRoom
{
    my ($self, $room) = @_;
    $room += 0;    # force room to be numeric
    my $sth = $self->dbh->prepare(
        qq!
		SELECT
			count(*)
		FROM row
		WHERE
			row.meta_default_data = 0 AND
			row.room = ?
	!
    );
    $sth->execute($room);
    my $countRef = $sth->fetch;
    return $$countRef[0];
}

sub deleteRow
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No row id specified." unless ($deleteId);
    croak "RM_ENGINE: This method is not yet supported.";
    return $deleteId;
}

sub updateRow
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update row. No row record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE row SET name = ?, room = ?, room_pos = ?, hidden_row = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateRowUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This row may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO row (name, room, room_pos, hidden_row, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateRowUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('row');
    }
    return $newId || $$record{'id'};
}

sub _validateRowUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: Unable to validate row. No row record specified." unless ($record);
    $self->_checkName($$record{'name'});
    $self->_checkNotes($$record{'notes'});
    return ($$record{'name'}, $$record{'room'}, $$record{'room_pos'}, $$record{'hidden_row'}, $$record{'notes'});
}


##############################################################################
# Service Level Methods                                                      #
##############################################################################

sub service
{
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare(
        qq!
		SELECT service.* 
		FROM service 
		WHERE id = ?
	!
    );
    $sth->execute($id);
    my $service = $sth->fetchrow_hashref('NAME_lc');
    croak "RM_ENGINE: No such service id." unless defined($$service{'id'});
    return $service;
}

sub serviceList
{
    my $self = shift;
    my $orderBy = shift || '';
    $orderBy = 'service.name' unless $self->_checkOrderBy($orderBy);
    my $sth = $self->dbh->prepare(
        qq!
		SELECT service.* 
		FROM service 
		WHERE service.meta_default_data = 0
		ORDER BY $orderBy
	!
    );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub updateService
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    croak "RM_ENGINE: Unable to update service level. No service level record specified." unless ($record);

    my ($sth, $newId);

    if ($$record{'id'})
    {
        $sth = $self->dbh->prepare(qq!UPDATE service SET name = ?, descript = ?, notes = ?, meta_update_time = ?, meta_update_user = ? WHERE id = ?!);
        my $ret = $sth->execute($self->_validateServiceUpdate($record), $updateTime, $updateUser, $$record{'id'});
        croak "RM_ENGINE: Update failed. This service level may have been removed before the update occured." if ($ret eq '0E0');
    }
    else
    {
        $sth = $self->dbh->prepare(qq!INSERT INTO service (name, descript, notes, meta_update_time, meta_update_user) VALUES(?, ?, ?, ?, ?)!);
        $sth->execute($self->_validateServiceUpdate($record), $updateTime, $updateUser);
        $newId = $self->_lastInsertId('service');
    }
    return $newId || $$record{'id'};
}

sub deleteService
{
    my ($self, $updateTime, $updateUser, $record) = @_;
    my $deleteId = (ref $record eq 'HASH') ? $$record{'id'} : $record;
    croak "RM_ENGINE: Delete failed. No service level id specified." unless ($deleteId);
    my $sth = $self->dbh->prepare(qq!DELETE FROM service WHERE id = ?!);
    my $ret = $sth->execute($deleteId);
    croak "RM_ENGINE: Delete failed. This service level does not currently exist, it may have been removed already." if ($ret eq '0E0');
    return $deleteId;
}

sub _validateServiceUpdate
{
    my ($self, $record) = @_;
    croak "RM_ENGINE: You must specify a name for the service level." unless (length($$record{'name'}) > 1);
    croak "RM_ENGINE: Names must be less than " . $self->getConf('maxstring') . " characters." unless (length($$record{'name'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Descriptions cannot exceed " . $self->getConf('maxstring') . " characters."
      unless (length($$record{'descript'}) <= $self->getConf('maxstring'));
    croak "RM_ENGINE: Notes cannot exceed " . $self->getConf('maxnote') . " characters." unless (length($$record{'notes'}) <= $self->getConf('maxnote'));
    return ($$record{'name'}, $$record{'descript'}, $$record{'notes'});
}

1;

=head1 NAME

RackMonkey::Engine - A DBI-based backend for Rackmonkey

=head1 SYNOPSIS

 use RackMonkey::Engine;
 my $backend = RackMonkey::Engine->new;
 my $devices = $backend->deviceList;
 foreach my $dev (@$devices)
 {
     print $$dev{'name'}." is a ".$$dev{'hardware_name'}.".\n";
 }

This assumes a suitable configuration file and database exist, see Description for details.

=head1 DESCRIPTION

This module abstracts a DBI database for use by RackMonkey applications. Data can be queried and updated without worrying about the underlying structure. The Engine uses neutral SQL that works on SQLite, Postgres and MySQL. 

A database with a suitable schema and a configuration file are required to use the engine. Both of these are supplied with the RackMonkey distribution. Please consult the RackMonkey install document and RackMonkey::Conf module for details.

=head1 TYPES

To work with RackMonkey data it's important to have a clear understanding of how the various types relate to each other:

=over 4

=item *

Servers, routers, switches etc. are devices and are contained within racks.

=item *

A device has a hardware model and an operating system.

=item *

A device optionally has a domain (such as rackmonkey.org), a role (such as database server), a customer and a service level.

=item *

Apps run on devices.

=item *

Racks are organised in rows which reside in rooms within buildings.

=back


=head1 DATA STRUCTURES

RackMonkey data isn't object-oriented because the data structures returned by DBI are usable straight away in HTML::Template and relatively little processing of the returned data goes on. This decision may be reviewed in future. Data structures are generally references to hashes or lists of hashes. An example an operating system record returned by the os method looks like this:

 {
   'meta_update_user' => 'install',
   'name' => 'Red Hat Enterprise Linux',
   'manufacturer_meta_default_data' => '0',
   'meta_default_data' => '0',
   'manufacturer' => '22',
   'notes' => '',
   'id' => '17',
   'meta_update_time' => '1985-07-24 00:00:00',
   'manufacturer_name' => 'Red Hat'
 };

And the data returned by simpleList('service') would look like this:

 [
    {
        'name' => '24/7',
        'id' => '4',
        'meta_default_data' => '0'
    },
    {
        'name' => 'Basic',
        'id' => '3',
        'meta_default_data' => '0'
    }
 ];

All data structures contain a unique 'id' field that can used to identify a particular instance of a given item (device, operating system etc.).

There are also three meta fields:

=over 4

=item *

meta_default_data - If true this indicates the item is not real, but represents a special case or concept. For example there is an OS called 'unknown' and a building called 'unracked'. This field allows the engine to treat these special cases differently without hardcoding magic into the code.

=item *

meta_update_time - Is a string representing the time this record was last updated. This time is always GMT. This field is automatically updated by the engine when actions are performed via performAct(), but if update methods (such as updateBuilding) are called directly the caller should supply this information. The time is in the format YYYY-MM-DD HH:MM:SS.

=item *

meta_update_user - Is a string representing the user who last updated this record. The caller must supply this data, whether calling performAct() or update methods directly. If a username is not available it is usual to store the IP of the client instead.

=back

=head1 METHODS

=head2 GENERAL METHODS

=head3 new

Creates a new instance of the engine and tries to load configuration using RackMonkey::Conf.

 our $backend = RackMonkey::Engine->new;

=head3 getConf($key)

Returns a config value given its key. Check RackMonkey::Conf for the available configuration options.

 print $backend->getConf('defaultview');

=head3 simpleItem($id, $table)

Returns the name and id of an item given its id and type (table it resides in).

 my $device = $backend->simpleItem(1, 'device');
 print "device id=".$$device{'id'}." is called: ".$$device{'name'};

=head3 simpleList($type, $all)

Returns a list of items of a given $type, optionally including meta default items if $all is true. Only the name, id and the meta_default_data value of the items is returned. To get more information use the item specific methods (deviceList, orgList etc.).
 
 # without meta default items
 my $buildings = $backend->simpleList('building');
 
 # with meta default items
 my $buildings = $backend->simpleList('building', 1);
 
=head3 itemCount($type)

Returns the count of the given type without meta default items.

 my $roomCount = $backend->itemCount('room');

=head3 performAct($type, $act, $updateUser, $record)

This method adds, updates or deletes item records. Further documentation on this method is still being written.

=head2 APP METHODS

=head3 app($app_id)

Returns a reference to a hash for an app identified by $app_id.

 my $app = $backend->app(3);
 print "App with id=3 has name " . $$app{'name'};

=head3 appList($orderBy)

Returns a reference to a list of all apps ordered by $orderBy. $orderby is the name of a column in the app table, such as app.id. If an order isn't specified then the apps are ordered by app.name.

 my $appList = $backend->apps('app.id'); # order by app.id
 foreach my $app (@$appList)
 {
     print $$app{'id'} . " has name " . $$app{'name'} . ".\n";
 }

=head3 appDevicesUsedList($app_id)

Returns a reference to a list of devices used by an app identified by $app_id.

=head3 appOnDeviceList($device_id)

Returns a reference to a list of apps using the device identified by $device_id. 

=head3 updateApp($updateTime, $updateUser, $record)

Updates or creates a new app using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc.

 # Change the name of the app with id=3 to 'FishFinder'
 my $app = $backend->app(3);
 $$app{'name'} = 'FishFinder';
 updateApp(gmtime, 'Mr Cod', $app);
 
 # Create a new app with the name 'SharkTank' and print its ID
 my $newApp = {'name' => 'SharkTank'};
 my $appID = updateApp(gmtime, 'Mr Cod', $newApp);
 print "My new app has id=$appID\n";

=head3 deleteApp($updateTime, $updateUser, $record)

Deletes the app identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This 
method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc.

 # delete the app with id=3
 $backend->deleteApp(undef, undef, 3);

=head2 BUILDING METHODS

=head3 building($building_id)

Returns a reference to a hash for a building identified by $building_id. See the app() method for an example.

=head3 buildingList($orderBy)

Returns a reference to a list of all buildings ordered by $orderBy. $orderby is the name of a column in the building table, such as building.id. If an order isn't specified then the buildings are ordered by building.name. See the appList() method for an example.

=head3 updateBuilding($updateTime, $updateUser, $record)

Updates or creates a new building using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteBuilding($updateTime, $updateUser, $record)

Deletes the building identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head2 DEVICE METHODS

=head3 device($device_id)

Returns a reference to a hash for a device identified by $device_id. See the app() method for an example.

=head3 deviceList($orderBy, [$filter], [$deviceSearch])

Returns a reference to a list of all devices ordered by $orderBy. $orderby is the name of a column in the devices table, such as device.id. If an order isn't specified then the devices are ordered by devices.name. Optionally also takes filter and search parameters. 

$filter is a reference to a hash containing one or more of the following filters: filter_device_customer, filter_device_role, filter_device_hardware and filter_device_os as the keys, with the ID of the type as a value. For example, if $$filer{'filter_device_os'} = 6, then only devices whose os field is 6 will be included in the results. $deviceSearch is a string that restricts the list of returned devices to those whose name, serial or asset number includes the specified string. Search matching is case-insensitive. See the deivce_default templates and associated rackmonkey.pl code for examples of this. See the appList() method for a simple example of list methods.

=head3 deviceListInRack($rack_id)

Returns a reference to a list of devices in the rack identified by $rack_id. Otherwise similar to deviceList(), but without the order by, filter or search options.

=head3 deviceListUnracked($orderBy, $filter, $filterBy, $deviceSearch)

Returns a reference to a list of all devices not in a rack. Otherwise indentical to deviceList(). This method may be merged with deviceList() in a later release.

=head3 deviceCountUnracked()

Returns the number of devices that are not racked as a scalar. For example:

 print $backend->deviceCountUnracked . "devices are unracked.\n";

=head3 updateDevice($updateTime, $updateUser, $record)

Updates or creates a new device using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteDevice($updateTime, $updateUser, $record)

Deletes the device identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 totalSizeDevice()

Returns the total size of all devices in U as a scalar. For example:

 print "Devices occupy " . $backend->totalSizeDevice . "U.\n";

=head3 duplicateSerials()

Returns a reference to a list of all devices having duplicate serial numbers. See the report_duplicates template and associated rackmonkey.pl code for an example of usage.

=head3 duplicateAssets()

Returns a reference to a list of all devices having duplicate asset numbers. See the report_duplicates template and associated rackmonkey.pl code for an example of usage.

=head3 duplicateOSLicenceKey()

Returns a reference to a list of all devices having duplicate OS licence keys. See the report_duplicates template and associated rackmonkey.pl code for an example of usage.

=head2 DOMAIN METHODS

=head3 domain($domain_id)

Returns a reference to a hash for a domain identified by $domain_id. See the app() method for an example.

=head3 domainList($orderBy)

Returns a reference to a list of all domains ordered by $orderBy. $orderby is the name of a column in the domain table, such as domain.id. If an order isn't specified then the domains are ordered by domain.name. See the appList() method for an example.

=head3 updateDomain($updateTime, $updateUser, $record)

Updates or creates a new domain using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteDomain($updateTime, $updateUser, $record)

Deletes the domain identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head2 HARDWARE METHODS

=head3 hardware($hardware_id)

Returns a reference to a hash for a hardware model identified by $hardware_id. See the app() method for an example.

=head3 hardwareList($orderBy)

Returns a reference to a list of all hardware models ordered by $orderBy. $orderby is the name of a column in the hardware table, such as hardware.id. If an order isn't specified then the hardware models are ordered by hardware.name. See the appList() method for an example.

=head3 hardwareListBasic()

Returns a reference to a list of all hardware models with basic information, including the manufacturer. For situations when the full information returned by hardwareList() isn't needed.

=head3 hardwareByManufacturer()

Returns a reference to a list of hardware manufacturers, each of which contains a hash that includes a reference to a list of hardware models from that manufacturer. The data structure returned is of form shown below (only some fields are shown for compactness):

 [
     {
     'maufacturer_id' => '18', 
     'maufacturer_name' => 'NetApp' 
     'models' => [
         { 
             'name' => 'FAS3170', 
             'size' => '6', 
             'manufacturer' => '18', 
         }, {...}, ] 
     },
     {
     'maufacturer_id' => '24', 
     'maufacturer_name' => 'Sun',
     'models' => [{...}, {...},]
     },
     {...},
 ]

=head3 updateHardware($updateTime, $updateUser, $record)

Updates or creates a new hardware model using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteHardware($updateTime, $updateUser, $record)

Deletes the hardware model identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 hardwareDeviceCount()

Returns a reference to a list of hardware models with the number of devices of that model and total space in U they occupy. See the report_count template and associated rackmonkey.pl code for an example of usage.

=head3 hardwareWithDevice()

Returns a reference to a list of hardware models that has at least one device. Otherwise similar to hardwareListBasic().

=head2 ORGANISATION (ORG) METHODS

=head3 org($org_id)

Returns a reference to a hash for a org identified by $org_id. See the app() method for an example.

=head3 orgList($orderBy)

Returns a reference to a list of all orgs ordered by $orderBy. $orderby is the name of a column in the org table, such as org.id. If an order isn't specified then the orgs are ordered by org.name. See the appList() method for an example.

=head3 manufacturerWithHardwareList()

Returns a reference to a list of manufactuers that has at least one hardware model.

=head3 updateOrg($updateTime, $updateUser, $record)

Updates or creates a new org using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteOrg($updateTime, $updateUser, $record)

Deletes the org identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 customerDeviceCount()

Returns a reference to a list of customers with the number of devices with that customer and total space in U they occupy. See the report_count template and associated rackmonkey.pl code for an example of usage.

=head3 customerWithDevice()

Returns a reference to a list of customers that has at least one device.

=head2 OPERATING SYSTEM (OS) METHODS

=head3 os($os_id)

Returns a reference to a hash for a OS identified by $os_id. See the app() method for an example.

=head3 osList($orderBy)

Returns a reference to a list of all OS ordered by $orderBy. $orderby is the name of a column in the OS table, such as os.id. If an order isn't specified then the OS are ordered by os.name. See the appList() method for an example.

=head3 updateOs($updateTime, $updateUser, $record)

Updates or creates a new OS using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteOs($updateTime, $updateUser, $record)

Deletes the OS identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 osDeviceCount

Returns a references to a list of OS with the number of devices using that OS and total space in U they occupy. See the report_count template and associated rackmonkey.pl code for an example of usage.

=head3 osWithDevice

Returns a reference to a list of OS that have at least one device using them.

=head2 RACK METHODS

=head3 rack($rack_id)

Returns a reference to a hash for a rack identified by $rack_id. See the app() method for an example.

=head3 rackList($orderBy)

Returns a reference to a list of all racks ordered by $orderBy. $orderby is the name of a column in the rack table, such as rack.id. If an order isn't specified then the racks are ordered by rack.name. See the appList() method for an example.

=head3 rackListInRoom($room_id)

Returns a reference to a list of all racks within the room identified by $room_id.

=head3 rackListBasic()

Returns a reference to a list of all racks with basic information, including the room. For situations when the full information returned by rackList() isn't needed.

=head3 rackPhysical($rack_id, [$selectDev], [$tableFormat])

Returns a list of all the devices in a rack, optionally in table format if $tableFormat is true (useful for creating HTML tables and similar) and with device with the id $selectDev selected. See the rack_physical templates and associated rackmonkey.pl code for an example of usage.

=head3 updateRack($updateTime, $updateUser, $record)

Updates or creates a new rack using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteRack($updateTime, $updateUser, $record)

Deletes the rack identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 totalSizeRack()

Returns a scalar with the total size in U of all racks.

=head2 ROLE METHODS

=head3 role($role_id)

Returns a reference to a hash for a role identified by $role_id. See the app() method for an example.

=head3 roleList($orderBy)

Returns a reference to a list of all role ordered by $orderBy. $orderby is the name of a column in the role table, such as role.id. If an order isn't specified then the roles are ordered by role.name. See the appList() method for an example.

=head3 updateRole($updateTime, $updateUser, $record)

Updates or creates a new role using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteRole($updateTime, $updateUser, $record)

Deletes the role identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 roleDeviceCount

Returns a references to a list of roles with the number of devices in that role and total space in U they occupy. See the report_count template and associated rackmonkey.pl code for an example of usage.

=head3 roleWithDevice

Returns a reference to a list of roles that have at least one device in that role.

=head2 ROOM METHODS

=head3 room($room_id)

Returns a reference to a hash for a room identified by $room_id. See the app() method for an example.

=head3 roomList($orderBy)

Returns a reference to a list of all rooms ordered by $orderBy. $orderby is the name of a column in the room table, such as room.id. If an order isn't specified then the rooms are ordered by room.name within each building. See the appList() method for an example.

=head3 updateRoom($updateTime, $updateUser, $record)

Updates or creates a new room using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteRoom($updateTime, $updateUser, $record)

Deletes the room identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head3 roomListInBuilding($building_id)

Returns a reference to a list of all rooms within the building identified by $building_id.

=head2 ROW METHODS

Rows are not fully supported in this release. Instead rows are automatically handled by rooms.

=head2 SERVICE LEVEL METHODS

=head3 service($service_id)

Returns a reference to a hash for a service level identified by $service_id. See the app() method for an example.

=head3 serviceList($orderBy)

Returns a reference to a list of all service levels ordered by $orderBy. $orderby is the name of a column in the service table, such as service.id. If an order isn't specified then the service levels are ordered by service.name. See the appList() method for an example.

=head3 updateService($updateTime, $updateUser, $record)

Updates or creates a new service level using the reference to the hash $record, the user $updateUser and the time/date $updateTime. Returns the unique id for the item created or updated as a scalar. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the updateApp() method for an example.

=head3 deleteService($updateTime, $updateUser, $record)

Deletes the service level identified by id, either stored as $$record{'id'} or directly as $record. $updateUser and updateTime are currently ignored by this method. This method can be called directly, but you may prefer to use performAct() as it automatically handles updating the RackMonkey log, setting the time etc. See the deleteApp() method for an example.

=head1 BUGS

You can view and report bugs at http://www.rackmonkey.org/issues

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

=head1 AUTHOR

Will Green - http://flux.org.uk

=head1 SEE ALSO

http://www.rackmonkey.org

=cut
