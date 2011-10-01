<?
chdir('../');
require_once('includes/header.inc.php');
require_once('includes/admin.inc.php');
require_once('admin/isadmin.php');


if (!empty($_POST)) {
   
} else {
   form_dump(array(
      'title' => array('text','','*'), 
      'gids' => array('text','','*'), 
      'add' => array('submit','add category')
   ));
}

require_once('includes/footer.inc.php');
?>
