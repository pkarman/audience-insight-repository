<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/


/************************
 * Routes controlled by subclasses of AIR2_APIController
 */
$api_routes = array(
    'alert',
    'background',
    'bin',
    'csv',
    'email',
    'import',
    'inquiry',
    'organization',
    'orgtree',
    'outcome',
    'outcomeexport',
    'preference',
    'project',
    'query',
    'savedsearch',
    'search',
    'source',
    'srcemail',
    'submission',
    'tag',
    'tank',
    'translation',
    'user',
);

$route['validator/([\w]+)'] = "validator/validate_record/$1";
$route['dashboard/([\w]+)'] = 'dashboard/get_org_stats/$1';
//$route['bin/([\w]+)'] = 'bin/index/bin/$1';
$route['password/([\w]+)'] = 'password/change_password_page/$1';

// alias search for "queries"
$route['search/queries'] = 'search/inquiries';
// alias search for "pinfluence"
$route['search/pinfluence'] = 'search/outcomes';

// querybuilder
$route['builder/([\w]+)'] = 'builder/index/$1';

// give the reader control of responses
$route['search/responses'] = 'reader';
$route['search/fuzzy-responses'] = 'reader';
$route['search/strict-responses'] = 'reader/strict';
$route['search/strict-active-responses'] = 'reader/strict_active';
$route['search/fuzzy-active-responses'] = 'reader/active';
$route['search/active-responses'] = 'reader/active';
$route['reader/strict-query/([\w]+)'] = 'reader/strict_query/$1';
$route['reader/active-query/([\w]+)'] = 'reader/active_query/$1';
$route['reader/strict-active-query/([\w]+)'] = 'reader/strict_active_query/$1';

// emails - "change" and "thanks" STEAL this route from the api
$route['email/change'] = 'emailchange/change';
$route['email/thanks'] = 'emailchange/thanks';
$route['email/unsubscribe'] = 'emailchange/unsubscribe';
$route['email/unsubscribe/(:any)'] = 'emailchange/unsubscribe/$1';
$route['email/unsubscribe-confirm'] = 'emailchange/unsubscribe_confirm';

// api namespace
$route['api/public/(:any)'] = 'public/$1';

// default
$route['default_controller'] = "home";
