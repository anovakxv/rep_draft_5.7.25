<?php

/* api function begin
  $aTmpObj['name'] = 'Lorem ipsum';
  $aTmpObj['subtitle'] = 'SubTitle';
  $aTmpObj['about'] = 'Consectetuer adipiscing elit';
  $aTmpObj['categories_id'] = '2';
  $aTmpObj['cities_id'] = '2';
  $aTmpObj['lead_id'] = '';
  $aTmpObj['aLeadsIDs'][0] = '1';
  $aTmpObj['aLeadsIDs'][1] = '2';
  $aTmpObj['aTexts'][0]['title'] = 'Dolor sit';
  $aTmpObj['aTexts'][0]['text'] = 'Dolor sit #amet, consectetuer adipiscing elit, sed diam #nonummy nibh euismod tincidunt ut laoreet #dolore magna aliquam erat volutpat.';
  $aTmpObj['aTexts'][1]['title'] = 'Another title';
  $aTmpObj['aTexts'][1]['text'] = 'Another text';
  $aTmpObj['aSections'][0]['title'] = 'New Section';
  $aTmpObj['aSections'][0]['indexes'] = '0,1';//aMultipleFiles[0], aMultipleFiles[1]...
  $aTmpObj['aSections'][1]['title'] = 'Another Section';
  $aTmpObj['aSections'][1]['indexes'] = '2,3';//aMultipleFiles[2], aMultipleFiles[3]...
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
*/

function api_create_portal($aObj, $LUser){
	global $RootDir, $RootDomain, $foursquare_client_key, $foursquare_client_secret;

	if($LUser['id'] == '')done_json("Login error!");
	if($aObj['name'] == '')done_json("name required!");
	
	
	$sql = "SELECT COUNT(*) FROM `users` WHERE `users_types_id`= 1 AND `id`='".mv($LUser['id'])."'";
	$res = mysql_custom_query($sql);
	if(mysql_result($res, 0, 0) == 0)done_json("Only Lead Users may Add/Edit Partners");
	
	if($aObj['lead_id'] != ''){
		$sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['lead_id'])."' AND `users_types_id` = 1";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_result($res, 0, 0) == 0)done_json("Wrong lead_id");
	 }
	
	if($aObj['users_types_id'] != "")check_existance_by_id("users_types", $aObj['users_types_id']);
	if($aObj['cities_id'] != "")check_existance_by_id("cities", $aObj['cities_id']);
	if($aObj['categories_id'] != "")check_existance_by_id("categories", $aObj['categories_id']);
	
	
	$aInsert = array();
	$aInsert["`users_id`"] = "'".mv($LUser['id'])."'";
	$aInsert["`lead_id`"] = "'".mvs($aObj['lead_id'])."'";
	$aInsert["`name`"] = "'".mvs($aObj['name'])."'";
	$aInsert["`subtitle`"] = "'".mvs($aObj['subtitle'])."'";
	$aInsert["`categories_id`"] = "'".mv($aObj['categories_id'])."'";
	$aInsert["`cities_id`"] = "'".mv($aObj['cities_id'])."'";
	$aInsert["`about`"] = "'".mvs($aObj['about'])."'";
		
	$sql = "INSERT INTO `portals` (".implode(", ", array_keys($aInsert)).")VALUES (".implode(", ", $aInsert).");";
	$res = mysql_query($sql) or die(mysql_error());
	$portals_id = mysql_insert_id();
	
	
	
	$aObj2 = array();
	$aObj2['portals_id'] = $portals_id;
	$aObj2['aLeadsIDs'] = $aObj['aLeadsIDs'];
	$aObj2['aTexts'] = $aObj['aTexts'];
	$aObj2['aSections'] = $aObj['aSections'];
	api_edit_portal($aObj2, $LUser);

	done_json($aLog, "result");

}
/* api function end */


function check_portal_editor_permission($user_id, $portals_id){
	
	$sql = "SELECT `users_id` FROM `portals` WHERE `id`='".mv($portals_id)."'";
	//echo $sql;exit;
 	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	if(mysql_num_rows($res)){
 	   $owner_id = mysql_result($res, 0, 0);
 	 }else{
 	 	done_json("the portal doesn't exist!");
 	  }
 	
 	  if($owner_id != $user_id){
 	  	$sql = "SELECT COUNT(*) FROM `portals_users` WHERE `users_id`='".mv($user_id)."' AND `portals_id`='".mv($aObj['portals_id'])."' AND `leader` = 1";
 	  	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	  	if(mysql_result($res, 0, 0) == 0)done_json("503");
 	   }
 	   
 	   return $owner_id;
 }
 
 /* api function begin
  $aTmpObj['aBasket'][1] = '1';//[products_id] -> count
  $aTmpObj['aBasket'][3] = '7';
  $aTmpObj['aBasket'][5] = '2';
  $aTmpObj['__return_result'] = '';//1
 */
 function api_basket_checkout($aObj, $LUser){
 	global $RootDomain, $RootDir, $StripeApiKey;
 	
 	if($LUser['id'] == '')done_json("Login error!");
 	if(!is_array($aObj['aBasket']) || count($aObj['aBasket']) == 0)done_json("aBasket is empty or wrong");
 	
 	
 	$sql = "SELECT `stripe_customer_id` FROM `users_payment_cards` WHERE `user_id`='".mv($LUser['id'])."' AND `stripe_customer_id` <> '' ORDER BY `id` DESC LIMIT 0, 1";
 	$res = mysql_custom_query($sql);
 	if(mysql_num_rows($res)){
 	  $stripe_customer_id = mysql_result($res, 0, 0);
 	 }else{
 	 	done_json("stripe customer id is empty");
 	  }
 	/*
 	foreach($aObj['aBasket'] as $type => $aGoodsIDs){
 		if(!is_array($aGoodsIDs) || count($aGoodsIDs) == 0)continue;
 		
 		if($type == 'aProducts'){*/
 	  
 	  		 $aGoodsIDs = array_keys($aObj['aBasket']);
 			
 			 $aIDs = check_existance_by_ids("products", $aGoodsIDs);
 			
 			 if(count($aIDs)){
 			 	
 			 	
 			 	$sql = "SELECT `id`, `price` FROM `products` WHERE `id` IN (".implode(", ", $aIDs).")";
 			 	$res = mysql_custom_query($sql);
 			 	$aProducts = array();
 			 	if(mysql_num_rows($res)){
 			 		while($row=mysql_fetch_assoc($res)){
 			 			$aProducts[$row['id']] = $row['price'];
 			 		 }
 			 	 }
 			 	 
 			 	 
 			 	 $transaction_id = "";
 			 	 $aPPr = array();
 			 	 if(count($aProducts)){
 			 	 	foreach($aProducts as $products_id => $price){
 			 	 	  if($price <= 0)$price = 0;
 			 	 	  $price = $price*$aObj['aBasket'][$products_id];
 			 	 	  $aPPr[$products_id] = $price;
 			 	 	 }
 			 	  }else{
 			 	 	 done_json("nothing to buy");
 			 	   }
 			 	 
 			 	//print_r($aPPr);exit;
 			 	
 			 	
 			   $aPP = array();
 			   $sql = "SELECT `id` as products_id, `portals_id` FROM `products` WHERE `id` IN (".implode(", ", $aIDs).")";
 			   $res = mysql_query($sql) or die(mysql_error());
 			   if(mysql_num_rows($res)){
 			   	 while($row=mysql_fetch_assoc($res)){
 			   	 	if(!isset($aPP[$row['portals_id']]))$aPP[$row['portals_id']] = 0;
 					$aPP[$row['portals_id']] += $aPPr[$row['products_id']];
 			   	   }
 			     }else{
 			    	continue;
 			      }
 			     
 			      
 			      //print_r($aPP);exit;
 			     
 			     $final_amount_to_pay = array_sum($aPPr);
 			     if($final_amount_to_pay > 0){
 			     	if($final_amount_to_pay >= 10000)done_json("Please message a Lead Rep for Offering trasnactions over $10,000");
 			     	
 			     	
 			     	
   			       //real transaction goes here
   			       
 			     	require($RootDir.'/lib/stripe/Stripe.php');
 			     	Stripe::setApiKey($StripeApiKey);
 			     	
 			     	try {
 			     		
 			     		$charge = Stripe_Charge::create(array(
 			     				"amount"   => $final_amount_to_pay*100, # $15.00 this time
 			     				"currency" => "usd",
 			     				"customer" => $stripe_customer_id)
 			     		);
 			     		
 			     		
 			     		//} catch(Stripe_CardError $e) {
 			     	  } catch (Exception $e) {
 			     		 $message = $e->getMessage();
 			     		 done_json($message);
 			     	   }
 			     	   
 			     	   if($charge->id != ""){
 			     	   	 $transaction_id = $charge->id ;
 			     	   }else{
 			     	    	done_json($charge);
 			     	    }
 			       
 			      }else{
 			     	 done_json("final_amount_to_pay = 0");
 			       }
 			     
 			     
 			     if($transaction_id != ""){
 			     	
 			     	
 			     	foreach($aPP as $portals_id => $amount){
 			     		$portals_transactions_id = log_new_portal_transaction($LUser['id'], $portals_id, $amount, "basket_checkout");
 			     	 }
 			     	
 			     	
 			     	
 			     	
 			     	$sql = "SELECT `id`, `portals_id` FROM `goals` WHERE `portals_id` IN (SELECT `portals_id` FROM `products` WHERE `id` IN (".implode(", ", $aIDs).")) AND `goal_types_id` = 1";
 			     	//echo $sql;exit;
 			     	$res = mysql_query($sql) or die(mysql_error());
 			     	if(mysql_num_rows($res)){
 			     		while($row=mysql_fetch_assoc($res)){
 			     			$aObj2 = array();
 			     			$aObj2['goals_id'] = $row['id'];
 			     			$aObj2['added_value'] = $aPP[$row['portals_id']];
 			     			log_goal_progress($LUser['id'], $aObj2, "sales");
 			     		}
 			     	}
 			      }
 			     
 			     
 			    
 			  }
 			/*
 		 }
 		
 	  }*/
 	
 	done_json("ok", "result");
 	
  }
 /* api function end */
  
  
  function log_new_portal_transaction($users_id, $portals_id, $amount, $key){
  	

  	$sql = "INSERT INTO `portals_transactions` (`users_id`, `portals_id`, `amount`, `key`) VALUES 
  			('".mv($users_id)."', '".mv($portals_id)."', '".mv($amount)."', '".mvs($key)."')";
  	$res = mysql_custom_query($sql);
  	$portals_transactions_id = mysql_insert_id();
  	
  	return $portals_transactions_id;
  	
  }
 
 
 
 /* api function begin
  $aTmpObj['aGroupHash'][0] = '';
  $aTmpObj['aGroupHash'][1] = '';
  $aTmpObj['__return_result'] = '';//1
 */
 function api_delete_portal_graphic($aObj, $LUser){
 	
 	if($LUser['id'] == '')done_json("Login error!");
 	if(!is_array($aObj['aGroupHash']) || count($aObj['aGroupHash']) == 0)done_json("aGroupHash is empty or wrong");
 	
 	$aToDB = array();
	foreach($aObj['aGroupHash'] as $key => $val){
		$val = trim($val);
		if($val == '')continue;
		$aToDB[$val] = "'".mvs($val)."'";
	}

	
	
	if(count($aToDB)){
		$sql = "SELECT `tbl_id` FROM `s3_content` WHERE `gr_hash` IN (".implode(", ", $aToDB).") AND `tbl_index` = 6 GROUP BY `gr_hash`";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				$aData[] = $row['tbl_id'];
			 }
		 }
		if(count($aData) != count($aToDB))done_json("Not all hashes are actual portals_graphic_sections files (".count($aData)." != ".count($aToDB).")");
	 }else{
		done_json("aIDs is empty");
	  }
 	
	  
	if(count($aData)){
	  
	  $sql = "SELECT pgs.`portals_id` FROM `portals_graphic_sections` as pgs WHERE pgs.`id` IN (".implode(", ", $aData).") GROUP BY pgs.`portals_id`";
	 // echo $sql;exit;
	  $res = mysql_query($sql) or die(mysql_error());
	  $aData = array();
	  if(mysql_num_rows($res)){
	  	while($row=mysql_fetch_assoc($res)){
	  		check_portal_editor_permission($LUser['id'], $row['portals_id']);
	  	 }
	   }
	  
	 }
	 
 		
	 $aS3IDs = array();
	 $sql = "DELETE FROM `portals_graphic_sections_s3_content` WHERE `s3_gr_hash` IN (".implode(", ", $aToDB).")";
 	 $res = mysql_query($sql) or die(mysql_error());

 	 $sql = "SELECT `id` FROM `s3_content` WHERE `gr_hash` IN (".implode(", ", $aToDB).")";
 	 $res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	 if(mysql_num_rows($res)){
 	 	while($row=mysql_fetch_assoc($res)){
 	 		 $S3Obj = new S3Content("0");
 	 	     $S3Obj->load($row['id']);
 	 	     $S3Obj->delete();
 	 	  }
 	  }else{
 	 	done_json("0 files for the gr_hash");
 	   }
 	 
 	   
 	 if($aObj['__return_result'] == '1')return array_keys($aToDB);
 	 done_json(array_keys($aToDB), "result");
  }
 /* api function end */
  
  
  
  /* api function begin
   $aTmpObj['aPGSIDs'][0] = '1';
   $aTmpObj['aPGSIDs'][1] = '2';
   $aTmpObj['__return_result'] = '';//1
  */
  function api_delete_portal_graphic_sections($aObj, $LUser){
  
  	if($LUser['id'] == '')done_json("Login error!");
  	if(!is_array($aObj['aPGSIDs']) || count($aObj['aPGSIDs']) == 0)done_json("aGroupHash is empty or wrong");
  
  	$aToDB = check_existance_by_ids("portals_graphic_sections", $aObj['aPGSIDs']);
  
  	if(count($aToDB)){
  			
  		$sql = "SELECT `portals_id` FROM `portals_graphic_sections` WHERE `id` IN (".implode(", ", $aToDB).")";
  		$res = mysql_query($sql) or die(mysql_error());
  		$aData = array();
  		if(mysql_num_rows($res)){
  			while($row=mysql_fetch_assoc($res)){
  				check_portal_editor_permission($LUser['id'], $row['portals_id']);
  			}
  		}
  			
  	 }else{
  		done_json('aToDB is empty (aPGSIDs is wrong)');
  	  }
  	
  	
  	  
  	  $sql = "SELECT `gr_hash` FROM `s3_content` WHERE `tbl_index` = 6 AND `tbl_id` IN (".implode(", ", $aToDB).") GROUP BY `gr_hash`";
  	  $res = mysql_query($sql) or die(mysql_error());
  	  $aFinalHash = array();
  	  if(mysql_num_rows($res)){
  	  	while($row=mysql_fetch_assoc($res)){
  	  		$aFinalHash[] = "'".$row['gr_hash']."'";
  	  	 }
  	   }
  	  
 		
	 $aS3IDs = array();
	 $sql = "DELETE FROM `portals_graphic_sections_s3_content` WHERE `portals_graphic_sections_id` IN (".implode(", ", $aToDB).")";
 	 $res = mysql_query($sql) or die(mysql_error());
 	 
 	 $sql = "DELETE FROM `portals_graphic_sections` WHERE `id` IN (".implode(", ", $aToDB).")";
 	 $res = mysql_query($sql) or die(mysql_error());
 	 
 	 if(count($aFinalHash)){

 	   $sql = "SELECT `id` FROM `s3_content` WHERE `gr_hash` IN (".implode(", ", $aFinalHash).")";
 	   $res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	   if(mysql_num_rows($res)){
 	 	while($row=mysql_fetch_assoc($res)){
 	 		 $S3Obj = new S3Content("0");
 	 	     $S3Obj->load($row['id']);
 	 	     $S3Obj->delete();
 	 	  }
 	    }else{
 	 	  done_json("0 files for the gr_hash");
 	     }
 	   }
 	   
 	 if($aObj['__return_result'] == '1')return $aFinalHash;
 	 done_json($aFinalHash, "result");
 	 
  }
  /* api function end */
 
 
 
 /* api function begin
  $aTmpObj['portals_id'] = '1';
  $aTmpObj['aSections'][0]['id'] = '';
  $aTmpObj['aSections'][0]['title'] = 'New Section';
  $aTmpObj['aSections'][0]['indexes'] = '0,1';//aMultipleFiles[0], aMultipleFiles[1]...
  $aTmpObj['aSections'][1]['id'] = '';
  $aTmpObj['aSections'][1]['title'] = 'Another Section';
  $aTmpObj['aSections'][1]['indexes'] = '2,3';//aMultipleFiles[2], aMultipleFiles[3]...
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $aTmpObj['__return_result'] = '';//1
 */
 function api_add_portal_graphic_sections($aObj, $LUser){
 	
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['portals_id'] == "")done_json("portals_id required!");
 	
 	$aInsertSQL = array();
 	$owner_id = check_portal_editor_permission($LUser['id'], $aObj['portals_id']);
 	$portals_graphic_sections_id = 0;
 	
 	if(!is_array($aObj['aSections']) || count($aObj['aSections']) == 0)done_json("aSections is empty or wrong!");
 	$aLog = array();
 	foreach($aObj['aSections'] as $key => $val){
 		
 		
 		$portals_graphic_sections_id = "";
 		if($val['id'] != ""){
 			$sql = "SELECT `id` FROM `portals_graphic_sections` WHERE `id`='".mvs($val['id'])."' AND `portals_id` = '".mv($aObj['portals_id'])."'";
 			$res = mysql_query($sql) or die(mysql_error());
 			if(mysql_num_rows($res)){
 				$portals_graphic_sections_id = mysql_result($res, 0, 0);
 			}else{
 				$aLog[$key] = 'portals_graphic_sections_id: 404 or 503';
 				continue;
 			}
 		}
 		
 		 
 		if($portals_graphic_sections_id == ""){
 			$sql = "INSERT INTO `portals_graphic_sections` (`title`, `portals_id`) VALUES ('".mvs($val['title'])."', '".mv($aObj['portals_id'])."')";
 			$res = mysql_query($sql) or die(mysql_error());
 			$portals_graphic_sections_id = mysql_insert_id();
 		}elseif($val['title'] != ''){
 			$sql = "UPDATE `portals_graphic_sections` SET `title`='".mvs($val['title'])."' WHERE `id` = '".$portals_graphic_sections_id."'";
 			$res = mysql_query($sql) or die(mysql_error());
 		}
 		
 		
 		if($val['indexes'] == ''){
 			$aLog[$key] = 'indexes is empty';
 			continue;
 		 }
 		 
 		   $aSources = array();
 		   $aSourcesNotes = array();
 		   $aFilesIndexes = explode(",", $val['indexes']);
 		   if(count($aFilesIndexes) == 0){
 			  $aLog[$key] = 'comma separated string is wrong';
 			  continue;
 		    }
 		   
 		    
 		   foreach ($aFilesIndexes as $key22 => $val22){
 		     	$aSources[] = $val22;
 		     	$aSourcesNotes[] = 'portal_file';
 		     }
 		        
 		   
 		      $aLog[$key]['aFiles'] = add_s3_files_to_a_table($portals_graphic_sections_id, 6, $aSources, $aSourcesNotes, 0);
 		      $aLog[$key]['portals_graphic_sections_id'] = $portals_graphic_sections_id;
 		      

 		      if(is_array($aLog[$key]['aFiles']) && count($aLog[$key]['aFiles'])){
 		      	 foreach($aLog[$key]['aFiles'] as $file_key => $aFLog){
 		      	 	if($aFLog['s3_content_ids'][0]['gr_hash'] != "")$aInsertSQL[] = "('".$portals_graphic_sections_id."', '".mvs($aFLog['s3_content_ids'][0]['gr_hash'])."')";
 		      	  }
 		       }
 		   
 		 }
 		 
 		 
 		 if(count($aInsertSQL)){
 		 	$sql = "INSERT INTO `portals_graphic_sections_s3_content` (`portals_graphic_sections_id`, `s3_gr_hash`) VALUES ".implode(", ", $aInsertSQL);
 		 	$res = mysql_query($sql) or die(mysql_error());
 		 }
 		
 		 
    if($aObj['__return_result'] == "1")return $aLog;
 	done_json($aLog, "result");
 	
 }
 /* api function end */
 
 
 
 /* api function begin
  $aTmpObj['portals_id'] = '1';
    $aTmpObj['__return_result'] = '';//1
 */
 function api_get_portal_graphic_sections($aObj, $LUser){
 
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['portals_id'] == "")done_json("portals_id required!");
 
 	$sql = "SELECT * FROM `portals_graphic_sections` WHERE `portals_id` = '".mv($aObj['portals_id'])."'";
 	$res = mysql_query($sql) or die(mysql_error());
 	$aPGS = array();
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			
 			$row['aFiles'] = get_s3_files(6, $row['id']);
 			
 			$aPGS[] = $row;
 		 }
 	  }
 		
 	if($aObj['__return_result'] == "1")return $aPGS;
 	done_json($aPGS, "result");
 
 }
 /* api function end */
 
 

/* api function begin
  $aTmpObj['portals_id'] = '1';
  $aTmpObj['name'] = 'Lorem ipsum';
  $aTmpObj['subtitle'] = 'SubTitle';
  $aTmpObj['about'] = 'Consectetuer adipiscing elit';
  $aTmpObj['categories_id'] = '2';
  $aTmpObj['cities_id'] = '2';
  $aTmpObj['lead_id'] = '1';
  $aTmpObj['aLeadsIDs'][0] = '1';
  $aTmpObj['aLeadsIDs'][1] = '2';
  $aTmpObj['aTexts'][0]['title'] = 'Dolor sit';
  $aTmpObj['aTexts'][0]['text'] = 'Dolor sit #amet, consectetuer adipiscing elit, sed diam #nonummy nibh euismod tincidunt ut laoreet #dolore magna aliquam erat volutpat.';
  $aTmpObj['aTexts'][1]['title'] = 'Another title';
  $aTmpObj['aTexts'][1]['text'] = 'Another text';
  $aTmpObj['aSections'][0]['title'] = 'New Section';
  $aTmpObj['aSections'][0]['indexes'] = '0,1';//aMultipleFiles[0], aMultipleFiles[1]...
  $aTmpObj['aSections'][1]['title'] = 'Another Section';
  $aTmpObj['aSections'][1]['indexes'] = '2,3';//aMultipleFiles[2], aMultipleFiles[3]...
  $aTmpObj['aDeleteGraphicGroupHashes'][0]='';
  $aTmpObj['aDeleteGraphicGroupHashes'][1]='';
  $aTmpObj['aDeletePGSIDs'][0] = '1';
  $aTmpObj['aDeletePGSIDs'][1] = '2';
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
  $input_file[] = "aMultipleFiles[]";
*/
 function api_edit_portal($aObj, $LUser){
 	
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['portals_id'] == "")done_json("portals_id required!");
 	
 	if($aObj['lead_id'] != ''){
 		$sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['lead_id'])."' AND `users_types_id` = 1";
 		$res = mysql_query($sql) or die(mysql_error());
 		if(mysql_result($res, 0, 0) == 0)done_json("Wrong lead_id");
 	}
 	
 	
    $owner_id = check_portal_editor_permission($LUser['id'], $aObj['portals_id']);
 	  
 	if($aObj['users_types_id'] != "")check_existance_by_id("user_types", $aObj['users_types_id']);
 	if($aObj['cities_id'] != "")check_existance_by_id("cities", $aObj['cities_id']);
 	if($aObj['categories_id'] != "")check_existance_by_id("categories", $aObj['categories_id']);
 	
 	$aLog = array();
 	
 	
 	if(is_array($aObj['aDeleteGraphicGroupHashes']) && count($aObj['aDeleteGraphicGroupHashes']) > 0){
 		$aObj2 = array();
 		$aObj2['aGroupHash'] = $aObj['aDeleteGraphicGroupHashes'];
 		$aObj2['__return_result'] = '1';
 		$aLog['aDeletedGraphicSectionGroupHashes'] = api_delete_portal_graphic($aObj2, $LUser);
 	 }
 	 
 	 if(is_array($aObj['aDeletePGSIDs']) && count($aObj['aDeletePGSIDs']) > 0){
 	 	$aObj2 = array();
 	 	$aObj2['aPGSIDs'] = $aObj['aDeletePGSIDs'];
 	 	$aObj2['__return_result'] = '1';
 	 	$aLog['aDeletedPGSIDs'] = api_delete_portal_graphic_sections($aObj2, $LUser);
 	 }
 	
 	
 	$aUpdateFields = array();
 	$aAuoUpdateColumns = array('name', 'subtitle', 'categories_id', 'cities_id', 'about', 'lead_id');
 	 
 	if(count($aAuoUpdateColumns)){
 		foreach($aAuoUpdateColumns as $key => $val){
 			if($aObj[$val] != "")$aUpdateFields[] = " `".$val."`='".mvs($aObj[$val])."' ";
 		}
 	}

 	if(count($aUpdateFields)){
 		$sql = "UPDATE `portals` SET ".implode(", ", $aUpdateFields)." WHERE `id`='".mv($aObj['portals_id'])."';";
 		$res = mysql_query($sql) or die(mysql_error());
 		$aLog['portals_fields'] = mysql_affected_rows();
 	 }
 	
 	
 	 if(is_array($aObj['aSections']) && count($aObj['aSections'])){
	    $aObj2 = array();
	    $aObj2['portals_id'] = $aObj['portals_id'];
	    $aObj2['aSections'] = $aObj['aSections'];
	    $aObj2['__return_result'] = '1';
	    $aLog['aFiles'] = api_add_portal_graphic_sections($aObj2, $LUser);
 	  }
 	
 	 
 	 if(isset($aObj['aTexts'])){
 	 	
 	 	$sql = "DELETE FROM `portals_texts` WHERE `portals_id`='".mv($aObj['portals_id'])."'";
 	 	$res = mysql_query($sql) or die(mysql_error());
 	 	
 	 	if(is_array($aObj['aTexts']) && count($aObj['aTexts'])){
 	 	  $aSQLs = array();
 	 	  foreach($aObj['aTexts'] as $key => $val){
 	 		 $text = trim($val['text']);
 	 		 $title = trim($val['title']);
 	 		 if($text == "" && $title == "")continue;
 	 		 $couple_hash = md5($title.$text);
 	 		 $aSQLs[$couple_hash] = "('".mv($aObj['portals_id'])."', '".mvs($title)."', '".mvs($text)."')";
 	 	   }
 	 	
 	 	  if(count($aSQLs)){
 	 	    $sql = "INSERT INTO `portals_texts` (`portals_id`, `title`, `text`) VALUES ".implode(", ", $aSQLs);
 	 	    $res = mysql_query($sql) or die(mysql_error());
 	 	    $aLog['portals_texts_new'] = mysql_affected_rows();
 	 	   }
 	 	 }
 	  }
 	  
 	  
 	  
 	 if(count($aObj['aLeadsIDs'])){
 	 	
 	 	$aObj['aLeadsIDs'] = array_unique($aObj['aLeadsIDs']);
 	 	 
 	 	 
 	 	$aToDB = array();
 	 	foreach($aObj['aLeadsIDs'] as $key => $val){
 	 		$val = trim($val);
 	 		if($val == '')continue;
 	 		$aToDB[$val] = "'".mv($val)."'";
 	 	}
 	 	
 	 if(count($aToDB)){
 	 	$sql = "SELECT COUNT(*) FROM `users` WHERE `id` IN (".implode(", ", $aToDB).")";
 	 	$res = mysql_query($sql) or die(mysql_error());
 	 	$xs = mysql_result($res, 0, 0);
 	 	if($xs == count($aToDB)){
 	 		
 	 		
 	 		$sql = "DELETE FROM `portals_users` WHERE `portals_id` = '".mv($aObj['portals_id'])."' AND `users_id` IN (".implode(", ", $aToDB).")";
 	 		$res = mysql_query($sql) or die(mysql_error().": ".$sql);
 	 		
 	 		$aSQLs = array();
 	 		foreach($aToDB as $key => $val){
 	 			if($val == "")continue;
 	 			$aSQLs[] = "(".$val.", '".mv($aObj['portals_id'])."', 1)";
 	 		}
 	 		
 	 		if(count($aSQLs)){
 	 			$sql = "INSERT INTO `portals_users` (`users_id`, `portals_id`, `leader`) VALUES ".implode(", ", $aSQLs);
 	 			$res = mysql_query($sql) or die(mysql_error());
 	 			$aLog['portals_users_new'] = mysql_affected_rows();
 	 		 }
 	 		 
 	 		
 	 	}else{
 	 		$aLog['portals_users_new'] = "some ids of aLeadsIDs are wrong (".$xs." != ".count($aToDB['aLeadsIDs']).")";
 	 	 }
 	  }
 	 	
 	 	

 	  }
 	

 	  $sql = "SELECT COUNT(*) FROM `portals_users` WHERE `portals_id`='".mv($aObj['portals_id'])."'";
 	  $res = mysql_custom_query($sql);
 	  $users_count = mysql_result($res, 0, 0);
 	  
 	  $sql = "UPDATE `portals` SET `_c_users_count` = '".$users_count."' WHERE `id`='".mv($aObj['portals_id'])."'";
 	  $res = mysql_custom_query($sql);
 	  
 	  
 	  api_portal_details($aObj, $LUser);
 	  done_json($aLog, "result");
  }
  
  /* api function end */
  
  
  /* api function begin
   $aTmpObj['portals_id'] = '1';
  */
  function api_portal_details($aObj, $LUser){
  	 if($LUser['id'] == '')done_json("Login error!");
  	 if($aObj['portals_id'] == "")done_json("portals_id required!");
  	 
  	 
  	 $aUsers = array();
  	 $sql = "SELECT * FROM `portals` WHERE `id` = '".mv($aObj['portals_id'])."'";
  	 $res = mysql_query($sql) or die(mysql_error());
  	 if(mysql_num_rows($res)){
  	 	$aPortal=mysql_fetch_assoc($res);
  	 	$aUsers[$aPortal['users_id']] = $aPortal['users_id'];
  	  }else{
  	 	 done_json("the portal doesn't exist");
  	   }
  	 
  	 
  	  $aPortal = manage_portal_row($aPortal);  	 
  	  
  	 /***/

  	  $sql = "SELECT * FROM `goals` WHERE `portals_id` = '".mv($aPortal['id'])."' ORDER BY `id` DESC";
  	  $res = mysql_query($sql) or die(mysql_error());
  	  $aGoals = array();
  	  if(mysql_num_rows($res)){
  	  	while($row22=mysql_fetch_assoc($res)){
  	  		$aGoals[] = $row22;
  	  	}
  	  }
  	  
  	  $aPortal['aGoals'] = $aGoals;
  	 
  	 $sql = "SELECT * FROM `portals_users` WHERE `portals_id` = '".mv($aPortal['id'])."' ORDER BY `id` DESC";
  	 $res = mysql_query($sql) or die(mysql_error());
  	 $aPortalUsers = array();
  	 if(mysql_num_rows($res)){
  	 	while($row22=mysql_fetch_assoc($res)){
  	 		$aPortalUsers[] = $row22;
  	 		$aUsers[$row22['users_id']] = $row22['users_id'];
  	 	}
  	  }
  	 
  	 $aPortal['aPortalUsers'] = $aPortalUsers;
  	 
  	 $sql = "SELECT * FROM `portals_texts` WHERE `portals_id` = '".mv($aPortal['id'])."' ORDER BY `id` ASC";
  	 $res = mysql_query($sql) or die(mysql_error());
  	 $aTexts = array();
  	 if(mysql_num_rows($res)){
  	 	while($row22=mysql_fetch_assoc($res)){
  	 		$aTexts[] = $row22;
  	 	}
  	 }
  	 
  	 $aPortal['aTexts'] = $aTexts;
  	 
  	 
  	// $aPortal['aFiles'] = get_s3_files("2", $aPortal['id']);
	    $aObj2 = array();
	    $aObj2['portals_id'] = $aObj['portals_id'];
	    $aObj2['__return_result'] = '1';
  	  $aPortal['aSections'] = api_get_portal_graphic_sections($aObj2, $LUser);

  	 
  	 if(count($aUsers)){
  	 	$sql = "SELECT * FROM `users` WHERE `id` IN (".implode(", ", $aUsers).")";
  	 	$res = mysql_query($sql) or die(mysql_error());
  	 	$aUsers = array();
  	 	if(mysql_num_rows($res)){
  	 		while($row=mysql_fetch_assoc($res)){
  	 			$row = manage_user_row($row, $LUser);
  	 			$aUsers[] = $row;
  	 		}
  	 	}
  	  }
  	 
  	 
  	 $aPortal['aUsers'] = $aUsers;
 	 /*
 	 $aRet = array();
 	 $aRet
 	 $aRet['aPortal'] = $aPortal;*/
 	 
 	 done_json($aPortal, "result");
  	 
   }
  /* api function end */
   
   
   /* api function begin
    $aTmpObj['portals_id'] = '1';
    $aTmpObj['todo'] = 'share';//unshare
   */
   function api_portal_share_via_feed($aObj, $LUser){//via
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['portals_id'] == "")done_json("portals_id required!");
   	 
   	$sql = "SELECT COUNT(*) FROM `portals` WHERE `id` = '".mv($aObj['portals_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	if(mysql_result($res, 0, 0) == 0)done_json("the portal doesn't exist!");
   	
   	
   	$sql = "SELECT COUNT(*) FROM `portals_users_share` WHERE `portals_id` = '".mv($aObj['portals_id'])."' AND `users_id` = '".mv($LUser['id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	$shared = mysql_result($res, 0, 0);
   	
   	
   	if($aObj['todo'] == 'share'){
   		if($shared > 0)done_json("the portal share already exists!");
   		
   		$sql = "INSERT INTO `portals_users_share` (`portals_id`, `users_id`) VALUES ('".mv($aObj['portals_id'])."', '".mv($LUser['id'])."');";
   		$res = mysql_query($sql) or die(mysql_error());

   		$sql = "SELECT `id` FROM `goals` WHERE `portals_id`='".mv($aObj['portals_id'])."' AND `goal_types_id` = 2";
   		$res = mysql_query($sql) or die(mysql_error());
 		if(mysql_num_rows($res)){
   			while($row=mysql_fetch_assoc($res)){
   					$aObj2 = array();
   					$aObj2['goals_id'] = $row['id'];
   					$aObj2['added_value'] = 1;
   					log_goal_progress($LUser['id'], $aObj2, "marketing");
    		  }
  		 }
   	  }
   	
   	 
   	  if($aObj['todo'] == 'unshare'){
   		if($shared == 0)done_json("the portal share doesn't exists!");
   		$sql = "DELETE FROM `portals_users_share` WHERE `portals_id` = '".mv($aObj['portals_id'])."' AND `users_id` = '".mv($LUser['id'])."'";
   		$res = mysql_query($sql) or die(mysql_error());

   		
   		$sql = "SELECT `id` FROM `goals` WHERE `portals_id`='".mv($aObj['portals_id'])."' AND `goal_types_id` = 2";
   		$res = mysql_query($sql) or die(mysql_error());
   		if(mysql_num_rows($res)){
   			while($row=mysql_fetch_assoc($res)){
   				delete_goal_progress_log($LUser['id'], $row['id'], "marketing");
   			}
   		}
      }

   	 
   	done_json("ok", "result");
   	 
   }
   /* api function end */
   
   
   
   /* api function begin
    $aTmpObj['portals_id'] = '1';
    $aTmpObj['aUsersIDs'][0] = '1';
    $aTmpObj['aUsersIDs'][1] = '2';
   */
   function api_portal_share_via_message($aObj, $LUser){//via
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['portals_id'] == "")done_json("portals_id required!");
   	if(!is_array($aObj['aUsersIDs']) || count($aObj['aUsersIDs']) == 0)done_json("aUsersIDs required!");
   	 
   	$sql = "SELECT COUNT(*) FROM `portals` WHERE `id` = '".mv($aObj['portals_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	if(mysql_result($res, 0, 0) == 0)done_json("the portal doesn't exist!");
   
    $aToDB = check_existance_by_ids("users", $aObj['aUsersIDs']);
   
    $aLog = array();
    if(count($aToDB)){
    	foreach($aToDB as $key => $val){
    		
    		$aObj2 = array();
    		$aObj2['users_id'] = $key;
    		$aObj2['message'] = 'I share a portal with you';
    		$aObj2['portals_id'] = $aObj['portals_id'];
    		$aObj2['__return_result'] = '1';
    		$aLog[$key] = api_send_message($aObj2, $LUser);
    		
    		$sql = "SELECT `id` FROM `goals` WHERE `portals_id`='".mv($aObj['portals_id'])."' AND `goal_types_id` = 2";
    		$res = mysql_query($sql) or die(mysql_error());
    		if(mysql_num_rows($res)){
    			while($row=mysql_fetch_assoc($res)){
    				$aObj2 = array();
    				$aObj2['goals_id'] = $row['id'];
    				$aObj2['added_value'] = 1;
    				log_goal_progress($LUser['id'], $aObj2, "marketing");
    			}
    		}
    	}
     }
    

   	 
   	done_json($aLog, "result");
   	 
   }
   /* api function end */
   
   
  
   
   /* api function begin
    $aTmpObj['products_id'] = '1';
   */
   function api_product_details($aObj, $LUser){
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['products_id'] == "")done_json("products_id required!");
   	 
   	 
   	$sql = "SELECT * FROM `products` WHERE `id` = '".mv($aObj['products_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	if(mysql_num_rows($res)){
   		$aProduct=mysql_fetch_assoc($res);
   	}else{
   		done_json("the product doesn't exist");
   	}
   	 
   	 
   	$aProduct = manage_product_row($aProduct);
   	$aProduct['aFiles'] = get_s3_files("4", $aProduct['id']);
   	 
   	done_json($aProduct, "result");
   	 
   }
   /* api function end */
   
   
   /* api function begin
    $aTmpObj['portals_id'] = '';
    $aTmpObj['todo'] = 'hide';//show
   */
   
   function api_hide_portal($aObj, $LUser){
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['portals_id'] == '')done_json("portals_id is empty!");
   	if($aObj['todo'] == '')done_json("todo is empty or wrong! Supported: hide, show");
   
   	$sql = "SELECT COUNT(*) FROM `portals` WHERE `id`='".mv($aObj['portals_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	$xs = mysql_result($res, 0, 0);
   	if($xs == 0)done_json("that portals_id doesn't exist!");
   
   	$sql = "SELECT COUNT(*) FROM `users_hidden_portals` WHERE `users_id`='".mv($LUser['id'])."' AND `portals_id`='".mv($aObj['portals_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	$xs = mysql_result($res, 0, 0);
   		
   	if($aObj['todo'] == 'hide'){
   		if($xs > 0)done_json("You are already hiding '".$aObj['portals_id']."'");
   
   		$sql = "INSERT INTO `users_hidden_portals` (`users_id`, `portals_id`) VALUES ('".mv($LUser['id'])."', '".mv($aObj['portals_id'])."');";
   		$res = mysql_query($sql) or die(mysql_error());
   			
   	}
   		
   	if($aObj['todo'] == 'show'){
   		if($xs == 0)done_json("You are not hiding '".$aObj['portals_id']."'");
   		$sql = "DELETE FROM `users_hidden_portals` WHERE `users_id`='".mv($LUser['id'])."' AND `portals_id`='".mv($aObj['portals_id'])."'";
   		$res = mysql_query($sql) or die(mysql_error());
   	}
   
   	done_json("ok", "result");
   }
   /* api function end */
   
   /* api function begin
    $aTmpObj['users_id'] = '';
    $aTmpObj['portals_id'] = '';
    $aTmpObj['cities_id'] = '';
    $aTmpObj['show_hidden'] = '1';//0
    $aTmpObj['limit'] = '50';//optional
    $aTmpObj['offset'] = '0';//optional
   */
   
   function api_get_shared_portals($aObj, $LUser){
   		
   	if($aObj['users_id'] == "")done_json("users_id is empty!");
   	$offset = (int)$aObj['offset'];
   	$limit = (int)$aObj['limit'];
   
   	if($limit == 0)$limit = 50;
   
   	if($offset < 0) done_json("offset is wrong!");
   	if($limit > 4096) done_json("limit should be <= 4096");
   		
   	$aConds = array();
   
   	$aConds[] = " pus.`portals_id`=p.`id` ";
   	$aConds[] = " pus.`users_id`='".mv($aObj['users_id'])."' ";
   		
   	if($aObj['show_hidden'] != "1" && $aObj['portals_id'] == ""){
   		$aConds[] = " p.`id`  NOT IN (SELECT `portals_id` FROM `users_hidden_portals` WHERE `users_id` = '".mv($LUser['id'])."') ";
   	}
   
   		
   	if($aObj['cities_id'] != ""){
   		$aConds[] = " p.`cities_id`  = '".mv($aObj['cities_id'])."' ";
   	}
   		
   	if($aObj['portals_id'] != ""){
   		$aConds[] = " p.`id`  = '".mv($aObj['portals_id'])."' ";
   	}
   
   
   	/*
   	 if($aObj['keyword'] != ""){
   	$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
   	}*/
   
   	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
   
   	$sql = "SELECT p.*, pus.`timestamp` as share_timestamp FROM `portals` as p, `portals_users_share` as pus ".$sql_cond." ORDER BY pus.`id` DESC LIMIT ".$offset.", ".$limit;
   	$res = mysql_query($sql) or die(mysql_error());
   	$aData = array();
   	if(mysql_num_rows($res)){
   		while($row=mysql_fetch_assoc($res)){
   			//$aData[] = $row;
   			$aData[] = manage_portal_row($row);
   		}
   	}
   		
   	done_json($aData, "result");
   		
   }
   /* api function end */
   
  
 /* api function begin
  $aTmpObj['users_id'] = '';
  $aTmpObj['portals_id'] = '';
  $aTmpObj['cities_id'] = '';
  $aTmpObj['home'] = '';//1,0 user created or in goal
  $aTmpObj['my_network'] = '';//1,0
  $aTmpObj['show_hidden'] = '1';//0
  $aTmpObj['limit'] = '50';//optional
  $aTmpObj['offset'] = '0';//optional
 */
 
 function api_get_portals($aObj, $LUser){
 		
 	$offset = (int)$aObj['offset'];
 	$limit = (int)$aObj['limit'];
 
 	if($limit == 0)$limit = 50;
 
 	if($offset < 0) done_json("offset is wrong!");
 	if($limit > 4096) done_json("limit should be <= 4096");
 		
 	$aConds = array();
 	
 	
 	if($aObj['home'] == "1"){
 		if($LUser['id'] == '' && $aObj['users_id'] == "")done_json("Login or users_id required!");
 		if($aObj['users_id'] == "")$aObj['users_id'] = $LUser['id'];
 		$aConds[] = " (`users_id`  = '".mv($aObj['users_id'])."' OR `id` IN (SELECT g.`portals_id` FROM `goals_team` as gt, `goals` as g WHERE g.`id` = gt.`goals_id` AND gt.`users_id2` = '".mv($aObj['users_id'])."' ORDER BY `users_id2` ASC  )) ";
 	 }elseif($aObj['users_id'] != ""){
 	   $aConds[] = " `users_id`  = '".mv($aObj['users_id'])."' ";
 	 }
 	 
 	   if($aObj['show_hidden'] != "1" && $aObj['portals_id'] == ""){
 	   	  $aConds[] = " `id`  NOT IN (SELECT `portals_id` FROM `users_hidden_portals` WHERE `users_id` = '".mv($LUser['id'])."') ";
 	    }

 	 if($aObj['keyword'] != ""){
                        $aConds[] = " LOWER(`name`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
                 }
                 

 	 if($aObj['cities_id'] != ""){
 	 	$aConds[] = " `cities_id`  = '".mv($aObj['cities_id'])."' ";
 	 }
 	 
 	 if($aObj['portals_id'] != ""){
 	 	$aConds[] = " `id`  = '".mv($aObj['portals_id'])."' ";
 	  }
 	  
 	 if($aObj['my_network'] != ""){
 	 	if($LUser['id'] == '')done_json("Login required when my_network is not null!");
 	 	
 	 	$sql_network1 = " `users_id` ".(($aObj['my_network'] != "1")?" NOT ":"")." IN (SELECT `users_id2` FROM `users_network` WHERE `users_id1` = '".mv($LUser['id'])."') ";
 	 	$sub_sql7wd = "SELECT pus.`portals_id` FROM `users_network` as un, `portals_users_share` as pus WHERE un.`users_id1` = '".mv($LUser['id'])."' AND pus.`users_id` = un.`users_id2`";
 	  	$sql_network2 = " `id` ".(($aObj['my_network'] != "1")?" NOT ":"")." IN (".$sub_sql7wd.") ";
 	  	
 	  	$aConds[] = " (".$sql_network1." OR ".$sql_network2.") ";
 	   }
 
 	  
 	/*
 	if($aObj['keyword'] != ""){
 		$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
 	}*/
 
 	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
 
 	$sql = "SELECT * FROM `portals` ".$sql_cond." ORDER BY `_c_users_count` DESC LIMIT ".$offset.", ".$limit;
 	$res = mysql_query($sql) or die(mysql_error());
 	$aData = array();
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			//$aData[] = $row;
 			$aData[] = manage_portal_row($row);
 		}
 	}
 		
 	done_json($aData, "result");
 		
 }
 /* api function end */
 
 
 
 /* api function begin
  $aTmpObj['users_id'] = '';
 $aTmpObj['portals_id'] = '';
 $aTmpObj['limit'] = '50';//optional
 $aTmpObj['offset'] = '0';//optional
 */
 
 function api_get_products($aObj, $LUser){
 		
 	$offset = (int)$aObj['offset'];
 	$limit = (int)$aObj['limit'];
 
 	if($limit == 0)$limit = 50;
 
 	if($offset < 0) done_json("offset is wrong!");
 	if($limit > 4096) done_json("limit should be <= 4096");
 		
 	$aConds = array();
 
 	if($aObj['users_id'] != ""){
 		$aConds[] = " `users_id`  = '".mv($aObj['users_id'])."' ";
 	}
 		
 	if($aObj['portals_id'] != ""){
 		$aConds[] = " `portals_id`  = '".mv($aObj['portals_id'])."' ";
 	}
 
 
 	/*
 	 if($aObj['keyword'] != ""){
 	$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
 	}*/
 
 	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
 
 	$sql = "SELECT * FROM `products` ".$sql_cond." ORDER BY `id` DESC LIMIT ".$offset.", ".$limit;
 	$res = mysql_query($sql) or die(mysql_error());
 	$aData = array();
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			$aData[] = manage_product_row($row);
 		}
 	}
 		
 	done_json($aData, "result");
 		
 }
 /* api function end */
 

 
 function manage_portal_row($row){
 	
 	$row['_c_file_max_640x640_url'] = "";
 	
 	
 	$sql = "SELECT `id` FROM `portals_graphic_sections` WHERE `portals_id`='".mv($row['id'])."'";
 	$res = mysql_query($sql) or die(mysql_error());
 	if(mysql_num_rows($res)){
 	  $portals_graphic_sections_id = mysql_result($res, 0, 0);
 	  
 	  $sql = "SELECT `url` FROM `s3_content` WHERE `key`='portal_file_max_640x640' AND `tbl_index` = 6 AND `tbl_id` = '".$portals_graphic_sections_id."' ORDER BY `id` ASC";
 	  $res = mysql_query($sql) or die(mysql_error());
 	  if(mysql_num_rows($res)){
 	  	$row['_c_file_max_640x640_url'] = mysql_result($res, 0, 0);
 	  }
 	  
 	 }
 	

 	
 	
 	return $row;
 	
  }
  
  
 function manage_product_row($row){
  
 	$row['_c_file_max_640x640_url'] = "";
 	
 	$sql = "SELECT `url` FROM `s3_content` WHERE `key`='file_max_640x640' AND `tbl_index` = 4 AND `tbl_id` = '".mv($row['id'])."' ";
 	//echo $sql;//exit;
 	$res = mysql_query($sql) or die(mysql_error());
 	if(mysql_num_rows($res)){
 		$row['_c_file_max_640x640_url'] = mysql_result($res, 0, 0);
 	}
 	
  	return $row;
  
  }

  
  /* api function begin
    $aTmpObj['portals_texts_id'] = '1';
  */
  
  function api_delete_portal_text($aObj, $LUser){
  	
  	if($LUser['id'] == '')done_json("Login error!");
  	if($aObj['portals_texts_id'] == '')done_json("portals_texts_id required!");
  	
  		$sql = "SELECT `portals_id` FROM `portals_texts` WHERE `id`='".mv($aObj['portals_texts_id'])."'";
  		$res = mysql_query($sql) or die(mysql_error());
  		if(mysql_num_rows($res)){
  		  $portals_id = mysql_result($res, 0, 0);
  		 }else{
  		 	done_json("the portal text doesn't exist!");
  		 }
  	
  	   $owner_id = check_portal_editor_permission($LUser['id'], $portals_id);
  	   
  	   $sql = "DELETE FROM `portals_texts` WHERE `id`='".mv($aObj['portals_texts_id'])."'";
  	   $res = mysql_query($sql) or die(mysql_error());
  	   done_json("ok", "result");
   }
  /* api function end */
   
   /* api function begin
    $aTmpObj['portals_users_id'] = '1';
   */
   
   function api_delete_portal_user($aObj, $LUser){
   	 
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['portals_users_id'] == '')done_json("portals_users_id required!");
   	 
   	$sql = "SELECT `portals_id` FROM `portals_users` WHERE `id`='".mv($aObj['portals_users_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	if(mysql_num_rows($res)){
   		$portals_id = mysql_result($res, 0, 0);
   	}else{
   		done_json("the portal user doesn't exist!");
   	}
   	 
   	$owner_id = check_portal_editor_permission($LUser['id'], $portals_id);
   
   	$sql = "DELETE FROM `portals_users` WHERE `id`='".mv($aObj['portals_users_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	
   	$sql = "SELECT COUNT(*) FROM `portals_users` WHERE `id`='".mv($portals_id)."'";
   	$res = mysql_custom_query($sql);
   	$users_count = mysql_result($res, 0, 0);
   	
   	$sql = "UPDATE `portals` SET `_c_users_count` = '".$users_count."' WHERE `id`='".mv($portals_id)."'";
   	$res = mysql_custom_query($sql);
   	
   	done_json("ok", "result");
   }
   /* api function end */
   
   
   /* api function begin
    $aTmpObj['portals_id'] = '1';
   */
    
   function api_delete_portal($aObj, $LUser){
   	 
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['portals_id'] == '')done_json("portals_id required!");
   	 
   	$owner_id = check_portal_editor_permission($LUser['id'], $aObj['portals_id']);
   
   	$res_log_txt = delete_db_row_and_related_data("portals", $aObj['portals_id']);
   
   	$aLog = array();
   	$aLog['log'] = $res_log_txt;
   	done_json("ok", "result");
   
   }
   /* api function end */
   
   
 
   
   /* api function begin
    $aTmpObj['products_id'] = '1';
   */
    
   function api_delete_product($aObj, $LUser){
   	 
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['products_id'] == '')done_json("products_id required!");
   	 
   	$sql = "SELECT `portals_id` FROM `products` WHERE `id`='".mv($aObj['products_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	if(mysql_num_rows($res)){
   		$portals_id = mysql_result($res, 0, 0);
   	}else{
   		done_json("the product doesn't exist!");
   	}
   	 
   	$owner_id = check_portal_editor_permission($LUser['id'], $portals_id);
   
   
   	$res_log_txt = delete_db_row_and_related_data("products", $aObj['products_id']);
   
   	$aLog = array();
   	$aLog['log'] = $res_log_txt;
   	done_json("ok", "result");
   }
   /* api function end */
   
   

   
  /* api function begin
   $aTmpObj['portals_id'] = '2';
   $aTmpObj['name'] = 'Dolor sit';
   $aTmpObj['subtitle'] = 'consectetuer adipiscing elit';
   $aTmpObj['description'] = 'Dolor sit #amet, consectetuer adipiscing elit, sed diam #nonummy nibh euismod tincidunt ut laoreet #dolore magna aliquam erat volutpat.';
   $aTmpObj['price'] = '12.55';
   $aTmpObj['aSources'][0] = '0';//aMultipleFiles[0]
   $aTmpObj['aSources'][1] = '1';//aMultipleFiles[1]; or url here
   $aTmpObj['aSourcesNotes'][0] = 'portal_file';
   $aTmpObj['aSourcesNotes'][1] = 'portal_file';
   $input_file[] = "aMultipleFiles[]";
   $input_file[] = "aMultipleFiles[]";
   */
    
   function api_create_product($aObj, $LUser){
   	global $RootDir, $RootDomain, $foursquare_client_key, $foursquare_client_secret;
   	 
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['name'] == '')done_json("name required!");
   	if($aObj['portals_id'] == '')done_json("portals_id required!");
   	if($aObj['description'] == '')done_json("description required!");
   	 
  // 	echo $aObj['portals_id'];exit;
   	$owner_id = check_portal_editor_permission($LUser['id'], $aObj['portals_id']);
   	
   	$sql = "SELECT `stripe_recipient_id` FROM `portals_bank_accounts` WHERE `portals_id`='".mv($aObj['portals_id'])."' AND `stripe_recipient_id` <> '' ORDER BY `id` DESC LIMIT 0, 1";
   	$res = mysql_custom_query($sql);
   	if(mysql_num_rows($res)){
   		$stripe_recipient_id = mysql_result($res, 0, 0);
   	}else{
   		done_json("Add a bank account to the portal first");
   	}
   	

   
   	$aInsert = array();
   	$aInsert["`users_id`"] = "'".mv($LUser['id'])."'";
   	$aInsert["`portals_id`"] = "'".mv($aObj['portals_id'])."'";
   	$aInsert["`subtitle`"] = "'".mv($aObj['subtitle'])."'";
   	$aInsert["`description`"] = "'".mvs($aObj['description'])."'";
   	$aInsert["`name`"] = "'".mvs($aObj['name'])."'";
   	$aInsert["`price`"] = "'".mv($aObj['price'])."'";
   	 
   	$sql = "INSERT INTO `products` (".implode(", ", array_keys($aInsert)).")VALUES (".implode(", ", $aInsert).");";
   	$res = mysql_query($sql) or die(mysql_error());
   	$products_id = mysql_insert_id();
   	 
   	$aObj2 = array();
   	$aObj2['products_id'] = $products_id;
   	$aObj2['aSources'] = $aObj['aSources'];
   	$aObj2['aSourcesNotes'] = $aObj['aSourcesNotes'];
   	api_edit_product($aObj2, $LUser);
   	 
   	done_json($aLog, "result");
   	 
   }
   /* api function end */
   
   
  /* api function begin
   $aTmpObj['products_id'] = '2';
   $aTmpObj['name'] = 'Dolor sit';
   $aTmpObj['subtitle'] = 'consectetuer adipiscing elit';
   $aTmpObj['description'] = 'Dolor sit #amet, consectetuer adipiscing elit, sed diam #nonummy nibh euismod tincidunt ut laoreet #dolore magna aliquam erat volutpat.';
   $aTmpObj['price'] = '12.55';
   $aTmpObj['aSources'][0] = '0';//aMultipleFiles[0]
   $aTmpObj['aSources'][1] = '1';//aMultipleFiles[1]; or url here
   $aTmpObj['aSourcesNotes'][0] = 'portal_file';
   $aTmpObj['aSourcesNotes'][1] = 'portal_file';
   $input_file[] = "aMultipleFiles[]";
   $input_file[] = "aMultipleFiles[]";
   */
   
   function api_edit_product($aObj, $LUser){
   	 
   	if($LUser['id'] == '')done_json("Login error!");
   	if($aObj['products_id'] == "")done_json("products_id required!");
   	 
   	$sql = "SELECT `portals_id` FROM `products` WHERE `id`='".mv($aObj['products_id'])."'";
   	$res = mysql_query($sql) or die(mysql_error());
   	if(mysql_num_rows($res)){
   		$portals_id = mysql_result($res, 0, 0);
   	}else{
   		done_json("parent portal doesn't exist!");
   	}
   	 
   	$owner_id = check_portal_editor_permission($LUser['id'], $portals_id);
   	 
   	$aLog = array();
   	 
   	$aUpdateFields = array();
   	$aAuoUpdateColumns = array('name', 'subtitle', 'description', 'price');
   	 
   	if(count($aAuoUpdateColumns)){
   		foreach($aAuoUpdateColumns as $key => $val){
   			if($aObj[$val] != "")$aUpdateFields[] = " `".$val."`='".mvs($aObj[$val])."' ";
   		}
   	}
   	 
   	if(count($aUpdateFields)){
   		$sql = "UPDATE `products` SET ".implode(", ", $aUpdateFields)." WHERE `id`='".mv($aObj['products_id'])."';";
   		$res = mysql_query($sql) or die(mysql_error());
   		$aLog['products_fields'] = mysql_affected_rows();
   	}
   	 
   	 
   	$new_files_count = count($aObj['aSources']);
   	if($new_files_count){
   		/*
   		$current_count = get_s3_files_count($aObj['products_id'], 3);
   		if($current_count + $new_files_count > 10){
   			$aLog['aFiles'] = "Main Graphics (up to 10 16x9 images from phone or cloud storage service); current count: ".($current_count + $new_files_count);
   		}else{*/
   			$aLog['aFiles'] = add_s3_files_to_a_table($aObj['products_id'], 4, $aObj['aSources'], $aSourcesNotes, $LUser['id']);
   		//}
   	}
   	 
    api_product_details($aObj, $LUser);
   	 
   	done_json($aLog, "result");
   }
    
   /* api function end */
   
   
 
 /* api function begin
  $aTmpObj['portals_id'] = '1';
 $aTmpObj['keyword'] = '';
 $aTmpObj['lat'] = '48.856735';//optional
 $aTmpObj['lng'] = '-74.005980';//optional
 $aTmpObj['restrict_by_distance'] = '0';//1
 $aTmpObj['distance'] = '10';//
 $aTmpObj['limit'] = '1';//optional
 $aTmpObj['offset'] = '0';//optional
 */
 
 function api_get_portal_nearest_rep($aObj, $LUser){
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['portals_id'] == '')done_json("portals_id is empty!");
 
 	$distance = (int)$aObj['distance'];
 	$aLeaders = array();
 
 	$sql = "SELECT `users_id` FROM `portals` WHERE `id`='".mv($aObj['portals_id'])."'";
 	$res = mysql_query($sql) or die(mysql_error());
 	if(mysql_num_rows($res)){
 		$owner_id = mysql_result($res, 0, 0);
 	 }else{
 		done_json("portals_id: 404");
 	  }
 
 
 
 	$sql = "SELECT COUNT(*) FROM `portals_users` WHERE `portals_id` = '".mv($aObj['portals_id'])."' AND `leader` = 1 AND `users_id` <> '".mv($LUser['id'])."'";
 	$res = mysql_query($sql) or die(mysql_error());
 	$leaders_count = mysql_result($res, 0, 0);
 	if($leaders_count == 0){
 			
 		if($owner_id == $LUser['id'])done_json("You are the one and only leader of the portal");
 			
 		$sql = "SELECT * FROM `users` WHERE `id` = '".mv($owner_id)."'";
 		$res = mysql_query($sql) or die(mysql_error());
 		if(mysql_num_rows($res)){
 			$row=mysql_fetch_assoc($res);
 			$aLeaders[] = manage_user_row($row);
 		}
 			
 	}
 
 
 	if(count($aLeaders) == 0){
 		$offset = (int)$aObj['offset'];
 		$limit = (int)$aObj['limit'];
 			
 		if($limit == 0)$limit = 1;
 			
 		if($offset < 0) done_json("offset is wrong!");
 		if($limit > 4096) done_json("limit should be <= 4096");
 			
 		$aConds = array();
 		$aConds[] = " `id` <> '".mv($LUser['id'])."'";
 		$aConds[] = " `id` IN (SELECT `users_id` FROM `portals_users` WHERE `portals_id` = ".mv($aObj['portals_id'])." AND `leader` = 1)";
 		if($aObj['keyword'] != ""){
 			$aConds[] = " LOWER(CONCAT_WS(' ', `fname`, `lname`)) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
 		}
 			
 		if($aObj['lat'] != '' && $aObj['lng'] != '' && $aObj['lat'] != '0' && $aObj['lng'] != '0'){
 			if($aObj['restrict_by_distance'] == '1'){
 				if($distance < 1)done_json("distance < 1");
 				$aConds[] = "((ACOS( SIN(`lat` * PI() /180 ) * SIN( (".mv($aObj['lat']).") * PI()/180 ) + COS(`lat` * PI()/180 ) * COS( ( ".mv($aObj['lat'])." ) * PI( ) /180 ) * COS( ((`lng`+0.000001) - ( ".mv($aObj['lng'])." ) ) * PI( ) /180 ) ) *180 / PI() ) * 60 * 1.1515) <= ".mv($distance);
 			}
 			$r_cond = ", ((ACOS( SIN(`lat` * PI() /180 ) * SIN( (".mv($aObj['lat']).") * PI()/180 ) + COS(`lat` * PI()/180 ) * COS( ( ".mv($aObj['lat'])." ) * PI( ) /180 ) * COS( ((`lng`+0.000001) - ( ".mv($aObj['lng'])." ) ) * PI( ) /180 ) ) *180 / PI() ) * 60 * 1.1515) as distance ";
 			 
 			$aConds[] = " `lat` <> '0.000000'";
 			$aConds[] = " `lng` <> '0.000000'";
 		}
 
 		 
 		$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
 		 
 		$order_sql = ($r_cond != "")?"`distance` ASC":"`id` DESC";
 			
 		$sql = "SELECT *".$r_cond." FROM `users` ".$sql_cond." ORDER BY ".$order_sql." LIMIT ".$offset.", ".$limit;
 		$res = mysql_query($sql) or die(mysql_error());
 		if(mysql_num_rows($res)){
 			while($row=mysql_fetch_assoc($res)){
 				$aLeaders[] = manage_user_row($row);
 			}
 		}
 	}
 
 	//if($LUser['id'] == '')done_json("Login error!");
 	if(count($aLeaders) == 0){
 		$cities_id = "";
 		$sql = "SELECT `cities_id` FROM `users` WHERE `id`='".mv($LUser['id'])."'";
 		$res = mysql_query($sql) or die(mysql_error());
 		if(mysql_num_rows($res)){
 			$cities_id = mysql_result($res, 0, 0);
 			if($cities_id == "0")$cities_id = "";
 		}else{
 			done_json("wrong login");
 		}
 			
 		if($cities_id != ""){
 			$sql = "SELECT * FROM `users` WHERE  `cities_id` = '".mv($cities_id)."' AND `id` IN (SELECT `users_id` FROM `portals_users` WHERE `portals_id` = ".mv($aObj['portals_id'])." AND `leader` = 1 AND `users_id` <> '".mv($LUser['id'])."') ORDER BY RAND() LIMIT ".$offset.", ".$limit;
 			$res = mysql_query($sql) or die(mysql_error());
 			if(mysql_num_rows($res)){
 				while($row=mysql_fetch_assoc($res)){
 					$aLeaders[] = manage_user_row($row);
 				}
 			}
 		}
 			
 	}
 		
 		
 	if(count($aLeaders) == 0){
 
 		$sql = "SELECT * FROM `users` WHERE `id` IN (SELECT `users_id` FROM `portals_users` WHERE `portals_id` = ".mv($aObj['portals_id'])." AND `leader` = 1` AND `users_id` <> '".mv($LUser['id'])."') ORDER BY RAND() LIMIT ".$offset.", ".$limit;
 		$res = mysql_query($sql) or die(mysql_error());
 		if(mysql_num_rows($res)){
 			while($row=mysql_fetch_assoc($res)){
 				$aLeaders[] = manage_user_row($row);
 			}
 		}
 	}
 
 		
 	done_json($aLeaders, "result");
 		
 }
 /* api function end */
 
 
 
 /* api function begin
  $aTmpObj['portals_id'] = '1';
 */
 
 function api_portal_get_balance($aObj, $LUser){
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['portals_id'] == "")done_json("portals_id is empty!");
 	
 	check_portal_editor_permission($LUser['id'], $aObj['portals_id']);
 	
 	
 	$sql = "SELECT SUM(`amount`) FROM `portals_transactions` WHERE `portals_id`='".mv($aObj['portals_id'])."'";
 	$res = mysql_custom_query($sql);
 	$amount_to_withdraw = mysql_result($res, 0, 0); 	
 	
 	
 	done_json($amount_to_withdraw, "result");
  }
 /* api function end */
 
 
 
 /* api function begin
  $aTmpObj['portals_id'] = '1';
 */
 
 function api_withdraw_money($aObj, $LUser){
 	global $RootDomain, $RootDir, $StripeApiKey;
 	
 	if($LUser['id'] == '')done_json("Login error!");
 	if($aObj['portals_id'] == "")done_json("portals_id is empty!");
 	
 	check_portal_editor_permission($LUser['id'], $aObj['portals_id']);
 	
 	$sql = "SELECT `stripe_recipient_id` FROM `portals_bank_accounts` WHERE `portals_id`='".mv($aObj['portals_id'])."' AND `stripe_recipient_id` <> '' ORDER BY `id` DESC LIMIT 0, 1";
 	$res = mysql_custom_query($sql);
 	if(mysql_num_rows($res)){
 		$stripe_recipient_id = mysql_result($res, 0, 0);
 	}else{
 		done_json("stripe customer id is empty");
 	}
 	
 	
 	
 	$sql = "SELECT SUM(`amount`) FROM `portals_transactions` WHERE `portals_id`='".mv($aObj['portals_id'])."'";
 	$res = mysql_custom_query($sql);
 	$amount_to_withdraw = mysql_result($res, 0, 0);
 	
 	if($amount_to_withdraw < 1)done_json("Nothing to withdraw");
 	
 	
 	require($RootDir.'/lib/stripe/Stripe.php');
 	Stripe::setApiKey($StripeApiKey);
 	
 	
 	try {
 		$transfer = Stripe_Transfer::create(array(
 				"amount" => $amount_to_withdraw*100, // amount in cents
 				"currency" => "usd",
 				"recipient" => $stripe_recipient_id,
 				"statement_descriptor" => "portal #".$aObj['portals_id'])
 		);
 	} catch (Exception $e) {
 		$message = $e->getMessage();
 		echo $message;exit;
 	}
 	
 	
 	
 	$portals_transactions_id = log_new_portal_transaction($LUser['id'], $aObj['portals_id'], (0-$amount_to_withdraw), "withdraw_money");
 	
 	$aRet = array();
 	$aRet['stripe_transfer_id'] = $transfer->id;
 	$aRet['portals_transactions_id'] = $portals_transactions_id;
 	
 	done_json($aRet, "result");
 
 }
 /* api function end */
 
 
 

 
?>
