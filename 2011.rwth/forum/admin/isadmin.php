<?

require_once('includes/admin.inc.php');
require_once('includes/vars.inc.php');

function is_admin_group($user) {
   $res = db_fetch_array($db_query("SELECT uid FROM users WHERE user='".sqlite_escape_string($user)."'"));
   $q = "SELECT COUNT(*) FROM groups WHERE (belongsto='".$res['0'].",%' OR belongsto='%,".$res['0'].",%' OR belongsto='%,".$res['0']."') AND group='admin'";

   $chk_admin = db_fetch_array(db_query($q));
   if ($chk_admin && $chk_admin['0'] == 1) {
      return true;
   } else {
      return false;
   }
}


if ((empty($_SESSION) || !isset($_SESSION['loggedin']) || $_SESSION['user'] != 'admin' || !in_admin_group($_SESSION['user'])) && $isadmin) {
   echo 'You have to login first buddy or you don\'t have admin rights:)';
   header('Location: '.$_SERVER['HTTP_HOST'].'/forum/login.php');
   sleep(2);
}
?>
