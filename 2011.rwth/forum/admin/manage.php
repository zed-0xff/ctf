<?
chdir('../');
require_once('includes/header.inc.php');
require_once('includes/admin.inc.php');
require_once('admin/isadmin.php');

if (!empty($_POST)) {
   form_dump(array(
      'Edit' => array('select','SELECT * FROM '.sqlite_escape_string($_POST['edit']).';'), 
      'table' => array('hidden', $_POST['table']),
      'change' => array('submit','manage selected')
   ));
} else {
   form_dump(array(
      'edit' => array('select','SELECT name FROM sqlite_master WHERE type="table";'), 
      'change' => array('submit','manage selected')
   ));
}

require_once('includes/footer.inc.php');

?>
