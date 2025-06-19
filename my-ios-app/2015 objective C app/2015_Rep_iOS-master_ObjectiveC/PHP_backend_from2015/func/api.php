<?php


if($_POST['todo'] == 'update_note' && $_POST['function'] != ""){
	
 	$sql = "SELECT `id` FROM `api_functions_md5` WHERE `name`='".mv($_POST['function'])."'";
    $res = mysql_query($sql) or die(mysql_error());
    if(mysql_num_rows($res)){
     	$sql = "UPDATE `api_functions_md5` SET `note`='".mvs($_POST['note'])."' WHERE `name`='".mv($_POST['function'])."'";
      }else{
 		$sql = "INSERT INTO `api_functions_md5` (`name` ,`md5` ,`note`) VALUES ('".mvs($_POST['function'])."', '".mvs($_POST['md5'])."', '".mvs($_POST['note'])."');";
      }
     $res = mysql_query($sql) or die(mysql_error());
 	go_back($RootDomain.'/test_api');
	
}

 if($_GET['todo'] == 'mark_as_tested' && $_GET['function'] != ""){
 	//unset($_SESSION['api_tpls'][$_GET['function']]);
 	
 	 $sql = "SELECT `id` FROM `api_functions_md5` WHERE `name`='".mv($_GET['function'])."'";
     $res = mysql_query($sql) or die(mysql_error());
     if(mysql_num_rows($res)){
     	$sql = "UPDATE `api_functions_md5` SET `md5`='".mvs($_GET['md5'])."' WHERE `name`='".mv($_GET['function'])."'";
      }else{
 		$sql = "INSERT INTO `api_functions_md5` (`name` ,`md5` ,`note`) VALUES ('".mvs($_GET['function'])."', '".mvs($_GET['md5'])."', '');";
       }
     $res = mysql_query($sql) or die(mysql_error());
 	go_back($RootDomain.'/test_api');
 }
 
  if($_GET['todo'] == 'mark_as_tested_all'){
 	//unset($_SESSION['api_tpls'][$_GET['function']]);
 	if(empty($_SESSION['aApiFunctions']))done_json("session is empty!");
 	
 	 $sql = "DELETE FROM `api_functions_md5`";
     $res = mysql_query($sql) or die(mysql_error());

     $aSQLs = array();
     foreach($_SESSION['aApiFunctions'] as $key => $val){
     	 $aSQLs[] = "('".mvs($val)."', '-')";
     	
     }
     
     if(count($aSQLs)){
       $sql = "INSERT INTO `api_functions_md5` (`name` ,`md5`) VALUES ".implode(", ", $aSQLs).";";
       $res = mysql_query($sql) or die(mysql_error());
      }
     
     
 	go_back($RootDomain.'/test_api');
 }
 
   if($_GET['todo'] == 'mark_as_untested_all'){
 	//unset($_SESSION['api_tpls'][$_GET['function']]);
 	if(empty($_SESSION['aApiFunctions']))done_json("session is empty!");
 	
 	 $sql = "DELETE FROM `api_functions_md5`";
     $res = mysql_query($sql) or die(mysql_error());
     
     
 	go_back($RootDomain.'/test_api');
 }
 
 
 if($_GET['todo'] == 'clear_session' && $_GET['function'] != ""){
 	unset($_SESSION['api_tpls'][$_GET['function']]);
 	go_back($RootDomain.'/test_api');
 }

 $json = $_POST['json'];
 if($json == ""){
   done_json("json is empty!");
 }
 
 $aObj = json_decode($json, true);
 
 
 if($_POST['__save_to_session']){
 	$_SESSION['api_tpls'][$_POST['function']] = $json;
 }

 if ($_POST['function'] != "" && substr($_POST['function'], 0, 4) == 'api_' && function_exists($_POST['function'])){
    $LUser = ($_SESSION['user']->id != "")?(array) $_SESSION['user']:array();
    if(isset($LUser['data']) && !isset($LUser['id']))$LUser = $LUser['data'];
 	call_user_func($_POST['function'], $aObj, $LUser);
 }else{
 	 done_json("Something wrong with '".$_POST['function']."'");
 }


 
?>