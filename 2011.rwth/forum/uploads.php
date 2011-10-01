<?

require_once('includes/header.inc.php');
require_once('includes/uploads.inc.php');

function form_file() {
	form_dump(array(
		'file'=>array('file','file'), 
		'submit'=>array('submit', 'Save post')
	), 'enctype="multipart/form-data"');
}


if (!isset($_POST['submit']) || empty($_POST['submit'])) {
	echo 'Please select the file to upload:<br />';
} else {
	if ($fname = file_save($_FILES['file'])) {
		echo 'file saved under <file><a href="/forum/uploads/'.$fname.'"></file>'.$fname."</a><br />\n<br />\n";
	} else {
		echo 'failed to save file';
	}
   echo '<br />'."\n";
}

form_file();

echo '<br /><br />'."\n";

require_once('includes/footer.inc.php');

?>
