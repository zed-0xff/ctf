<?

global $db;

function news_fetch_all($url) {
	$newscont = file_get_contents($url);
	$parted = explode('===', $newscont);
	$ts_news = array();
	foreach ($parted as $p) {
		$ts_news[] = explode('@@@', $p);
	}

	return $ts_news;
}

function news_check_last_id() {
	$q = "SELECT nid FROM news ORDER BY nid DESC LIMIT 1";
	$res = db_fetch_array(db_query($q), SQLITE_NUM);

	if ($res) {
		return $res['0']['0'];
	} else {
		die('db error occured - table news is possibly empty');
	}	
}

function news_get_last_five() {
	$q = "SELECT * FROM news ORDER BY ts DESC LIMIT 5";
	$res = db_fetch_array(db_query($q), SQLITE_ASSOC);

	if ($res) {
		return $res;
	} else {
		die('db error occured - table news is possibly empty');
	}	
}


function news_get_all() {
	$q = 'SELECT * FROM news ORDER BY ts DESC';
	$res = db_fetch_array(db_query($q), SQLITE_ASSOC);

	if ($res) {
		return $res;
	} else {
		die('could not select * from news');
	}
}


function news_add_one($arr) {
	if (!is_numeric($arr['0'])) {
		return FALSE;
	}

   $res = db_fetch_array(db_query("SELECT COUNT(*) FROM news WHERE ts='".$arr['0']."' AND content='".sqlite_escape_string($arr['1'])."'"), SQLITE_NUMROW);

   if ($res['0']['0'] != 0) {
      return FALSE;
   } 

	$q = "INSERT INTO news VALUES (NULL,'".sqlite_escape_string($arr['0'])."', '".sqlite_escape_string($arr['1'])."')";
	$res = db_query($q);
	if ($res) {
		return TRUE;
	} else {
		return FALSE;
	}
}

?>
