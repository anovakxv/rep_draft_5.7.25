<?php

  	$aS3FilesTables = array('1' => "users", "2" => "portals", "3" => "goals", "4" => "products", "5" => "goals_progress_log", "6" => "portals_graphic_sections");
  	
 /* api function begin 
    $aTmpObj['tbl_id'] = '1';
    $aTmpObj['tbl_index'] = '1';
  	$aTmpObj['main_photo_index'] = '1';//optional
  	$aTmpObj['aSources'][0] = 'http://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Hotel_de_Paris_(Monte-Carlo).jpg/325px-Hotel_de_Paris_(Monte-Carlo).jpg';
  	$aTmpObj['aSources'][1] = '0';//aMultipleFiles[0]
  	$aTmpObj['aSources'][2] = '1';//aMultipleFiles[1]
  	$aTmpObj['aSources'][3] = 'aRegularFile';
  	$aTmpObj['aSourcesNotes'][0] = '';
  	$aTmpObj['aSourcesNotes'][1] = '';
  	$aTmpObj['aSourcesNotes'][2] = '';
  	$aTmpObj['aSourcesNotes'][3] = '';
  	$input_file[] = "aMultipleFiles[]";
  	$input_file[] = "aMultipleFiles[]";
  	$input_file[] = "aRegularFile";
  */
function api_add_s3_files($aObj, $LUser){
	global $RootDomain, $RootDir, $aS3FilesTables;
  	if($LUser['id'] == '')done_json("Login error!");
	
  	$aLog = array();
  	
  	/*
  	print_r($aObj);
  	print_r($_POST);
    print_r($_FILES);
    exit;*/

  	$aInstructions = array();
  	$aOkFileTypes = array();
  	
  	$aLog = add_s3_files_to_a_table($aObj['tbl_id'], $aObj['tbl_index'], $aObj['aSources'], $aObj['aSourcesNotes'], $LUser['id'], $aInstructions, $aOkFileTypes);
  	
	if($aObj['__return_result'] == '1'){
		return $aLog;
	 }
	 
	done_json($aLog, "result");
	
 }
/* api function end */
 
 
 
 
 function add_s3_files_to_a_table($tbl_id, $tbl_index, $aSources, $aSourcesNotes = array(), $users_id = 0, $aInstructions = array(), $aOkFileTypes = array()){
 	global $RootDomain, $RootDir, $aS3FilesTables;
 	
  	if($tbl_id == '')return "tbl_id required!";
  	if($tbl_index == '')return "tbl_index required!";
  	if(!is_array($aSources) || count($aSources) == 0)return "aSources is empty or wrong!";
  	
  	if(!isset($aS3FilesTables[$tbl_index]))return "Wrong tbl_index!";
  	 
  	$user_id_c = ($aS3FilesTables[$tbl_index] == 'users')?'id':'users_id';
  	 
  	$aSQLs = array();
  	$aSQLs[] = " `id`='".mv($tbl_id)."' ";
  	if($users_id > 0){
  		$aSQLs[] = " `".$user_id_c."` = '".mv($users_id)."' ";
  	 }
  	 
  	 $sql = "SELECT COUNT(*) FROM `".$aS3FilesTables[$tbl_index]."` WHERE ".implode(" AND ", $aSQLs);
  	// echo $sql;exit;
  	 $res = mysql_query($sql) or die(mysql_error().' '.$sql);
  	 if(mysql_result($res, 0, 0) == 0)return "table: 404 or 503!";
  	 
  	 if(!is_array($aOkFileTypes) || count($aOkFileTypes) == 0){
  	 	$aOkFileTypes = array('image' => true, 'other' => false);
  	 }
  	
  	 
 	foreach($aSources as $key => $val){
 	
 		//echo filter_var($val, FILTER_VALIDATE_URL);exit;
 		if(filter_var($val, FILTER_VALIDATE_URL) !== FALSE){
 			
 			$ext = get_file_ext($val);
 			if($ext != "")$ext = ".".$ext;
 			
 			$ufile_name = 'tmp_'.$tbl_id.'_'.time().$ext;
 			$tmp_file_location = $RootDir.'/upload/'.$users_id.'/'.$ufile_name;
 			
 			if(file_put_contents($tmp_file_location, fopen($val, 'r'))){
  			   $_FILES['_s3_auto_file']['name'] = $ufile_name;
 			   $_FILES['_s3_auto_file']['tmp_name'] = $tmp_file_location;
 			   $_FILES['_s3_auto_file']['unlink_original'] = "unlink_original";			
 			 }else{
 			 	$aLog['file_'.$key] = "download/save error";
 			 }

 			
 		}elseif($_FILES['aMultipleFiles']['name'][$val] != ""){
 			$_FILES['_s3_auto_file']['name'] = $_FILES['aMultipleFiles']['name'][$val];
 			$_FILES['_s3_auto_file']['tmp_name'] = $_FILES['aMultipleFiles']['tmp_name'][$val];
 		}elseif($_FILES[$val]['name'] != ""){
 			$_FILES['_s3_auto_file'] = $_FILES[$val];
 		 }else{
 			$aLog['file_'.$key] = "empty";
 			continue;
 		   }
 		 
 		   //print_r($_FILES);exit;
 		 
 		$file_type == "";
 		foreach($aOkFileTypes as $key22 => $val22){
 			
 			if($key22 == 'other')continue;
 			
 			if($key22 == 'image' && $val22 == true){
	  			$image_check = is_the_picture_is_good($_FILES['_s3_auto_file']['tmp_name']);
	  			

	 			if($image_check == ""){
	 			    $file_type = 'image';
	 		       }else{
	 		       	 $aLog['file_'.$key] = $image_check;
	 		       }
 			   }	
 			   
 		  }
 		  
 		  if($file_type == ""){
 		  	
 		  	if($aOkFileTypes['other'] == true){
 		  		$file_type = 'other';
 		  	 }else{
  		  	   if($aLog['file_'.$key] == "")$aLog['file_'.$key] = "unsupported file type";
 		  	   continue;		  		
 		  	 }
 		  	 
 		   }
 		
 		

 	
 		$main_photo_index = "";
 		//$txt_note_index = ($main_photo_index == $key && $key != "")?'main':'file';
 		$txt_note_index = 'file';
 		if($aSourcesNotes[$key] != ""){
 			$txt_note_index = $aSourcesNotes[$key];
 		}
 		
 	
 		 
 		$oContent = new S3Content($users_id);
 		$oContent->prepareInstructions = (count($aInstructions))?$aInstructions:get_default_s3_files_instructions($txt_note_index);
 		$oContent->unlink_original_file = true;
 		$oContent->feedback_type = "json";
 		$oContent->save_tmp_file($_FILES['_s3_auto_file']);
 		$oContent->full_file_check();
 		$oContent->type = $file_type;
 		$oContent->tbl_index = $tbl_index;
 		$oContent->txt_note_index = $txt_note_index;
 		$oContent->tbl_id = $tbl_id;
 		$oContent->order = $key;
 		//$oContent->working_directory = $RootDir.'/upload/'..'/';
 		$oContent->prepare_files_for_save();
 		$aS3Data = $oContent->save_files_to_db();
 		 
 		 
 		if(file_exists($tmp_file_location))unlink($tmp_file_location);
 		 
 		if(!empty($aS3Data['s3_content_ids'])){
 			$ids_str = implode(", ", $aS3Data['s3_content_ids']);
 			//$sql = "UPDATE `events` SET `s3_content_ids` = '".mv($ids_str)."' WHERE `id`='".mv($tbl_id)."'";
 			//$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 			$aLog['file_'.$key] = $aS3Data;
 		}else{
 			$aLog['file_'.$key] = "empty s3 ids";
 		}
 	
 	}
 	return $aLog;
 	
 }
 
 
 
 function get_default_s3_files_instructions($txt_note_index = "file"){
 	$aInstructions = array();
 	$aInstructions['image'][0]['key'] ='original';
 	$aInstructions['image'][0]['txt_note'] = $txt_note_index.'_original';
 	$aInstructions['image'][0]['upload_to_s3'] ='0';
 	$aInstructions['image'][1]['key'] ='resize';
 	$aInstructions['image'][1]['txt_note'] = $txt_note_index.'_max_640x640';
 	$aInstructions['image'][1]['size']['x'] ='640';
 	$aInstructions['image'][1]['size']['y'] ='640';
 	$aInstructions['image'][1]['size']['ifbiggerthan'] ='640';
 	$aInstructions['image'][1]['resize_mode'] ='x_or_y';
 	$aInstructions['image'][1]['upload_to_s3'] ='0';
 	$aInstructions['image'][2]['key'] ='resize';
 	$aInstructions['image'][2]['txt_note'] = $txt_note_index.'_thumb_86x86';
 	$aInstructions['image'][2]['size']['x'] ='86';
 	$aInstructions['image'][2]['size']['y'] ='86';
 	$aInstructions['image'][2]['resize_mode'] ='x_and_y';
 	$aInstructions['image'][2]['upload_to_s3'] ='0';
 	
 	
 	$aInstructions['video'][0]['key'] ='original';
 	$aInstructions['video'][0]['txt_note'] =$txt_note_index.'_original';
 	$aInstructions['video'][0]['upload_to_s3'] ='0';
 	$aInstructions['video'][1]['key'] ='thumb';
 	$aInstructions['video'][1]['txt_note'] = $txt_note_index.'_thumb_original';
 	$aInstructions['video'][1]['size']['x'] ='';
 	$aInstructions['video'][1]['size']['y'] ='';
 	$aInstructions['video'][1]['resize_mode'] ='';
 	$aInstructions['video'][1]['upload_to_s3'] ='0';
 	$aInstructions['video'][2]['key'] ='thumb';
 	$aInstructions['video'][2]['txt_note'] = $txt_note_index.'_max_640x640';
 	$aInstructions['video'][2]['size']['x'] ='640';
 	$aInstructions['video'][2]['size']['y'] ='640';
 	$aInstructions['video'][2]['resize_mode'] ='x_or_y';
 	$aInstructions['video'][2]['upload_to_s3'] ='0';
 	$aInstructions['video'][3]['key'] ='thumb';
 	$aInstructions['video'][3]['txt_note'] = $txt_note_index.'_thumb_86x86';
 	$aInstructions['video'][3]['size']['x'] ='86';
 	$aInstructions['video'][3]['size']['y'] ='86';
 	$aInstructions['video'][3]['resize_mode'] ='x_and_y';
 	$aInstructions['video'][3]['upload_to_s3'] ='0';
 	
 	$aInstructions['audio'][0]['key'] ='original';
 	$aInstructions['audio'][0]['txt_note'] =$txt_note_index.'_original';
 	$aInstructions['audio'][0]['upload_to_s3'] ='0';
 	
 	return $aInstructions;
 }
 
 
 
 
 
 
  /* api function begin 
  	$aTmpObj['aS3IDs'][0] = '';//id here
  	$aTmpObj['aS3IDs'][1] = '';//id here
  	$aTmpObj['aS3IDs'][2] = '';//id here
  	$aTmpObj['aGroupHash'][0] = '';//or group hash
  	$aTmpObj['aGroupHash'][1] = '';//or group hash
  	$aTmpObj['__return_result'] = '';//1
  */
 function api_delete_media($aObj, $LUser){ //echo 'me!';exit;
 	
 	 if($LUser['id'] == '')done_json("login required!");
 	   	 
 	 if(is_array($aObj['aGroupHash']) && count($aObj['aGroupHash'])){
 	 	
 	 	if(!is_array($aObj['aS3IDs']))$aObj['aS3IDs'] = array();
 	 	
 	 	$aToDB = array();
 	 	foreach($aObj['aGroupHash'] as $key=>$val){
 	 		if($val == "")continue;
 	 		$aToDB[$val] = "'".mvs($val)."'";
 	 	 }
 	 	 
 	 	 
 	 	if(count($aToDB) == 0)done_json("something wrong with aGroupHash");
 	 	
 	 	$sql = "SELECT `id` FROM `s3_content` WHERE `gr_hash` IN (".implode(", ", $aToDB).") AND `users_id` = '".mv($LUser['id'])."'";
 	 	//echo $sql;exit;
 		$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 		if(mysql_num_rows($res)){
  			while($row=mysql_fetch_assoc($res)){
    			$aObj['aS3IDs'][] = $row['id'];
   			  }
 		  }else{
 		  	if($aObj['__return_result'] == '1')return "0 files for the gr_hash";
 		  	done_json("0 files for the gr_hash");
 		  }
 	 	
 	 }
 	 
 	 
 	 if(!is_array($aObj['aS3IDs']) || count($aObj['aS3IDs']) == 0){
 	 	if($aObj['__return_result'] == '1')return "aS3IDs is empty or wrong!";
 	 	done_json("aS3IDs is empty or wrong!");
 	 }
 	 
 	 $aToDB = array();
 	 foreach($aObj['aS3IDs'] as $key=>$val){
 	 	$aToDB[$val] = "'".mv($val)."'";
 	 }
 	 
 	 $sql = "SELECT COUNT(*) FROM `s3_content` WHERE `users_id`='".mv($LUser['id'])."' AND (`id` IN (".implode(", ", $aToDB).")) LIMIT 0, 1";
 	 $res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	 $xs = mysql_result($res, 0, 0);
 	 if($xs != count($aObj['aS3IDs']))done_json("ids mismatch: 404 or 503; ".$xs."!=".count($aObj['aS3IDs']));
 	 	
 	 foreach($aObj['aS3IDs'] as $key => $s3_content_id){
	   $S3Obj = new S3Content($LUser['id']);
 	   $S3Obj->load($s3_content_id);
 	   $S3Obj->delete();
 	  }
 	  
 	  if($aObj['__return_result'] == '1')return "ok";
 	  done_json("ok", "result");
  }
/* api function end */
  
  
 function delete_s3_files_by_main_key($users_id, $main_key){
 	
 	if($users_id == "" || $main_key == "")return "empty users_id or main_key";

 	//$aS3IDs = array();
 	$sql = "SELECT `id` FROM `s3_content` WHERE `main_key`='".mvs($main_key)."' AND `users_id` = '".mv($users_id)."'";
 	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			
 			$S3Obj = new S3Content($users_id);
 			$S3Obj->load($row['id']);
 			$S3Obj->delete(); 			
 			
 		}
 	}
  	
 	return "ok";
  }
  
  
 function get_s3_files_count($tbl_id, $tbl_index){
  	
 	$sql = "SELECT COUNT(*) FROM `s3_content` WHERE `tbl_index` = ".mv($tbl_index)." AND `tbl_id` = '".mv($tbl_id)."' GROUP BY `hash`";
 	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	$count = mysql_num_rows($res);
 	
 	return $count;
 	
  }
  
  
 function get_s3_files($tbl_index, $tbl_id){
	
/*
 	$sql = "SELECT `id`, `gr_hash`, `url`, `length`, `key`, `type`, `order`, `width`,`height`, `size`, `date`, `md5` FROM `s3_content` WHERE `tbl_index` = ".mv($tbl_index)." AND `tbl_id` = '".mv($tbl_id)."' ORDER BY `order` ASC";
 	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	$aData = array();
 	if(mysql_num_rows($res)){
  		while($row=mysql_fetch_assoc($res)){
  			//_thumb_original
  			if($row['key'] == 'yaps_image_original' || $row['key'] == 'main_image_original'){
  				$the_key = "aOriginal";
   			  }elseif($row['key'] == 'yaps_image_max_640x640' || $row['key'] == 'main_image_max_640x640'){
  				 $the_key = "aMax640";
  				}else{
  					$the_key = "aOther";
  				  //continue;
  			 	 }
  			 	 
  			if(!isset($aData[$the_key]))$aData[$the_key] = array();
  			
  			   if($row['key'] == 'main_image_original' || $row['key'] == 'main_image_max_640x640'){
  				  array_unshift($aData[$the_key], $row);
  				 }else{
  			  	   $aData[$the_key][] = $row;
  				  }
  				  
   		 }
 	 }*/
 	
 	
 	
  	$sql = "SELECT * FROM `s3_content` WHERE `tbl_index` = ".mv($tbl_index)." AND `tbl_id` = '".mv($tbl_id)."' ORDER BY `id` ASC";
 	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
 	$aData = array();
 	if(mysql_num_rows($res)){
  		while($row=mysql_fetch_assoc($res)){
  			
  			if($row['key'] == 'audio_original' || strpos(" ".$row['key'], "waveform_"))continue;

  			
  			if($row['gr_hash'] == ''){
  			  if(!isset($aData[$row['key']]))$aData[$row['key']] = array();
    		  $aData[$row['key']][] = $row;
    		  continue;
  			 }
  			 
  			if(!isset($aData[$row['gr_hash']]))$aData[$row['gr_hash']] = array('type' => $row['type'], 'gr_hash' => $row['gr_hash']);
  			
  			/*
  			if($row['type'] == "image" && $row['key'] == 'file_original'){
  				$aData[$row['gr_hash']]['file_thumb_original'] = $row['url'];
  			 }*/
  			
  			$aData[$row['gr_hash']][$row['key']] = $row['url'];
   		 }
   		 $aData = array_values($aData);
 	 }
 	
 	 
 	 return $aData;
	
}
  
  
?>