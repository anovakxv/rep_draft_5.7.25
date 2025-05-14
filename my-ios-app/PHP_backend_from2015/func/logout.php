<?php
 
   unset($_SESSION['user']);
     setcookie("upd", "", 0, "/");
     setcookie("uid", "", 0, "/");
   if(!empty($V[2])){
   	 go($RootDomain.'/'.$V[2]);
    }
   
   home();
   
?>