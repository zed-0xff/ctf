<?
chdir('../');
require_once('includes/header.inc.php');

if (!$isadmin) {
   die('no admin rights buddy:)');
}

form_dump(array(
	'query' => array('text','','*'), 
	'execute' => array('submit','execute')
));

require_once('includes/footer.inc.php');

?>
