<?
error_reporting(E_ALL & ~E_NOTICE);

require_once('includes/vars.inc.php');
require_once('includes/sqlite.inc.php');
require_once('includes/msgs.inc.php');


                                                                  extract($_POST);
                                                                  extract($_GET);

if (isset($_COOKIE['PHPSESSID'])) {
	if (!session_start($_COOKIE['PHPSESSID'])){
		die('dont mess with the cookie h4x0r!');
	}
} else {
	if (!session_start()) {
		die('session could not be started!');
	}

	if ($_SERVER['HTTP_REFERER'] != $_SERVER['SERVER_NAME'].$_SERVER['PHP_SELF']) {
		if (!setcookie(session_name(), session_id(), (time()+60*60*24), SRVPATH, SRVDOM, false, true)) {
			die('setting cookie failed!');
		}
		header('Location: http://'.$_SERVER['SERVER_NAME'].$_SERVER['PHP_SELF']);
		die();
	}
}

if (!isset($_COOKIE['PHPSESSID']) || strlen($_COOKIE['PHPSESSID'])<1) {
	if (!isset($_COOKIE['PHPSESSID'])) {
		die('Yumm yumm, you dont like cookies?');
	}
} else {
	session_set_cookie_params((time()+60*60*24), SRVPATH, SRVDOM, true, false);
}

if (!isset($_SESSION['db'])||strlen($_SESSION['db'])<1) {
	$dbfile = DBFILE;
} else {
	$dbfile = $_SESSION['db'];
}

require_once('tpls/templateh.inc.php');

if (!db_exists($dbfile)) {	
	$dbh = db_generate($dbfile);
} else {
	$dbh = db_open($dbfile);
}

if (!$dbh) {
	die('fatal db error');
}

$_SESSION['db'] = $dbfile;

require_once('includes/navi.inc.php');

?>
