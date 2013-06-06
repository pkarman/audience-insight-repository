<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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

/*
|--------------------------------------------------------------------------
| Email change request form
|--------------------------------------------------------------------------
*/
?>

<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Public Insight Network | Email Change Request</title>
<script src="<?php echo $static_url ?>/lib/shared/jquery-1.7.2.min.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="<?php echo $static_url ?>/css/login.css" />

<script type="text/javascript">
//<![CDATA[
function getFocus() {
  if (document.forms.length > 0) {
    document.forms[0].elements[0].focus();
    document.forms[0].elements[0].select();
  }
}

function validate() {
    var name = $('input[name="name"]');
    var before = $('input[name="before"]');
    var after = $('input[name="after"]');

    clear_errors(); // start fresh 
    if (!name.val().length) {
        add_error("You must provide a name");
        return false;
    }
    if (!before.val().length) {
        add_error("You must provide a before email");
        return false;
    }
    if (!before.val().match(/^.+\@.+\.\w+$/)) {
        add_error(before.val() + " does not look like an email addresss");
        return false;
    }
    if (!after.val().length) {
        add_error("You must provide a after email");
        return false;
    }
    if (!after.val().match(/^.+\@.+\.\w+$/)) {
        add_error(after.val() + " does not look like an email addresss");
        return false;
    }
    
    $('#submitbtn').val('Submitting...');
    $('#submitbtn').attr('disabled', 'disabled');
    return true;
}

function add_error(err) {
    var errRow = $('#error');
    if (!errRow || !errRow.length) {
        $('#change-request > tbody:last').prepend('<tr id="error"><td colspan="2"><div class="error"></div></td></tr>');
        errRow = $('#error');
    }
    errRow.find('div').append(err); 
}

function clear_errors() {
    $('#error').remove();
}

//]]>
</script>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>

<body onload="getFocus()">

<header>
    <div class="wrap">
        <a href="http://publicinsightnetwork.org"><img src="<?php echo $static_url ?>/css/img/pin-logo-white.png" /></a>
    </div>
</header>

<div class="wrap panel" id="change">
    <h2>Update your email address</h2>
  
    <?php if ($method == 'GET') :?>
	<form method="POST" onsubmit="return validate()" >
        <table id="change-request">            
            <?php if (isset($error)) { ?>
            <tr id="error"><td colspan="2"><div class="error"><?php echo $error ?></div></td></tr>
            <?php } ?>
            
            <tr>
                <td style="text-align: right; padding-right: 5px;">Name</td>
                <td><input name="name" value="" style="width: 200px;" /></td>
            </tr>
            <tr>
                <td style="text-align: right; padding-right: 5px;">Old email</td>
                <td><input name="before" value="" style="width: 200px;" /></td>
            </tr>
            <tr>
                <td style="text-align: right; padding-right: 5px;">New email</td>
                <td><input name="after" value="" style="width: 200px;" /></td>
            </tr>
            <tr>
                <td></td>
                <td style="text-align: left;">
                    <input id="submitbtn" type="submit" name="submit" value="Submit" />
                </td>
            </tr>            
        </table>
    </form>
    <?php else : ?>
    
	<table border="0" style="width: 100%;">
        <tr>
            <td colspan="2" style="text-align: center;">
                <strong>Thank you for your request.<br />
                We'll get to work on it right away.</strong>
            </td>
        </tr>
    </table>
    <?php endif; ?>
</div>

<div class="wrap" id="copyright">
    &copy; 2013 <a href="http://americanpublicmedia.org/">American Public Media Group</a>
</div>

</body>
</html>
