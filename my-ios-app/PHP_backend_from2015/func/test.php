<?php

 	 require($RootDir.'/lib/stripe/Stripe.php');
 	 Stripe::setApiKey($StripeApiKey);
 	 /*
 	 $aTest = Stripe_Balance::retrieve();
 	 
 	 print_r($aTest);
 	 exit;*/
 	 
 try { 	
// Create a transfer to the specified recipient
$transfer = Stripe_Transfer::create(array(
  "amount" => 300, // amount in cents
  "currency" => "usd",
  "recipient" => "rp_15mMLwHAEXK6soQmaWB9Kpwm",
  "statement_descriptor" => "JULY SALES")
);
} catch (Exception $e) {
	$message = $e->getMessage();
	echo $message;exit;
}

print_r($transfer);exit;


//"bank_account" => $bank_account_id,




?>