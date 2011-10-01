<?

/*
 * fetch news from external server (rwthctf news distribution system)
 */

require_once('includes/header.inc.php');
require_once('includes/news.inc.php');


$news = news_fetch_all('http://localhost/newstest.txt');

$id = news_check_last_id();

$items = count($news);

while ($id < $items) {
	if (isset($news[$id])) {
		news_add_one($news[$id]);
	}
	++$id;
}

if (isset($_GET['all'])) {
	$dbnews = news_get_all();
} else {
	$dbnews = news_get_last_five();
}

echo '<table border=1 width=800>'."\n";
echo '<tr><td>time:</td><td>news:</td></tr>'."\n";
foreach ($dbnews as $d) {
   echo '<tr><td>';
   echo @date("d.m.Y H:i", $d['ts']);
   echo '</td><td>';
   echo $d['content'];
   echo '</td></tr>'."\n";
}
echo '</table>'."\n";

require_once('includes/footer.inc.php');
?>
