<?
require_once('includes/header.inc.php');
require_once('includes/posts.inc.php');

var_dump($_SESSION);

if (!isset($_POST)) {
	form_dump(array('user'=>array('text',"$user"), 
			'title'=>array('text','','*'),
			'message'=>array('textarea',''), 
			'submit'=>array('submit', 'Save post')
	));
} else {

}

require_once('includes/footer.inc.php');
?>
