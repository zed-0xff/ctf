<?php
require_once('includes/header.inc.php');
require_once('includes/user.inc.php');

if (!isset($_POST) OR empty($_POST)) {
	echo 'Please fill in the registration form:</br>'."\n";
	user_dump_form();
} else {
	if (count($_POST) != 6 || 
	    !array_key_exists('name', $_POST) ||
	    !array_key_exists('email', $_POST) ||
	    !array_key_exists('username', $_POST) ||
	    !array_key_exists('password1', $_POST) ||
	    !array_key_exists('password2', $_POST)) {
		die('changing the structure of the post-form is not allowed you script kiddie:-)');
	} 
		
	$checks = true;
	foreach ($_POST as $k=>$v) {
		if (empty($v)) {
			$checks = false;
			echo '<error>no empty args allowed!</error>';
		}
	}

	if (!check_email($_POST['email'])) {
		$checks = false;
		echo '<error>supplied email not in valid email address format!</error>';
	}

	if (strlen($_POST['password1']) < 4 || strcmp($_POST['password1'],$_POST['password2']) != 0) {
		$checks = false;
		echo '<error>min 4 chars and the same pass please, y0u l33t h@x0r!</error>';
	}

	foreach($_POST as $k=>$v) {
		if ($k != 'password1' || $k != 'password2') {
			$_POST[$k] = htmlentities(preg_replace('/[^0-9A-Za-z@._#$%&-]/','', $v));
		}
	}

	if (user_exists($_POST['username'])) {
      $checks = false;
		echo '<error>Username already exists, try with another one</error>';
	}

	if ($checks) {
		user_save($_POST);
		echo '<a href="http://'.$_SERVER['HTTP_HOST'].substr($_SERVER['REQUEST_URI'], 0, strrpos($_SERVER['REQUEST_URI'],'/')).'/login.php">go to login page</a><br/>';
	} else {
		user_dump_form($_POST['name'], $_POST['email'], $_POST['username'], $_POST['password1'], $_POST['password2']);

	}
}


require_once('includes/footer.inc.php');
?>
