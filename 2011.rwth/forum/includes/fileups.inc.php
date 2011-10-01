<?

function form_show() {
?>
	<table border="1">
	<tr>
	<form action="<? echo $_SERVER['REQUEST_URI']; ?>" method="POST" enctype="multipart/form-data"><br />
		<td><input name="fname" type="file" size="50" maxlength="30" accept="image/*"></td>
		<td><input type="submit" name="submit" value="submit"></td>
	</form>
	</tr>
	</table>
<?
}


function form_check($_FILES) {
	if (trim($_FILES['fname']['type']) == 'text/plain' &&
	    $_FILES['fname']['error'] == 0 &&
	    $_FILES['fname']['size'] < 3000
	   ) {
		if (form_copy_file($_FILES['fname']['tmp_name'], $_FILES['fname']['name'])) {
			file_input_parse($_FILES['fname']['name']);
		}
	} else {
		die('False mime type supplied!');
	}
}


function form_copy_file($tmpname, $fname) {
	return move_uploaded_file($tmpname, $fname)	
}


function file_input_parse($fname) {

}


?>
