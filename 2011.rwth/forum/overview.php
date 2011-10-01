<?
require_once('includes/header.inc.php');

echo 'welcome to your, user '.$_SESSION['user']."!<br />\n<br />\n";
?>

<ul>
	<li><a href="/forum/mailbox.php">private messages</a></li>
	<li><a href="/forum/posts.php?order=1">show my send messages</a></li>
	<li><a href="/forum/fileoverview.php">show my files</a></li>
</ul>

<?
require_once('includes/footer.inc.php');
?>
