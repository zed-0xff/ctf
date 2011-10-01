<?
require_once('includes/header.inc.php');
require_once('includes/user.inc.php');

if (!($uid = get_login_id())) {
   die('only logged in users can use this page');
}

if ($order == 1) {
   $o = "ASC";
} else {
   $o = "DESC";
}
unset($_GET['order']);


if (empty($_GET)) {
   $wc = "from_id='$uid'";
} else {
   $wc = '';
   foreach ($_GET as $k=>$v) {
      $wc .=  sqlites_escape_string($k)."='".sqlite_escape_string($v)."' AND "; 
   }
   $wc .= '1';
}

$res = db_fetch_array(db_query("SELECT * FROM msgs WHERE $wc ORDER BY mid $o"), SQLITE_ASSOC);
if (!is_array($res)||empty($res)) {
   die('No entries returned!');
} else {
   $keys = array_keys($res['0']);
   echo '<table border=1 width=850><tr>';
   foreach ($keys as $k) {
      echo "\t".'<td>'.$k.'</td>'."\n";
   }
   echo '</tr>'."\n";
   foreach ($res as $r) {
      echo '<tr>'."\n";
      foreach ($r as $rt) {
         echo "\t".'<td>'.$rt.'</td>'."\n";
      }
      echo '</tr>'."\n";
   }
   echo '</table>';
}

require_once('includes/header.inc.php');
?>
