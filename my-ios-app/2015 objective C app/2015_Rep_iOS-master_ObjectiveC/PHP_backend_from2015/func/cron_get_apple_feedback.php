<?php
 

 if (!isset($V[1]) || $V[1] == ''){
   $RootDir = "/var/www/html";//
   include($RootDir."/config.php");
   include($RootDir."/lib/project.php");
   include($RootDir."/lib/functions.php");
   include($RootDir."/lib/media.php");
   include($RootDir."/lib/mail.php");
   include($RootDir."/lib/api_users.php");
   require $RootDir.'/lib/Smarty.class.php';
   //require $RootDir.'/lib/S3Content.class.php';
   $smarty = new Smarty;
 }
 
 $cron_filename = "cron_get_apple_feedback.php";
 cron_log_end($cron_filename, 512);
 
 
 tmp_log("cron_start!");
 
 
	$apnsHost = 'gateway.push.apple.com';
	$apnsPort = 2196;

	$streamContext = stream_context_create();
	stream_context_set_option($streamContext, 'ssl', 'local_cert', $RootDir.'/func/'.$apnsCert);
	
	
	$apns = stream_socket_client('ssl://'.$apnsHost.':'.$apnsPort, $error, $errorString, 60, STREAM_CLIENT_CONNECT, $streamContext);
	if ($apns === FALSE) {
		//tmp_log("Error: $error, $errorString\n");
		print "Error: $error, $errorString\n";
		exit(0);
	}
	
	
	$aTokens = array();
	//and read the data on the connection:
	while(!feof($apns)) {
		$data = fread($apns, 38);
		if(strlen($data)) {
			$aTokens[] = unpack("N1timestamp/n1length/H*devtoken", $data);
		}
	}
	fclose($apns);
	
	if(count($aTokens)){
		$aUpdate = array();
		foreach($aTokens as $key => $val){
			if(trim($val['devtoken']) == '')continue;
			$aUpdate[$val['devtoken']] = "'".mvs($val['devtoken'])."'";
		 }
		
		if(count($aUpdate)){
		  $sql = "UPDATE `users` SET `device_token_active` = 0 WHERE `device_token` IN (".implode(", ", $aUpdate).")";
		  echo $sql;
		  $res = mysql_custom_query($sql);
		 }
		
	}else{
		echo '*empty*';
	}
   
   
 cron_log_end($cron_filename);
 tmp_log("DONE!");
 echo '<br><br>DONE!';
 exit;
 
 
 

?>