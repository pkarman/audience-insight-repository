<?php
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

require_once 'Search_Proxy.php';

/**
 * Bin
 *
 * A container to hold sources for use in bulk operations
 *
 * @property integer   $bin_id
 * @property string    $bin_uuid
 * @property integer   $bin_user_id
 * @property string    $bin_name
 * @property string    $bin_desc
 * @property string    $bin_type
 * @property string    $bin_status
 * @property boolean   $bin_shared_flag
 * @property integer   $bin_cre_user
 * @property integer   $bin_upd_user
 * @property timestamp $bin_cre_dtim
 * @property timestamp $bin_upd_dtim
 *
 * @property User                $User
 * @property Doctrine_Collection $BinSource
 * @property Doctrine_Collection $BinSrcResponseSet
 *
 * @author  rcavis
 * @package default
 */
class Bin extends AIR2_Record {

    // code_master values
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_ACTIVE_PROMPT_NOTES = 'P';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_SOURCE = 'S';

    // business-rule limits
    public static $MAX_CSV_EXPORT = 2500;


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('bin');
        $this->hasColumn('bin_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('bin_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('bin_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('bin_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('bin_desc', 'string', 255, array(

            ));
        $this->hasColumn('bin_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_SOURCE,
            ));
        $this->hasColumn('bin_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('bin_shared_flag ', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('bin_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('bin_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('bin_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('bin_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'bin_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasMany('BinSource', array(
                'local' => 'bin_id',
                'foreign' => 'bsrc_bin_id',
            ));
        $this->hasMany('BinSrcResponseSet', array(
                'local' => 'bin_id',
                'foreign' => 'bsrs_bin_id',
            ));
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @param Doctrine_Query $q
     * @param string $alias
     * @param string $search
     * @param boolean $useOr
     */
    public static function add_search_str($q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "({$a}bin_name like ?)";
        $params = array("%$search%");

        // try to also search User, if it's part of the query and has an alias
        if ($alias) {
            $parts = $q->getDqlPart('from');
            foreach ($parts as $dql) {
                if (preg_match("/$alias.User.*$/", $dql, $matches)) {
                    $usr_alias = preg_replace("/$alias.User\s*/", '', $matches[0]);

                    // must have alias
                    if ($usr_alias) {
                        $tmp = Doctrine_Query::create();
                        User::add_search_str($tmp, $usr_alias, $search);
                        $usrq = array_pop($tmp->getDqlPart('where'));
                        $usrp = $tmp->getFlattenedParams();

                        $str .= " or $usrq";
                        $params = array_merge($params, $usrp);
                    }
                }
            }
        }

        // add to query
        if ($useOr) {
            $q->orWhere($str, $params);
        }
        else {
            $q->addWhere($str, $params);
        }
    }


    /**
     * Read - owner or shared
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($this->bin_user_id == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        if ($this->bin_shared_flag) {
            return AIR2_AUTHZ_IS_PUBLIC;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Write - owner
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if (!$this->exists()) {
            $authz = $user->get_authz();
            foreach ($authz as $org_id => $role) {
                if ($role & ACTION_BATCH_CREATE) {
                    return AIR2_AUTHZ_IS_NEW;
                }
            }
        }
        if ($this->bin_user_id == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manage - same as write
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


    /**
     * Read - owner or shared
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_read($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";
        $uid = $u->user_id;
        $q->addWhere("({$a}bin_shared_flag=1 or {$a}bin_user_id=$uid)");
    }


    /**
     * Write - owner
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_write($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";
        $q->addWhere("{$a}bin_user_id = ?", $u->user_id);
    }


    /**
     * Manage - same as write
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_manage($q, $u, $alias=null) {
        self::query_may_write($q, $u, $alias);
    }



    /**
     * Schedule a job_queue to export this bin to a csv, and email it to the
     * user.  Note that this will FAIL if the user has no email.
     *
     * @param  User     $usr
     * @param  boolean  $allfacts
     * @param  boolean  $notes
     * @return JobQueue $job
     */
    public function queue_csv_export($usr, $extra=array()) {
        $cmd = sprintf("PERL AIR2_ROOT/bin/csv-export.pl --user_id=%d --bin_id=%d --format=email",
            $usr->user_id,
            $this->bin_id
        );
        foreach ($extra as $param => $bool) {
            if (is_int($param) && is_string($bool)) {
                $cmd .= " --$bool";
            }
            else {
                $val = ($bool) ? '1' : '0';
                $cmd .= " --$param=$val";
            }
        }

        // check for email address
        if ($usr->UserEmailAddress->count() == 0) {
            throw new Exception('User must have an email to export a CSV');
        }
        $job = new JobQueue();
        $job->jq_job = $cmd;
        $job->save();
        return $job;
    }


    /**
     * Schedule a job_queue to export any submissions in this bin to an excel
     * spreadsheet, and email it to the user.
     *
     * @param  User     $usr
     * @return JobQueue $job
     */
    public function queue_xls_export($usr) {
        $cmd = sprintf("PERL AIR2_ROOT/bin/xls-export.pl --user_id=%d --bin_id=%d --format=email --logging",
            $usr->user_id,
            $this->bin_id
        );

        foreach ($extra as $param => $bool) {
            if (is_int($param) && is_string($bool)) {
                $cmd .= " --$bool";
            }
            else {
                $val = ($bool) ? '1' : '0';
                $cmd .= " --$param=$val";
            }
        }

        // check for email address
        if ($usr->UserEmailAddress->count() == 0) {
            throw new Exception('User must have an email to export');
        }
        $job = new JobQueue();
        $job->jq_job = $cmd;
        $job->save();
        return $job;
    }


}
