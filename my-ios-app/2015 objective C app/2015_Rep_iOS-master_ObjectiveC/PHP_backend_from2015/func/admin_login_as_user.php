<?php

 if($_SESSION['ALogged'] == ""){
 	e404();
 }

if($V[2] == ""){
 	echo 'User ID is empty!';exit;
 }
 
 $sql = "SELECT * FROM `users` WHERE `id`='".mv($V[2])."'";
 $res = mysql_query($sql) or die(mysql_error());
 if(mysql_num_rows($res)){
 	$row=mysql_fetch_assoc($res);
 	$_SESSION['user'] = new User();
 	$_SESSION['user']->CreateUserObject("", $row, "full");
 	go($RootDomain.'/myprofile/');
 }else{
 	echo "that user doesn't exist!";
 	exit;
 }
 
 
 
?>