<?php
//new_follower, new_media_comment

 if (!isset($V[1]) || $V[1] == ''){
   $RootDir = "/var/www/html";//
   include($RootDir."/config.php");
   include($RootDir."/lib/project.php");
   include($RootDir."/lib/functions.php");
   include($RootDir."/lib/media.php");
   include($RootDir."/lib/mail.php");
   include($RootDir."/lib/api_users.php");
   include($RootDir."/lib/api_files.php");
   include($RootDir."/lib/api_portal.php");
   include($RootDir."/lib/api_other.php");
   include($RootDir."/lib/api_payments.php");
   include($RootDir."/lib/api_braintreep.php");
   include($RootDir."/lib/api_goals.php");
   
   require $RootDir.'/lib/Smarty.class.php';
   //require $RootDir.'/lib/S3Content.class.php';
   $smarty = new Smarty;
 }
 

 $sql = "SELECT * FROM `cron_log` WHERE `name`='cron_send_alerts.php'";
 $res = mysql_query($sql) or die(mysql_error());
 if(mysql_num_rows($res)){
 	$row=mysql_fetch_assoc($res);
 	if(time() - $row['lastnote'] > 3600 || $_GET['todo'] == 'run_anyway'){
 		$sql = "DELETE FROM `cron_log` WHERE `name` = 'cron_send_alerts.php';";
 		$res = mysql_query($sql) or die(mysql_error());
 	}else{
 		echo 'CRON IS ALREADY EXECUTING...  <a href="'.$RootDomain.'/func/cron_send_alerts/?todo=run_anyway">run anyway</a>';
 		exit;
 	}
 }
 
 
 $sql = "INSERT INTO `cron_log` (`name`, `lastnote`) VALUES ('cron_send_alerts.php', '".time()."');";
 $res = mysql_query($sql) or die(mysql_error());
 
 
 tmp_log("cron_start!");
 
 
 for($_c_main = 0; $_c_main < 10; $_c_main++){
 
 
 /*
   $sql = "DELETE FROM `alerts` WHERE `date_read` > 0 AND `date_read` < ".(time() - 60*60);
   $res = mysql_query($sql) or die(mysql_error());
 */
 
 	
 $sql = "SELECT `id` FROM `activities` WHERE `push` = 1 AND `push_sent_date` = '0000-00-00 00:00:00' ORDER BY `id` DESC LIMIT 0, 1";
 $res = mysql_query($sql) or die(mysql_error());
 if(mysql_num_rows($res)){
 	
 	
 	$local_apns = true;
 	$streamContext = stream_context_create();
 	stream_context_set_option($streamContext, 'ssl', 'local_cert', $RootDir.'/func/'.$apnsCert);
 	
 	$apns = stream_socket_client('ssl://'.$apnsHost.':'.$apnsPort, $error, $errorString, 60, STREAM_CLIENT_CONNECT, $streamContext);
 	if ($apns === FALSE) {
 		tmp_log("Error: $error, $errorString\n");
 		print "Error: $error, $errorString\n";
 		echo $RootDir.'/func/'.$apnsCert;exit;
 		exit(0);
 	}
 	
 	 $last_id = mysql_result($res, 0, 0);

 	 $TaskPriceCache = array();
  
 	//$sql = "SELECT a.*, COUNT(*) AS c, u.`device_token` FROM `alerts` as a, `users` as u WHERE a.`sent` = 0 AND a.`users_id2` = u.`id` AND a.`id` <= '".($last_id)."' GROUP BY a.`users_id2`";
 	$sql = "SELECT a.*, u.`device_token` FROM `activities` as a, `users` as u WHERE u.`device_token_active` = 1 AND a.`push` = 1 AND a.`push_sent_date` = '0000-00-00 00:00:00' AND a.`users_id2` = u.`id` AND a.`id` <= '".($last_id)."'";
 	$res = mysql_query($sql) or die(mysql_error());
 	$aData = array();
 	if(mysql_num_rows($res)){
  	while($row=mysql_fetch_assoc($res)){
  		 if($row['device_token'] == "")continue;
  		 $row['c'] = 1;
  	
  	 	 $sql22 = "SELECT COUNT(*) FROM `activities` WHERE `read`='0' AND `users_id2` = '".$row['users_id2']."'";
     	 $res22 = mysql_query($sql22) or die(mysql_error());
     	 $row['c'] = mysql_result($res22, 0, 0);
	     if($row['c'] == 0)continue;
		  	/*
		  	if($row['c'] > 1){
		  		$message = "You have ".$row['c']." new alerts!";
		  	}else{*/
		  		$sender_flname = "";
		  		
		  		   $sql22 = "SELECT `fname`, `lname` FROM `users` WHERE `id`='".$row['users_id1']."'";
		   		   $res22 = mysql_query($sql22) or die(mysql_error());
		   		   if(mysql_num_rows($res22)){
		   		   	 $sender_flname = mysql_result($res22, 0, 0).' '.mysql_result($res22, 0, 1);
		   		    }
		  		 

		   		    
		  		$aMessagesTxt['new_follower'] = 'You have a new follower'.(($sender_flname != "")?": ":"").$sender_flname.'!';
		  		$aMessagesTxt['new_direct_message'] = 'You have one new message.';
		  		$aMessagesTxt['new_goal_invite'] = 'New goal invite.';
		  		$aMessagesTxt['quota_is_reached'] = 'Quota is reached.';
		  		$aMessagesTxt['goal_invite_declined'] = 'Goal invite declined.';
		
		  		
		  		$message = isset($aMessagesTxt[$row['type']])?$aMessagesTxt[$row['type']]:'You have 1 new alert!';
		  	  //}
		  	  
		  	  
		  	 $action_loc_key = "";
		  	 if($row['type'] == 'new_follower' || $row['type'] == 'new_tasks_comment'){
		  	 	$action_loc_key = "View";
		  	  }
		  	  
		  	  
		  	 $send_id = $row['id'];
		  	 if($row['type'] == 'new_direct_message'){
		  	 	$send_id = $row['users_id1'];
		  	  }
		  	  
		  	 $sound = ($row['sound'] == "1")?"default":"0";
		     send_notification_alerts_new($apns, $row['device_token'], $row['c'], $message, $action_loc_key, $row['type'], $send_id, $sound);
		  	
		   }
		   
		   
		   
		   
		    $sql = "UPDATE `activities` SET `push_sent_date` = NOW() WHERE `id` <= '".($last_id)."' AND `push` = 1";
		    $res = mysql_query($sql) or die(mysql_error());
		    
		   /*
		    $sql = "DELETE FROM `alerts` WHERE `id` <= '".($last_id)."'";
		    $res = mysql_query($sql) or die(mysql_error());
		    */
		 }
 
 
  }else{
 	  tmp_log("All alerts already sent!");
 	  echo 'All alerts already sent';
   }
 
 
   sleep(5);
   
 }//for
   
   
 $sql = "DELETE FROM `cron_log` WHERE `name` = 'cron_send_alerts.php';";
 $res = mysql_query($sql) or die(mysql_error());
 tmp_log("DONE!");
 echo '<br><br>DONE!';
 exit;
 
 
 
 

 function send_notification_alerts_new($apns, $token, $badge = 1, $message = "", $action_loc_key = "", $type = "", $id = "", $sound = "default"){
 	global $RootDir;
 	$streamContext = stream_context_create();
    
 	$local_apns = false;
 	
 	if ($apns == "new") {
 	
 		$local_apns = true;
 		$streamContext = stream_context_create();
 		stream_context_set_option($streamContext, 'ssl', 'local_cert', $RootDir.'/func/'.$apnsCert);
 	
 		$apns = stream_socket_client('ssl://'.$apnsHost.':'.$apnsPort, $error, $errorString, 60, STREAM_CLIENT_CONNECT, $streamContext);
 		if ($apns === FALSE) {
 			tmp_log("Error: $error, $errorString\n");
 			print "Error: $error, $errorString\n";
 			exit(0);
 		}
 		 
 	}


// You can access the errors using the variables $error and $errorString
if($message == '')$message = 'You have 1 new alert!';

$data = file_get_contents($RootDir.'/_tmp/push_msgs.log');
$data .= "\r\n".$token.': '.$message.' ('.date("F j, Y, g:i a").')';
file_put_contents($RootDir.'/_tmp/push_msgs.log', $data);
/*return;
exit;*/
 
// Now we need to create JSON which can be sent to APNS

if($action_loc_key != ""){
	$message = array('body' => $message, 'action-loc-key' => $action_loc_key);
 }


$load = array(
            'aps' => array(
                'alert' => $message,
                'badge' => (int)$badge,
                'sound' => 'default'
            ),
            'type' => $type,
            'id' => $id
        );
$payload = json_encode($load);
 
// The payload needs to be packed before it can be sent
$apnsMessage = chr(0) . chr(0) . chr(32);
$apnsMessage .= pack('H*', str_replace(' ', '', $token));
$apnsMessage .= chr(0) . chr(strlen($payload)) . $payload;
 
// Write the payload to the APNS
fwrite($apns, $apnsMessage);
echo "just wrote " . $payload;
tmp_log("just wrote " . $payload);
// Close the connection
 
  if($local_apns){
     fclose($apns);
   }
 	
 }



?>
