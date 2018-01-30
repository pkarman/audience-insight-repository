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
use Test::More tests => 114;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::User;
use Rose::DBx::Object::Indexed::Indexer;
use Search::Tools::XML;
use JSON;
use Plack::Test;
use utf8;

my $stxml          = Search::Tools::XML->new;
my $debug          = $ENV{PERL_DEBUG} || 0;
my $ellips         = "…";
my $TEST_ORG_NAME0 = 'testorg0';
my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_ORG_NAME2 = 'testorg2';
my $TEST_USERNAME  = 'ima-test-user';
my $TEST_PROJECT   = 'ima-test-project';
my $TEST_INQ_UUID  = 'testinq12345';
my $TEST_INQ_UUID2 = 'testinq67890';
my $TEST_INQ_UUID3 = 'testinq78901';
my $TMP_DIR        = AIR2::Config::get_tmp_dir->subdir('search');
$AIR2::Config::SEARCH_ROOT = $TMP_DIR;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

$TMP_DIR->mkpath($debug);
my $xml_dir = $TMP_DIR->subdir('xml/sources');
$xml_dir->mkpath($debug);
my $index_dir = $TMP_DIR->subdir('index/sources');
$index_dir->mkpath($debug);

##################################################################################
## set up test data
##################################################################################

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);

ok( my $project2 = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT . 2,
        prj_display_name => $TEST_PROJECT . 2,
    ),
    "new project2"
);

ok( my $project3 = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT . 3,
        prj_display_name => $TEST_PROJECT . 3,
    ),
    "new project3"
);

ok( $project->load_or_save,  "save project" );
ok( $project2->load_or_save, "save project2" );
ok( $project3->save,         "save project3" );

ok( my $org0 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME0,
        )->load_or_save(),
    "create test org0"
);
ok( my $org1 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME1,
        org_parent_id      => $org0->org_id,
        )->load_or_save(),
    "create test org1"
);
ok( my $org2 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2,
        org_parent_id      => $org0->org_id,
        )->load_or_save(),
    "create test org2"
);
ok( my $org3 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2 . '-child',
        org_parent_id      => $org2->org_id,
        )->load_or_save(),
    "create test org3 child of org2"
);
ok( my $inactive_org = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2 . '-child-inactive',
        org_parent_id      => $org2->org_id,
        org_status         => 'F',
        )->save(),
    "create test inactive_org child of org2"
);

for my $o ( ( $org0, $org1, $org2, $org3, $inactive_org ) ) {
    diag(
        sprintf(
            "[%s] org=%s parent=%s",
            $o->org_id, $o->org_name, ( $o->org_parent_id || 'undef' ),
        )
    );
}

ok( my $user = AIR2Test::User->new(
        user_username   => $TEST_USERNAME,
        user_first_name => 'First',
        user_last_name  => 'Last',
    ),
    "create test user"
);
ok( $user->load_or_save(), "save test user" );

# must do this AFTER we set default_prj_id above
ok( $project->add_project_orgs(
        [   {   porg_org_id          => $org1->org_id,
                porg_contact_user_id => $user->user_id,
            },
            {   porg_org_id          => $org2->org_id,
                porg_contact_user_id => $user->user_id,
            }
        ]
    ),
    "add orgs to project"
);
ok( $project->save(), "write ProjectOrgs" );

ok( $project2->add_project_orgs(
        [   {   porg_org_id          => $org2->org_id,
                porg_contact_user_id => $user->user_id,
            }
        ]
    ),
    "add orgs to project2"
);
ok( $project2->save(), "write ProjectOrgs2" );

ok( $project3->add_project_orgs(
        [   {   porg_org_id          => $inactive_org->org_id,
                porg_contact_user_id => $user->user_id
            }
        ]
    ),
    "add orgs to project3"
);

ok( my $source = AIR2Test::Source->new(
        src_username  => $TEST_USERNAME,
        src_post_name => 'esquire',
    ),
    "new source"
);
ok( $source->add_emails(
        [ { sem_email => $TEST_USERNAME . '@nosuchemail.org' } ]
    ),
    "add email address"
);
ok( $source->add_organizations( [$org1] ), "add orgs to source" );
ok( $source->add_annotations( [ { srcan_value => 'seeme annotation' } ] ),
    "add source annotations" );
ok( $source->load_or_save(), "save source" );

ok( my $source2 = AIR2Test::Source->new(
        src_username  => $TEST_USERNAME . '2',
        src_post_name => 'esquire',
    ),
    "new source"
);
ok( $source2->add_emails(
        [ { sem_email => $TEST_USERNAME . '@really-nosuchemail.org' } ]
    ),
    "add email address"
);
ok( $source2->add_organizations( [$org2] ), "add orgs to source" );
ok( $source2->add_annotations( [ { srcan_value => 'seeme annotation2' } ] ),
    "add source annotations" );
ok( $source2->load_or_save(), "save source2" );

ok( my $source3 = AIR2Test::Source->new(
        src_username  => $TEST_USERNAME . '3',
        src_post_name => 'esquire',
    ),
    "new source"
);
ok( $source3->add_emails(
        [ { sem_email => $TEST_USERNAME . '@3really-nosuchemail.org' } ]
    ),
    "add email address"
);
ok( $source3->add_src_orgs(
        [   { so_org_id => $org1->org_id, so_status => 'A' },
            { so_org_id => $org2->org_id, so_status => 'F' },
            { so_org_id => $org3->org_id, so_status => 'A' },
        ]
    ),
    "add orgs, one opt-in one opt-out one opt-in-to-child-of-opt-out"
);
ok( $source3->load_or_save(), "save source3" );

# must do this explicitly since orgs are cached at startup
AIR2::Organization::clear_caches();
AIR2::SrcOrgCache::refresh_cache($source);
AIR2::SrcOrgCache::refresh_cache($source2);
AIR2::SrcOrgCache::refresh_cache($source3);

####################
## set up queries
ok( my $inq = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_INQ_UUID,
        inq_title => 'the color query',
    ),
    "create test inquiry"
);

ok( $inq->add_projects( [ $project, $project2 ] ),
    "add projects to inquiry" );

ok( my $inq2 = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_INQ_UUID2,
        inq_title => 'the shape query',
    ),
    "create test inquiry2"
);

ok( $inq2->add_projects( [$project2] ), "add projects to inquiry2" );

ok( my $ques
        = AIR2::Question->new( ques_value => 'what is your favorite color' ),
    "new question"
);
ok( $inq->add_questions( [$ques] ), "add question" );
ok( $inq->load_or_save, "save inquiry" );

ok( my $ques2
        = AIR2::Question->new( ques_value => 'what is your favorite shape' ),
    "new question2"
);
ok( $inq2->add_questions( [$ques2] ), "add question2" );
ok( $inq2->load_or_save, "save inquiry2" );

ok( my $inq_with_inactive_org = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_INQ_UUID3,
        inq_title => 'belongs to inactive org'
    ),
    "create test inq_with_inactive_org"
);
ok( $inq_with_inactive_org->add_projects( [$project3] ),
    "add project3 to inq_with_inactive_org" );
ok( $inq_with_inactive_org->save(), "save inq_with_inactive_org" );

##############################
## set up responses
ok( my $srs = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source->src_id,
        srs_inq_id => $inq->inq_id,
        srs_date   => time(),
    ),
    "new SrcResponseset"
);
ok( my $response = AIR2::SrcResponse->new(
        sr_src_id     => $source->src_id,
        sr_ques_id    => $ques->ques_id,
        sr_orig_value => "blue is my favorite color$ellips",
    ),
    "new response"
);
ok( $srs->add_responses( [$response] ), "add responses" );
ok( $srs->save(), "save SrcResponseSet" );

ok( my $srs2 = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source2->src_id,
        srs_inq_id => $inq->inq_id,
        srs_date   => time(),
    ),
    "new SrcResponseset"
);
ok( my $response2 = AIR2::SrcResponse->new(
        sr_src_id     => $source2->src_id,
        sr_ques_id    => $ques->ques_id,
        sr_orig_value => "red is my favorite color$ellips",
    ),
    "new response"
);
ok( $srs2->add_responses( [$response2] ), "add responses" );
ok( $srs2->save(), "save SrcResponseSet" );

ok( my $srs3 = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source->src_id,
        srs_inq_id => $inq2->inq_id,
        srs_date   => time(),
    ),
    "new SrcResponseset"
);
ok( my $response3 = AIR2::SrcResponse->new(
        sr_src_id     => $source->src_id,
        sr_ques_id    => $ques2->ques_id,
        sr_orig_value => "circle is my favorite shape$ellips",
    ),
    "new response"
);
ok( $srs3->add_responses( [$response3] ), "add response3" );
ok( $srs3->save(), "save SrcResponseSet 2" );

#################################
## responses XML

ok( my $resp_xml = $srs->as_xml(
        { debug => $debug, base_dir => $TMP_DIR->subdir('xml/responses') }
    ),
    "get resp_xml"
);
ok( my $resp_xml2 = $srs2->as_xml(
        { debug => $debug, base_dir => $TMP_DIR->subdir('xml/responses') }
    ),
    "get resp_xml2"
);
ok( my $resp_xml3 = $srs3->as_xml(
        { debug => $debug, base_dir => $TMP_DIR->subdir('xml/responses') }
    ),
    "get resp_xml3"
);

#diag("write xml for " . $srs->srs_id);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $srs->srs_id,
        base   => $TMP_DIR->subdir('xml/responses'),
        xml    => $resp_xml,
        pretty => $debug,
    ),
    "write resp_xml"
);

#diag("write xml for " . $srs2->srs_id);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $srs2->srs_id,
        base   => $TMP_DIR->subdir('xml/responses'),
        xml    => $resp_xml2,
        pretty => $debug,
    ),
    "write resp_xml2"
);

#diag("write xml for " . $srs3->srs_id);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $srs3->srs_id,
        base   => $TMP_DIR->subdir('xml/responses'),
        xml    => $resp_xml3,
        pretty => $debug,
    ),
    "write resp_xml3"
);

#############################
## sources xml
ok( my $xml = $source->as_xml(
        {   debug    => $debug,
            base_dir => $xml_dir,
        }
    ),
    "source->as_xml"
);

#diag( Search::Tools::XML->tidy($xml) );

# authz string should be explicit + parents/children
my $xml_authz_str = join( ',', $org0->org_id, $org1->org_id );
like( $xml, qr/authz="$xml_authz_str"/, "source authz str" );

ok( AIR2::SearchUtils::write_xml_file(
        pk     => $source->src_id,
        base   => $xml_dir,
        xml    => $xml,
        pretty => $debug,
        debug  => $debug,
    ),
    "write xml file"
);

ok( my $xml2 = $source2->as_xml(
        {   debug    => $debug,
            base_dir => $xml_dir,
        }
    ),
    "source2->as_xml"
);

#diag( Search::Tools::XML->tidy($xml2) );

# authz string should be explicit + parents/children
my $xml2_authz_str = join( ',',
    $org0->org_id, $org2->org_id, $org3->org_id, $inactive_org->org_id );
like( $xml2, qr/authz="$xml2_authz_str"/, "source2 authz str" );

ok( AIR2::SearchUtils::write_xml_file(
        pk     => $source2->src_id,
        base   => $xml_dir,
        xml    => $xml2,
        pretty => $debug,
        debug  => $debug,
    ),
    "write xml file"
);

ok( my $xml3 = $source3->as_xml(
        {   debug    => $debug,
            base_dir => $xml_dir,
        }
    ),
    "source3->as_xml"
);

#diag( Search::Tools::XML->tidy($xml3) );

# authz string should be explicit + parents/children
my $xml3_authz_str = join( ',',
    $org0->org_id, $org1->org_id, $org2->org_id,
    $org3->org_id, $inactive_org->org_id );
like( $xml3, qr/authz="$xml3_authz_str"/, "source3 authz str" );

ok( AIR2::SearchUtils::write_xml_file(
        pk     => $source3->src_id,
        base   => $xml_dir,
        xml    => $xml3,
        pretty => $debug,
        debug  => $debug,
    ),
    "write source3 xml file"
);

#############################
## inquiry xml
ok( my $inqxml = $inq->as_xml(
        {   debug    => $debug,
            base_dir => $TMP_DIR->subdir('xml/inquiries')
        }
    ),
    "make inqxml"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $inq->inq_id,
        base   => $TMP_DIR->subdir('xml/inquiries'),
        xml    => $inqxml,
        pretty => $debug,
        debug  => $debug,
    ),
    "write inqxml file"
);
ok( my $inqxml2 = $inq2->as_xml(
        {   debug    => $debug,
            base_dir => $TMP_DIR->subdir('xml/inquiries')
        }
    ),
    "make inqxml2"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $inq2->inq_id,
        base   => $TMP_DIR->subdir('xml/inquiries'),
        xml    => $inqxml2,
        pretty => $debug,
        debug  => $debug,
    ),
    "write inqxml2 file"
);

ok( my $inactive_inq_xml = $inq_with_inactive_org->as_xml(
        {   debug    => $debug,
            base_dir => $TMP_DIR->subdir('xml/inquiries')
        }
    ),
    "make inactive_inq_xml"
);

my $inactive_org_inq_authz
    = sprintf( 'authz="%s"', join( ',', ( $org0->org_id, $org2->org_id ) ) );
like( $inactive_inq_xml, qr/$inactive_org_inq_authz/,
    "authz for inq with inactive org" );

$debug and diag(`tree $TMP_DIR`);

#########################
## create indexes
is( AIR2TestUtils::create_index(
        invindex => $index_dir,
        config =>
            AIR2::Config->get_app_root->file('etc/search/sources.config'),
        input => $xml_dir,
        debug => $debug,
    ),
    3,
    "create tmp source index with 3 docs in it"
);

is( AIR2TestUtils::create_index(
        invindex => $TMP_DIR->subdir('index/inquiries'),
        config =>
            AIR2::Config->get_app_root->file('etc/search/inquiries.config'),
        input => $TMP_DIR->subdir('xml/inquiries'),
        debug => $debug,
    ),
    2,
    "create tmp inquiries index with 2 docs in it"
);

is( AIR2TestUtils::create_index(
        invindex => $TMP_DIR->subdir('index/responses'),
        config =>
            AIR2::Config->get_app_root->file('etc/search/responses.config'),
        input => $TMP_DIR->subdir('xml/responses'),
        debug => $debug,
    ),
    3,
    "create tmp responses index with 3 docs in it"
);

##########################################################################################
## authz tests
##########################################################################################

ok( my $at  = AIR2TestUtils->new_auth_tkt(), "get auth tkt object" );
ok( my $tkt = AIR2TestUtils::dummy_tkt(),    "get dummy auth tkt" );

# SHHHHHHHHHH!
#$ENV{AIR2_QUIET} = 1;

my $skip_routes = {
    projects                => 1,
    'fuzzy-sources'         => 1,
    'sources'               => 1,
    'fuzzy-active-sources'  => 1,
    'active-sources'        => 1,
    'fuzzy-primary-sources' => 1,
    'primary-sources'       => 1,
    'fuzzy-responses'       => 1,
    'responses'             => 1,
    'public-responses'      => 1,
};

# defer loading this till after test is compiled so that TMP_DIR is
# correctly recognized by AI2::Config and all the Search::Servers
require AIR2::Search::MasterServer;
test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req      = HTTP::Request->new(
            GET => "/strict-sources/search?q=color&air2_tkt=$tkt&c=1" );
        my $resp = $callback->($req);

        #dump($resp);

        ok( my $json = decode_json( $resp->content ),
            "json decode body of response" );

        #dump($json);

        is( $json->{unauthz_total}, 2, "dummy has 2 unauthz hits" );
        is( $json->{total},         0, "dummy has 0 authz hits" );
    },
);

#########################################################################
# test access to source1
my $src1_authz = encode_json(
    {   user => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz( { $org1->org_id => 1 } )
    }
);
my $src1_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $src1_authz
);

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req      = HTTP::Request->new(
            GET => "/strict-sources/search?q=color&air2_tkt=$src1_tkt" );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total}, 2, "src1_tkt has unauthz 2 hits" );
        is( $json->{total},         1, "src1_tkt has authz to 1 hit" );
        is( $json->{results}->[0]->{src_username},
            $TEST_USERNAME, "one hit == source1" );

    },
);

##########################################################################
# test access to source2
my $src2_authz = encode_json(
    {   user => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz( { $org2->org_id => 1 } )
    }
);
my $src2_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $src2_authz
);

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req      = HTTP::Request->new(
            GET => "/strict-sources/search?q=color&air2_tkt=$src2_tkt" );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total}, 2, "src2_tkt has unauthz 2 hits" );
        is( $json->{total},         1, "src2_tkt has authz to 1 hit" );
        is( $json->{results}->[0]->{src_username},
            $TEST_USERNAME . '2',
            "one hit == source2"
        );

    },
);

############################################################################
# test annotation field aliasing (TODO really should be in a query-test .t file ...)
test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req
            = HTTP::Request->new( GET =>
                "/strict-sources/search?q=annotation%3dseeme&air2_tkt=$src2_tkt"
            );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total}, 2, "src2_tkt has unauthz hits" );
        is( $json->{total},         1, "src2_tkt has authz to hit" );
        is( $json->{results}->[0]->{src_username},
            $TEST_USERNAME . '2',
            "one hit == source2"
        );
    },
);

############################################################################
# same for src_post_name
test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req
            = HTTP::Request->new( GET =>
                "/strict-sources/search?q=profile%3desquire&s=src_username&air2_tkt=$src2_tkt"
            );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total},
            3, "src2_tkt has unauthz hits for profile=esquire" );
        is( $json->{total}, 2,
            "src2_tkt has authz to hit for profile=esquire" );
        is( $json->{results}->[0]->{src_username},
            $TEST_USERNAME . '2',
            "one hit == source2"
        );
    },
);

############################################################################
# active-sources vs sources
test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req
            = HTTP::Request->new( GET =>
                "/strict-active-sources/search?q=profile%3desquire&air2_tkt=$src2_tkt"
            );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );

        #diag( dump $json );
        is( $json->{unauthz_total},
            3, "active-sources + src2_tkt has unauthz hits" );
        is( $json->{total}, 1, "active-soruces + src2_tkt has authz hit" );

    },
);

############################################################################
### trac #2266 authz inheritance
# test access to source3
# this dummy user is in org3 (child of org2)
# so should see source2 (active org2, parent) and source3 (active org3, direct)
my $src3_authz = encode_json(
    {   user => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz( { $org3->org_id => 1 } )
    }
);
my $src3_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $src3_authz
);

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req
            = HTTP::Request->new( GET =>
                "/strict-active-sources/search?q=profile%3desquire&air2_tkt=$src3_tkt&s=src_username"
            );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total},
            3, "active-sources + src3_tkt has unauthz hits" );
        is( $json->{total}, 2, "active-soruces + src3_tkt has authz hits" );
        is( $json->{results}->[0]->{src_username},
            "ima-test-user2", "source2" );
        is( $json->{results}->[1]->{src_username},
            "ima-test-user3", "source3" );

    },
);

#################################################
## responses authz
#
# 2 projects
# project1 is connected to org1 and org2
# project2 is connected to org2
# user1 in org1 can see responses to project1
# user2 in org2 can see responses to both project1 and project2
# source in org1 makes responses to both project1 and project2
# user1 can see source but not response to project2
# user2 can see both responses but not source

my $org1_authz = encode_json(
    {   user => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz( { $org1->org_id => 1 } )
    }
);
my $org1_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $org1_authz
);

my $org2_authz = encode_json(
    {   user => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz( { $org2->org_id => 1 } )
    }
);
my $org2_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $org2_authz
);

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req      = HTTP::Request->new(
            GET => "/strict-responses/search?q=is&air2_tkt=$org1_tkt" );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total},
            3, "responses + org1_tkt has unauthz hits" );
        is( $json->{total}, 2, "responses + org1_tkt has authz hits" );
        for my $r ( @{ $json->{results} } ) {
            is( $r->{inq_title}, "the color query", "got color query" );
            is( scalar( @{ $r->{qa} } ), 1, "got 1 qa match" );
            for my $qa ( @{ $r->{qa} } ) {

                #diag( dump $qa );
                like( $qa->{resp}, qr/$ellips/, "matches utf8 character" );
            }
        }

    },
);

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip_routes } ),
    client => sub {
        my $callback = shift;
        my $req      = HTTP::Request->new(
            GET => "/strict-responses/search?q=is&air2_tkt=$org2_tkt" );
        my $resp = $callback->($req);
        my $json = decode_json( $resp->content );
        is( $json->{unauthz_total},
            3, "responses + org2_tkt has unauthz hits" );
        is( $json->{total}, 3, "responses + org2_tkt has authz hits" );

    },
);

#################################################################
# clean up unless debug is on
#################################################################
END {
    if ( !$debug ) {
        $TMP_DIR->rmtree;
    }
}
