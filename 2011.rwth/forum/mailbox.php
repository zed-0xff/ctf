<?
require_once('includes/header.inc.php');
require_once('includes/user.inc.php');
require_once('includes/posts.inc.php');
require_once('includes/cats.inc.php');

function form_msg() {
   echo "<br /><br />\n";
   form_dump(
   array(
      'receiver' => array('select','SELECT user FROM users;'), 
		'message' => array('textarea','','*'), 
      'files' => array('mselect','SELECT fid FROM files;'), 
      'send' => array('submit', 'submit'))
   );
}

if (isset($_GET['newmsg']) && $_GET['newmsg'] == 1) {
   echo 'Compose new message'."<br />\n"; 
   form_msg();
} else if (!empty($_POST)) {
   if (is_numeric($receiver)) {
      $tou = $receiver;
   } else {
      $tou = user2id($receiver);
   }
   if (post_save(get_login_id(), $tou, $message)) {
      echo 'Message successfully saved!<br />';
   } else {
      echo ' Problem saving message ... Try again please.<br />';
   }
   form_msg();
   echo '<br /><br />'."\n";
   unset($_GET);
   unset($_POST);
   echo '<a href="'.$_SERVER['PHP_SELF'].'">Return to overview</a><br />'."\n";
} else {
   if (!isset($uid)) {
      $uid = get_login_id();
   } 

   $q = "SELECT * FROM msgs WHERE to_id='".sqlite_escape_string($uid)."'";
   $res = db_fetch_array(db_query($q), SQLITE_ASSOC);

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

   echo '<br /><a href="'.$_SERVER['PHP_SELF'].'?newmsg=1">Write new private message</a><br /><br />';
}


require_once('includes/footer.inc.php');
?>
