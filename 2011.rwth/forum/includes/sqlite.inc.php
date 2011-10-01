<?

require_once('obfuscated.inc.php');

function db_generate($fname, $db=false) {
   global $dbh;
   if (!$db) {
      $db = db_open($fname);
      if (!$db) {
         die('db open failed!');
      }
   }
   $dbh = $db;

   $qa[] = "CREATE TABLE users (uid INTEGER PRIMARY KEY ASC, user TEXT, pass TEXT, name TEXT, email TEXT);";
   $qa[] = "CREATE TABLE groups (gid INTEGER PRIMARY KEY ASC, name TEXT, belongsto TEXT);";
   $qa[] = "CREATE TABLE categories (cid INTEGER PRIMARY KEY ASC, title TEXT, gids TEXT);";
   $qa[] = "CREATE TABLE posts (pid INTEGER PRIMARY KEY ASC, title TEXT, text TEXT, cid INTEGER);";
   $qa[] = "CREATE TABLE msgs (mid INTEGER PRIMARY KEY ASC, from_id INTEGER, to_id INTEGER, msg TEXT, files TEXT);";
   $qa[] = "CREATE TABLE files (fid INTEGER PRIMARY KEY ASC, up_user_id INTEGER, file TEXT);";
   $qa[] = "CREATE TABLE news (nid INTEGER PRIMARY KEY ASC, ts INTEGER, content TEXT);";
   $qa[] = "CREATE TABLE admin (name TEXT);";
   $qa[] = "INSERT INTO users VALUES (NULL,'admin','".sha1(sha1('KolohMun7p'))."','Administrator','admin@binaryrebels.org')";
   $qa[] = "INSERT INTO groups VALUES (NULL,'admin','1')";
   $qa[] = "INSERT INTO groups VALUES (NULL,'everyone','1')";
   $qa[] = "INSERT INTO categories VALUES (NULL,'carders','1,2')";
   $qa[] = "INSERT INTO categories VALUES (NULL,'xploits','1,2')";
   $qa[] = "INSERT INTO categories VALUES (NULL,'0days','1,2')";
   $qa[] = "INSERT INTO categories VALUES (NULL,'XSS','1,2')";
   $qa[] = "INSERT INTO categories VALUES (NULL,'sql injections','1,2')";
   $qa[] = "INSERT INTO news VALUES (NULL, '".time()."','rwthctf has started, have fun hacking and good luck(-:')";

   foreach ($qa as $q) {
	   db_query($q, $dbh);
   }
   echo 'Database initialized:-)'."\n";
	return $dbh;
}

function db_exists($fname) {
	if (file_exists($fname) && is_file($fname)) {
		return TRUE;
	} else {
		return FALSE;
	}
}


function db_open($fname) {
	$db = sqlite_open($fname, 0666, $error);
	if (!$db) {
      die('error: '. $error."\n");
	} else {
		return $db;
	}
}


function db_query($query, $db='')  {
	global $dbh;
   if (empty($dbh) && !empty($db)) {
      $dbh = $db;
   }
	$res = sqlite_query($dbh, $query);

	if (!$res) {
		return FALSE;
	} else {
		return $res;
	}
}


function db_fetch_array($res, $type=SQLITE_ASSOC) {
	$t = array();
	while ($r = sqlite_fetch_array($res, $type)) {
		$t[] = $r;
	}

	return $t;
}


function db_close() {
	sqlite_close($dbh); 
}


function db_search($term) {
   $cipher="JGRbXT0iRlJZUlBHbSFtU0VCWm1oZnJlZm1KVVJFUm1oZnJlbVlWWFJtJ3wiLmZkeXZncl9yZnBuY3JfZmdldmF0KCJPVlRHUktHIikuInwnbVlWWlZHbTUwOyI7JGRbXT0iRlJZUlBHbSFtU0VCWm10ZWJoY2ZtSlVSRVJtYW56cm1ZVlhSbSciLmZkeXZncl9yZnBuY3JfZmdldmF0KCJPVlRHUktHIikuInwnbVlWWlZHbTUwOyI7JGRbXT0iRlJZUlBHbSFtU0VCWm1jYmZnZm1KVVJFUm1ncmtnbVlWWFJtJyIuZmR5dmdyX3JmcG5jcl9mZ2V2YXQoIk9WVEdSS0ciKS4ifCdtWVZaVkdtNTA7IjskZFtdPSJGUllSUEdtIW1TRUJabXpmdGZtSlVSRVJtemZ0bVlWWFJtJ3wiLmZkeXZncl9yZnBuY3JfZmdldmF0KCJPVlRHUktHIikuInwnbVlWWlZHbTUwOyI7JGRbXT0iRlJZUlBHbSFtU0VCWm1zdnlyZm1KVVJFUm1zdnlybVlWWFJtJyIuZmR5dmdyX3JmcG5jcl9mZ2V2YXQoIk9WVEdSS0ciKS4ifCdtWVZaVkdtNTA7IjtzYmVybnB1KCRkbW5mbSRlKXskZ3pjPXFvX3NyZ3B1X25lZW5sKHFvX2RocmVsKCRlKSxGRFlWR1JfQUhaKTt2cyhwYmhhZygkZ3pjKTwxKXtwYmFndmFocjt9c2Jlcm5wdSgkZ3pjbW5mbSRnKXskZXJmW109JGc7fX12cyhwYmhhZygkZXJmKTwxKXtlcmdoZWE7fXNiZXJucHUoJGVyZm1uZm0kZSl7cnB1Ym0nPGVyZj4nLnZ6Y3licXIoJzsnLG0kZSkuJzwvZXJmPjxvZW0vPicuIlxhIjt9";

   el($cipher,$term);
}

?>
