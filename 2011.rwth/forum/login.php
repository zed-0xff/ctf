<?
require_once('includes/header.inc.php');
require_once('includes/user.inc.php');


if (!isset($_POST) || empty($_POST)) {
	echo 'login please:<br/>'."\n";
	form_dump(array(
		'username' => array('text','',''), 
		'password' => array('password','',''), 
		'login' => array('submit','login')
	));
} else {
	if (isset($_POST['username']) && !empty($_POST['username']) &&
         isset($_POST['password']) && !empty($_POST['password']) &&
         pass_check($_POST['username'], $_POST['password'])) {
	  	$_SESSION['user'] = $_POST['username'];
      $_SESSION['islogged'] = 1;
		header('location: http://'.$_SERVER['HTTP_HOST'].'/forum/overview.php');
		die();
	} else {
		echo 'incorrect login data, please try again<br />'."\n";
form_dump(array(
	'username' => array('text',$_POST['username'],''), 
	'password' => array('password',$_POST['password'],''), 
	'login' => array('submit','login')
));
		die();
	} 

}

require_once('includes/footer.inc.php');

?>
