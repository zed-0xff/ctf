<?
$url = $_SERVER['REQUEST_URI'];
$turl = basename(substr($url, strrpos($url, '/')));
$num = strpos($turl, '?');
if ($num > 0) {
   $pname = substr($turl, 0, $num);
} else {
   $pname = $turl;
}
var_dump($pname);

$res = @db_fetch_array(@db_query("SELECT name FROM admin WHERE name='".$pname."'"), SQLITE_NUM);
if (count($res) > 0) {
   foreach ($res['0'] as $r) {
      echo implode(';', $r)."<br />\n";
   }
}
?>
