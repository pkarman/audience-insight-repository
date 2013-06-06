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

require_once 'rframe/AIRAPI_Resource.php';

/**
 * Project/Annotation API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Project_Annotation extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('prjan_value');
    protected $UPDATE_DATA = array('prjan_value');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'prjan_cre_dtim desc';
    protected $sort_valids    = array('prjan_cre_dtim');

    // metadata
    protected $ident = 'prjan_id';
    protected $fields = array(
        'prjan_id',
        'prjan_value',
        'prjan_cre_dtim',
        'prjan_upd_dtim',
        'CreUser' => array(
            'DEF::USERSTAMP',
            'UserOrg' => 'DEF::USERORG',
        ),
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $prj_id = $this->parent_rec->prj_id;

        $q = Doctrine_Query::create()->from('ProjectAnnotation a');
        $q->where('a.prjan_prj_id = ?', $prj_id);
        $q->leftJoin('a.CreUser u');
        $q->leftJoin('u.UserOrg uo WITH uo.uo_home_flag = true');
        $q->leftJoin('uo.Organization o');
        return $q;
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $prjan = new ProjectAnnotation();
        $prjan->Project = $this->parent_rec;
        $prjan->prjan_cre_user = $this->user->user_id;
        $prjan->prjan_upd_user = $this->user->user_id;
        return $prjan;
    }
    

    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->andWhere('a.prjan_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        $rec->prjan_upd_user = $this->user->user_id;
    }


}
