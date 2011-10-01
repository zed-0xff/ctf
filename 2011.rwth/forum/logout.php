<?
require_once('includes/header.inc.php');

$_SESSION = array();
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    var_dump($params);
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

session_destroy();

header('Location: '.preg_replace('/logout/', 'index',$_SERVER['PHP_SELF']));

require_once('includes/footer.inc.php');
?>
