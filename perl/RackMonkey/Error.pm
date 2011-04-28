package RackMonkey::Error;
##############################################################################
# RackMonkey - Know Your Racks - http://www.rackmonkey.org                   #
# Version 1.2.5-1                                                            #
# (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                  #
# Error handling functions for RackMonkey                                    #
##############################################################################

use strict;
use warnings;

our $VERSION = '1.2.5-1';
our $AUTHOR  = 'Will Green (wgreen at users.sourceforge.net)';

sub enlighten
{
    my $errStr    = shift;
    my $newErrStr = "An error occurred.";

    # HTML::Template couldn't open template
    if ($errStr =~ /HTML::Template->new\(\) : Cannot open included file (.+tmpl)/)
    {
        $newErrStr = "Couldn't open template $1.\nCheck that the template path (tmplpath) in rackmonkey.conf is correct.";
    }

    # SQLite foreign key constraint: delete table names with underscores (messy: this should be fixed in RackMonkey 1.3)
    elsif ($errStr =~ /violates foreign key constraint "fkd_(.*?_.*?)_(.*?)_id"/)
    {
        my $refItem = $1;
        my $delItem = $2;

        $refItem = 'app' if ($refItem eq 'device_app');
        $newErrStr = "Delete violates data integrity check.\nRackMonkey cannot delete that $delItem, it is connected to one or more $refItem(s). Delete the connection to the $refItem(s) and try again.";
    }

    # SQLite foreign key constraint: delete
    elsif ($errStr =~ /violates foreign key constraint "fkd_(.*?)_(.*?)_id"/)
    {
        my $refItem = $1;
        my $delItem = $2;
        $delItem = 'row/room' if ($delItem eq 'row');
        $newErrStr = "Delete violates data integrity check.\nRackMonkey cannot delete that $delItem, it is listed as a $delItem for one or more $refItem(s).";
    }

    # SQLite foreign key constraint: insert or update (also catches NOT NULL)
    elsif ($errStr =~ /violates foreign key constraint "fk[iu]_(.*?)_(.*?)_id"/)
    {
        $newErrStr = "You need to choose a valid $2 for this $1. If you did choose a $2 it may have been deleted by another user.";
    }

    # SQLite unqiueness constraints
    elsif ($errStr =~ /columns? (.*?) (?:is|are) not unique/)
    {
        # hack to message to account for the fact that some racks are in the hidden rows (no row management)
        my $clash = ($1 eq 'name, row') ? 'name and row or room' : $1;

        $clash = 'combination of device name and domain' if ($clash eq 'name, domain');

        # device/app relationship gets its own message
        if ($clash eq 'app, device, relation')
        {
            $newErrStr = "This app is already connected to that device with that relationship.";
        }
        else
        {
            $newErrStr = "Couldn't create entry: $clash is not unique.\nAn entry of that type with that $clash already exists, please choose another $clash.";
        }
    }

    # Postgres foreign key constraint: delete
    elsif ($errStr =~ /delete on table ".*?" violates foreign key constraint "(.*?)_(.*?)_fkey"/)
    {
        my $refItem = $1;
        my $delItem = $2;
        $delItem = 'row/room' if ($delItem eq 'row');
        if ($delItem eq 'app_device')
        {
            $delItem = $refItem;
            $refItem = 'app';
        }
        $newErrStr = "Delete violates data integrity check.\nRackMonkey cannot delete that $delItem, it is listed as a $delItem for one or more $refItem(s).";
    }

    # Postgres foreign key constraint: insert/update
    elsif ($errStr =~ /insert or update on table ".*?" violates foreign key constraint "(.*?)_(.*?)_fkey"/)
    {
        $newErrStr = "You need to choose a valid $2 for this $1. If you did choose a $2 it may have been deleted by another user.";
    }

    # Postgres NOT NULL
    elsif ($errStr =~ /null value in column "(.*?)" violates not-null constraint/)
    {
        $newErrStr = "You need to specify a $1.";
    }

    # Postgres unqiueness constraints - rather messy, need to find better way of dealing with constraint errors
    elsif ($errStr =~ /duplicate key value violates unique constraint "(.*?)"/)
    {
        my $constraint = $1;
        my ($type) = $constraint =~ /(.*?)_.*/;
        my $property = 'name';
        if ($constraint eq 'device_name_unique')
        {
            $property = 'name and domain';
        }
        elsif ($constraint eq 'rack_row_unique' or $constraint eq 'row_room_unique')
        {
            $property = 'name and row or room';
        }
        elsif ($constraint eq 'room_building_unique')
        {
            $property = 'name and building';
        }
        elsif ($constraint eq 'device_app_unique')
        {
            $type     = 'app/device relationship';
            $property = 'app/device relationship';
        }
        $newErrStr = "Couldn't create $type.\nAn entry of that type with that $property already exists, please choose another $property.";
    }

    # MySQL foreign key constraint: delete
    elsif ($errStr =~ /Cannot delete or update a parent row: a foreign key constraint fails.*?CONSTRAINT.*?`(.*?)_ibfk.*?FOREIGN KEY \(`(.*?)`\) /)
    {
        my $refItem = $1;
        my $delItem = $2;
        $delItem = 'row/room' if ($delItem eq 'row');
        $refItem = 'app'      if ($refItem eq 'device_app');
        $newErrStr = "Delete violates data integrity check.\nRackMonkey cannot delete that $delItem, it is listed as a $delItem for one or more $refItem(s).";
    }

    # MySQL foreign key constraint: update/insert
    elsif ($errStr =~ /Cannot add or update a child row: a foreign key constraint fails.*?CONSTRAINT.*?`(.*?)_.*?FOREIGN KEY \(`(.*?)`\) /)
    {
        $newErrStr = "You need to choose a valid $2 for this $1. If you did choose a $2 it may have been deleted by another user.";
    }

    # MySQL NOT NULL
    elsif ($errStr =~ /Column '(.*?)' cannot be null/)
    {
        $newErrStr = "You need to specify a $1.";
    }

    # MySQL unqiueness constraints - rather messy
    elsif ($errStr =~ /Duplicate entry.*?Statement.*?(INSERT INTO|UPDATE) (.*?)\s/)
    {
        my $actType    = ($1 eq 'UPDATE') ? 'update' : 'create';
        my $constraint = $2;
        my $property   = 'name';
        if ($constraint eq 'device')
        {
            $property = 'name and domain';
        }
        elsif ($constraint eq 'rack' or $constraint eq 'row')
        {
            $property = 'name and row or room';
        }
        elsif ($constraint eq 'room')
        {
            $property = 'name and building';
        }
        elsif ($constraint eq 'device_app')
        {
            $property = $constraint = 'app/device relationship';
        }
        $newErrStr = "Couldn't $actType $constraint.\nAn entry of that type with that $property already exists, please choose another $property.";
    }

    # DBI errors
    elsif ($errStr =~ /install_driver\((.*?)\)\s*failed.*?Available drivers:(.*?)\./s)    # Unable to load DBI driver with avaliable drivers list
    {
        $newErrStr = "Couldn't load perl database driver DBD::$1.\nThis error is usually caused by mistyping the driver name in the configuration file (driver names are case sensitive) or failing to have the required driver module installed. See the installation instructions for more details.\n\nYour system appears to have the following DBI drivers available: $2.";
    }
    elsif ($errStr =~ /install_driver\((.*?)\)\s*failed/)                                 # Unable to load DBI driver without avaliable drivers list
    {
        $newErrStr = "Couldn't load perl database driver DBD::$1.\nThis error is usually caused by mistyping the driver name in the configuration file (driver names are case sensitive) or failing to have the required driver module installed. See the installation instructions for more details.";
    }
    elsif ($errStr =~ /Can't locate object method "driver" via package "DBD::(.*?)"/)
    {
        $newErrStr = "Couldn't load perl database driver DBD::$1.\nHave you got the capitalisation of the name right in rackmonkey.conf? See the installation instructions for more details.";
    }
    elsif ($errStr =~ /^DBI connect/)
    {
        $newErrStr = "Couldn't connect to RackMonkey database.\nCheck your database is available and that 'dbconnect', 'dbuser' and 'dbpass' are correct in rackmonkey.conf.";
    }

    elsif ($errStr =~ /attempt to write a readonly database/)
    {
        $newErrStr = "Couldn't write to the RackMonkey database.\nThe database file needs to be writable by the user running RackMonkey (for example: httpd or www-data if running as a web application).";
    }
    elsif ($errStr =~ /execute failed: unable to open database file/)
    {
        $newErrStr = "Couldn't write to the RackMonkey database.\nThe directory containing the database file needs to be writable by the user running RackMonkey (for example: httpd or www-data if running as a web application).";
    }

    # Errors users should never see
    elsif ($errStr =~ /not a valid configuration parameter/)
    {
        $newErrStr = "RackMonkey tried to access a configuration setting which wasn't defined. This error should never occur, please report.";
    }

    # Internal RackMonkey errors
    elsif ($errStr =~ /RMERR:(.*)at.*?line.*/)
    {
        $newErrStr = "$1";
    }

    # Internal RackMonkey Engine errors
    elsif ($errStr =~ /RM_ENGINE:(.*)at.*?line.*/)
    {
        $newErrStr = "$1";
    }

    # Internal RackMonkey Engine errors without line numbers
    elsif ($errStr =~ /RM_ENGINE:(.*)/)
    {
        $newErrStr = "$1";
    }

    # Internal RackMonkey errors for XLS plugin
    elsif ($errStr =~ /RM2XLS:(.*)at.*?line.*/)
    {
        $newErrStr = "$1";
    }
    return $newErrStr;
}

sub display
{
    my ($errMsg, $friendlyErrMsg, $sys) = @_;

    my $systemInfo;
    if (keys %$sys > 0)
    {
        $systemInfo = join '<br/>', map "$_: $$sys{$_}", sort keys %$sys;
    }
    else
    {
        $systemInfo = 'System information is not available. This is probably because the RackMonkey Engine failed to initialise.';
    }

    $errMsg         =~ s/\n/\n\t\t<br\/>/gm;    # replace newlines with <br> for HTML
    $friendlyErrMsg =~ s/\n/\n\t\t<br\/>/gm;    # replace newlines with <br> for HTML
    $systemInfo     =~ s/\n/\n\t\t<br\/>/gm;    # replace newlines with <br> for HTML

    print <<END;
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
		<head>
			<title>RackMonkey Error</title>
		</head>
		<body style='font-family:sans-serif'>
		<hr/>
		<p><strong style='color: maroon'>RackMonkey Error</strong></p>
		<p>
		$friendlyErrMsg
		</p>
		
		<p><strong>Fixing the problem:</strong></p>
		<ul>
			<li>Use the web browser back button to return to the previous page and correct the problem</li>
			<li>View <a href="./rackmonkey.pl?view=help&amp;view_type=errors">Help for Error Messages</a> (local, may not work if RackMonkey has yet to initialize)</li>	
			<li>View <a href="http://www.rackmonkey.org/doc/1.2.5">Online Help</a> (requires Internet connectivity)</li>	
			<li>Consult the troubleshooting.txt included with RackMonkey (covers database and installation errors)</li>		
			<li>Go to RackMonkey <a href="./rackmonkey.pl">home view</a></li>
		</ul>
		
		<p style='font-size: small'>
		<strong>Error Details</strong><br/>
		$errMsg
		</p>
		
		<p style='font-size: small'>
		<strong>RackMonkey System Details</strong><br/>
		$systemInfo
		</p>
		
		<p style='font-size: small'>
			<em>If you believe this is a bug: send this entire message and a record of what you did to the
			<a href='http://www.rackmonkey.org'>RackMonkey developers</a>.</em>
		</p>
		
		<hr/>
		</body>
	</html>
END
    exit;
}

1;

=head1 NAME

RackMonkey::Error - Creates User-Friendly Error Messages

=head1 SYNOPSIS

 use RackMonkey::Engine;
 use RackMonkey::Error;

 my $backend;
 eval
 {
     $backend = RackMonkey::Engine->new;
     # run RackMonkey methods here
 };
 if ($@)
 {
     my $errMsg = $@;
     print $cgi->header;
     my $friendErr = RackMonkey::Error::enlighten($errMsg);
     RackMonkey::Error::display($errMsg, $friendErr, $backend->{'sys'});
 }

=head1 DESCRIPTION

The RackMonkey::Error helps present error messages to users in a clear and helpful way. It adds user-friendly descriptions to common messages, such as foreign key constraint violations.

=head1 BUGS

You can view and report bugs at http://www.rackmonkey.org/issues

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

=head1 AUTHOR

Will Green - http://flux.org.uk

=head1 SEE ALSO

http://www.rackmonkey.org
