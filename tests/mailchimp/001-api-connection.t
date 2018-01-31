#!/usr/bin/env perl
###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin";
use AIR2::Config;
use Data::Dump qw( dump );
use JSON;
use AIR2::Mailchimp;

use MailchimpUtils;

SKIP: {
    skip( "skipping mailchimp", 3 ) unless MailchimpUtils::env_ok();

    ok( my $chimp = MailchimpUtils::client(), "new AIR2::Mailchimp" );
    ok( $chimp->isa('AIR2::Mailchimp'), 'isa AIR2::Mailchimp' );
    is( ref( $chimp->mailing_list ), 'HASH',
        'initialized with mailing list' );

    MailchimpUtils::debug_list();
}
