<?php

 if($_POST['admin_timezone_select'] != "" && $_SESSION['ALogged']){
 	$_SESSION['admin_timezone'] = $_POST['admin_timezone_select'];
 }

 go_back($RootDomain."/admin");
 
?>
