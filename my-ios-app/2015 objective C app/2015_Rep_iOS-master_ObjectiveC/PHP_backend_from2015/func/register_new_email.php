<?php 

  if (is($V[2])){
  	
    $sql = "SELECT `new_email`, `user_id` FROM `email_updaters` WHERE `hash` = '".mv($V[2])."'";
    $res = mysql_query($sql) or die(mysql_error());
    @$new_email=mysql_result($res,0,0);
    @$user_id=mysql_result($res,0,1);
    
    if ($new_email != "" && $user_id != ""){
    	
      $sql = "SELECT `id` FROM `users` WHERE `email`='".mv($new_email)."'";
      $res = mysql_query($sql) or die(mysql_error());
      @$theid=mysql_result($res,0,0);
      if (mysql_num_rows($res) == 0 || $theid == $user_id){
            	
        $sql = "UPDATE `users` SET `email` = '".mv($new_email)."', `confirmed` = 1 WHERE `id` = ".$user_id." LIMIT 1 ;";
        $res = mysql_query($sql) or die(mysql_error());

        $sql = "DELETE FROM `email_updaters` WHERE `user_id`='".$user_id."'";
        $res = mysql_query($sql) or die(mysql_error());
    	
        if ($_SESSION['user']->id != ""){
          $_SESSION['user']->email = $new_email;
         }
  	    $_SESSION['login_note_color'] = 'green';
  	    $_SESSION['login_note_txt'] = 'successfully verified';
  	    
      }else{
  	    $_SESSION['login_note_color'] = 'red';
  	    $_SESSION['login_note_txt'] = 'the e-mail address ('.$new_email.') is already registered';
      }

    }else{
  	    $_SESSION['login_note_color'] = 'red';
  	    $_SESSION['login_note_txt'] = 'Email confirmation error. Wrong code.';
    }
  	
  }
 
go($RootDomain.'/login');

?>