#!/usr/bin/env perl
##############################################################################
# RackMonkey - Know Your Racks - http://www.rackmonkey.org                   #
# Version 1.2.5-1                                                            #
# (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                  #
# Main RackMonkey CGI script                                                 #
##############################################################################

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

use strict;
use warnings;

use 5.006_001;

use HTML::Template;
use HTML::Entities;
use Time::Local;

use RackMonkey::CGI;
use RackMonkey::Engine;
use RackMonkey::Error;

our $VERSION = '1.2.5-1';
our $AUTHOR  = 'Will Green (wgreen at users.sourceforge.net)';

our ($template, $cgi, $conf, $backend);

$cgi = new RackMonkey::CGI;

eval {
    $backend = RackMonkey::Engine->new;
    $conf    = $backend->getConfHash;

    my $fullURL      = $cgi->url;
    my $baseURL      = $cgi->baseUrl;
    my $view         = $cgi->view($$conf{'defaultview'});
    my $id           = $cgi->viewId;
    my $viewType     = $cgi->viewType;
    my $act          = $cgi->act;
    my $filterBy     = $cgi->filterBy;
    my $deviceSearch = $cgi->deviceSearch;

    my $orderBy = $cgi->orderBy;

    my $loggedInUser = $ENV{'REMOTE_USER'} || $ENV{'REMOTE_ADDR'};

    if ($act) # perform act, and return status: 303 (See Other) to redirect to a view
    {
        die "RMERR: You are logged in as 'guest'. Guest users can't update RackMonkey." if (lc($loggedInUser) eq 'guest');

        my $actData = $cgi->vars;

        # Trim whitespace from the start and end of all submitted values
        for (values %$actData)
        {
            s/^\s+//;
            s/\s+$//;
        }

        # delete id, only act_ids should be used be used for acts, ids are used for views
        delete $$actData{'id'};

        # convert act_id into a normal id for use by the engine
        if ($$actData{'act_id'})
        {
            $$actData{'id'} = $$actData{'act_id'};
            delete $$actData{'act_id'};
        }

        my $lastCreatedId = $backend->performAct($cgi->actOn, $act, $loggedInUser, scalar($cgi->vars));
        $id = $lastCreatedId if (!$id);    # use lastCreatedId if there isn't an id
        my $redirectUrl = "$fullURL?view=$view&view_type=$viewType";
        $redirectUrl .= "&id=$id"                      if ($id);
        $redirectUrl .= "&last_created_id=$lastCreatedId";
        $redirectUrl .= "&device_search=$deviceSearch" if ($deviceSearch);

        $cgi->redirect303($redirectUrl);
    }
    else # display a view
    {
        unless ($view =~ /^(?:config|help|app|building|device|deviceApp|domain|hardware|network|power|org|os|rack|report|role|room|row|service|system)$/)
        {
            die "RMERR: '$view' is not a valid view. Did you type the URL manually? Note that view names are singular, for example device NOT devices.";
        }

        if ($view eq 'system') # check for this view first: it doesn't use templates
        {
            print $cgi->header('text/plain');
            my %sys = %{$backend->{'sys'}};
            print map "$_: $sys{$_}\n", sort keys %sys;
            exit;
        }

        my $templatePath = $$conf{'tmplpath'} . "/${view}_${viewType}.tmpl";
        $template = HTML::Template->new('filename' => $templatePath, 'die_on_bad_params' => 0, 'global_vars' => 1, 'case_sensitive' => 1, 'loop_context_vars' => 1);

        if (($view eq 'config') || ($view eq 'help') || ($view eq 'network') || ($view eq 'power'))
        {
            # do nothing - pages are static content
        }
        elsif ($view eq 'app')
        {
            if ($viewType =~ /^default/)
            {
                my $apps = $backend->appList($orderBy);
                for my $a (@$apps)
                {
                    $$a{'descript_short'} = shortStr($$a{'descript'});
                    $$a{'notes'}          = formatNotes($$a{'notes'}, 1);
                    $$a{'notes_short'}    = shortStr($$a{'notes'});
                }
                my $totalAppCount  = $backend->itemCount('app');
                my $listedAppCount = @$apps;
                $template->param('total_app_count'  => $totalAppCount);
                $template->param('listed_app_count' => $listedAppCount);
                $template->param('all_apps_listed'  => ($totalAppCount == $listedAppCount));
                $template->param('apps'             => $apps);
            }
            elsif (($viewType =~ /^edit/) || ($viewType =~ /^single/))
            {
                my $app = $backend->app($id);

                if ($viewType =~ /^single/)
                {
                    $$app{'notes'} = formatNotes($$app{'notes'});
                }

                my $devices = $backend->appDevicesUsedList($id);
                $$app{'app_devices'} = $devices;
                $template->param($app);
            }
        }
        elsif ($view eq 'building')
        {
            if ($viewType =~ /^default/)
            {
                my $buildings = $backend->buildingList($orderBy);
                for my $b (@$buildings)
                {
                    $$b{'notes'} = formatNotes($$b{'notes'}, 1);
                    $$b{'notes_short'} = shortStr($$b{'notes'});
                }
                my $totalBuildingCount  = $backend->itemCount('building');
                my $listedBuildingCount = @$buildings;
                $template->param('total_building_count'  => $totalBuildingCount);
                $template->param('listed_building_count' => $listedBuildingCount);
                $template->param('all_buildings_listed'  => ($totalBuildingCount == $listedBuildingCount));
                $template->param('buildings'             => $buildings);
            }
            elsif (($viewType =~ /^edit/) || ($viewType =~ /^single/))
            {
                my $building = $backend->building($id);
                if ($viewType =~ /^single/)
                {
                    $$building{'rooms'} = $backend->roomListInBuilding($id);
                    $$building{'notes'} = formatNotes($$building{'notes'});
                }
                $template->param($building);
            }
        }
        elsif ($view eq 'device')
        {
            if ($viewType =~ /^default/)
            {
                my $devices;

                if ($viewType =~ /^default_unracked/)
                {
                    $devices = $backend->deviceListUnracked($orderBy, $filterBy, $deviceSearch);
                }
                else
                {
                    $devices = $backend->deviceList($orderBy, $filterBy, $deviceSearch);
                }

                my $filterBy = $cgi->filterBy;

                my $customers = $backend->customerWithDevice;
                unshift @$customers, {'id' => '', name => 'All'};
                $template->param('customerlist' => $cgi->selectItem($customers, $$filterBy{'device.customer'}));

                my $roles = $backend->roleWithDevice;
                unshift @$roles, {'id' => '', name => 'All'};
                $template->param('rolelist' => $cgi->selectItem($roles, $$filterBy{'device.role'}));

                my $hardware = $backend->hardwareWithDevice;
                unshift @$hardware, {'id' => '', name => 'All'};
                $template->param('hardwarelist' => $cgi->selectItem($hardware, $$filterBy{'device.hardware'}));

                my $os = $backend->osWithDevice;
                unshift @$os, {'id' => '', name => 'All'};
                $template->param('oslist' => $cgi->selectItem($os, $$filterBy{'device.os'}));

                for my $d (@$devices)
                {
                    $$d{'age'}         = calculateAge($$d{'purchased'});    # determine age in years from purchased date
                    $$d{'notes'}       = formatNotes($$d{'notes'}, 1);
                    $$d{'notes_short'} = shortStr($$d{'notes'});
                }

                $template->param('device_search' => $deviceSearch);
                $template->param('devices'       => $devices);

                my $totalDeviceCount  = $backend->itemCount('device');
                my $listedDeviceCount = @$devices;
                $template->param('total_device_count'  => $totalDeviceCount);
                $template->param('listed_device_count' => $listedDeviceCount);
                $template->param('all_devices_listed'  => ($totalDeviceCount == $listedDeviceCount));
            }
            else
            {
                my $selectedManufacturer  = $cgi->lastCreatedId;
                my $selectedHardwareModel = $cgi->lastCreatedId;
                my $selectedOs            = $cgi->lastCreatedId;
                my $selectedRole          = $cgi->lastCreatedId;
                my $selectedCustomer      = $cgi->lastCreatedId;
                my $selectedService       = $cgi->lastCreatedId;
                my $selectedRack          = $cgi->selectProperty('rack') || $cgi->lastCreatedId;
                my $selectedDomain        = $cgi->lastCreatedId;

                if (($viewType =~ /^edit/) || ($viewType =~ /^single/) || ($viewType =~ /^create/))
                {
                    my $device = {};

                    if ($id)
                    {
                        $device          = $backend->device($id);
                        $$device{'age'}  = calculateAge($$device{'purchased'});
                        $$device{'apps'} = $backend->appOnDeviceList($id);
                    }

                    if ($viewType =~ /^single/)
                    {
                        $$device{'notes'} = formatNotes($$device{'notes'});

                        if (lc($$device{'hardware_manufacturer_name'}) =~ /dell/)    # not very extensible
                        {
                            $template->param('dell_query' => $$conf{'dellquery'});
                        }
                    }

                    if ($viewType !~ /^single/)
                    {
                        # Use database value for selected if none in CGI
                        $selectedManufacturer  = $$device{'hardware_manufacturer_id'} if (!$selectedManufacturer);
                        $selectedHardwareModel = $$device{'hardware'}                 if (!$selectedHardwareModel);
                        $selectedOs            = $$device{'os'}                       if (!$selectedOs);
                        $selectedRole          = $$device{'role'}                     if (!$selectedRole);
                        $selectedCustomer      = $$device{'customer'}                 if (!$selectedCustomer);
                        $selectedService       = $$device{'service'}                  if (!$selectedService);
                        $selectedRack          = $$device{'rack'}                     if (!$selectedRack);
                        $selectedDomain        = $$device{'domain'}                   if (!$selectedDomain);
                    }

                    # clear values unique to a device if we're copying an existing device
                    if ($viewType =~ /^create/)
                    {
                        $$device{'name'}            = '';
                        $$device{'rack_pos'}        = '';
                        $$device{'asset_no'}        = '';
                        $$device{'serial_no'}       = '';
                        $$device{'in_service'}      = 1;    # default is in service
                        $$device{'notes'}           = '';
                        $$device{'os_licence_key'}  = '';
                    }

                    $template->param($device);
                }
                if (($viewType =~ /^edit/) || ($viewType =~ /^create/))
                {
                    $template->param('selected_manufacturer'   => $selectedManufacturer);
                    $template->param('selected_hardware_model' => $selectedHardwareModel);
                    # manufacturerlist: run selectItem to prefix - on meta_default items, should be separate sub from selectItem
                    $template->param('manufacturerlist'        => $cgi->selectItem($backend->manufacturerWithHardwareList, 0));
                    $template->param('modelList'               => $backend->hardwareByManufacturer); # Todo: Need to add '-' prefix to meta default items
                    $template->param('oslist'                  => $cgi->selectItem($backend->simpleList('os', 1), $selectedOs));
                    $template->param('rolelist'                => $cgi->selectItem($backend->simpleList('role', 1), $selectedRole));
                    $template->param('customerlist'            => $cgi->selectItem($backend->simpleList('customer', 1), $selectedCustomer));
                    $template->param('servicelist'             => $cgi->selectItem($backend->simpleList('service', 1), $selectedService));
                    $template->param('racklist'                => $cgi->selectRack($backend->rackListBasic, $selectedRack));
                    $template->param('domainlist'              => $cgi->selectItem($backend->simpleList('domain', 1), $selectedDomain));
                    $template->param('rack_pos'                => $cgi->selectProperty('position'));
                }
            }
        }
        elsif ($view eq 'deviceApp')
        {
            if ($viewType =~ /^create/)
            {
                my $app = $backend->app($id);
                $template->param($app);

                my $devices = $backend->deviceList;
                $template->param('devices' => $devices);

                my $relations = $backend->simpleList('app_relation', 1);
                $template->param('relations' => $relations);
            }
        }
        elsif ($view eq 'domain')
        {
            if ($viewType =~ /^default/)
            {
                my $domains = $backend->domainList($orderBy);
                for my $d (@$domains)
                {
                    $$d{'notes'}          = formatNotes($$d{'notes'}, 1);
                    $$d{'notes_short'}    = shortStr($$d{'notes'});
                    $$d{'descript_short'} = shortStr($$d{'descript'});
                }
                my $totalDomainCount  = $backend->itemCount('domain');
                my $listedDomainCount = @$domains;
                $template->param('total_domain_count'  => $totalDomainCount);
                $template->param('listed_domain_count' => $listedDomainCount);
                $template->param('all_domains_listed'  => ($totalDomainCount == $listedDomainCount));
                $template->param('domains'             => $domains);
            }
            elsif (($viewType =~ /^edit/) || ($viewType =~ /^single/))
            {
                my $domain = $backend->domain($id);
                if ($viewType =~ /^single/)
                {
                    $$domain{'notes'} = formatNotes($$domain{'notes'});
                }
                $template->param($domain);
            }
        }
        elsif ($view eq 'hardware')
        {
            if ($viewType =~ /^default/)
            {
                my $hardware = $backend->hardwareList($orderBy);
                for my $h (@$hardware)
                {
                    $$h{'notes'} = formatNotes($$h{'notes'}, 1);
                    $$h{'notes_short'} = shortStr($$h{'notes'});
                }
                my $totalHardwareCount  = $backend->itemCount('hardware');
                my $listedHardwareCount = @$hardware;
                $template->param('total_hardware_count'  => $totalHardwareCount);
                $template->param('listed_hardware_count' => $listedHardwareCount);
                $template->param('all_hardware_listed'   => ($totalHardwareCount == $listedHardwareCount));
                $template->param('hardware'              => $hardware);
            }
            else
            {
                my $selectedManufacturer = $cgi->lastCreatedId;    # need to sort out this mess of CGI vars and make clearer!

                if (($viewType =~ /^edit/) || ($viewType =~ /^single/))
                {
                    my $hardware = $backend->hardware($id);
                    if ($viewType =~ /^single/)
                    {
                        $$hardware{'notes'} = formatNotes($$hardware{'notes'});
                    }
                    $selectedManufacturer = $$hardware{'manufacturer'} if (!$selectedManufacturer);    # Use database value for selected if none in CGI
                    $$hardware{'support_url_short'} = shortURL($$hardware{'support_url'});             # not actually needed by edit view
                    $$hardware{'spec_url_short'}    = shortURL($$hardware{'spec_url'});                # not actually needed by edit view
                    $template->param($hardware);
                }

                if (($viewType =~ /^edit/) || ($viewType =~ /^create/))
                {
                    $template->param('manufacturerlist' => $cgi->selectItem($backend->simpleList('hardware_manufacturer', 1), $selectedManufacturer));
                }
            }
        }
        elsif ($view eq 'org')
        {
            if ($viewType =~ /^default/)
            {
                my $orgs = $backend->orgList($orderBy);

                my $totalOrgCount  = $backend->itemCount('org');
                my $listedOrgCount = @$orgs;
                $template->param('total_org_count'  => $totalOrgCount);
                $template->param('listed_org_count' => $listedOrgCount);
                $template->param('all_org_listed'   => ($totalOrgCount == $listedOrgCount));

                for my $o (@$orgs)
                {
                    $$o{'notes'}          = formatNotes($$o{'notes'}, 1);
                    $$o{'notes_short'}    = shortStr($$o{'notes'});
                    $$o{'descript_short'} = shortStr($$o{'descript'});
                }
                $template->param('orgs' => $orgs);
            }
            elsif (($viewType =~ /^edit/) || ($viewType =~ /^single/))
            {
                my $org = $backend->org($id);
                if ($viewType =~ /^single/)
                {
                    $$org{'notes'} = formatNotes($$org{'notes'});
                }
                $template->param($org);
            }
            elsif ($viewType =~ /^create/)
            {
                $template->param({'customer' => $cgi->customer, 'software' => $cgi->software, 'hardware' => $cgi->hardware});
            }
        }
        elsif ($view eq 'os')
        {
            if ($viewType =~ /^default/)
            {
                my $os = $backend->osList($orderBy);
                for my $o (@$os)
                {
                    $$o{'notes'} = formatNotes($$o{'notes'}, 1);
                    $$o{'notes_short'} = shortStr($$o{'notes'});
                }
                my $totalOSCount  = $backend->itemCount('os');
                my $listedOSCount = @$os;
                $template->param('total_os_count'   => $totalOSCount);
                $template->param('listed_os_count'  => $listedOSCount);
                $template->param('all_os_listed'    => ($totalOSCount == $listedOSCount));
                $template->param('operatingsystems' => $os);
            }
            else
            {
                my $selectedManufacturer = $cgi->lastCreatedId;

                if (($viewType =~ /^edit/) || ($viewType =~ /^single/))
                {
                    my $operatingSystem = $backend->os($id);
                    if ($viewType =~ /^single/)
                    {
                        $$operatingSystem{'notes'} = formatNotes($$operatingSystem{'notes'});
                    }
                    $template->param($operatingSystem);
                    $selectedManufacturer = $$operatingSystem{'manufacturer'} if (!$selectedManufacturer);    # Use database value for selected if none in CGI
                }

                if (($viewType =~ /^edit/) || ($viewType =~ /^create/))
                {
                    $template->param('manufacturerlist' => $cgi->selectItem($backend->simpleList('software_manufacturer', 1), $selectedManufacturer));
                }
            }
        }
        elsif ($view eq 'rack')
        {
            if ($viewType =~ /^default/)
            {
                my $racks = $backend->rackList($orderBy);
                for my $r (@$racks)
                {
                    $$r{'notes'} = formatNotes($$r{'notes'}, 1);
                    $$r{'notes_short'} = shortStr($$r{'notes'});
                }
                my $totalRackCount  = $backend->itemCount('rack');
                my $listedRackCount = @$racks;
                $template->param('total_rack_count'  => $totalRackCount);
                $template->param('listed_rack_count' => $listedRackCount);
                $template->param('all_racks_listed'  => ($totalRackCount == $listedRackCount));
                $template->param('racks'             => $racks);
            }
            elsif ($viewType =~ /^physical/)
            {
                my @rackIdList = $cgi->rackList;
                push(@rackIdList, $id) if (scalar(@rackIdList) == 0);    # add current rack id if no list
                die "RMERR: You need to select at least one rack to display. Use the checkboxes at the right of the rack table to select racks."
                  unless $rackIdList[0];
                my @racks;
                my $selectDevice = $cgi->id('device');
                for my $rackId (@rackIdList)
                {
                    my $rack = $backend->rack($rackId);
                    $$rack{'rack_layout'} = $backend->rackPhysical($rackId, $selectDevice, 1);
                    push @racks, $rack;
                }
                $template->param('rack_list' => \@racks);
                $template->param('device_id' => $selectDevice);
            }
            else
            {
                my $selectedRoom = $cgi->lastCreatedId || $cgi->id('room');

                if (($viewType =~ /^edit/) || ($viewType =~ /^single/) || ($viewType =~ /^create/))
                {
                    my $rack = {};
                    if ($id)    # used if copying, editing or displaying single view, but not for a plain create
                    {
                        $rack = $backend->rack($id);
                    }
                    else
                    {
                        $$rack{'numbering_direction'} = $$conf{'number_from_top'};
                    }

                    $selectedRoom = $$rack{'room'} if (!$selectedRoom);    # Use database value for selected if none in CGI - not actually needed in single view

                    if ($viewType !~ /^single/)
                    {
                        $template->param('roomlist' => $cgi->selectRoom($backend->roomListBasic, $selectedRoom));
                    }
                    else
                    {
                        $$rack{'notes'} = formatNotes($$rack{'notes'});
                    }

                    # clear rack notes and name if we're creating a new device (so copy works)
                    if ($viewType =~ /^create/)
                    {
                        $$rack{'name'}  = '';
                        $$rack{'notes'} = '';
                    }

                    $template->param($rack);
                }
            }
        }
        elsif ($view eq 'report')
        {
            if ($viewType =~ /^default/)
            {
                my $totalDevices    = $backend->itemCount('device');
                my $unrackedDevices = $backend->deviceCountUnracked;
                $template->param('device_count'          => $totalDevices);
                $template->param('unracked_device_count' => $unrackedDevices);
                $template->param('racked_device_count'   => $totalDevices - $unrackedDevices);
                $template->param('rack_count'            => $backend->itemCount('rack'));
                my $rackSize   = $backend->totalSizeRack;
                my $deviceSize = $backend->totalSizeDevice;
                $template->param('total_rack_space' => $rackSize);
                $template->param('used_rack_space'  => $deviceSize);
                $template->param('free_rack_space'  => $rackSize - $deviceSize);
            }
            elsif ($viewType =~ /^counts/)
            {
                $template->param('customer_device_count' => $backend->customerDeviceCount);
                $template->param('role_device_count'     => $backend->roleDeviceCount);
                $template->param('hardware_device_count' => $backend->hardwareDeviceCount);
                $template->param('os_device_count'       => $backend->osDeviceCount);
            }
            elsif ($viewType =~ /^duplicates/)
            {
                $template->param('serials'   => $backend->duplicateSerials);
                $template->param('assets'    => $backend->duplicateAssets);
                $template->param('oslicence' => $backend->duplicateOSLicenceKey);
            }
        }
        elsif ($view eq 'role')
        {
            if ($viewType =~ /^default/)
            {
                my $roles = $backend->roleList($orderBy);

                my $totalRoleCount  = $backend->itemCount('role');
                my $listedRoleCount = @$roles;
                $template->param('total_role_count'  => $totalRoleCount);
                $template->param('listed_role_count' => $listedRoleCount);
                $template->param('all_role_listed'   => ($totalRoleCount == $listedRoleCount));

                for my $r (@$roles)
                {
                    $$r{'notes'}          = formatNotes($$r{'notes'}, 1);
                    $$r{'notes_short'}    = shortStr($$r{'notes'});
                    $$r{'descript_short'} = shortStr($$r{'descript'});
                }
                $template->param('roles' => $roles);
            }
            elsif (($viewType =~ /^edit/) || ($viewType =~ /^single/))
            {
                my $role = $backend->role($id);
                if ($viewType =~ /^single/)
                {
                    $$role{'notes'} = formatNotes($$role{'notes'});
                }
                $template->param($role);
            }
        }
        elsif ($view eq 'room')
        {
            if ($viewType =~ /^default/)
            {
                my $rooms = $backend->roomList($orderBy);
                for my $r (@$rooms)
                {
                    $$r{'notes'} = formatNotes($$r{'notes'}, 1);
                    $$r{'notes_short'} = shortStr($$r{'notes'});
                }
                my $totalRoomCount  = $backend->itemCount('room');
                my $listedRoomCount = @$rooms;
                $template->param('total_room_count'  => $totalRoomCount);
                $template->param('listed_room_count' => $listedRoomCount);
                $template->param('all_rooms_listed'  => ($totalRoomCount == $listedRoomCount));
                $template->param('rooms'             => $rooms);
            }
            else
            {
                my $selectedBuilding = $cgi->lastCreatedId || $cgi->id('building');

                if (($viewType =~ /^edit/) || ($viewType =~ /^single/))
                {
                    my $room = $backend->room($id);
                    if ($viewType =~ /^single/)
                    {
                        $$room{'notes'} = formatNotes($$room{'notes'});
                    }
                    $$room{'row_count'} = $backend->rowCountInRoom($id);
                    $selectedBuilding = $$room{'building'} if (!$selectedBuilding);    # Use database value for selected if none in CGI - not actually needed in single view
                    if ($viewType =~ /^single/)
                    {
                        $$room{'racks'} = $backend->rackListInRoom($id);               # fix method then use
                    }
                    $template->param($room);
                }

                if (($viewType =~ /^edit/) || ($viewType =~ /^create/))
                {
                    $template->param('buildinglist' => $cgi->selectItem($backend->simpleList('building'), $selectedBuilding));
                }
            }
        }
        elsif ($view eq 'row')
        {
            $template->param('rows' => $backend->rowListInRoom($cgi->id('room')));
            $template->param($backend->room($cgi->id('room')));
        }
        elsif ($view eq 'service')
        {
            if ($viewType =~ /^default/)
            {
                my $serviceLevels = $backend->serviceList($orderBy);

                my $totalServiceCount  = $backend->itemCount('service');
                my $listedServiceCount = @$serviceLevels;
                $template->param('total_service_count'  => $totalServiceCount);
                $template->param('listed_service_count' => $listedServiceCount);
                $template->param('all_service_listed'   => ($totalServiceCount == $listedServiceCount));

                for my $s (@$serviceLevels)
                {
                    $$s{'notes'}          = formatNotes($$s{'notes'}, 1);
                    $$s{'notes_short'}    = shortStr($$s{'notes'});
                    $$s{'descript_short'} = shortStr($$s{'descript'});
                }
                $template->param('services' => $serviceLevels);
            }
            elsif (($viewType =~ /^edit/) || ($viewType =~ /^single/))
            {
                my $service = $backend->service($id);
                if ($viewType =~ /^single/)
                {
                    $$service{'notes'} = formatNotes($$service{'notes'});
                }
                $template->param($service);
            }
        }
        else
        {
            die "RMERR: No such view. This error should not occur. Please report to developers.";
        }
    }

    # create rack dropdown
    my $selectedRack = 0;
    $selectedRack = $id if (($viewType =~ /^physical/) && ($view eq 'rack'));
    $template->param('racknavlist' => $cgi->selectRack($backend->rackListBasic(1), $selectedRack));

    # Get version, date and user for page footer
    $template->param('version' => "$VERSION");
    my ($minute, $hour, $day, $month, $year) = (gmtime)[1, 2, 3, 4, 5];
    my $currentDate = sprintf("%04d-%02d-%02d %02d:%02d GMT", $year + 1900, $month + 1, $day, $hour, $minute);
    $template->param('date'           => $currentDate);
    $template->param('logged_in_user' => $ENV{'REMOTE_USER'});
    $template->param('user_ip'        => $ENV{'REMOTE_ADDR'});

    # Make the current view and view_type available in the template
    $template->param('view'      => $cgi->view);
    $template->param('view_type' => $cgi->viewType);

    # Support overriding the next view of the template
    $template->param('return_view'      => $cgi->returnView     || $view);
    $template->param('return_view_type' => $cgi->returnViewType || '');
    $template->param('return_view_id'   => $cgi->returnViewId   || 0);

    # support hiding and showing of filters
    $template->param('show_filters'  => $cgi->showFilters);
    $template->param('filter_string' => $cgi->filterString);

    # XLS Plugin
    if ($$conf{'plugin_xls'})
    {
        my $rack2XLSURL = $baseURL;
        my $rackXLSName = $$conf{'plugin_xls'};
        
        if ($rack2XLSURL =~ /rackmonkey\.pl/)
        {
            $rack2XLSURL =~ s/\/(.*?)\.pl/$rackXLSName/;
        }
        else
        {
            $rack2XLSURL .= $rackXLSName;
        }
        $template->param('rack2xls_url' => $rack2XLSURL);
    }

    # DNS Plugin
    if ($$conf{'plugin_dns'})
    {
        my $rackDNSURL = $baseURL;
        my $rackDNSName = $$conf{'plugin_dns'};
        
        if ($rackDNSURL =~ /rackmonkey\.pl/)
        {
            $rackDNSURL =~ s/\/(.*?)\.pl/$rackDNSName/;
        }
        else
        {
            $rackDNSURL .= $rackDNSName;
        }
        $template->param('rackdns_url' => $rackDNSURL);
    }

    $template->param('base_url' => $baseURL);
    $template->param('web_root' => $$conf{'wwwpath'});
    $template->param('size_of_u' => $$conf{'size_of_u'});
    
    $template->param('order_by' => $orderBy);

    print $cgi->header;
    print $template->output;
};
if ($@)
{
    my $errMsg = $@;
    print $cgi->header;
    my $friendlyErrMsg = RackMonkey::Error::enlighten($errMsg);
    RackMonkey::Error::display($errMsg, $friendlyErrMsg, $backend->{'sys'});
}

sub shortStr
{
    my $str = shift;
    return unless defined $str;
    if (length($str) > $$conf{'shorttextlen'})
    {
        return substr($str, 0, $$conf{'shorttextlen'}) . '...';
    }
    return '';
}

sub shortURL
{
    my $url = shift;
    return unless defined $url;
    if (length($url) > $$conf{'shorturllen'})
    {
        return substr($url, 0, $$conf{'shorturllen'}) . '...';
    }
    return '';
}

sub calculateAge
{
    my $date = shift;
    return unless defined $date;
    my ($year, $month, $day) = $date =~ /(\d{4})-(\d{2})-(\d{2})/;
    if ($year)
    {
        $month--;    # perl months start at 0
        my $startTime = timelocal(0, 0, 12, $day, $month, $year);
        my $age = (time - $startTime) / (86400 * 365.24);    # Age in years
        return sprintf("%.1f", $age);
    }
    return '';
}

sub formatNotes
{
    my $note = shift;
    my $inline = shift || 0;
    $note = encode_entities($note);                             # we don't use HTML::Template escape so have to encode here

    unless ($inline)
    {
        $note =~ s/\n/<br>/sg;                                  # turn newlines into break tags
        $note =~ s/\[(.*?)\|(.*?)\]/<a href="$1">$2<\/a>/sg;    # create hyperlinks
        $note =~ s/\*\*\*(.*?)\*\*\*/<strong>$1<\/strong>/sg;   # strong using ***
        $note =~ s/\*\*(.*?)\*\*/<em>$1<\/em>/sg;               # emphasis using **
    }
    else
    {
        $note =~ s/\[(.*?)\|(.*?)\]/$2 ($1)/sg;                 # can't make proper hyperlinks inline as they may be truncated
        $note =~ s/\*\*\*(.*?)\*\*\*/$1/sg;                     # remove ***
        $note =~ s/\*\*(.*?)\*\*/$1/sg;                         # remove **
    }

    return $note;
}
