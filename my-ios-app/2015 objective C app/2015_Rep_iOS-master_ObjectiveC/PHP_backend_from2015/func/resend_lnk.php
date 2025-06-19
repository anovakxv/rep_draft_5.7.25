<?php 

  $sql = "SELECT *  FROM `users` WHERE `id` = '".mv($V[2])."' AND `confirmed` = 0";
  $res = mysql_query($sql) or die(mysql_error());
  if (mysql_num_rows($res)){
  	$row = mysql_fetch_assoc($res);
  	if ($row['confirmed']){
  	 $_SESSION['login_note_color'] = 'green';
  	 $_SESSION['login_note_txt'] = 'This email is already verified';
  	}else{	
    $user = new User();
    $user->CreateUserObject("", $row);
    $user->SendActivationEmail();
  	}
  }else{
  	 $_SESSION['login_note_color'] = 'red';
  	 $_SESSION['login_note_txt'] = 'Error!';
  }
  
  
   go($RootDomain.'/login');
 
?>