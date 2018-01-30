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
use Carp;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Getopt::Long;
use Pod::Usage;
use Text::CSV_XS;
use JSON;
use Data::Dump qw( dump );

use AIR2::Config;
use AIR2::Emailer;
use AIR2::User;
use AIR2::Organization;
use AIR2::Project;
use AIR2::Inquiry;
use AIR2::OutcomeWriter;
use AIR2::Utils;

=pod

=head1 NAME

outcome-export.pl

=head1 SYNOPSIS

 outcome-export.pl [options]
    --help
    --debug
    --sources
    --user_id=i
    --org_id=i
    --prj_id=i
    --inq_id=i
    --start_date=s
    --end_date=s
    --format=[csv|json|email]
    --count

=head1 DESCRIPTION

Exports outcomes to a CSV file or JSON object.  Can either
write to the screen, or mail the results to an AIR user.

Passing the --sources option will produce a row for every
src_outcome record in each of the outcomes.

=cut

my ($help,   $debug,      $sources,  $user_id, $org_id, $prj_id,
    $inq_id, $start_date, $end_date, $format,  $count
);
GetOptions(
    'help'         => \$help,
    'debug'        => \$debug,
    'sources'      => \$sources,
    'user_id=i'    => \$user_id,
    'org_id=i'     => \$org_id,
    'prj_id=i'     => \$prj_id,
    'inq_id=i'     => \$inq_id,
    'start_date=s' => \$start_date,
    'end_date=s'   => \$end_date,
    'format=s'     => \$format,
    'count'        => \$count,
) or pod2usage(2);

if ($help) {
    pod2usage(2);
}
$debug   = 0     unless defined $debug;
$sources = 0     unless defined $sources;
$format  = 'csv' unless defined $format;
$count   = 0     unless defined $count;

# check user
die "user_id required" unless defined $user_id;
my $user = AIR2::User->new( user_id => $user_id )->load_speculative
    or die "unknown user_id($user_id)";
if ( !$user->get_primary_email() && $format eq 'email' ) {
    croak "User " . $user->user_username . " has no email address!";
}

# format defaults to outputting a csv to screen
if ( $format ne 'csv' && $format ne 'json' && $format ne 'email' ) {
    pod2usage(
        'Invalid format specified! Valid formats are (csv, json, email)');
}

# get the csv object
my $opts = ();
$opts->{debug}      = 1           if $debug;
$opts->{sources}    = 1           if $sources;
$opts->{count}      = 1           if $count;
$opts->{org_id}     = $org_id     if $org_id;
$opts->{prj_id}     = $prj_id     if $prj_id;
$opts->{inq_id}     = $inq_id     if $inq_id;
$opts->{start_date} = $start_date if $start_date;
$opts->{end_date}   = $end_date   if $end_date;
my $obj = AIR2::OutcomeWriter->get_obj( $user_id, $opts );

# count just prints an integer
if ( $opts->{count} ) {
    print $obj;
    exit;
}

# write to output format
if ( $format eq 'csv' ) {
    my $csv = Text::CSV_XS->new( { binary => 1, eol => $/ } )
        or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
    $csv->print( "STDOUT", $_ ) for @{$obj};
}
elsif ( $format eq 'json' ) {
    my $json = encode_json($obj);
    print $json;
}
elsif ( $format eq 'email' ) {
    my $eml = $user->get_primary_email()->uem_address();

    # report any constraints in the email body
    my $body = "Export of all PINfluence";
    if (   $org_id
        || $prj_id
        || $inq_id
        || $start_date
        || $end_date
        || $sources )
    {
        $body
            = "Your PINfluence report is available at the URL below. It includes:\n";
    }
    if ($org_id) {
        my $org = AIR2::Organization->new( org_id => $org_id )->load;
        $body .= "  --Organization = " . $org->org_display_name . "\n";
    }
    if ($prj_id) {
        my $prj = AIR2::Project->new( prj_id => $prj_id )->load;
        $body .= "  --Project = " . $prj->prj_display_name . "\n";
    }
    if ($inq_id) {
        my $inq = AIR2::Inquiry->new( inq_id => $inq_id )->load;
        $body .= "  --Query = " . $inq->inq_ext_title . "\n";
    }
    if ($start_date) {
        $body .= "  --Date > $start_date\n";
    }
    if ($end_date) {
        $body .= "  --Date < $end_date\n";
    }
    if ($sources) {
        $body .= "  --One row per source\n";
    }
    else {
        $body .= "  --One row per PINfluence entry\n";
    }

    # generate the csv file
    my $url = AIR2::Utils::write_secure_csv_report( rows => $obj );
    $body .= "\nReport available at:\n$url\n";

    # fire!
    send_email(
        to       => $eml,
        subject => "Here is the PINfluence Report you just exported from AIR",
        text    => $body,
    );
}

sub send_email {
    my %args = @_;
    if ($debug) {
        dump \%args;
    }
    my $emailer = AIR2::Emailer->new( debug => $debug );
    $emailer->send(%args);
}
