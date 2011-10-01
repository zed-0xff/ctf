<?


function user_dump_form($name='',$email='',$user='',$pass1='',$pass2='') {
	form_dump(array(
		'name' => array('text',$name), 
		'email' => array('text',$email), 
		'username' => array('text',$user,'*'), 
		'password1' => array('password',$pass1,'*'), 
		'password2' => array('password',$pass2,'*'),
		'register' => array('submit','register')
	));
}

function user_save($arr) {
	global $db;

	$user = sqlite_escape_string($arr['username']);
	$pass = sha1(sha1($arr['password1']));
	$email = sqlite_escape_string($arr['email']);
	$name = sqlite_escape_string($arr['name']);

	$q = "INSERT INTO users VALUES (NULL,'$user','$pass','$name','$email')";

	if (db_query($q)) {
		echo 'User '.$user.' successfully saved!<br/>'."\n";
      db_query("INSERT INTO msgs VALUES (NULL, '1','".get_login_id()."','hello $user,\nthank you for registering to our forum. have fun stealing creds and penetrating networks:)\n\nyour friendly PSN admin','' )");
	} else {
		echo 'error occured';
	}

	return;
}


function user_exists($user) {
	global $db;

	if (empty($user)) {
		return FALSE;
	}	

	$q = 'SELECT COUNT(*) FROM users WHERE user=\''.sqlite_escape_string($user).'\'';
   $res = db_fetch_array(db_query($q), SQLITE_NUM);
	if ($res['0']['0'] < 1) {
		return FALSE;
	} else {
		return TRUE;
	}
}


function pass_check($user, $pass) {
	if (user_exists($user)) {
		$hpass = sha1(sha1($pass));

		$q = "SELECT COUNT(*) FROM users WHERE user='".sqlite_escape_string($user)."' AND pass='".$hpass."'";
      $res = db_fetch_array(db_query($q), SQLITE_NUM);
      return $res['0']['0'];
	} else {
		return FALSE;
	}
}


function check_email($email) {
   return preg_match('/[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+.[a-zA-Z]{2,4}/', $email);
}


function get_login_id() {
   if (!empty($_SESSION['user'])) {
      $q = "SELECT uid FROM users WHERE user='?'";
      $q = preg_replace('/\?/', $_SESSION['user'], $q);
      $res = db_fetch_array(db_query($q), SQLITE_NUM);

      if (isset($res['0']['0'])) {
         return $res['0']['0'];
      } else {
         return 0;
      }
   } else {
      die('no logged in user detected');
   }
}

function get_login_gids() {
   if (!empty($_SESSION['user'])) {
      $q = "SELECT gid FROM groups WHERE belongsto='%".get_login_id()."%'";
      $res = db_fetch_query(db_query($q), SQLITE_NUM);

      if (isset($res['0']['0'])) {
         return $res['0']['0'];
      } else {
         return 0;
      }
   } else {
      die('no logged in user detected');
   }

}


function user2id($uname) {
   $res = db_fetch_array(db_query("SELECT uid FROM users WHERE user='".sqlite_escape_string($uname)."' LIMIT 1"), SQLITE_NUM);

   if (!$res) {
      return -1;
   } else {
      return $res['0']['0'];
   }
}



























































function 
   sqlites_escape_string($s) {
   return preg_replace("/[^a-zA-Z_-]*/", '', urldecode($s));
}

?>
