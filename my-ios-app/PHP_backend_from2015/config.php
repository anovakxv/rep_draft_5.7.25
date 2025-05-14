<?php
if(!isset($_GET['dbg']) || $_GET['dbg'] != '768') error_reporting(0);

 $PassSalt = "123454532f";
 $SkipSlashes = 2;
 $RootDomain = 'http://localhost/gravity';
 $RootDir = 'C:\xampp\htdocs\gravity';
 $LocalHost = true;
 $ProjectName = "Gravity";
 $PublicTestApi = true;

$dbHost = "localhost";
$dbBase = "gravity";
$dbUser = "root";
$dbPass = "";
$MYSQL_RES = mysql_connect($dbHost,$dbUser,$dbPass) OR DIE("Error of connection");
mysql_query("SET NAMES UTF8MB4");
mysql_select_db($dbBase) or die(mysql_error());
session_start();


	$S3_awsAccessKey = '';
	$S3_awsSecretKey = '/pyxG';
	$S3_bucketName = "";
	
	
	$StripeApiKey = "sk_live_GirzUAcXEQjoTKDgqfohVfxI"; //- production

//twitter
$consumer_key = "";
$consumer_secret = "";


//api_get_activities, cron_send_alerts
$aGActivitiesTables = array();
$aGActivitiesTables["listings"] = true;
$aGActivitiesTables["listings_comments"] = true;



$apnsHost = 'gateway.push.apple.com';
$apnsPort = 2195;
$apnsCert = 'apple_push_notification_production.pem';


?>