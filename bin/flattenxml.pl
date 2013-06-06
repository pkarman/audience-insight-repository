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

#
# gunzip and resolve all xincludes
#
#

use strict;
use warnings;
use Carp;
use SWISH::3;

my $file = shift or die "$0 file.xml";
print get_xml( $file );

sub get_xml {
     my $buf = SWISH::3->slurp(shift);
     return replace_xincludes($buf);
}

sub replace_xincludes {
    my $buf = shift;
    $buf =~ s,<xi:include href="(.+?)"/>,get_xml($1),ge;
    return $buf;
}

