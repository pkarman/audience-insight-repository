#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Socket;
use Test::More tests => 3;
use AIR2::DBManager;
use Data::Dump qw( dump );
use AIR2::DB;
use Rose::DB::Object::Metadata;

# "our" to share between packages
our $DB = AIR2::DBManager->new_or_cached();

{

    package DummyUserVisit;
    @DummyUserVisit::ISA = ('AIR2::DB');

    sub init_db {
        return $main::DB;
    }
}

ok( my $uv_meta = Rose::DB::Object::Metadata->new(
        table => 'user_visit',
        class => 'DummyUserVisit',
    ),
    "new uv_meta"
);
$uv_meta->auto_initialize();

my $has_uv_ipaddr = 0;
my $has_uv_ip     = 0;
for my $col ( @{ $uv_meta->columns } ) {
    if ( $col->name eq "uv_ipaddr" ) {
        $has_uv_ipaddr = 1;
    }
    if ( $col->name eq 'uv_ip' ) {
        $has_uv_ip = 1;
    }
}

# create column
if ( !$has_uv_ipaddr ) {
    ok( $DB->dbh->do(
            "alter table user_visit add column uv_ipaddr varchar(64)" # could be 45 but you never know
        ),
        "add uv_ipaddr"
    );
}
else {
    pass("uv_ipaddr already exists");
}

if ($has_uv_ip) {

    # migrate data
    my $uvs = DummyUserVisit->fetch_all_iterator;
    while ( my $uv = $uvs->next ) {
        my $ip_str = inet_ntoa( pack( "N", $uv->uv_ip ) );
        $uv->uv_ipaddr($ip_str);
        $uv->set_admin_update(1);
        $uv->update();
    }

    # remove column
    ok( $DB->dbh->do("alter table user_visit drop column uv_ip"),
        "remove uv_ip" );
}
else {
    pass("uv_ip does not exist");
}
