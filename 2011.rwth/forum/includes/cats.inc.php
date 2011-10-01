<?

function cat_add($title, $gids) {
	$q = "INSERT INTO categories (NULL,'".sqlite_escape_string($title)."','".sqlite_escape_string($gids)."')";
	if (db_query($q)) {
		return TRUE;
	} else {
		return FALSE;
	}
}

function cat_del($name) {
	$q = "DELETE FROM cats WHERE title='".sqlite_escape_string($name)."'";
   return db_query($q);
}

function cat_exists($name) {
   $q = "SELECT COUNT(*) FROM cats WHERE title='".sqlite_escape_string($name)."'";

   $res = db_fetch_array(db_query($q));
	return $res;
}

function cat_list($gid=NULL) {
	$q = "SELECT cid, title FROM categories";
	if ($gid != NULL) {
	       	$q .= "WHERE gids LIKE '%".$gid."%'";
	}

	$res = db_fetch_array(db_query($q), SQLITE_ASSOC);

	if ($res) {
		return $res;
	} else { 
		return array();
	}
}

extract($_POST);
extract($_GET);

?>
