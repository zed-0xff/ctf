<?
require_once('includes/header.inc.php');
require_once('includes/user.inc.php');

$q = "SELECT * FROM files WHERE up_user_id='".get_login_id()."'";
$res = db_fetch_array(db_query($q), SQLITE_ASSOC);

$keys = array_keys($res['0']);
echo '<table border=1 width=850><tr>';
foreach ($keys as $k) {
   echo "\t".'<td>'.$k.'</td>'."\n";
}
echo '</tr>'."\n";
foreach ($res as $r) {
   echo '<tr>'."\n";
   foreach ($r as $k=>$rt) {
      echo "\t".'<td>';
      if ($k == 'file') {
         echo '<a href="uploads/'.$rt.'">';
      }
      echo $rt;
      if ($k == 'file') {
         echo '</a>';
      }
      echo '</td>'."\n";
   }
   echo '</tr>'."\n";
}
echo '</table>';
echo '<br /><br />'."\n";

echo '<a href="'.$_SERVER['HTTP_REFERER'].'">Back</a>' ;
require_once('includes/footer.inc.php');
?>
