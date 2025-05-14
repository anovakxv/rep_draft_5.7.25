<?php


	$appBundle = "com.hinter.Hinter";
	$apnsCert = "apple_push_notification_production.pem";
	$RootDir = '/var/www/html';

echo 'DONE '.send_notification_alerts_new("f0eb9f63673b386d5ba5a38abb5467ba3a15b89a73ff9eb67db399b2ba09cbd9", 1, "Test Message ".rand(0, 599), "", "", "0", "default");

exit;





function send_notification_alerts_new($token, $badge = 1, $message = "", $action_loc_key = "", $type = "", $id = "", $sound = "default"){
	global $RootDir;
	$streamContext = stream_context_create();

	$apnsHost = 'gateway.push.apple.com';
	$apnsPort = 2195;
	$apnsCert = 'apple_push_notification_production.pem';


	stream_context_set_option($streamContext, 'ssl', 'local_cert', $RootDir.'/func/'.$apnsCert);
	//stream_context_set_option($streamContext, 'tls', 'local_cert', $RootDir.'/func/'.$apnsCert2);
	//stream_context_set_option($streamContext, 'ssl', 'local_cert', '/etc/ssl/certs/Entrust.net_Premium_2048_Secure_Server_CA.pem');
	
	
	$apns = stream_socket_client('ssl://'.$apnsHost.':'.$apnsPort, $error, $errorString, 60, STREAM_CLIENT_CONNECT, $streamContext);
	if ($apns === FALSE) {
		//tmp_log("Error: $error, $errorString\n");
		print "Error: $error, $errorString\n";
		exit(0);
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
	//tmp_log("just wrote " . $payload);
	// Close the connection
	fclose($apns);

}







/*
$img = imagecreatetruecolor(1216, 640);
$bg = imagecolorallocate ( $img, 255, 255, 255 );
imagefilledrectangle($img,0,0,1216,640,$bg);
imagejpeg($img,$RootDir."/_tmp_myimg.jpg", 100);
*/


$photo_to_paste=$RootDir."/_tmp/38bc81eac0f6b37472a491e3e2927b6e.jpg";  //image 321 x 400

$im = imagecreatetruecolor(1216, 640);
$bg = imagecolorallocate ( $im, 255, 255, 255 );
imagefilledrectangle($im,0,0,1216,640,$bg);

$condicion = GetImageSize($photo_to_paste); // image format?

if($condicion[2] == 1) //gif
	$im2 = imagecreatefromgif("$photo_to_paste");
if($condicion[2] == 2) //jpg
	$im2 = imagecreatefromjpeg("$photo_to_paste");
if($condicion[2] == 3) //png
	$im2 = imagecreatefrompng("$photo_to_paste");



imagecopy($im, $im2, (imagesx($im)/2)-(imagesx($im2)/2), (imagesy($im)/2)-(imagesy($im2)/2), 0, 0, imagesx($im2), imagesy($im2));

imagejpeg($im,$RootDir."/_tmp/myimg.jpg",90);
imagedestroy($im);
imagedestroy($im2);





echo 'Check: <img style="border:1px solid gray" src="'.$RootDomain."/_tmp/myimg.jpg".'">';
exit;

//1216x640



echo md5($PassSalt."Realitypunch").'<br>';
echo md5($PassSalt."realitypunch").' <= Gotta be<br>';
echo md5("Realitypunch").'<br>';
echo md5("realitypunch").'<br>';
echo md5("Realitypunch ").'<br>';
echo md5("realitypunch ").'<br>';
echo md5($PassSalt."Realitypunch ").'<br>';
echo md5($PassSalt."realitypunch ").'<br>';
exit;

$bitly = new bitly('halcyonthird', 'R_53789d8c6dfa7e320b95d96d93b84e2a');
$data = $bitly->shorten("http://google.com", true);

print_r($data);exit;
exit;
/************/


 $sql = "SELECT COUNT(*) FROM `admins`";
 $res = query_to_db($sql);
 $count = mysql_result($res, 0, 0);
 echo 'GOT:'.$count;exit;
 
 
echo my_mail("halcyon.user@gmail.com", "test", "my cool message");

echo 'ok!';
exit;


$data = '{"1":{"id":"1","categories_id":"0","goal":"0","got_points":"0","percent":0},"2":{"id":"2","categories_id":"0","goal":"0","got_points":"0","percent":0},"3":{"id":"3","categories_id":"0","goal":"0","got_points":0,"percent":0}}';

$aXS = json_decode($data);

print_r($aXS);exit;

?>