<?
function post_check() {
   return;
}

function post_save($fromu, $tou, $msg, $files=array()) {
   if (db_query("INSERT INTO msgs VALUES (NULL,'".sqlite_escape_string($fromu)."','".sqlite_escape_string($tou)."','".sqlite_escape_string($msg)."','".sqlite_escape_string(implode(';',$files))."')")) {
      return TRUE;
   } else {
      return FALSE;
   }
}

?>
