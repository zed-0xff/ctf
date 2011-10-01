<div id='mainnav'>
	<div id='sub'><a id='l' href="/forum/">home</a></div>
	<div id='sub'><a id='l' href="/forum/news.php">news</a></div>
	<div id='sub'><a id='l' href="/forum/categories.php">categories</a></div>
	<div id='sub'><a id='l' href="/forum/uploads.php">uploads</a></div>
	<div id='sub'><a id='l' href="/forum/search.php">search</a></div>
<?
if ($_SESSION['islogged']) {
?>
	<div id='sub'><a id='l' href="/forum/overview.php">overview</a></div>
	<div id='sub'><a id='l' href="/forum/mailbox.php">mailbox</a></div>
<?
}
?>
	<div id='null'></div>
<?
if (!$_SESSION['islogged']) {
?>
	<div id='sub'><a id='r' href="/forum/login.php">login</a></div>
	<div id='sub'><a id='r' href="/forum/register.php">register</a></div>
<?
} else {
?>
   <div id='sub'><a id='r' href="/forum/logout.php">logout</a></div>
<?
}
?>
	<div id='clear' />
</div>
<br />
<br />
