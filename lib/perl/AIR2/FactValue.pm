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

package AIR2::FactValue;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'fact_value',

    columns => [
        fv_id      => { type => 'serial',  not_null => 1 },
        fv_fact_id => { type => 'integer', default  => '0', not_null => 1 },
        fv_parent_fv_id => { type => 'integer' },
        fv_seq => { type => 'integer', default => 10, not_null => 1 },
        fv_value => {
            type     => 'varchar',
            default  => '',  # TODO
            length   => 128,
            not_null => 1
        },
        fv_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        fv_cre_user => { type => 'integer', not_null => 1 },
        fv_upd_user => { type => 'integer' },
        fv_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        fv_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['fv_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { fv_cre_user => 'user_id' },
        },

        fact => {
            class       => 'AIR2::Fact',
            key_columns => { fv_fact_id => 'fact_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { fv_upd_user => 'user_id' },
        },
    ],

    relationships => [
        src_facts => {
            class      => 'AIR2::SrcFact',
            column_map => { fv_id => 'sf_fv_id' },
            type       => 'one to many',
        },

        src_mapped_facts => {
            class      => 'AIR2::SrcFact',
            column_map => { fv_id => 'sf_src_fv_id' },
            type       => 'one to many',
        },

        translation_map => {
            class      => 'AIR2::TranslationMap',
            column_map => { fv_id => 'xm_xlate_to_fv_id' },
            type       => 'one to many',
        },
    ],
);

1;

