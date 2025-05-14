<?php 

  function my_mail($email, $subject, $message, $headers = '', $vars = array()){
  	
  	global $smarty, $RootDir, $LocalHost, $ProjectName;
  	
  if($headers == ''){
    $headers = 'From: admin@halcyon.com'."\r\n".
     'Content-type: text/html; charset=UTF-8'."\r\n".
    'X-Mailer: PHP/' . phpversion();
   }
    
   if($vars['plain_txt'] != 'plain_txt'){
     $smarty->assign('body', $message);
     $smarty->assign('vars', $vars);
	 $message = $smarty->fetch($RootDir."/templates/mail.tpl");
    }
	
	//echo "test: ".mail("halcyon.third@gmail.com", "Test email!", "Just a little test.");
	
    if ($LocalHost){
    	file_put_contents($RootDir.'/_tmp/'.makeSeo($email.'-'.$subject).".html", $message);
     }else{
  	  // mail($email, $subject, $message, $headers);//exit;
  	  
require($RootDir."/PHPMailer_5.2.1/class.phpmailer.php");
$mail = new PHPMailer();
$mail->IsSMTP();  // telling the class to use SMTP
$mail->Host = "smtp.gmail.com"; // SMTP server
$mail->From = "halcyon.third@gmail.com";
$mail->FromName = $ProjectName;
$mail->AddAddress($email);
$mail->Subject  = $subject;
$mail->Body     = $message;
$mail->WordWrap = 50;
//$mail->SMTPDebug  = 2;   
$mail->SMTPAuth = true;    
$mail->SMTPSecure = "tls";    
$mail->Username = "halcyon.third@gmail.com"; // SMTP account username
$mail->Password = "h@lcy0n1"; // SMTP account password
$mail->IsHTML(true);
return $mail->Send();

     }
  	
  }


?>
