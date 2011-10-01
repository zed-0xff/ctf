<?
require_once('includes/header.inc.php');
require_once('includes/user.inc.php');
require_once('includes/cats.inc.php');

if (!isset($cid) || empty($cid)) {
	echo 'choose a category to be shown:<br/>'."\n";

	$list = cat_list();

   foreach ($list as $l) {
      echo $l['cid'].': <a href="'.$_SERVER['PHP_SELF'].'?cid='.$l['cid'].'">'.$l['title'].'</a><br />'."\n";
   }
	if (!empty($list)) {
      
	}

} else if (isset($post) && $post==1) {
   if (!is_numeric($cid)) {
		echo 't00 l3m@ y0u b@d h@x0r (-;<br />';
		die();
	}

   echo 'Post a message in this category: <br />'."\n";
   form_dump(array(
      'title' => array('text','','*'), 
      'text' => array('text','','*'), 
      'cid' => array('hidden',$cid,'*'), 
      'add' => array('submit','post now')
   ));

   echo '<br /><br /><a href="'.substr($_SERVER['PHP_SELF'], 0, strpos($_SERVER['PHP_SELF'], '?')).'?cid='.$cid.'">Show all posts</a><br />'."\n";

} else {
	$q = "SELECT pid,title FROM posts WHERE cid='".$cid."'";
	$res = db_fetch_array(db_query($q), SQLITE_ASSOC);

   if (empty($res)) {
      echo 'no entries in this category...';
   } else {
      var_dump($res);
   }

   echo '<br /><br /><a href="'.substr($_SERVER['PHP_SELF'], 0, strpos($_SERVER['PHP_SELF'], '?')).'?post=1&cid='.$cid.'">Post in this category</a><br />'."\n";
}


require_once('includes/footer.inc.php');
?>
