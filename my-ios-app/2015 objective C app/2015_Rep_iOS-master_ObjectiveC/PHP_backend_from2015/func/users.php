<?php 
  gate();
  
   $type = $V[2];
   $user_id2 = $V[3];
   $todo = $V[4];
   
   if($type != "blocks" && $type != "followers"){
   	 go_back($RootDomain.'/profile/'.$user_id2);
   }
  
   $sql = "SELECT COUNT(*) FROM `users_".$type."` WHERE `user_id1` = '".$_SESSION['user']->id."' AND `user_id2`='".mv($user_id2)."'";
   $res = mysql_query($sql) or die(mysql_error());
   $liked = mysql_result($res, 0, 0);
  
   $sql = "DELETE FROM `users_".$type."` WHERE `user_id1`='".$_SESSION['user']->id."' AND `user_id2`='".mv($user_id2)."'";
   $res = mysql_query($sql) or die(mysql_error());
  
   if ($todo == '1'){
     $sql = "INSERT INTO `users_".$type."` (`user_id1` , `user_id2`, `date`) VALUES ('".$_SESSION['user']->id."', '".mv($user_id2)."', NOW());";
     $res = mysql_query($sql) or die(mysql_error());
    }
  
  	
go_back($RootDomain.'/profile/'.$user_id2);

?>