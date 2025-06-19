<?php

 $table = "skills";
 //$table = "categories";
 
 
 //UPDATE `locations` SET `lat` = 53.5500 + RAND() + RAND(), `lng` = 2.4333-RAND()-RAND(), `radius` = FLOOR(RAND(2)*20)

 $content = file_get_contents($RootDomain.'/_tmp/'.$table.'.txt');
 
 if($_GET['todo'] == 'TRUNCATE'){
   $sql = "TRUNCATE `".$table."`";
   $res = mysql_query($sql) or die(mysql_error());
  }

 $aData = explode("\r\n", $content);
 $aLastParents = array();
 $aCategories = array();
 foreach($aData as $key => $val){

 	if(trim($val) == "")continue;
 	$parent_id = 0;
 	
 	for($c = 5; $c >= 0; $c--){
 	  if(trim(substr($val, 0, $c)) == ""){
 		 $parent_id = isset($aLastParents[$c-1])?$aLastParents[$c-1]:0;
 		 
 		 break;
 	   }
 	 }
 	 
 	$sql = "INSERT INTO `".$table."` (`title`, `parent`) VALUES ('".mvs(trim($val))."', '".$parent_id."')";
	$res = mysql_query($sql) or die(mysql_error());
	$aLastParents[$c] = mysql_insert_id();
  }
  
  echo 'DONE!';

?>