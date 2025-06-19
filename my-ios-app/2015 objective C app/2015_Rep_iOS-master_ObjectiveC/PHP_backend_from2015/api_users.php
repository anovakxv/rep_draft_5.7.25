<?php
 //return_json || __return_result
 

function api_login_user($aObj, $LUser){
  global $PassSalt, $RootDir, $consumer_key, $consumer_secret;
  
  if(($aObj['email'] != "" || $aObj['username'] != "") && $aObj['password'] != "")
   {
  	
   	 $login = ($aObj['email'] != "")?$aObj['email']:$aObj['username'];
   	
   	$_SESSION['user'] = new User();
    if($_SESSION['user']->Login($login, $aObj['password'])){
    	$row = $_SESSION['user']->data;
    	
     	setcookie("uid", $row['id'], time()+(3600*24*7), "/");
     	setcookie("upd", md5($row['password'].$row['id'].$PassSalt), time()+(3600*24*7),"/");
     	
    	$row = manage_user_row($row, $LUser, '0');
    	mark_all_activities_as_read($row['id']);
		done_json($row, "result");
	 }else{
	   done_json("Invalid email/username or password");
	  }
   }
   
   
   done_json("empty Email or Password");
 }
/* api function end */
 
 

 function prepare_file_ppic_from_url($uid, $url, $source = ""){
	global $RootDir;
	
	$ext = get_file_ext($url);
	if($ext == "" || strlen($ext) > 5)$ext = 'jpg';
	
  	$the_tmp_local_file = $RootDir.'/upload/_tmp_'.$source.'_'.$uid.'.'.$ext;
  	$cnt = file_get_contents($url);
  	file_put_contents($the_tmp_local_file, $cnt);

  	
  	$log = is_the_picture_is_good($the_tmp_local_file);
  	if($log == ""){
  		$_FILES['img_name']['name'] = '_tmp_'.$source.'_'.$uid.'.'.$ext;
  		$_FILES['img_name']['tmp_name'] = $the_tmp_local_file;
  		$_FILES['img_name']['unlink_original'] = "unlink_original";
  	 }else{
  	 	unlink($the_tmp_local_file);
  	 }
 }
 
 

 /* api function begin  
    $aTmpObj['fname'] = 'halcyon';
    $aTmpObj['lname'] = 'third';
    $aTmpObj['users_types_id'] = '2';
    $aTmpObj['broadcast'] = 'Broadcast text...';
    $aTmpObj['about'] = 'About Me...';
    $aTmpObj['phone'] = '322333';
    $aTmpObj['cities_id'] = '1';
   	$aTmpObj['email'] = 'halcyon.third@gmail.com';
  	$aTmpObj['password'] = 'halcyon.third';
   	$aTmpObj['username'] = 'halcyon_third';
    $aTmpObj['aSkills'][0] = '1';
    $aTmpObj['aSkills'][1] = '2';
    $aTmpObj['aSkills'][2] = '3';
    $aTmpObj['manual_city'] = 'NY';
    $aTmpObj['other_skill'] = 'C++ Development';
  	$input_file[] = "img_name"; */
 
	  function api_register_user($aObj, $LUser, $social = false){
		global $PassSalt, $RootDir;
		 
		$aSkillsSQL = array();
		$aSkillsIDs = array();
		
		if($social || check_user_data($aObj)){
			
			
			
			if(isset($aObj['aSkills'])){
				$aSkillsIDs = check_existance_by_ids("skills", $aObj['aSkills']);
			 }
			
			
			//$confirmed = ($social && $aObj['email'] != "")?'1':'0';
			$confirmed = '1';
			
			if($aObj['facebook_id'] != ""){
				$aObj['facebook_id'] = "";
				//done_json("direct facebook_id deprecated, use fb_access_token instead");
			 }
			 
			 
			if($aObj['fb_access_token'] != ""){
				
			  $json = execute_curl_request("https://graph.facebook.com/me/?access_token=".$aObj['fb_access_token']);
			  $aData = json_decode($json);
				if ($aData->id != ""){
				   $aObj['facebook_id'] = $aData->id;
			   }
		  
			 }
			 
		 if($aObj['fname'] == "" && $aObj['lname'] == "" && $aObj['flname'] != ""){
				 
				 $aTmp = explode(" ", $aObj['flname'], 2);
				 $aTmp['fname'] = $aTmp[0];
				 $aTmp['lname'] = $aTmp[1];
				 
			 }
			 
			 
		   if($aObj['users_types_id'] != ""){
			   check_existance_by_id("user_types", $aObj['users_types_id']);
						   /*  I’d like to REMOVE the email authentication that is currently in place to allow for a user to choose UserType “LEAD".
			   if($aObj['users_types_id'] == '1'){
				   if($aObj['email'] == "")done_json("email is empty!");
				   $sql = "SELECT COUNT(*) FROM `verified_email_accounts` WHERE LOWER(`email`)= LOWER('".mvs($aObj['email'])."') AND `verified` = 1";
				   $res = mysql_custom_query($sql);
				   if(mysql_result($res, 0, 0) == 0)done_json("Your email is not authorized as a Lead Account");
			   }*/
		   }
		   if(!empty($aObj['cities_id']))check_existance_by_id("cities", $aObj['cities_id']);
			 
			 $aInsert = array();
			 $aInsert["`email`"] = "'".mvs($aObj['email'])."'";
			 $aInsert["`about`"] = "'".mvs($aObj['about'])."'";
			 $aInsert["`broadcast`"] = "'".mvs($aObj['broadcast'])."'";
			 $aInsert["`phone`"] = "'".mvs($aObj['phone'])."'";
			 $aInsert["`cities_id`"] = "'".mv($aObj['cities_id'])."'";
			 $aInsert["`users_types_id`"] = "'".mv($aObj['users_types_id'])."'";
			 $aInsert["`password`"] = "'".mv(md5($PassSalt.$aObj['password']))."'";
			 $aInsert["`fname`"] = "'".mvs($aObj['fname'])."'";
			 $aInsert["`lname`"] = "'".mvs($aObj['lname'])."'";
			 $aInsert["`username`"] = "'".mvs($aObj['username'])."'";
			 $aInsert["`confirmed`"] = "'".$confirmed."'";
			 $aInsert["`facebook_id`"] = "'".mvs($aObj['facebook_id'])."'";
			 $aInsert["`device_token`"] = "'".mvs($aObj['device_token'])."'";
			 $aInsert["`twitter_id`"] = "'".mvs($aObj['twitter_id'])."'";
			 $aInsert["`manual_city`"] = "'".mvs($aObj['manual_city'])."'";
			 $aInsert["`other_skill`"] = "'".mvs($aObj['other_skill'])."'";
			
		$sql = "INSERT INTO `users` (".implode(", ", array_keys($aInsert)).")VALUES (".implode(", ", $aInsert).");";
		$res = mysql_custom_query($sql);
	   $users_id = mysql_insert_id();
	   
	   
	   if(count($aSkillsIDs)){
		 foreach($aSkillsIDs as $key => $val){
		   $aSkillsSQL[] = "('".mv($users_id)."', ".$val.")";
		 }
		}
	   
	   if(count($aSkillsSQL)){
		   $sql = "INSERT INTO `users_skills` (`users_id` ,`skills_id`) VALUES ".implode(", ", $aSkillsSQL).";";
		   $res = mysql_custom_query($sql);
	   }
	   
	   
	   
	   
	   
	   $aSQL = array();
	   
	   if($aObj['facebook_id'] != ""){
		   $sql = "SELECT * FROM `goals_pre_invites` WHERE (`type`='fb' AND `identifier`='".mv($aObj['facebook_id'])."')";
		   $res = mysql_query($sql) or die(mysql_error());
		   $aSQL = array();
		   if(mysql_num_rows($res)){
			   while($row=mysql_fetch_assoc($res)){
				   $aSQL[$row['goals_id']] = "('".$row['users_id']."', '".$users_id."', '".$row['goals_id']."', 1)";
			   }
		   }
	   }
		
		
	   if($aObj['email'] != ""){
		   $sql = "SELECT * FROM `goals_pre_invites` WHERE (`type`='email' AND `identifier`='".mv($aObj['email'])."')";
		   $res = mysql_query($sql) or die(mysql_error());
		   if ($aSQL == null) {
			   $aSQL = array();
		   }
		   if(mysql_num_rows($res)){
			   while($row=mysql_fetch_assoc($res)){
				   $aSQL[$row['goals_id']] = "('".$row['users_id']."', '".$users_id."', '".$row['goals_id']."', 1)";
			   }
		   }
	   }
		
	   if($aObj['phone'] != ""){
		   $sql = "SELECT * FROM `goals_pre_invites` WHERE (`type`='phone' AND `identifier`='".mv($aObj['phone'])."')";
		   $res = mysql_query($sql) or die(mysql_error());
		   if ($aSQL == null) {
			   $aSQL = array();
		   }
		   if(mysql_num_rows($res)){
			   while($row=mysql_fetch_assoc($res)){
				   $aSQL[$row['goals_id']] = "('".$row['users_id']."', '".$users_id."', '".$row['goals_id']."', 1)";
			   }
		   }
	   }
		
		
	   
	   if(count($aSQL)){
		   $sql = "INSERT INTO `goals_team` (`users_id1`, `users_id2`, `goals_id`, `confirmed`) VALUES ".implode(", ", $aSQL);
		   $res = mysql_query($sql) or die(mysql_error());
		   $sql = "DELETE FROM `goals_pre_invites` WHERE (`type`='phone' AND `identifier`='".mv($aObj['phone'])."') OR (`type`='email' AND `identifier`='".mv($aObj['email'])."') OR (`type`='fb' AND `identifier`='".mv($aObj['facebook_id'])."')";
		   $res = mysql_query($sql) or die(mysql_error());
		   
		   foreach($aSQL as $goals_id => $val){
			  $aObj2 = array();
			  $aObj2['goals_id'] = $goals_id;
			  $aObj2['added_value'] = 1;
			  $goals_progress_log_id = log_goal_progress($users_id, $aObj2, "recruiting");
			}
	   }
	   
	   
	   
	   
	   
	   
	   
	   mkdir($RootDir."/upload/".$users_id, 0777);
	   chmod($RootDir."/upload/".$users_id, 0777);
	   
	   
	   if($_FILES['img_name']['name'] != ""){
		  $aSources = array('img_name');
		  $aSourcesNotes = array('profile_picture');
		  add_s3_files_to_a_table($users_id, 1, $aSources, $aSourcesNotes, $users_id);
		}
			
		  api_login_user(array('email' => $aObj['email'], 'password' => $aObj['password']), $LUser);
		   //done_json($lastid, 'user_id');
		 }
		 
		 done_json("check_user_data");
	 }
   /* api function end */
	 
   function manage_user_row($row, $logged_in_user_id = 0, $level = '1'){
	   global $RootDomain, $RootDir;
	   
	   $row['flname'] = $row['fname'].(($row['lname'] != "")?' '.$row['lname']:"");
	   
	   if(is_array($row['data']) && count($row['data'])){
		   $row = array_merge($row, $row['data']);
		   unset($row['data']);
	   }
		
	   unset($row['password']);
	   unset($row['device_token']);
	   
	   if($level == '1'){
		 unset($row['email']);
	   }
	   
	   
	   $sql = "SELECT s.* FROM `skills` as s, `users_skills` as us WHERE us.`users_id` = '".mv($row['id'])."' AND s.`id` = us.`skills_id`";
	   $res = mysql_custom_query($sql);
	   $aSkills = array();
	   if(mysql_num_rows($res)){
		   while($row22=mysql_fetch_assoc($res)){
			   $aSkills[] = $row22;
		   }
	   }
	   $row['aSkills'] = $aSkills;
	   
	   
	   return $row;
   }

   
/* api function begin  
    $aTmpObj['fname'] = 'halcyon';
    $aTmpObj['lname'] = 'third';
   	$aTmpObj['email'] = 'halcyon.third@gmail.com';
  	$aTmpObj['password'] = 'halcyon.third';
   	$aTmpObj['username'] = 'halcyon_third';
    $aTmpObj['users_types_id'] = '2';
    $aTmpObj['device_token'] = 'XXXX';
    $aTmpObj['broadcast'] = 'Broadcast text...';
    $aTmpObj['about'] = 'About Me...';
    $aTmpObj['phone'] = '322333';
    $aTmpObj['cities_id'] = '0';
    $aTmpObj['manual_city'] = 'NY';
    $aTmpObj['lat'] = '40.71448';//optional
    $aTmpObj['lng'] = '-74.00598';//optional
    $aTmpObj['aSkills'][0] = '1';
    $aTmpObj['aSkills'][1] = '2';
    $aTmpObj['aSkills'][2] = '3';
    $aTmpObj['other_skill'] = 'C++ Development';
  	$input_file[] = "img_name"; */

function api_edit_user($aObj, $LUser){
	global $PassSalt;
	
	//print_r($LUser);exit;
	if($LUser['id'] == '')done_json("login required!");
	
   //if($aObj['fname'] == '')done_json('fname Required');
   //if($aObj['lname'] == '')done_json('lname Required');
  
	if($aObj['email'] != ""){
		check_new_email($aObj['email'], $LUser['email']);
		$aUpdateFields[] = " `email`='".mvs($aObj['email'])."' ";
	}
	
		if($aObj['users_types_id'] != ""){
			check_existance_by_id("user_types", $aObj['users_types_id']);
			if($aObj['users_types_id'] == '1'){
				if($aObj['email'] != ""){
					$email_to_check = $aObj['email'];
				 }else{
				 	$sql = "SELECT `email` FROM `users` WHERE `id`='".mv($LUser['id'])."'";
				 	$res = mysql_custom_query($sql);
				 	if(mysql_num_rows($res)){
				 	  $email_to_check = mysql_result($res, 0, 0);
				 	}else{
				 		done_json("the user doesn't exist anymore");
				 	}
				 }
                                 /* I’d like to REMOVE the email authentication that is currently in place to allow for a user to choose UserType “LEAD".
				$sql = "SELECT COUNT(*) FROM `verified_email_accounts` WHERE LOWER(`email`)= LOWER('".mv($email_to_check)."') AND `verified` = 1";
				$res = mysql_custom_query($sql);
				if(mysql_result($res, 0, 0) == 0)done_json("Your email is not authorized as a Lead Account");
                                  */
			}
		}
		
		
	if(!empty($aObj['cities_id']))check_existance_by_id("cities", $aObj['cities_id']);
	
    
   $aUpdateFields = array();
   
   $aAuoUpdateColumns = array('fname', 'lname', 'users_types_id', 'cities_id', 'broadcast', 'about', 'phone', 'device_token', 'lat', 'lng', 'other_skill');
   
   if(isset($aObj['manual_city'])){
       $aUpdateFields[] = " `manual_city`='".mvs($aObj['manual_city'])."' ";
   }
   
   if(count($aAuoUpdateColumns)){
   	 foreach($aAuoUpdateColumns as $key => $val){
   	 	if($aObj[$val] != "")$aUpdateFields[] = " `".$val."`='".mvs($aObj[$val])."' ";
   	 }
   }


    
   if($aObj['username'] != ""){
      $r = check_new_username($aObj['username'], $LUser['username']);
      if($r != "")done_json($r);
      $aUpdateFields[] = " `username`='".mvs($aObj['username'])."' ";
    }
    
  //check_new_username($aObj['username'], $LUser['username']);
		
   if($aObj['password'] != ""){
  	  $aUpdateFields[] = " `password`='".md5($PassSalt.$aObj['password'])."' ";
    }
 
 //$email_confirmed = ($aObj['email'] != $LUser['email'])?"`email_confirmed`='0',":"";
 
 if(count($aUpdateFields)){
   $sql = "UPDATE `users` SET ".implode(", ", $aUpdateFields)." WHERE `id` = '".mv($LUser['id'])."';";
   $res = mysql_custom_query($sql);
  }
  
  
 //update_user_images($LUser['id']);
 
  if($_FILES['img_name']['name'] != ""){
  	
  	 delete_s3_files_by_main_key($LUser['id'], "profile_picture");
  	
     $aSources = array('img_name');
     $aSourcesNotes = array('profile_picture');
     $aLog = add_s3_files_to_a_table($LUser['id'], 1, $aSources, $aSourcesNotes, $LUser['id']);
   }
 
   
   
   if(isset($aObj['aSkills'])){
   	
   	
   	  $aIDs = check_existance_by_ids("skills", $aObj['aSkills']);
   	
   	  $sql = "DELETE FROM `users_skills` WHERE `users_id`='".mv($LUser['id'])."'";
   	  $res = mysql_custom_query($sql);
   	
   	
      $aSQLs = array();
   	
   	  foreach($aIDs as $key => $val){
   		 $aSQLs[] = "('".mv($LUser['id'])."', ".$val.")";
   	    }
   	
      if(count($aSQLs)){
   		$sql = "INSERT INTO `users_skills` (`users_id` ,`skills_id`) VALUES ".implode(", ", $aSQLs).";";
   		$res = mysql_custom_query($sql);
       }
   	
     }
   
   //print_r($aLog);exit;
 /*
  $sql = "SELECT * FROM `users` WHERE `id` = '".$LUser['id']."';";
  $res = mysql_custom_query($sql);
  $row=mysql_fetch_assoc($res);
  $row = manage_user_row($row, $LUser, '0');
  */
  $_SESSION['user'] = new User();
  $_SESSION['user']->CreateUserObject($LUser['id']);
	
  api_user_profile(array(), $LUser);
  //done_json("ok", "result");
}
/* api function end */
 

function check_existance_by_ids($table, $aIDs){

	if($table == "" || !is_array($aIDs) || count($aIDs) == 0)done_json("empty or wrong table/aIDs data");

	$aToDB = array();
	foreach($aIDs as $key => $val){
		$val = trim($val);
		if($val == '')continue;
		//if(preg_match("/^[a-zA-Z0-9][a-zA-Z0-9\.\-\_]+\@([a-zA-Z0-9_-]+\.)+[a-zA-Z]+$/", $val)){
		$aToDB[$val] = "'".mvs($val)."'";
		/*}else{
		 $aLog[$val] = 'wrong email!';
		}*/
	}

	if(count($aToDB)){
		$sql = "SELECT COUNT(*) FROM `".mv($table)."` WHERE `id` IN (".implode(", ", $aToDB).")";
		//echo $sql;exit;
		$res = mysql_custom_query($sql);
		if(mysql_result($res, 0, 0) != count($aToDB))done_json($table.": aIDs is wrong!");
	}else{
		done_json($table.": aIDs is empty");
	}

	return $aToDB;
}

 
 function generate_random_password($user_id){
   global $PassSalt;
   $password = rand(0, 999999).'_'.$user_id.'_'.rand(0, 999999);
   $password = md5($PassSalt.$password);
   $sql2 = "UPDATE `users` SET `password` = '".$password."' WHERE `id`='".mv($user_id)."'";
   $res2 = mysql_query($sql2) or die(mysql_error());
}

 
function remember_me_login_user($cookies){
 global $PassSalt;
 if($cookies['uid'] != "" && $cookies['upd'] != "")
   {
	//$sql = "SELECT * FROM `user` WHERE `id` = '".mv($cookies['uid'])."'";
	$sql = "SELECT users.* FROM `users` WHERE users.`id` = '".mv($cookies['uid'])."'";
	$res = mysql_custom_query($sql);
	if (mysql_num_rows($res)){
      $row=mysql_fetch_assoc($res);
	  if($cookies['upd'] == md5($row['password'].$row['id'].$PassSalt)){
	    $_SESSION['user'] = new User();
	    $_SESSION['user']->createUserObject("", $row);
	  	$row = manage_user_row($row, array(), '0');
	    return true;
	  }
	  //echo $cookies['upd'] .' != '. $row['password'];//exit;
	 }
   }
   
   return false;
 }
 
 /* api function begin 
  
  */
 function api_logout_user($aObj, $LUser){
 	unset($_SESSION['user']);
     setcookie("upd", "", 0, "/");
     setcookie("uid", "", 0, "/");
 	done_json("ok", "result");
  }
/* api function end */
  
function get_users_from_sql($sql){
   $res = mysql_custom_query($sql);
   $aData = array();
    if(mysql_num_rows($res)){
      while($row=mysql_fetch_assoc($res)){
   	    $row = manage_user_row($row);
        $aData[] = $row;
       }
     }
 	return $aData;
 }
 
 function get_1_user($user_id){
 	
   if($user_id == '')return;
   
   $sql = "SELECT * FROM `users` WHERE `id` = '".mv($user_id)."'";
   $res = mysql_custom_query($sql);
   $aData = array();
    if(mysql_num_rows($res)){
        $row=mysql_fetch_assoc($res);
   	    $aData = manage_user_row($row);
     }
 	return $aData;


/* api function begin 
      $aTmpObj['email'] = 'halcyon.third@gmail.com';
      $aTmpObj['hash'] = '';//or hash
      $aTmpObj['new_password'] = '';//optional. I'll generate if empty.
  	 */
 function api_forgot_password($aObj, $LUser){
	global $PassSalt, $RootDomain, $ProjectName;
	
	if($aObj['email'] == '' && $aObj['hash'] == '')done_json("email or (hash and/or new_password) required!");
	//if($aObj['done_json'] == '')done_json("email required!");
	
	if($aObj['hash'] == ''){
	   $sql = "SELECT `id`, `password` FROM `users` WHERE `email`='".mv($aObj['email'])."'";
       $res = mysql_custom_query($sql);
       if(mysql_num_rows($res) == 0)done_json("that user doesn't exist!");
       
       $users_id = mysql_result($res, 0, 0);
       $user_pass = mysql_result($res, 0, 1);
       $hash = md5($users_id.$user_pass.$PassSalt);
       
   	   $sql = "INSERT INTO `password_updaters` (`users_id` ,`hash` ,`timestamp`) VALUES ('".$users_id."', '".$hash."', NOW());";
       $res = mysql_custom_query($sql);
       
	   $message = "Your hash is ".$hash."; the link to reset your password is ".$RootDomain.'/reset_password/'.$hash."/ account: ".$aObj['email'].".";
	   my_mail($aObj['email'], 'Reset your '.$ProjectName.' password', $message);
	   done_json("sent", "result");
	 }
	 
	
	 if($aObj['hash'] != ''){

	 	$show_new_password = false;
	 	if($aObj['new_password'] == ""){
	 		$aObj['new_password'] = substr(md5($PassSalt.time()), rand(2, 5), rand(5, 8)).'_'.substr($aObj['hash'], rand(2, 5), rand(5, 8));
	 		$show_new_password = true;
	 	 }
	 	
	    $sql = "SELECT * FROM `password_updaters` WHERE `hash`='".mv($aObj['hash'])."'";
   		$res = mysql_custom_query($sql);
   		if(mysql_num_rows($res)){
      	  $aPData = mysql_fetch_assoc($res);
      	  
         	$pass_str = md5($PassSalt.$aObj['new_password']);
         	$sql = "UPDATE `users` SET `password` = '".mv($pass_str)."' WHERE `id`='".mv($aPData['users_id'])."'";
            $res = mysql_custom_query($sql);
            
         	$sql = "DELETE FROM `password_updaters` WHERE `users_id`='".mv($aPData['users_id'])."'";
            $res = mysql_custom_query($sql);
      	  
            if($show_new_password){
            	done_json($aObj['new_password'], "new_password");
            }
            
            done_json("ok", "result");
    	 }else{
    	    done_json("wrong hash");
          }
	 	
	 	
	  }
	
	
 }
 /* api function end */
 


 /* api function begin
  $aTmpObj['users_id'] = '1';
  $aTmpObj['message'] = 'test message '.time();
  $aTmpObj['portals_id'] = '';//share
  $aTmpObj['__return_result'] = '';//1
 */
 function api_send_message($aObj, $LUser){
 
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['users_id'] == '')done_json("users_id is empty!");
 	if($aObj['message'] == '')done_json("message required!");
 	
 	if($aObj['portals_id'] != ''){
 	  $sql = "SELECT COUNT(*) FROM `portals` WHERE `id` = '".mv($aObj['portals_id'])."'";
 	  $res = mysql_custom_query($sql);
 	  if(mysql_result($res, 0, 0) == 0)done_json("the portal doesn't exist!");
 	 }
 	 
 	if(does_user_block($aObj['users_id'], $LUser['id'])){
 		if($aObj['__return_result'] == "1")return "blocked!";
 		done_json("blocked!");
 	}
 		
 	$sql = "INSERT INTO `messages` (`users_id1`, `users_id2`, `portals_id`, `text`) VALUE
 	 ('".mv($LUser['id'])."', '".mv($aObj['users_id'])."', '".mv($aObj['portals_id'])."', '".mvs($aObj['message'])."')";
 	$res = mysql_custom_query($sql);
 	$messages_id = mysql_insert_id();
 
 	register_new_activity($LUser['id'], $aObj['users_id'], "new_direct_message", "1", $messages_id, "messages");
 	
 	$sql = "DELETE FROM `users_hidden_conversations` WHERE (`users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."') OR (`users_id2`='".mv($LUser['id'])."' AND `users_id1`='".mv($aObj['users_id'])."')";
 	$res = mysql_custom_query($sql);
 		
 	if($aObj['__return_result'] == "1")return "sent";
 	done_json("sent", "result");
 }
 /* api function end */
 
   
 /* api function begin
  $aTmpObj['messages_id'] = '1';
  $aTmpObj['users_id'] = '1';
 */
 function api_delete_message($aObj, $LUser){
  
    if($LUser['id'] == '')done_json("Login error!");
    if($aObj['messages_id'] == '' && $aObj['users_id'] == '')done_json("messages_id AND users_id are empty!");
    if($aObj['messages_id'] != '' && $aObj['users_id'] != '')done_json("messages_id OR users_id required, not both!");
 
  	   $where = ($aObj['messages_id'] != "")?" (`id`='".mv($aObj['messages_id'])."' AND (`users_id1` = '".mv($LUser['id'])."' OR `users_id2` = '".mv($LUser['id'])."')) ":" ((`users_id1` = '".mv($LUser['id'])."' AND `users_id2` = '".mv($aObj['users_id'])."' ) OR ((`users_id1` = '".mv($aObj['users_id'])."' AND `users_id2` = '".mv($LUser['id'])."')))  ";
   	   $aLog = array();
 
	   $sql33 = "SELECT * FROM `messages` WHERE ".$where;
	   $res33 = mysql_query($sql33) or die(mysql_error());
 
 	   if (mysql_num_rows($res33)){
 		while($row33 = mysql_fetch_assoc($res33)){
 
 
   	   	 $files_log = "";
 
  	          $sql = "DELETE FROM `messages` WHERE `id`='".mv($row33['id'])."'";
  		      $res = mysql_custom_query($sql);
  		      if(mysql_affected_rows() > 0){
  				 $aLog[] = $row33['id']."; S3: ".$files_log;
   	   			}
 
 
 
   	   	  }
   	    }
 
 
 
   	   			 
   	   	  done_json($aLog, "result");
   	   			 
   	 }
   /* api function end */
   	 
   	 /* api function begin
   	   $aTmpObj['users_id'] = '';
   	   $aTmpObj['todo'] = 'hide';//show
   	 */
   	  
   	 function api_hide_conversation($aObj, $LUser){
   	 	if($LUser['id'] == '')done_json("Login error!");
   	 	if($aObj['users_id'] == '')done_json("users_id is empty!");
   	 	if($aObj['todo'] == '')done_json("todo is empty or wrong! Supported: hide, show");
   	 	
   	 	$sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['users_id'])."'";
   	 	$res = mysql_custom_query($sql);
   	 	$xs = mysql_result($res, 0, 0);
   	 	if($xs == 0)done_json("that users_id doesn't exist!");
   	 	
   	 	$sql = "SELECT COUNT(*) FROM `users_hidden_conversations` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
   	 	$res = mysql_custom_query($sql);
   	 	$xs = mysql_result($res, 0, 0);
   	 	 
   	 	if($aObj['todo'] == 'hide'){
   	 		if($xs > 0)done_json("You are already hiding '".$aObj['users_id']."'");
   	 		 
   	 		$sql = "INSERT INTO `users_hidden_conversations` (`users_id1`, `users_id2`) VALUES ('".mv($LUser['id'])."', '".mv($aObj['users_id'])."');";
   	 		$res = mysql_custom_query($sql);
   	 		
   	 	}
   	 	 
   	 	if($aObj['todo'] == 'show'){
   	 		if($xs == 0)done_json("You are not hiding '".$aObj['users_id']."'");
   	 		$sql = "DELETE FROM `users_hidden_conversations` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
   	 		$res = mysql_custom_query($sql);
   	 	}
   	 	
   	 	done_json("ok", "result");
   	 }
   	 /* api function end */

   	/* api function begin
   	 $aTmpObj['users_id'] = '';
   	 $aTmpObj['keyword'] = '';//keyword_text + keyword_flname
   	 $aTmpObj['keyword_text'] = 'a';
   	 $aTmpObj['keyword_flname'] = 'a';
   	 $aTmpObj['show_hidden'] = '1';//0
   	 $aTmpObj['newer_than_id'] = '1';
   	 $aTmpObj['chats_id'] = '';
   	 $aTmpObj['order'] = 'ASC';//DESC
   	 $aTmpObj['limit'] = '50';//optional
   	 $aTmpObj['offset'] = '0';//optional
   	 */
   	 
   	 function api_get_messages($aObj, $LUser){
   	 	 
   	 	if($LUser['id'] == '')done_json("Login error!");
   	 	 
   	 	if($aObj['keyword'] != ""){
   	 		$aObj['keyword_text'] = $aObj['keyword'];
   	 		$aObj['keyword_flname'] = $aObj['keyword'];
   	 	 }
   	 	 
   	 	if($aObj['order'] != '' && $aObj['order'] != 'ASC' && $aObj['order'] != 'DESC')done_json("order is wrong! ASC or DESC required");
   	 	$order = ($aObj['order'] == 'DESC')?'DESC':'ASC';
   	 	 
   	 	$offset = (int)$aObj['offset'];
   	 	$limit = (int)$aObj['limit'];
   	 	
   	 	if($limit == 0)$limit = 50;
   	 
   	 	if($offset < 0) done_json("offset is wrong!");
   	 	if($limit > 4096) done_json("limit should be < 4096");
   	 
   	 	$new_messages_count = 0;
   	 
   	 	/*
   	 	 $index1 = ($aObj['inbox'] == '1')?'2':'1';
   	 	$index2 = ($aObj['inbox'] == '1')?'1':'2';*/
   	 	
   	 	
   	 	
   	 	$aAlreadyReadInTheChatIds = array();
   	 	//if($aObj['chats_id'] != ""){
   	 	  $sql = "SELECT `messages_id` FROM `messages_read` WHERE `users_id` = '".mv($LUser['id'])."' ORDER BY `id` DESC LIMIT 0, 1024";//AND `chats_id` = '".mv($aObj['chats_id'])."'
   	 	  $res = mysql_custom_query($sql);
   	 	  if(mysql_num_rows($res)){
   	 		while($row=mysql_fetch_assoc($res)){
   	 			$aAlreadyReadInTheChatIds[$row['messages_id']] = $row['messages_id'];
   	 		 }
   	 	   }
   	 	 //}   	 	
   	 	 
   	 	 
   	 	$aSQLs = array();
   	 
   	 	if($aObj['newer_than_id'] != ""){
   	 		$aObj['newer_than_id'] = (int)$aObj['newer_than_id'];
   	 		$aSQLs[] = "m.`id` > '".mv($aObj['newer_than_id'])."'";
   	 	 }
   	 
   	 	if($aObj['keyword_text'] != "" && $aObj['keyword_flname'] == ""){
   	 		$aSQLs[] = " lower(m.`text`) LIKE lower('%".mvs($aObj['keyword_text'])."%') ";
   	 	 }
   	 	 
   	 	 
   	 	
   	 	if($aObj['portals_id'] != ""){
   	 		$aSQLs[] = " m.`portals_id` = '".mv($aObj['portals_id'])."' ";
   	 	 }
   	 
   	 	if($aObj['users_id'] == "" && $aObj['chats_id'] == ""){
   	 		$groupped_c = ", MAX(m.`timestamp`) as timestamp, COUNT(*) as messages_count ";
   	 		$group_by = " GROUP BY group_cond ";
   	 		
   	 		if($aObj['show_hidden'] != "1"){
   	 			$aSQLs[] = "m.`users_id1` NOT IN (SELECT `users_id2` FROM `users_hidden_conversations` WHERE `users_id1` = '".mv($LUser['id'])."')";
   	 			$aSQLs[] = "m.`users_id2` NOT IN (SELECT `users_id2` FROM `users_hidden_conversations` WHERE `users_id1` = '".mv($LUser['id'])."')";
   	 			$aSQLs[] = "m.`chats_id` NOT IN (SELECT `chats_id` FROM `chats_hidden_conversations` WHERE `users_id` = '".mv($LUser['id'])."')";
   	 		}
   	 		
   	 		$aSQLs[] = " (m.`users_id2` = '".mv($LUser['id'])."' OR m.`users_id1` = '".mv($LUser['id'])."' OR m.`chats_id` IN (SELECT `chats_id` FROM `chats_users` WHERE `users_id` = '".mv($LUser['id'])."'))";
   	 		
   	 		if($aObj['keyword_flname'] != ""){ 
   	 			
   	 			$or_text = ($aObj['keyword_text'] != "")?" OR lower(m.`text`) LIKE lower('%".mvs($aObj['keyword_text'])."%')":"";
   	 					
   	 			$aSQLs[] = " (LOWER(CONCAT_WS(' ', u.`fname`, u.`lname`)) LIKE '%".mv(strtolower($aObj['keyword_flname']))."%'".$or_text.")";
   	 		 }

   	 		//$sql = "select *, COUNT(*) as messages_count from (SELECT m.*, IF(m.`users_id1` = '".mv($LUser['id'])."', m.`users_id2`, m.`users_id1` ) as the_other FROM `messages` as m WHERE ".implode(" AND ", $aSQLs)." ORDER BY m.`timestamp` DESC ) AS x GROUP BY the_other";
   	 		$sub_sql = "SELECT m.*, u.`id` as the_other FROM `messages` as m LEFT JOIN `users` u ON u.`id` = IF(m.`users_id1` = '".mv($LUser['id'])."', m.`users_id2`, m.`users_id1`) WHERE ".implode(" AND ", $aSQLs)." ORDER BY m.`timestamp` DESC";
   	 		
   	 		$sql = "select x.*, COUNT(*) as messages_count, if(x.`chats_id` > 0, CONCAT('c', x.`chats_id`), the_other) as group_cond from (".$sub_sql.") AS x".$flname_keyword_sql." GROUP BY group_cond ORDER BY x.`timestamp` DESC";
   	 		
   	 	}elseif($aObj['chats_id'] != ""){
   	 		$aSQLs[] = " m.`chats_id` = '".mv($aObj['chats_id'])."' ";
   	 		$sql = "SELECT m.* FROM `messages` as m WHERE ".implode(" AND ", $aSQLs)." ORDER BY m.`timestamp` ".$order." LIMIT ".$offset.", ".$limit;
   	 	}else{
   	 		$aSQLs[] = " ( (m.`users_id1` = '".mv($LUser['id'])."' AND m.`users_id2` = '".mv($aObj['users_id'])."') OR (m.`users_id2` = '".mv($LUser['id'])."' AND m.`users_id1` = '".mv($aObj['users_id'])."')  )";
   	 		$sql = "SELECT m.*, IF(m.`users_id1` = '".mv($LUser['id'])."', m.`users_id2`, m.`users_id1` ) as the_other FROM `messages` as m WHERE ".implode(" AND ", $aSQLs)." ORDER BY m.`timestamp` ".$order." LIMIT ".$offset.", ".$limit;
   	 	}
   	 
   	 	//echo $sql;exit;
   	 	$res = mysql_custom_query($sql);
   	 	$aData = array();
   	 	$aReadIds = array();
   	 	$aCheckChatMessagesForReadIds = array();
   	 	$aPortalsIDs = array();
   	 	$aChatsIDs = array();
   	 	if(mysql_num_rows($res)){
   	 		while($row=mysql_fetch_assoc($res)){
   	 			if($row['portals_id'] > 0)$aPortalsIDs[$row['portals_id']] = $row['portals_id'];
   	 			if($row['chats_id'] > 0)$aChatsIDs[$row['chats_id']] = $row['chats_id'];
   	 			
   	 			
   	 			if($aObj['users_id'] == "" && $aObj['chats_id'] == ""){
   	 				
   	 				if(!empty($row['chats_id']))$sql22 = "SELECT COUNT(*) as messages_count_new FROM `messages` WHERE `chats_id` = '".mv($row['chats_id'])."' AND `id` NOT IN (SELECT `messages_id` FROM `messages_read` WHERE `users_id` = '".mv($LUser['id'])."' AND `chats_id` = '".mv($row['chats_id'])."') ";
   	 				if(!empty($row['the_other']))$sql22 = "SELECT COUNT(*) as messages_count_new FROM `messages` WHERE `read` = 0 AND (`users_id2` = '".mv($LUser['id'])."' AND `users_id1` = '".mv($row['the_other'])."') ";
   	 				$res22 = mysql_custom_query($sql22);
   	 				$row['messages_count_new'] = mysql_result($res22, 0, 0);
   	 				$new_messages_count += $row['messages_count_new'];
   	 			}
   	 			
   	 			
   	 			if(!empty($row['chats_id'])){
   	 				$row['read'] = ($aAlreadyReadInTheChatIds[$row['id']] != "")?'1':'0';
   	 			 }
   	 
   	 			if($row['users_id2'] != $LUser['id'] && empty($row['chats_id']))$row['read'] = "1";
   	 			 
   	 			$aData[] = $row;
   	 			if($row['the_other'] != "")$aUsers[$row['the_other']] = $row['the_other'];
   	 			$aUsers[$row['users_id1']] = $row['users_id1'];
   	 			$aReadIds[$row['id']] = $row['id'];
   	 		}
   	 	}
   	 	
   	 	
   	 	

   	 	
   	 	
   	 	
   	 		
   	 		
   	 	if(count($aReadIds) && $aObj['users_id'] != ""){
   	 		$sql = "UPDATE `messages` SET `read` = 1 WHERE `id` IN (".implode(", ", $aReadIds).") AND `users_id2` = '".mv($LUser['id'])."'";
   	 		$res = mysql_custom_query($sql);
   	 	 }
   	 	 
   	 	 if(count($aReadIds) && $aObj['chats_id'] != ""){
   	 	 	

   	 	 	foreach($aAlreadyReadInTheChatIds as $key => $val){
   	 	 		unset($aReadIds[$val]);
   	 	 	 }
  
  		    if(count($aReadIds)){
   	 	 	   $aInsert = array();
   	 	 	   foreach($aReadIds as $key => $val){
   	 	 	   	 $aInsert[] = "('".mv($LUser['id'])."', '".mv($aObj['chats_id'])."', '".mv($val)."')";
   	 	 	   }
   	 	 	   if(count($aInsert)){
   	 	 	   	$sql = "INSERT INTO `messages_read` (`users_id`, `chats_id`, `messages_id`) VALUES ".implode(', ',  $aInsert);
   	 	 	   	$res = mysql_custom_query($sql);
   	 	 	   }
   	 	 	   
  		     }
   	 	 }
   	 
   	 		
   	 	$aRUsers = array();
   	 
   	 	if(count($aData)){
   	 			
   	 		if(count($aUsers)){
   	 			$sql = "SELECT * FROM `users` WHERE `id` IN (".implode(", ", $aUsers).")";
   	 			
	//			 if($aObj['keyword'] != ""){
        //            		    $sql .= " AND LOWER(CONCAT_WS(' ', `fname`, `lname`)) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
        //         		}
				$res = mysql_custom_query($sql);
   	 			$aUsers = array();
   	 			if(mysql_num_rows($res)){
   	 				while($row=mysql_fetch_assoc($res)){
   	 					$row = manage_user_row($row, $LUser);
   	 					//$aUsers[$row['id']] = $row;
   	 					$aRUsers[] = $row;
   	 				}
   	 			}
   	 			 
   	 			 
   	 		}
   	 
   	 
   	 	}
   	 		
   	 	$aData = array_values($aData);
   	 	/*
   	 	 $aRet = array();
   	 	$aRet['aUsers'] = $aUsers;
   	 	$aRet['aMessages'] = $aData;*/
   	 		
   	 	if ($aObj['__return_result'] == '1'){
   	 		return $aData;
   	 	}
   	 	 
   	 	
   	 	//print_r($aPortalsIDs);exit;
   	 	$aPortals = array();
   	 	if(count($aPortalsIDs)){
   	 		$sql = "SELECT * FROM `portals` WHERE `id` IN (".implode(", ", $aPortalsIDs).")";
   	 		$res = mysql_custom_query($sql);
   	 		if(mysql_num_rows($res)){
   	 			while($row=mysql_fetch_assoc($res)){
   	 				$aPortals[] = manage_portal_row($row);
   	 			 }
   	 		 }
   	 	 }
   	 	 
   	 	 $aChats = array();
   	 	 if(count($aChatsIDs)){
   	 	 	$sql = "SELECT * FROM `chats` WHERE `id` IN (".implode(", ", $aChatsIDs).")";
   	 	 	$res = mysql_custom_query($sql);
   	 	 	if(mysql_num_rows($res)){
   	 	 		while($row=mysql_fetch_assoc($res)){
   	 	 			$aChats[] =$row;
   	 	 		}
   	 	 	}
   	 	 }
   	 	 
   	 	 
   	 	 
   	 	
   	 	$aRet = array();
   	 	$aRet['aData'] = $aData;
   	 	$aRet['aUsers'] = $aRUsers;
   	 	$aRet['aPortals'] = $aPortals;
   	 	$aRet['aChats'] = $aChats;
   	 	if($aObj['users_id'] == "")$aRet['new_messages_count'] = $new_messages_count;
   	 	 
   	 	done_json($aRet, "result");
   	 	 
   	 	 
   	 }
   	 /* api function end */
   	 
   	 
   	 

   	 /* api function begin
   	  $aTmpObj['keyword'] = '';
   	   $aTmpObj['users_types_id'] = '';//
      $aTmpObj['lat'] = '48.856735';//optional
      $aTmpObj['lng'] = '-74.005980';//optional
      $aTmpObj['restrict_by_distance'] = '0';//1
	  $aTmpObj['distance'] = '10';//
   	  $aTmpObj['limit'] = '50';//optional
   	  $aTmpObj['offset'] = '0';//optional
   	 */
   	 
   	 function api_get_users($aObj, $LUser){
   	 
   	 	$offset = (int)$aObj['offset'];
   	 	$limit = (int)$aObj['limit'];
   	 
   	 	if($limit == 0)$limit = 50;
   	 
   	 	if($offset < 0) done_json("offset is wrong!");
   	 	if($limit > 4096) done_json("limit should be <= 4096");
   	 
   	 	$aConds = array();
   	 	
   	 	if($aObj['users_types_id'] != ""){
   	 		check_existance_by_id("user_types", $aObj['users_types_id']);
   	 		$aConds[] = " `users_types_id` = '".mv($aObj['users_types_id'])."' ";
   	 	}
   	 
   	 	if($aObj['keyword'] != ""){
   	 		$aConds[] = " LOWER(CONCAT_WS(' ', `fname`, `lname`)) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
   	 	 }
   	 	 
   	 	 if($aObj['lat'] != '' && $aObj['lng'] != ''){
   	 	 	if($aObj['restrict_by_distance'] == '1'){
   	 	 		if($distance < 1)done_json("distance < 1");
   	 	 		$aConds[] = "((ACOS( SIN(`lat` * PI() /180 ) * SIN( (".mv($aObj['lat']).") * PI()/180 ) + COS(`lat` * PI()/180 ) * COS( ( ".mv($aObj['lat'])." ) * PI( ) /180 ) * COS( ((`lng`+0.000001) - ( ".mv($aObj['lng'])." ) ) * PI( ) /180 ) ) *180 / PI() ) * 60 * 1.1515) <= ".mv($distance);
   	 	 	}
   	 	 	$r_cond = ", ((ACOS( SIN(`lat` * PI() /180 ) * SIN( (".mv($aObj['lat']).") * PI()/180 ) + COS(`lat` * PI()/180 ) * COS( ( ".mv($aObj['lat'])." ) * PI( ) /180 ) * COS( ((`lng`+0.000001) - ( ".mv($aObj['lng'])." ) ) * PI( ) /180 ) ) *180 / PI() ) * 60 * 1.1515) as distance ";
   	 	 	
   	 	 	$aConds[] = " `lat` <> '0.000000'";
   	 	 	$aConds[] = " `lng` <> '0.000000'";
   	 	 }
   	 	
   	 	if($LUser['id'] != ''){
   	 		$aConds[] = " `id` <> '".mv($LUser['id'])."'";
   	 	 }
   	 	
   	 	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
   	 	
   	 	$order_sql = ($r_cond != "")?"`distance` ASC":"`id` DESC";
   	 
   	 	$sql = "SELECT *".$r_cond." FROM `users` ".$sql_cond." ORDER BY ".$order_sql." LIMIT ".$offset.", ".$limit;
   	 	$res = mysql_custom_query($sql);
   	 	$aData = array();
   	 	if(mysql_num_rows($res)){
   	 		while($row=mysql_fetch_assoc($res)){
   	 			$aData[] = manage_user_row($row);
   	 		}
   	 	 }
   	 
   	 	done_json($aData, "result");
   	 
   	 }
   	 /* api function end */
   	 
   	 
   	 
/* api function begin  
  $aTmpObj['users_id'] = '1';
  $aTmpObj['todo'] = 'add';//delete */ 

function api_add_to_network_action($aObj, $LUser){
	
	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['users_id'] == '')done_json("users_id is empty!");
 	if($aObj['todo'] == '')done_json("todo is empty or wrong! Supported: add, delete");
 	
  	 $sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['users_id'])."'";
     $res = mysql_custom_query($sql);
     $xs = mysql_result($res, 0, 0);
     if($xs == 0)done_json("that users_id doesn't exist!");
 	
  	 $sql = "SELECT COUNT(*) FROM `users_network` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
     $res = mysql_custom_query($sql);
     $xs = mysql_result($res, 0, 0);
     
     if($aObj['todo'] == 'add'){
       if($xs > 0)done_json("user '".$aObj['users_id']."' is already in your network");
       if(does_user_block($aObj['users_id'], $LUser['id']))done_json("blocked", "error");
       
       $sql = "INSERT INTO `users_network` (`users_id1`, `users_id2`) VALUES ('".mv($LUser['id'])."', '".mv($aObj['users_id'])."');";
       $res = mysql_custom_query($sql);
       
       //register_new_activity($LUser['id'], $aObj['users_id'], "new_network_user", 0, $LUser['id'], "users");
      }
     
     if($aObj['todo'] == 'delete'){
       if($xs == 0)done_json("404");
       $sql = "DELETE FROM `users_network` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
       $res = mysql_custom_query($sql);
      // delete_activity($LUser['id'], $aObj['users_id'], "new_network_user", $LUser['id'], "users");
      }
 	
 	done_json("ok", "result");
 }
/* api function end */
 
 

 /* api function begin
  $aTmpObj['users_id'] = '1';*/
 
 function api_get_my_networks($aObj, $LUser){
 	if($aObj['users_id'] == '')done_json("users_id is empty!");
 	 
 	$sql = "SELECT u.* FROM `users` as u, `users_network` as uf WHERE uf.`users_id2` = '".mv($aObj['users_id'])."' AND u.`id` = uf.`users_id1`";
 	$res = mysql_custom_query($sql);
 	$aData = array();
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			$row = manage_user_row($row, $LUser);
 			$aData[] = $row;
 		}
 	}
 	done_json($aData, "result");
 	 
 }
 /* api function end */
 
 /* api function begin
   $aTmpObj['users_id'] = '1';
   $aTmpObj['invited_goal_id'] = '1';//optional
   $aTmpObj['not_in_chats_id'] = '1';//optional
  */
 
 function api_members_of_my_network($aObj, $LUser){
 	if($aObj['users_id'] == '')done_json("users_id is empty!");
 	 
 	
 	$aSQLs = array();
 	$aSQLs[] = " uf.`users_id1` = '".mv($aObj['users_id'])."' ";
 	$aSQLs[] = " u.`id` = uf.`users_id2` ";
 	if($aObj['invited_goal_id'] != ""){
 	  $aSQLs[] = " u.`id` NOT IN (SELECT `users_id2` FROM `goals_team` WHERE `goals_id` = '".mv($aObj['invited_goal_id'])."') ";
 	 }
 	 
 	 if($aObj['not_in_chats_id'] != ""){
 	 	check_existance_by_id("chats", $aObj['not_in_chats_id']);
 	 	$aSQLs[] = " u.`id` NOT IN (SELECT `users_id` FROM `chats_users` WHERE `chats_id` = '".mv($aObj['not_in_chats_id'])."') ";
 	 }
if($aObj['keyword'] != ""){

                       $aSQLs[] = " LOWER(CONCAT_WS(' ', `fname`, `lname`)) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
                 }
 	
 	$sql = "SELECT u.*, uf.`timestamp` as `follow_date` FROM `users` as u, `users_network` as uf WHERE ".implode(" AND ", $aSQLs);
 	$res = mysql_custom_query($sql);
 	$aUsersData = array();
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			$row = manage_user_row($row, $LUser);
 			$aUsersData[] = $row;
 		}
 	}
 	 
 	 
 	done_json($aUsersData, "result");
 	 
 }
 /* api function end */
 

 /* api function begin
 */
 function api_get_total_counts($aObj, $LUser){
 	if($LUser['id'] == '')done_json("login required!");
 
 	$sql = "SELECT COUNT(*) FROM `goals_team` WHERE `users_id2`='".mv($LUser['id'])."' AND `confirmed` = 0";
 	$res = mysql_custom_query($sql);
 	$goals_team_invites_new = mysql_result($res, 0, 0);
 		
 	$aRet = array();
 	$aRet['goals_team_invites_new'] = $goals_team_invites_new;
 		
 	done_json($aRet, "result");
 }
 /* api function end */
 
 
 

 /* api function begin
  $aTmpObj['parent_id'] = '';
 $aTmpObj['skills_id'] = '';
 $aTmpObj['keyword'] = '';
 $aTmpObj['limit'] = '50';
 $aTmpObj['offset'] = '0';
  $aTmpObj['__return_result'] = '';
 */
 
 function api_get_skills($aObj, $LUser){
 
 	$offset = (int)$aObj['offset'];
 	$limit = (int)$aObj['limit'];
 
 	if($offset < 0) done_json("offset is wrong!");
 	if($limit > 4096) done_json("limit should be < 4096");
 
 	if($limit == 0)$limit = 50;
 
 	$aConds = array();
 	$aConds[] = "`visible` = '1'";
 
 	if($aObj['parent_id'] != ''){
 		$aConds[] = "`parent` = '".mv($aObj['parent_id'])."'";
 	}
 
 	if($aObj['skills_id'] != ''){
 		$aConds[] = "`id` = '".mv($aObj['skills_id'])."'";
 	}
 
 	if($aObj['keyword'] != ''){
 		$aConds[] = "lower(`title`) LIKE lower('%".mvs($aObj['keyword'])."%')";
 	}
 
 	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
 
 
 	$sql = "SELECT * FROM `skills` ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
 	$res = mysql_custom_query($sql);
 	$aData = array();
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 
 			$aData[] = $row;
 
 		}
 	}
 
 	if($aObj['__return_result'] == '1'){
 		return $aData;
 	}
 	done_json($aData, "result");
 
 }
 /* api function end */
 
 
 
 /* api function begin
  $aTmpObj['chats_id'] = "1";
  $aTmpObj['title'] = "New Cool Chat";
  $aTmpObj['aAddIDs'][0] = '1';//user_id
  $aTmpObj['aAddIDs'][1] = '2';//user_id
  $aTmpObj['aDelIDs'] = array();
 */
 
 function api_manage_chat($aObj, $LUser){
 	
 	 if($LUser['id'] == '')done_json("login required!");
 	 
 	 //if(empty($aObj['aAddIDs']) && empty($aObj['aDelIDs']))done_json("aAddIDs or aDelIDs required!");
 	 
 	 if(!empty($aObj['aDelIDs']) && $aObj['chats_id'] == "")done_json("for aDelIDs chats_id required!");
 	 
 	 if($aObj['chats_id'] != ""){
 	 	check_existance_by_id("chats", $aObj['chats_id']);
 	 	$sql = "SELECT COUNT(*) FROM `chats_users` WHERE `chats_id`='".mv($aObj['chats_id'])."' AND `users_id` = '".mv($LUser['id'])."'";
 	 	$res = mysql_custom_query($sql);
 	 	if(mysql_result($res, 0, 0) == 0)done_json("503");
 	  }
 	  

 	  if(!empty($aObj['aAddIDs']))$aAddIDsToDb = check_existance_by_ids("users", $aObj['aAddIDs']);
 	  if(!empty($aObj['aDelIDs']))$aDelIDsToDb = check_existance_by_ids("users", $aObj['aDelIDs']);
 	  
 	 
 	  if($aObj['chats_id'] == ""){
 	  	$sql = "INSERT INTO `chats` (`users_id`, `title`) VALUES ('".mv($LUser['id'])."', '".mvs($aObj['title'])."')";
 	  	$res = mysql_custom_query($sql);
 	  	$chats_id = mysql_insert_id();
 	  	
 	  	$sql = "INSERT INTO `chats_users` (`users_id`, `chats_id`) VALUES ('".mv($LUser['id'])."', '".mv($chats_id)."')";
 	  	$res = mysql_custom_query($sql);
 	   }else{
 	   	
 	   	 if(isset($aObj['title'])){
 	   	 	$sql = "UPDATE `chats` SET `title` = '".mvs($aObj['title'])."' WHERE `id`='".mv($aObj['chats_id'])."'";
 	   	 	$res = mysql_custom_query($sql);
 	   	  }
 	   	
 	   	
 	   	 $chats_id = $aObj['chats_id'];
 	   }
 	   
 	   
 	   $sql = "SELECT `users_id` FROM `chats_users` WHERE `chats_id` = '".mv($chats_id)."'";
 	   $res = mysql_custom_query($sql);
 	   $aCurrentUsers = array();
 	   if(mysql_num_rows($res)){
 	   	while($row=mysql_fetch_assoc($res)){
 	   		$aCurrentUsers[$row['users_id']] = $row['users_id'];
 	   	  }
 	    }
 	   
 	   $aAddIDsToDbLog = array();
 	   if(!empty($aAddIDsToDb)){
 	   	  $aInsertSQL = array();
		  foreach($aAddIDsToDb as $key => $val){
 	   	        if($aCurrentUsers[$key] != ""){
 	   	        	$aAddIDsToDbLog[$key] = 'already in the chat';
 	   	         }else{
 	   	         	$aAddIDsToDbLog[$key] = 'ok';
 	   	         	$aInsertSQL[] = "('".$key."', '".mv($chats_id)."')";
 	   	         }
		    }
		    
		  if(count($aInsertSQL)){
		  	$sql = "INSERT INTO `chats_users` (`users_id`, `chats_id`) VALUES ".implode(", ", $aInsertSQL);
		  	$res = mysql_custom_query($sql);
		  }
        }
        
        
        $aDelIDsToDbLog = array();
        if(!empty($aDelIDsToDb)){
        	$aDelSQL = array();
        	foreach($aDelIDsToDb as $key => $val){
        		if($aCurrentUsers[$key] == ""){
        			$aDelIDsToDbLog[$key] = 'not in the chat';
        		}else{
        			$aDelIDsToDbLog[$key] = 'ok';
        			$aDelSQL[] = $val;
        		}
        	}
        
        	if(count($aDelSQL)){
        		$sql = "DELETE FROM `chats_users` WHERE `users_id` IN (".implode(", ", $aDelSQL).") AND `chats_id` = '".mv($chats_id)."'";
        		$res = mysql_custom_query($sql);
        	}
        }
        
       $aLog = array();
       $aLog['chats_id'] = $chats_id;
       $aLog['aAddIDsToDbLog'] = $aAddIDsToDbLog;
       $aLog['aDelIDsToDbLog'] = $aDelIDsToDbLog;
       ;
 	   
 	  done_json($aLog, "result");
 	}
 	/* api function end */
 	
 	
  /* api function begin
 	$aTmpObj['chats_id'] = '1';
 	$aTmpObj['message'] = 'test message '.time();
 	$aTmpObj['portals_id'] = '';//share
 	$aTmpObj['__return_result'] = '';//1
 	*/
 	function api_send_chat_message($aObj, $LUser){
 	
 		if($LUser['id'] == '')done_json("Login error!");
 		if($aObj['chats_id'] == '')done_json("chats_id is empty!");
 		if($aObj['message'] == '')done_json("message required!");
 	
 		if($aObj['portals_id'] != ''){
 			$sql = "SELECT COUNT(*) FROM `portals` WHERE `id` = '".mv($aObj['portals_id'])."'";
 			$res = mysql_custom_query($sql);
 			if(mysql_result($res, 0, 0) == 0)done_json("the portal doesn't exist!");
 		}
 	
 			
 		$sql = "INSERT INTO `messages` (`users_id1`, `chats_id`, `portals_id`, `text`) VALUE
 	 ('".mv($LUser['id'])."', '".mv($aObj['chats_id'])."', '".mv($aObj['portals_id'])."', '".mvs($aObj['message'])."')";
 		$res = mysql_custom_query($sql);
 		$messages_id = mysql_insert_id();
 	
 		//register_new_activity($LUser['id'], $aObj['users_id'], "new_direct_message", "1", $messages_id, "messages");
 		
 		
 		$sql = "DELETE FROM `chats_hidden_conversations` WHERE `chats_id`='".mv($aObj['chats_id'])."'";
 		$res = mysql_custom_query($sql);
 			
 		if($aObj['__return_result'] == "1")return "sent";
 		done_json("sent", "result");
 	}
 	/* api function end */
 	
 	
 	
 	/* api function begin
 	 $aTmpObj['chats_id'] = '1';
  	 $aTmpObj['limit'] = '50';//optional
     $aTmpObj['offset'] = '0';//optional
 	 $aTmpObj['__return_result'] = '';//1
 	*/
 	function api_get_chat_users($aObj, $LUser){
 	
 		if($LUser['id'] == '')done_json("Login error!");
 		if($aObj['chats_id'] == '')done_json("chats_id is empty!");
 		
   	$offset = (int)$aObj['offset'];
   	$limit = (int)$aObj['limit'];
   
   	if($limit == 0)$limit = 50;
   
   	if($offset < 0) done_json("offset is wrong!");
   	if($limit > 4096) done_json("limit should be <= 4096");
   	
   	
   	$sql = "SELECT u.* FROM `chats_users` as cu, `users` as u WHERE cu.`chats_id` = '".mv($aObj['chats_id'])."' AND cu.`users_id` = u.`id` LIMIT ".$offset.", ".$limit;
   	$res = mysql_custom_query($sql);
   	$aData = array();
   	if(mysql_num_rows($res)){
   		while($row=mysql_fetch_assoc($res)){
   			$aData[] = $row;
   		}
   	}
 	
 		if($aObj['__return_result'] == "1")return $aData;
 		done_json($aData, "result");
 	}
 	/* api function end */
 	
 	

 	/* api function begin
 	 $aTmpObj['chats_id'] = "1";
 	*/
 	
 	function api_delete_chat($aObj, $LUser){
 		
 		if($LUser['id'] == '')done_json("login required!");
 		if($aObj['chats_id'] == "")done_json("chats_id required!");
 			
 		check_existance_by_id("chats", $aObj['chats_id']);
 		$sql = "SELECT COUNT(*) FROM `chats_users` WHERE `chats_id`='".mv($aObj['chats_id'])."' AND `users_id` = '".mv($LUser['id'])."'";
 		$res = mysql_custom_query($sql);
 		if(mysql_result($res, 0, 0) == 0){
 			
 			$sql = "SELECT COUNT(*) FROM `chats` WHERE `id`='".mv($aObj['chats_id'])."' AND `users_id` = '".mv($LUser['id'])."'";
 			$res = mysql_custom_query($sql);
 			$count = mysql_result($res, 0, 0);
 			if(mysql_result($res, 0, 0) == 0)done_json("503");
 		}
 		
 		
 		$res_log_txt = delete_db_row_and_related_data("chats", $aObj['chats_id']);
 		
 		done_json($res_log_txt, "result");
 	 }
 	/* api function end */
 	 
 	 
 	 /* api function begin
 	  $aTmpObj['chats_id'] = '';
 	  $aTmpObj['todo'] = 'hide';//show
 	 */
 	 
 	 function api_hide_chat_conversation($aObj, $LUser){
 	 	if($LUser['id'] == '')done_json("Login error!");
 	 	if($aObj['chats_id'] == '')done_json("chats_id is empty!");
 	 	if($aObj['todo'] == '')done_json("todo is empty or wrong! Supported: hide, show");
 	 
 	 	check_existance_by_id("chats", $aObj['chats_id']);
 	 
 	 	$sql = "SELECT COUNT(*) FROM `chats_hidden_conversations` WHERE `users_id`='".mv($LUser['id'])."' AND `chats_id`='".mv($aObj['chats_id'])."'";
 	 	$res = mysql_custom_query($sql);
 	 	$xs = mysql_result($res, 0, 0);
 	 		
 	 	if($aObj['todo'] == 'hide'){
 	 		if($xs > 0)done_json("You are already hiding '".$aObj['chats_id']."'");
 	 
 	 		$sql = "INSERT INTO `chats_hidden_conversations` (`users_id`, `chats_id`) VALUES ('".mv($LUser['id'])."', '".mv($aObj['chats_id'])."');";
 	 		$res = mysql_custom_query($sql);
 	 			
 	 	}
 	 		
 	 	if($aObj['todo'] == 'show'){
 	 		if($xs == 0)done_json("You are not hiding '".$aObj['chats_id']."'");
 	 		$sql = "DELETE FROM `chats_hidden_conversations` WHERE `users_id`='".mv($LUser['id'])."' AND `chats_id`='".mv($aObj['chats_id'])."'";
 	 		$res = mysql_custom_query($sql);
 	 	}
 	 
 	 	done_json("ok", "result");
 	 }
 	 /* api function end */
 	 

	  function social_network_login_by_row($row, $LUser){
		global $PassSalt;
  
			if($row['password'] == ''){
				$row['password'] = generate_random_password($row['id']);
			 }
			
		   setcookie("uid", $row['id'], time()+(3600*24*7), "/");
		   setcookie("upd", md5($row['password'].$row['id'].$PassSalt), time()+(3600*24*7),"/");
		   
		  if($aObj['device_token'] != "" && $LUser['device_token'] != $row['device_token']){
			  $sql = "UPDATE `users` SET `device_token` = '".mv($aObj['device_token'])."' WHERE `id`='".mv($row['id'])."'";
			  $res = mysql_custom_query($sql);
			  $row['device_token'] = $aObj['device_token'];
		   }
		   
		  $sql = "UPDATE `users` SET `last_login` = NOW() WHERE `id`='".mv($row['id'])."'";
		  $res = mysql_custom_query($sql);
		   
			$_SESSION['user'] = new User();
			$_SESSION['user']->CreateUserObject("", $row);
			$row = manage_user_row($row, $LUser, '0');
			mark_all_activities_as_read($row['id']);
			done_json($row, 'result');
   }
  


 	 function get_user_data_from_fb($aData, $access_token = ""){
	
		if($aData->id == '')return array();
		$aUser = array();
		$aUser['facebook_id'] = $aData->id;
		$aUser['hometown'] = $aData->hometown->name;
		$aUser['work_place'] = $aData->work[0]->position->name;
		$aUser['work_company'] = $aData->work[0]->employer->name;
		$aUser['education'] = $aData->education[0]->school->name;
		$aUser['relationship'] = ($aData->relationship_status == "In a relationship")?'1':'0';
		
			 if($aData->birthday != ""){
				$birthDate = explode("/", $aData->birthday);
				$age = (date("md", date("U", mktime(0, 0, 0, $birthDate[0], $birthDate[1], $birthDate[2]))) > date("md")?((date("Y") - $birthDate[2]) - 1):(date("Y") - $birthDate[2]));
				 $aUser['age'] = $age;
			}
			
		 $aUser['fname'] = $aData->first_name;
		 $aUser['lname'] = $aData->last_name;
		$aUser['flname'] = $aData->name;
		  $aUser['email'] = $aData->email;
		  $aUser['password'] = rand(0, 999999).'_'.$aData->id.'_'.rand(0, 999999);;
		  $aUser['bio'] = $aData->about;
		  $aUser['web_link'] = $aData->link;;
		  $aUser['fb_access_token'] = $access_token;
		  if($aUser['email'] == "" || strlen($aUser['email']) > 64){
			//$aUser['email'] = 'fbtmp_'.$aData->id.'_id'.time().'@tmp.fb.com';
		  }
		  
		  
		 $sql2 = "SELECT COUNT(*) FROM `users` WHERE `username`='".mv($aData->username)."'";
		 $res2 = mysql_query($sql2) or die(mysql_error());
		 $xs = mysql_result($res2, 0, 0);
		 if(mysql_num_rows($res2) == 0){
			 $aUser['username'] = makeSeo($aData->username);
		 }
		 
		//if($aTmpObj['username'] == '')$aTmpObj['username'] = 'fbtmp_'.$aData->id.'_id'.time();
		  
		  if($aData->location->name != ""){
			$aUser['location'] = $aData->location->name;
		  }elseif($aData->hometown->name){
			$aUser['location'] = $aData->hometown->name;
		   }
		   
	
		   
		   prepare_file_ppic_from_url($aData->id, "https://graph.facebook.com/".$aData->id."/picture?type=large", "fb");
		   
		return $aUser;
	}
	
	/* api function begin  
	   $aTmpObj['access_token'] = 'CAAJ9c3xIt4ABAGIXkic5Wg6Yy6OLlsC5QardFZAZCi7evoM7MisWDVbjg7JgdA3mXjgknY6EZCSuwyW1Uj7u7aGsXZCes2gsIIFwKBNKvXw445bTEm6Tlr2CGZBku6hpZCGkwhCRtoy5R2LNECKk6zsLiMRpJIicYoF3KoAZB9nCOYwYnWOUg9dwdFRiZBxqvNg3pHDi5RqBz3MRJydNcuOMCgiuo8u14nmzpw2B49S22yrzZCV9GtLYQ';
	  */
	function api_facebook_login($aObj, $LUser){
		
		$aTmpObj = array();
		
	  if($aObj['access_token'] != ""){
		   
		$json = execute_curl_request("https://graph.facebook.com/me/?access_token=".$aObj['access_token'].'');
		 $aData = json_decode($json);
	 
		 if ($aData->id != ""){
	
			$sql = "SELECT * FROM `users` WHERE `facebook_id`='".mv($aData->id)."'";
			$res = mysql_custom_query($sql);
			if(mysql_num_rows($res) == 0){
				
		  $sql2 = "SELECT * FROM `users` WHERE `email`='".mv($aData->email)."'";
		 $res2 = mysql_query($sql2) or die(mysql_error());
		 if(mysql_num_rows($res2)){
		   $aUser = mysql_fetch_assoc($res2);
		   $id = $aUser['id'];
		   $sql = "UPDATE `users` SET `facebook_id`='".mv($aData->id)."' WHERE `id`='".mv($id)."'";
		  $res = mysql_custom_query($sql);	
		  $aTmpObj['device_token'] = $aObj['device_token'];
			 $aTmpObj['access_token'] = $aObj['access_token'];
			 $aTmpObj['fb_redirect'] = (isset($aTmpObj['fb_redirect'])?1:$aTmpObj['fb_redirect']+1);
			 if($aTmpObj['fb_redirect'] < 3){
			  social_network_login_by_row($aUser, $LUser);
			 }else{
				 done_json("FB redirects me constantly");
			 }
		  }
		  
				  $aTmpObj = get_user_data_from_fb($aData, $aObj['access_token']);
				api_register_user($aTmpObj, array(), true);
			}else{
			  $row=mysql_fetch_assoc($res);
			  social_network_login_by_row($row, $LUser);
			 }/*else{
				done_json($aData, 'fbinfo');
			  }*/
		   }
	  
		 if (isset($aData->error->message) && $aData->error->message != ""){
			 done_json($aData->error->message);
			}else{
			  done_json("Wrong facebook_id!");
			 }
		   
	   }else{
		   done_json("access_token is empty!");
	   }
	   done_json("something wrong!");
	}
	/* api function end */
	
	
 
	function get_users_ff_ids($users_id, $following){
 
 
		if($following){
			$sql = "SELECT `users_id2` as users_id FROM `users_followers` WHERE `users_id1` = '".mv($users_id)."'";
		}else{
			$sql = "SELECT `users_id1` as users_id FROM `users_followers` WHERE `users_id2` = '".mv($users_id)."'";
		}
		$res = mysql_custom_query($sql);
		$aData = array();
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				$aData[] = $row['users_id'];
			}
		}
	
		return $aData;
	}
   

 /* api function begin  
  $aTmpObj['users_id'] = '1';*/ 

  function api_user_profile($aObj, $LUser){
	if($aObj['users_id'] == '' && $LUser['id'] == '')done_json("login or users_id required!");
	if($aObj['users_id'] == '')$aObj['users_id'] = $LUser['id'];
	
	$sql = "SELECT * FROM `users` WHERE `id`='".mv($aObj['users_id'])."'";
    $res = mysql_custom_query($sql);
    if(mysql_num_rows($res)){
      $row=mysql_fetch_assoc($res);	
      /*
      $aUser = new User();
      $aUser->CreateUserObject("", $row, "full");
      $row = (array) $aUser;*/
    }else{
    	done_json("That user doesn't exist!");
     }
     
     if($LUser['id'] != ""){
   		$sql = "SELECT COUNT(*) FROM `users_followers` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
   		$res = mysql_custom_query($sql);
   		$row['i_follow'] = mysql_result($res,0,0);
   		
   		$sql = "SELECT COUNT(*) FROM `users_followers` WHERE `users_id2`='".mv($LUser['id'])."' AND `users_id1`='".mv($aObj['users_id'])."'";
   		$res = mysql_custom_query($sql);
   		$row['i_am_followed_by'] = mysql_result($res,0,0);
   		
   		$sql = "SELECT COUNT(*) FROM `users_network` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
   		$res = mysql_custom_query($sql);
   		$row['in_my_network'] = mysql_result($res,0,0);
   		 
   		$sql = "SELECT COUNT(*) FROM `users_network` WHERE `users_id2`='".mv($LUser['id'])."' AND `users_id1`='".mv($aObj['users_id'])."'";
   		$res = mysql_custom_query($sql);
   		$row['i_am_in_their_network'] = mysql_result($res,0,0);
      }else{
      	$row['i_follow'] = '-';
      	$row['i_am_followed_by'] = '-';
      	$row['in_my_network'] = '-';
      	$row['i_am_in_their_network'] = '-';
      }
     
     
    $level = ($LUser['id'] == $aObj['users_id'])?'0':'1';
    $row = manage_user_row($row, $LUser, $level);
    
    done_json($row, "result");
}
/* api function end */
  

 function check_user_data($data, $type = 'register'){
	
  //if(strlen($data['bio']) > 140)done_json('Users bio has a 140 character limit-Comment form 140 character limit');
  //if($data['username'] == '')done_json('username required');
  //if($data['fname'] == '')done_json('name required');

	check_new_email($data['email'], "");
 	if($data['username'] != ''){
	   $res_str = check_new_username($data['username'], "");
	   if($res_str != "")done_json($res_str);
	 }
	
	if($data['password'] == '')done_json('password required');
	
	 return true;
 }
  
 function check_new_email($email, $old_email = ""){

	 if ($email == ""){
		done_json('Email address required');
	   }

	 if(preg_match("/^[a-zA-Z0-9][a-zA-Z0-9\.\-\_]+\@([a-zA-Z0-9_-]+\.)+[a-zA-Z]+$/", $email)){
		$sql = "SELECT COUNT(*) FROM `users` WHERE lower(`email`) = lower('".mv($email)."')";
		$res = mysql_custom_query($sql);
		$us_count=mysql_result($res,0,0);
		if($us_count > 0 && ($old_email == '' || ($old_email != '' && $email != $old_email))){
		   done_json('Email not unique');
		  }
	 }else{
	   done_json('Invalid email address');
	 }

	 return true;
	}
	
 function check_new_username($username, $old_username = ""){
 	
 	if ($username == ""){
 		return 'Username is empty!';	
 	 }
 	
   	if(preg_match('/^[a-z0-9_]*$/i', $username)){
 	  $sql = "SELECT COUNT(*) FROM `users` WHERE lower(`username`) = lower('".mv($username)."')";
      $res = mysql_custom_query($sql);
      $us_count=mysql_result($res,0,0);
   	  if($us_count > 0 && ($old_username == '' || ($old_username != '' && $username != $old_username))){
		   done_json('Username not unique');
		  }
	 }else{
	  return 'Username: only use letters, numbers and \'_\'';	
	 }
 	
	 return '';
 }

 
/* api function begin 
  $aTmpObj['users_id'] = '1';*/ 
  
  function api_user_followers($aObj, $LUser){
   if($aObj['users_id'] == '')done_json("users_id is empty!");
   
   $sql = "SELECT u.* FROM `users` as u, `users_followers` as uf WHERE uf.`users_id2` = '".mv($aObj['users_id'])."' AND u.`id` = uf.`users_id1`";
   $res = mysql_custom_query($sql);
   $aData = array();
    if(mysql_num_rows($res)){
      while($row=mysql_fetch_assoc($res)){
   	    $row = manage_user_row($row, $LUser);
        $aData[] = $row;
       }
     }
 	done_json($aData, "result");
   
}
/* api function end */

 /* api function begin
  $aTmpObj['users_id'] = '1';*/ 

function api_user_following($aObj, $LUser){
   if($aObj['users_id'] == '')done_json("users_id is empty!");
   
   $sql = "SELECT u.*, uf.`timestamp` as `follow_date` FROM `users` as u, `users_followers` as uf WHERE uf.`users_id1` = '".mv($aObj['users_id'])."' AND u.`id` = uf.`users_id2`";
   $res = mysql_custom_query($sql);
   $aUsersData = array();
    if(mysql_num_rows($res)){
      while($row=mysql_fetch_assoc($res)){
   	    $row = manage_user_row($row, $LUser);
        $aUsersData[] = $row;
       }
     }
     
     
 	done_json($aUsersData, "result");
   
}
/* api function end */

/* api function begin  
  $aTmpObj['users_id'] = '1';
  $aTmpObj['todo'] = 'follow';//unfollow */ 

function api_ff_user($aObj, $LUser){
	
	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['users_id'] == '')done_json("users_id is empty!");
 	if($aObj['todo'] == '')done_json("todo is empty or wrong! Supported: follow, unfollow");
 	
  	 $sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['users_id'])."'";
     $res = mysql_custom_query($sql);
     $xs = mysql_result($res, 0, 0);
     if($xs == 0)done_json("that users_id doesn't exist!");
 	
  	 $sql = "SELECT COUNT(*) FROM `users_followers` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
     $res = mysql_custom_query($sql);
     $xs = mysql_result($res, 0, 0);
     
     if($aObj['todo'] == 'follow'){
       if($xs > 0)done_json("You are already following '".$aObj['users_id']."'");
       if(does_user_block($aObj['users_id'], $LUser['id']))done_json("blocked", "error");
       
       $sql = "INSERT INTO `users_followers` (`users_id1`, `users_id2`) VALUES ('".mv($LUser['id'])."', '".mv($aObj['users_id'])."');";
       $res = mysql_custom_query($sql);
       
       register_new_activity($LUser['id'], $aObj['users_id'], "new_follower", 0, $LUser['id'], "users");
      }
     
     if($aObj['todo'] == 'unfollow'){
       if($xs == 0)done_json("You are not following '".$aObj['users_id']."'");
       $sql = "DELETE FROM `users_followers` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
       $res = mysql_custom_query($sql);
       delete_activity($LUser['id'], $aObj['users_id'], "new_follower", $LUser['id'], "users");
      }
 	
 	done_json("ok", "result");
 }
/* api function end */
 

/* api function begin 
  $aTmpObj['users_id'] = '1';
  $aTmpObj['todo'] = 'block';//unblock */ 
 
  function api_block_user($aObj, $LUser){
 	
	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['users_id'] == '')done_json("users_id is empty!");
 	if($aObj['todo'] == '')done_json("todo is empty or wrong! Supported: block, unblock");
 	 
  	 $sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['users_id'])."'";
     $res = mysql_custom_query($sql);
     $xs = mysql_result($res, 0, 0);
     if($xs == 0)done_json("that users_id doesn't exist!");
 	
  	 $sql = "SELECT COUNT(*) FROM `users_blocks` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
     $res = mysql_custom_query($sql);
     $xs = mysql_result($res, 0, 0);
     
     if($aObj['todo'] == 'block'){
       if($xs > 0)done_json("You are already blocking '".$aObj['users_id']."'");
       
       /***/
       $sql = "DELETE FROM `users_followers` WHERE (`users_id1`='".mv($aObj['users_id'])."' AND `users_id2`='".mv($LUser['id'])."') OR (`users_id2`='".mv($aObj['users_id'])."' AND `users_id1`='".mv($LUser['id'])."')";
       $res = mysql_custom_query($sql);
       /*
       $sql = "DELETE FROM `users_favorites` WHERE (`users_id1`='".mv($aObj['users_id'])."' AND `users_id2`='".mv($LUser['id'])."') OR (`users_id2`='".mv($aObj['users_id'])."' AND `users_id1`='".mv($LUser['id'])."')";
       $res = mysql_custom_query($sql);*/
       /***/
       
       $sql = "INSERT INTO `users_blocks` (`users_id1`, `users_id2`) VALUES ('".mv($LUser['id'])."', '".mv($aObj['users_id'])."');";
       $res = mysql_custom_query($sql);

       done_json("ok", "result");
      }
     
     if($aObj['todo'] == 'unblock'){
       if($xs == 0)done_json("You are not blocking '".$aObj['users_id']."'");
       $sql = "DELETE FROM `users_blocks` WHERE `users_id1`='".mv($LUser['id'])."' AND `users_id2`='".mv($aObj['users_id'])."'";
       $res = mysql_custom_query($sql);
       done_json("ok", "result");
      }
 	
 	done_json("ok", "result");
 	
  }
  /* api function end */
  
  function does_user_follow($users_id1, $users_id2){

   if ($users_id1 == "" || $users_id1 == '0' || $users_id2 == "" || $users_id2 == '0') return '-';
	
   $sql = "SELECT COUNT(*) FROM `users_followers` WHERE `users_id1`='".mv($user_id1)."' AND `users_id2`='".mv($user_id2)."'";
   $res = mysql_custom_query($sql);
   $xs = mysql_result($res, 0, 0);
	
   return $xs;
 }
 
 function does_user_block($users_id1, $users_id2){

   if ($users_id1 == "" || $users_id1 == '0' || $users_id2 == "" || $users_id2 == '0') return '-';
	
   $sql = "SELECT COUNT(*) FROM `users_blocks` WHERE `users_id1`='".mv($users_id1)."' AND `users_id2`='".mv($users_id2)."'";
   $res = mysql_custom_query($sql);
   $xs = mysql_result($res, 0, 0);
	
   return $xs;
 }
 
	/* api function begin  
	   $aTmpObj['access_token'] = 'xxx';
	  */
	function api_instagram_login($aObj, $LUser){
		
	   if($aObj['access_token'] == "")done_json("access_token is empty!");
		   
		  $json = execute_curl_request("https://api.instagram.com/v1/users/self/?access_token=".$aObj['access_token']);
		  
		  //$json = '{"data": {"id": "1574083","username": "snoopdogg","full_name": "Snoop Dogg","profile_picture": "http://distillery.s3.amazonaws.com/profiles/profile_1574083_75sq_1295469061.jpg","bio": "This is my bio","website": "http://snoopdogg.com","counts": {"media": 1320,"follows": 420,"followed_by": 3410}}';
		  $aData = json_decode($json, true);
		  
		  if($aData['meta']['code'] != 200)done_json($aData);
		  
		  $aData = $aData['data'];
		  
		  /*
		  $aData = array();
		  $aData['id'] = "1574083";
		  $aData['username'] = "snoopdogg";
		  $aData['full_name'] = "Snoop Dogg";
		  $aData['profile_picture'] = "http://localhost/ClickIn/upload/brand-header-simple.png";
		  */
		  if ($aData['id']!= ""){
			  
			  $sql = "SELECT * FROM `users` WHERE `instagram_id`='".mv($aData['id'])."'";
			$res = mysql_custom_query($sql);
			if(mysql_num_rows($res) == 0){
				$aTmpObj = array();
				$aTmpObj['email'] = "-";
				$aTmpObj['flname'] = $aData['full_name'];
				$aTmpObj['checked_instagram_id'] = $aData['id'];
				$aTmpObj['password'] = rand(0, 999999).'_'.$aData['id'].'_'.rand(0, 999999);;
				
		 $sql2 = "SELECT COUNT(*) FROM `users` WHERE `username`='".mv(makeSeo($aData['username']))."'";
		 $res2 = mysql_query($sql2) or die(mysql_error());
		 $xs = mysql_result($res2, 0, 0);
		 if(mysql_num_rows($res2) == 0){
			 $aTmpObj['username'] = makeSeo($aData['username']);
		  }
				
				if($aData['profile_picture'] != ""){
					 prepare_file_ppic_from_url($aData['id'], $aData['profile_picture'], "inst");
				  }
				
				api_register_user($aTmpObj, array(), true);
			 }else{
			   $row=mysql_fetch_assoc($res);
			   social_network_login_by_row($row, $LUser);
			  }
			  
		  }else{
			  done_json("can't get user id!");
		  }
		 
		  done_json("something wrong!");
	 }
	 
	 /* api function end */
	
	
	/* api function begin  
		   $aTmpObj['email'] = 'halcyon.third@gmail.com';
		   $aTmpObj['password'] = 'halcyon.third';
	  */ 


	  function api_twitter_login($aObj, $LUser){
		global $PassSalt, $RootDir, $consumer_key, $consumer_secret;
	
	 if($aObj['twitter_access_token'] != "" && $aObj['twitter_access_token_secret'] != "" && $consumer_key != "" && $consumer_secret != "")
		{
		  done_json("disabled!");
		  include $RootDir.'/lib/EpiCurl.php';
		  include $RootDir.'/lib/EpiOAuth.php';
		  include $RootDir.'/lib/EpiTwitter.php';
	
		  $twitterObj = new EpiTwitter($consumer_key, $consumer_secret);
		  $twitterObj->setToken($aObj['twitter_access_token'],  $aObj['twitter_access_token_secret']);
		  $twitterObj->response;
			
		  $status = $twitterObj->httpRequest('GET', 'https://api.twitter.com/1.1/account/verify_credentials.json');
		  $status->response;
		  $aData = json_decode($status->data);
		  if($aData->id_str != ""){
			  
			  
		$sql = "SELECT `user_id` FROM `twitter_tokens` WHERE `twitter_id`='".mv($aData->id_str)."'";
		$res = mysql_custom_query($sql);
		if (mysql_num_rows($res)){
		   //$user_id=mysql_result($res,0,0);
		   $sql = "UPDATE `twitter_tokens` SET 
		   `token` = '".mv($aObj['twitter_access_token'])."', `token_secret` = '".mv($aObj['twitter_access_token_secret'])."',
			   `name` = '".mv($aData->name)."', `last_login` = NOW(),
			   `link` = 'http://twitter.com/".mv($aData->screen_name)."'
		   WHERE `twitter_id` = '".mv($aData->id_str)."'";
		  }else{
			$sql = "INSERT INTO `twitter_tokens` (`user_id` , `token` , `token_secret` , `twitter_id`,
			 `name`, `last_login`, `link`
			 )  VALUES (
			 '0', '".mv($aObj['twitter_access_token'])."', '".mv($aObj['twitter_access_token_secret'])."', '".mv($aData->id_str)."',
			 '".mv($aData->name)."', NOW(), 'http://twitter.com/".mv($twitterInfo->screen_name)."');";
		   }
			  $res = mysql_custom_query($sql);
			  
			$sql = "SELECT * FROM `users` WHERE `twitter_id`='".mv($aData->id_str)."'";
			$res = mysql_custom_query($sql);
			if(mysql_num_rows($res)){
			  $row=mysql_fetch_assoc($res);
			  $row = manage_user_row($row, $LUser, '0');
				
			  if($aObj['device_token'] != "" && $aObj['device_token'] != $row['device_token']){
				$sql = "UPDATE `users` SET `device_token` = '".mv($aObj['device_token'])."' WHERE `id`='".mv($row['id'])."'";
				$res = mysql_custom_query($sql);
				$row['device_token'] = $aObj['device_token'];
			   }
			   
			  $_SESSION['user'] = new User();
			  $_SESSION['user']->CreateUserObject("", $row);
			  $row = manage_user_row($row, $LUser, '0');
	
			  done_json($row, 'result');
				
			}else{
				
		$aTmpObj['flname'] = $aData->name;
		  $aTmpObj['password'] = rand(0, 999999).'_'.$aData->id_str.'_'.rand(0, 999999);;
		  $aTmpObj['bio'] = $aData->description;
		  $aTmpObj['web_link'] = 'http://twitter.com/'.$aData->screen_name;
		  $aTmpObj['twitter_id'] = $aData->id_str;
		  $aTmpObj['location'] = $aData->location;
		  $aTmpObj['device_token'] = $aObj['device_token'];
		  //$aTmpObj['email'] = 'twtmp_'.$aData->id_str.'_id'.time().'@slabo.com';
		  
		   $sql2 = "SELECT COUNT(*) FROM `users` WHERE `username`='".mv($aData->screen_name)."'";
		 $res2 = mysql_query($sql2) or die(mysql_error());
		 $xs = mysql_result($res2, 0, 0);
		 if(mysql_num_rows($res2) == 0){
			 $aTmpObj['username'] = $aData->screen_name;
		 }else{
			 //$aTmpObj['username'] = 'twtmp_'.$aData->id_str.'_id'.time();
		 }
				
		  //print_r($aData);exit;
		  
			 if($aData->profile_image_url != ""){
				prepare_file_ppic_from_url($aData->id_str, $aData->profile_image_url, "tw");
			}
			
		   api_register_user($aTmpObj, array(), true);
	
		  }
		  echo $status->data;
		  exit;
			
		}
	  }
	  done_json("something wrong!");
	}
	 /* api function end */
	
	 
 
 /************/
 
 /* api function begin  
   	$aTmpObj['twitter_access_token'] = 'xxx';
   	$aTmpObj['twitter_access_token_secret'] = 'yyy';
  */ 

   	 
?>
