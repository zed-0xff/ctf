<?
chdir('../');
require_once('includes/header.inc.php');
require_once('includes/admin.inc.php');
require_once('admin/isadmin.php');
require_once('includes/user.inc.php');

if (!empty($_POST)) {
   $accepted = true;

   if (!empty($_POST['username']) && !empty($_POST['password']) && !empty($_POST['email'])) {
         if (user_exists($_POST['username'])) {
            echo "Supplied username already exists<br />\n";
            $accepted = false;
         }

         if (!check_email($_POST['email'])) {
            echo "Email not in the right format [a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+.[a-zA-Z]{2,4}<br />\n";
            $accepted = false;
         }

         if (strlen($_POST['password'])<7) {
            echo "Password must be min 7 chars long!<br />\n";
            $accepted = false;
         }

         if ($accepted) {
            user_save(array('username'=>$_POST['username'], 'password1'=>$_POST['password'], 'email'=>$_POST['email'], 'name'=>$_POST['name']));
         }
         
   } else {
      echo "Username, password and email have to be supplied:-)<br />\n";
   }
} 

form_dump(array(
   'username' => array('text','','*'), 
   'password' => array('text','','*'), 
   'name' => array('text','',''), 
   'email' => array('text','','*'), 
   'add' => array('submit','add')
), 'name="adduser"');

require_once('includes/footer.inc.php');

?>
