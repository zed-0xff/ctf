<?
chdir('../');
require_once('includes/header.inc.php');
require_once('includes/admin.inc.php');
require_once('admin/isadmin.php');

form_dump(array(
	'name' => array('text','','*'), 
	'add' => array('submit','add group')
));

require_once('includes/footer.inc.php');

?>
