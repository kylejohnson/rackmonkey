package RackMonkey::Conf;
##############################################################################
# RackMonkey - Know Your Racks - http://www.rackmonkey.org                   #
# Version 1.2.5-1                                                            #
# (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                  #
# Configuration for RackMonkey                                               #
##############################################################################

use strict;
use warnings;

use Carp;

our $VERSION = '1.2.5-1';
our $AUTHOR  = 'Will Green (wgreen at users.sourceforge.net)';

sub new
{
    my ($className) = @_;
    my $self = {
        'configpath'                => $ENV{'RACKMONKEY_CONF'} || '/etc/rackmonkey.conf',
        'dbconnect'                 => '',
        'dbuser'                    => '',
        'dbpass'                    => '',
        'tmplpath'                  => '',
        'wwwpath'                   => '',
        'plugin_pdf'                => 0,
        'plugin_xls'                => 0,
        'defaultview'               => 'rack',
        'dateformat'                => '%Y-%m-%d',
        'shorttextlen'              => 32,
        'shorturllen'               => 64,
        'maxnote'                   => 4095,
        'maxstring'                 => 255,
        'maxracksize'               => 255,
        'dellquery'                 => '',
        'number_from_top'           => 0,
        'size_of_u'                 => 14,
        'bypass_db_driver_checks'   => 0
    };
    unless (open(CONFIG, "<$$self{'configpath'}"))
    {
        croak "RMERR: Cannot open configuration file '$$self{'configpath'}': $!. See the installation document for advice on creating a configuration file. You can override the configuration file location with the RACKMONKEY_CONF variable in httpd-rackmonkey.conf.";
    }

    while (<CONFIG>)
    {
        chomp;
        s/^#.*//;      # comments at start of lines
        s/\s+#.*//;    # comments after whitespace
        s/^\s+//;      # whitespace
        s/\s+$//;      # 	"	"
        next unless length;
        my ($key, $value) = m/\s*(.*?)\s*=\s*(.*)\s*/;
        $$self{"$key"} = "$value";
    }

    close(CONFIG);

    bless $self, $className;
}

1;

=head1 NAME

RackMonkey::Conf - RackMonkey configuration information

=head1 SYNOPSIS

 my $conf = RackMonkey::Conf->new;
 print "DB connect string is: " . $$conf{'dbconnect'};
 
=head1 DESCRIPTION

RackMonkey has used a text-based configuration files since release 1.2.4. This module parses that file, providing access to RackMonkey configuration information. RackMonkey::Conf looks for the configuration file in the location specified by the RACKMONKEY_CONF environment variable or falls back on '/etc/rackmonkey.conf'. At present access to the configuration information is directly via the conf hash, see synopsis.

=head1 BUGS

You can view and report bugs at http://www.rackmonkey.org/issues

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

=head1 AUTHOR

Will Green - http://flux.org.uk

=head1 SEE ALSO

http://www.rackmonkey.org
