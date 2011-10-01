<?


function msg_write($user, $_POST=array()) {

	if (isset($_POST['submit']) && !empty($_POST['submit'])
	    && isset($_POST['msgsend']) && !empty($_POST['msgsend'])) {
		msg_write2db($_POST['user'], $_POST['message'], '');
	} else {
	form_dump(array('user'=>array('text',"$user"), 
			'message'=>array('textarea',''), 
			'msgsend'=>array('hidden','msgsend'), 
			'submit'=>array('submit', 'Send message'),
			'testfile'=>array('password', 'testpass'))
		);
	}
}

function msg_write2db ($user,$msg, $files_array) {
	echo "msg_write2db ($user,$msg, $files_array)";
	
}

function msg_print($id, $user, $msg) {
	echo '<div>From:  </div><br />';
	echo '<div>Message: </div><br />';
}

function msg_($id) {
	$l = db_query("SELECT * FROM messages WHERE mid='".$id."'");
	$res = db_fetch_array($l);

}

function msg_list() {
	$l = db_query($q);
	$res = db_fetch_array($l);

	echo '<table>'."\n";
	foreach ($res as $k=>$v){
		echo '<tr> <td>'.htmlentities($k).'</td> <td>'.htmlentities($v).'</td> </tr>'."\n";
	}
	echo '</table>'."\n";
}

function msg_attach_file($msgid, $file) {
}


/*
 *
 * $array = array('name0' => array('type0','value0') 'name1' => array('type1','value1'))
 */
function form_dump($array=array('text','',''),$opts='') {
	echo '<table class="forms">';
	echo '<form method="post" action="'.$_SERVER['PHP_SELF'].'" '.$opts.'>'."\n";
	foreach ($array as $k=>$v) {
		echo '<tr>'."\n";
		list($type, $value, $star) = $v;
		switch ($type) {
			case 'text':
			case 'password':
				echo "\t".'<td id="first">'.htmlentities(ucfirst($k));
				if (!empty($star)) {
					echo "($star)";
				}
					
				echo ':</td>'."\n";
				echo "\t".'<td><input type="'.htmlentities($type).'" name="'.htmlentities($k).'" value="'.htmlentities($value).'" /></td>'."\n";
				break;
			case 'hidden':
			case 'submit':
				echo "\t".'<td>&nbsp;</td>'."\n";
				echo "\t".'<td><input type="'.htmlentities($type).'" name="'.htmlentities($k).'" value="'.htmlentities($value).'" /></td>'."\n";
				break;
			case 'textarea':
				echo "\t".'<td id="first">'.htmlentities(ucfirst($k)).':</td>'."\n";
				echo "\t".'<td><textarea name="'.htmlentities($k).'" value="'.htmlentities($value).'"></textarea></td>'."\n";
				break;
			case 'select':
         case 'mselect':
				echo "\t".'<td id="first">'.htmlentities(ucfirst($k)).':</td>'."\n";
            echo "\t".'<td>';
            $ores = db_query($value);
            if (!$ores) {
               die('error:'.$ores);
            }
            $tmp = db_fetch_array($ores);
            if (count($tmp[0]) > 2) {
               foreach ($tmp as $t) {
                  $keys = array_keys($t);
                  foreach ($keys as $k) {
                     if (is_numeric($k)) {
                        unset($t[$k]);
                     }
                  }
                  echo '<table border=1><tr>';
                  foreach (array_keys($t) as $keys) {
                     echo '<td>'.$keys.'</td>';
                  }
                  echo '</tr><tr>';
                  foreach ($t as $ak => $a) {
                     echo '<td>'.$a.'</td>';
                     if (preg_match('/[a-z]+id/',$ak)) {
                        $tmp_id = $ak.'_'.$a;
                     }
                  }
                  echo '<td><input class="custom" type="submit" value="delete" name="'.$tmp_id.'"></td>';
                  echo '</tr></table>';
               }
            } else {
               echo '<select '; 
               if ($type == 'mselect') {
                  echo 'multiple ';
                  if (count($tmp) > 1) {
                     echo 'size="5" ';
                  } else {
                     echo 'size="1" ';
                  }
               }
               echo 'name="'.$k.'">';
               if (count($tmp) < 1) {
                  echo '<option value=""></option>'."\n";
               }
               foreach ($tmp as $t) {
                  echo '<option value="'.htmlentities(current($t)).'">'.htmlentities(current($t)).'</option>'."\n";
               }
               echo '</select>';
            }
            echo '</td>'."\n";
				break;
			case 'file':
				echo "\t".'<td id="first">'.htmlentities(ucfirst($k)).':</td>'."\n";
				echo "\t".'<td><input type="'.htmlentities($type).'" name="'.htmlentities($k).'" value="'.htmlentities($value).'" size="34" /></td>'."\n";
			default:
				break;
		}
		echo '</tr>'."\n";
	}
	echo '</form>'."\n";
	echo '</table>'."\n";
}

?>
