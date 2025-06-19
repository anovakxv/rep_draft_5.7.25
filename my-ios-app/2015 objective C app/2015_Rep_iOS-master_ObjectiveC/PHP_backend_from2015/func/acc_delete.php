<?php 

 if(empty($_SESSION['ALogged'])){
 	gate();
 }
 
 $admin_modifing = ($_SESSION['ALogged'] == "1" && !empty($V[2]) && empty($V[3]));

 if ($V[2] == md5($_SESSION['user']->password) || $admin_modifing){
   
  $user_id = ($admin_modifing)?$V[2]:$_SESSION['user']->id;
    
 	$sql = "DELETE FROM `email_updaters` WHERE `user_id` = '".$user_id."'";
    $res = mysql_query($sql) or die(mysql_error());
    
 	$sql = "DELETE FROM `followers` WHERE `user_id1` = '".$user_id."' OR `user_id2` = '".$user_id."'";
    $res = mysql_query($sql) or die(mysql_error());
    
 	$sql = "DELETE FROM `news` WHERE `user_id` = '".$user_id."'";
    $res = mysql_query($sql) or die(mysql_error());
    
 	$sql = "DELETE FROM `users` WHERE `id` = '".$user_id."'";
    $res = mysql_query($sql) or die(mysql_error());
    
 $sql = "SELECT `id` FROM `resume` WHERE `user_id` = '".$user_id."'";
 $res = mysql_query($sql) or die(mysql_error());
 if(mysql_numrows($res)){
  while($row=mysql_fetch_assoc($res)){
    delete_resume($row['id']);
   }
 }
    
 	deleteDir($RootDir."/upload/".$user_id);
 	
  	if(!$admin_modifing){
 	 unset($_SESSION['user']);
 	}
 	
  }
  
if(!$admin_modifing){
  home();
 }else{
 	go_back($RootDomain.'/admin/data/users/');
  }


function deleteDir($dirPath) {
    if (! is_dir($dirPath)) {
        //throw new InvalidArgumentException('$dirPath must be a directory');
        return;
    }
    if (substr($dirPath, strlen($dirPath) - 1, 1) != '/') {
        $dirPath .= '/';
    }
    $files = glob($dirPath . '*', GLOB_MARK);
    foreach ($files as $file) {
        if (is_dir($file)) {
            deleteDir($file);
        } else {
            unlink($file);
        }
    }
    rmdir($dirPath);
}

?>

