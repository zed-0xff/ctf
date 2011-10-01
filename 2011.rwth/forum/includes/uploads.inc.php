<?
require_once('sqlite.inc.php');
require_once('user.inc.php');

function file_save($filearr) {
	if ($filearr['error'] != 0) {
		echo 'error occured by upload';
		return FALSE;
	}

	$path = $_SERVER['DOCUMENT_ROOT'].'/forum/uploads/';

	if (file_exists($filearr['tmp_name']) && is_readable($filearr['tmp_name'])) {

		$newname = md5($filearr['tmp_name']);
		if (strrpos($filearr['name'], '.')) {
			$ext = substr($filearr['name'], strrpos($filearr['name'], '.'));
		} else {
			$ext = '';
		}
		
		while (file_exists($path.$newname)) {
			echo "filename $newname exists<br />\n";
			$newname = md5($newname);
		}
		
		$newname = substr($newname, 0, -5).'.'.substr($newname, -4);
		if (move_uploaded_file($filearr['tmp_name'], $path.$newname)) {
         db_query("INSERT INTO files VALUES(NULL,'".get_login_id()."','$newname')");
			return $newname;
		}
	} {
      echo "\n".$filearr['tmp_name']."\n";
	   return FALSE;
   }
}
?>
