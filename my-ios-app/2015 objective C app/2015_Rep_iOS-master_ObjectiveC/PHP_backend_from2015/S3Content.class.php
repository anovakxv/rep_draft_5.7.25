<?php 
/*** !!!latest!!! ***/

 class S3Content {
    private $data = array();
    public $feedback_type = "return";
    public $s3_content_table = "s3_content";
    public $SupportedFileFormats = array();
    private $FilesToDB = array();
    public $prepareInstructions = array();
    //public $type;
    public $owner_id;//login required
    public $RootDir, $RootDomain;
    public $tmp_file_path;
    public $working_directory;
    public $file_checked = false;
    public $unlink_original_file = false;
    public $original_id;
    
    public function __construct($owner_id = -1){
    	  global $RootDir, $RootDomain;

  	    $this->SupportedFileFormats['video'] = array('mp4','flv','avi', 'mpg', 'wmv', 'mkv', 'mov');
  		$this->SupportedFileFormats['image'] = array('jpg', 'jpeg', 'gif','png', 'wbmp');
  		$this->SupportedFileFormats['audio'] = array('mp3', 'wav', 'ogg');
  		
  		$this->RootDir = $RootDir;
  		$this->RootDomain = $RootDomain;

        if($owner_id == -1){
           if($_SESSION['user']->id != ""){
           	 $this->owner_id = $_SESSION['user']->id;
            }elseif($_SESSION['user']['id'] != ""){
           	  $this->owner_id = $_SESSION['user']['id'];
             }else{
             	$this->msg("login required!");
             }
         }else{
         	$this->owner_id = $owner_id;
         }
         
         $this->user_id = $this->owner_id;
         
 
        $this->working_directory = $this->RootDir.'/upload/'.$this->owner_id;
    	if(!is_dir($this->working_directory)){
      		mkdir($this->working_directory, 0777);
      		chmod($this->working_directory, 0777);
		 }
     }
     
    public function load($id, $row = array()){
  
    	if(count($row)){
    	   $this->data = $row;
    	 }elseif($id != ""){
    		$sql = "SELECT * FROM `".$this->s3_content_table."` WHERE `id`='".mv($id)."'";
        	$res = mysql_query($sql) or die(mysql_error());
        	if(mysql_num_rows($res)){
	        	$this->data = mysql_fetch_assoc($res);
          	 }else{
        		$this->msg("404 1");
           	  }
    	  }else{
    	  	$this->msg("404 2");
    	  }
    	
     }
     
  public function delete(){
    global $S3_awsAccessKey, $S3_awsSecretKey, $RootDir, $S3_bucketName;
	
       if($this->local_name != "" && file_exists($this->working_directory.'/'.$this->local_name)){
       	 unlink($this->working_directory.'/'.$this->local_name);
        }else{
        	//echo 'no file'.$this->working_directory.'/'.$this->local_name;
         }
        
       if($this->name != "" && $this->bucket != ""){
       	
       		if (!class_exists('S3')) require_once $RootDir.'/lib/S3.php';
       		$s3 = new S3($S3_awsAccessKey, $S3_awsSecretKey);
 
       	     $s3->deleteObject($this->bucket, $this->name);       	
        } 
        
        $sql = "DELETE FROM `".$this->s3_content_table."` WHERE `id` = '".$this->id."'";
		$res = mysql_query($sql) or die(mysql_error());
        
    }
     
    public function upload_local_file_to_s3(){
     	
    	global $S3_awsAccessKey, $S3_awsSecretKey, $RootDir, $S3_bucketName;

    	
    	if($this->upload_to_s3 != "1")$this->msg('upload_to_s3 is false!');
     	if($this->local_name == "")$this->msg('local_name is empty!');
     	$local_file_path = $this->working_directory.'/'.$this->local_name;
  		if (!file_exists($local_file_path))done_json('File not found! location: '.$local_file_path);
  		
  		if (!class_exists('S3')) require_once $RootDir.'/lib/S3.php';
  		$s3 = new S3($S3_awsAccessKey, $S3_awsSecretKey);
      $name_to_s3 = $this->user_id.'_'.$this->local_name;
   	  if ($s3->putObjectFile($local_file_path, $S3_bucketName, $name_to_s3, S3::ACL_PUBLIC_READ)){
  		 // echo "S3::putObjectFile(): File copied to {$S3_bucketName}/".$file.'<br>';
		  //$info = $s3->getObjectInfo($S3_bucketName, $this->user_id.'_'.$this->local_name);
		  
		/*if($info['bucket'] != "" && $info['name'] != ""){*/
		   $sql = "UPDATE `".$this->s3_content_table."` SET 
		    `local_name` = '', 
		    `bucket` = '".mv($S3_bucketName)."',
		    `name` = '".mv($name_to_s3)."',
		    `hash` = 'no hash',
		    `url` = 'http://".$S3_bucketName.".s3.amazonaws.com/".$name_to_s3."'
		    WHERE `id`='".$this->id."'";
 		   $res = mysql_query($sql) or die(mysql_error());
		   unlink($local_file_path);
		 /*}else{
		 	$this->msg("s3 putObjectFile 2: info");
		 	echo $s3->error;
		 	print_r($info);
		 }*/
		 
      }else{
    	$this->msg("s3 putObjectFile 1");
       }
  
    
    return false;
     	
   }
     /******************/
     
     
     
    public function convert_content_to_new_s3($format, $thumb = false){
     	global $RootDir;
     	
     	
    	if($this->local_name == "")$this->msg('local_name is empty!');
        if($this->type != "video")$this->msg('wrong content type!');
    	 
    	$file = $this->working_directory.'/'.$this->local_name;
    	$file_new_local_name = md5($this->local_name.'_'.time()).'.'.$format;
    	$file_new = $this->working_directory.'/'.$file_new_local_name;
        if(!file_exists($file))$this->msg('wrong content type!');
        if(file_exists($file_new))unlink($file_new);
    	
        $scale_part = (do_we_need_resize($file))?"-vf scale=640:ih*640/iw":"";
        
        if(strtolower($format) == 'mp4'){
          $s = "ffmpeg -i ".$file." -vcodec libx264 -sameq ".$scale_part." ".$file_new."  2>&1";
         }
         
        if(strtolower($format) == 'webm'){
          $s = "ffmpeg -i ".$file." -acodec libvorbis -sameq ".$scale_part." ".$file_new."  2>&1";
         }
         
        if(strtolower($format) == 'ogg'){
          $s = "ffmpeg -i ".$file." -acodec libvorbis -sameq ".$scale_part." ".$file_new."  2>&1";
         }
        $convertation_log = shell_exec($s);
    		
        if(!file_exists($file_new) || filesize($file_new) < 512)$this->msg($convertation_log);
        
        $pieces = explode("/upload/", $this->working_directory);
        
        $url = $RootDomain.'/upload/'.$pieces[1].'/'.$file_new_local_name;
	    $sql = "INSERT INTO `".$this->s3_content_table."` (`users_id`, `local_name`, `bucket`,`name`, `hash`, `size`, `key`, `type`, `url` )
				VALUES ('".mv($this->user_id)."', '".$file_new_local_name."', '', '', '', '".filesize($file_new)."','converted to ".$format."', 'video', '".$url."');";
		        $res = mysql_query($sql) or die(mysql_error());

		 return mysql_insert_id();

        
     }
     
     public function convert_audio_content_to_new_s3($format = "ogg"){
     	global $RootDir;
     	
     	
    	if($this->local_name == "")$this->msg('local_name is empty!');
        if($this->type != "audio")$this->msg('wrong content type!');
    	 
    	$file = $this->working_directory.'/'.$this->local_name;
    	$file_new_local_name = md5($this->local_name.'_'.time()).'.ogg';
    	$file_new = $this->working_directory.'/'.$file_new_local_name;
        if(!file_exists($file))$this->msg('wrong content type!');
        if(file_exists($file_new))unlink($file_new);
    	
        
        $s = "ffmpeg -i ".$file." -acodec libvorbis -f ogg -y ".$scale_part." ".$file_new."  2>&1";
        $convertation_log = shell_exec($s);
    		
        if(!file_exists($file_new) || filesize($file_new) < 512)$this->msg($convertation_log);
        
        //$url = $this->working_directory.'/'.$file_new_local_name;
		$pieces = explode("/upload/", $this->working_directory);
        $url = $RootDomain.'/upload/'.$pieces[1].'/'.$file_new_local_name;
	    $sql = "INSERT INTO `".$this->s3_content_table."` (`users_id`, `local_name`, `bucket`,`name`, `hash`, `size`, `key`, `type`, `url` )
				VALUES ('".mv($this->user_id)."', '".$file_new_local_name."', '', '', '', '".filesize($file_new)."','converted to ".$format."', 'audio', '".$url."');";
		        $res = mysql_query($sql) or die(mysql_error());

		 return mysql_insert_id();

        
     }
     
     
    public function prepare_files_for_save(){
    	
    	$good_files_path;
    	$this->FilesToDB = array();
 

    	
    	if($this->tmp_file_path == "")$this->msg("xxx|not enough data");

    	$this->good_files_path = array();
    	
    	if($this->type == "")$this->type = "attachment";
    		
    		if(is_array($this->prepareInstructions[$this->type]) && count($this->prepareInstructions[$this->type])){
    			foreach($this->prepareInstructions[$this->type] as $key => $val){
    				
    				$new_file_type = $this->type;
    				
    				if($val['name'] == ''){
    					if($this->type == 'video' && $val['key'] == 'thumb'){
    					  $val['name'] = md5($this->type.'_'.$this->owner_id.'_'.time().'_'.rand(10, 9999999)).'.jpg';
    					}else{
    					  $val['name'] = md5($this->type.'_'.$this->owner_id.'_'.time().'_'.rand(10, 9999999)).'.'.get_file_ext($this->tmp_file_path);
    					}

    				 }
    				
    				$full_file_location_tmp = $this->working_directory.'/tmp_'.$val['name'];
    				$full_file_location = $this->working_directory.'/'.$val['name'];
    				if(file_exists($full_file_location_tmp))unlink($full_file_location_tmp);
    				if(file_exists($full_file_location))unlink($full_file_location);
    				
    				
    			if($this->type == 'image'){
    				if($val['resize_mode'] == 'x_or_y'){
    					if(!isset($val['size']['ifbiggerthan']) || $val['size']['ifbiggerthan'] == "")$val['size']['ifbiggerthan'] = 0;
    					ProportionalImageResize($this->tmp_file_path, $full_file_location, $val['size']['x'], $val['size']['y'], $val['size']['ifbiggerthan']);
    				 }elseif($val['resize_mode'] == 'x_and_y'){
    				 	ManualImageResize($this->tmp_file_path, $full_file_location, $val['size']['x'], $val['size']['y']);
    				  }else{
    				  	copy($this->tmp_file_path, $full_file_location);
    				  }
    			  }elseif($this->type == 'video'){
    			  	
    			  	if($val['key'] == 'original'){
    			  	  copy($this->tmp_file_path, $full_file_location);
    			  	 }
    			  	 
    			    if($val['key'] == 'thumb'){
    			       $new_file_type = 'image';
    			  	   make_video_thumb($this->tmp_file_path, $full_file_location_tmp);
    			  	   if($val['size']['x'] != '' && $val['size']['y'] != ''){
    			  	     ManualImageResize($full_file_location_tmp, $full_file_location, $val['size']['x'], $val['size']['y']);
    			  	    }else{
    			  	      copy($full_file_location_tmp, $full_file_location);
    			  	    }
    			  	   unlink($full_file_location_tmp);
    			  	 }
    			  	
    			  }else{
    			  	copy($this->tmp_file_path, $full_file_location);
    			  }
    				  
    			  
    			  
    				  if(file_exists($full_file_location)){
    				  	$aTmp['full_file_location'] = $full_file_location;
    				  	$aTmp['local_name'] = $val['name'];
    				  	$aTmp['txt_note'] = $val['txt_note'];
    				  	$aTmp['key'] = $val['key'];
    				  	$aTmp['type'] = $new_file_type;
    				  	$aTmp['upload_to_s3'] = ($val['upload_to_s3'] != "0")?"1":"0";
    				    $this->FilesToDB[] = $aTmp;
    				  }
    				  
    			}
    		 }
    		
    		
		  	

		  /*
		if($this->type == 'video'){
		   $targetFile = $this->prepare_video_for_save($targetFile, $targetThumb);
		   $this->length = get_video_length($targetFile);
		  }*/
    		
    	
    	
     }
     
    public function save_files_to_db(){
      	global $RootDomain, $RootDir, $dbBase, $aS3FilesTables;
    	$aData = array();

    	$gr_hash = time().'_'.count($this->FilesToDB).'_'.rand(32, 2048);
    	
    	if(is_array($this->FilesToDB) && count($this->FilesToDB)){

    		foreach ($this->FilesToDB as $key => $val){
    			
    			$pieces = explode("/upload/", $this->working_directory);
        		$url = $RootDomain.'/upload/'.$pieces[1].'/'.$val['local_name'];
    			
    			//$url = $this->working_directory.'/'.$val['local_name'];
    			if($val['upload_to_s3'] != "0" && $val['upload_to_s3'] != "1"){
    				$val['upload_to_s3'] = "1";
    			 }

    			$w = 0;
    			$h = 1;
    			if($val['type'] == 'image'){
    			  $aDimensions = getimagesize($RootDir.'/upload/'.$pieces[1].'/'.$val['local_name']);
    			  $w = $aDimensions[0];
    			  $h = $aDimensions[1];
    			 }
    			
    			 
    		    if($val['type'] == 'video'){
    			   $length = get_video_length($RootDir.'/upload/'.$pieces[1].'/'.$val['local_name']);
    			 }
    			 
    		    if($val['type'] == 'audio'){
    			   $length = get_audio_length($RootDir.'/upload/'.$pieces[1].'/'.$val['local_name']);
    			 }
    			 
    			 
    			 //print_r($this);exit;
    			 
    			 $md5 = md5_file($RootDir.'/upload/'.$pieces[1].'/'.$val['local_name']);
    			 
    			 
    			//tbl_index: 1 = events; 2 = users;
     		   $s = filesize($val['full_file_location']);
    		   $val['txt_note'] = str_replace('{$original_id}', $this->original_id, $val['txt_note']);
			   $sql = "INSERT INTO `".$this->s3_content_table."` (
			   `users_id`, `local_name`, `bucket`,
			   `name`, `hash`, `size`,`width`,`height`, `length`,
			   `main_key`, `key`, `type`, `url`, `upload_to_s3`,
				`tbl_index`, `tbl_id`, `order`, `gr_hash`, `md5`
			   )
				VALUES (
				'".mv($this->owner_id)."', '".mv($val['local_name'])."', '".mv($val['bucket'])."',
				'".mv($val['name'])."', '".mv($val['hash'])."', '".$s."', '".$w."', '".$h."', '".$length."',
				'".mv($this->txt_note_index)."', '".$val['txt_note']."', '".mv($val['type'])."', '".mv($url)."', '".mv($val['upload_to_s3'])."',
				'".mv($this->tbl_index)."', '".mv($this->tbl_id)."','".mv($this->order)."','".mv($gr_hash)."', '".mv($md5)."'
				);";
		        $res = mysql_query($sql) or die(mysql_error());
		        $last_id = mysql_insert_id();
		        $aTMPsw2 = array();
		        $aTMPsw2['id'] = $last_id;
		        $aTMPsw2['gr_hash'] = $gr_hash;
		        $aTMPsw2['s'] = $s;
		        $aTMPsw2['w'] = $w;
		        $aTMPsw2['h'] = $h;
		        $aData[] = $aTMPsw2;
		        if($val['key'] == 'original'){
		          $this->original_id = $last_id;	 
		        }
		        
		        $url_key_column = "_c_".$val['txt_note']."_url";
		        $sql = "SELECT `TABLE_NAME` FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '".$dbBase."' AND COLUMN_NAME = '".mv($url_key_column)."'";
		        $res = mysql_query($sql) or die(mysql_error());
		        if(mysql_num_rows($res)){
		           while($row=mysql_fetch_assoc($res)){
		           	  if($row['TABLE_NAME'] != $aS3FilesTables[$this->tbl_index])continue;//protection for now
		           	  
		           	  $users_id_c = ($row['TABLE_NAME'] == 'users')?'id':'users_id';
		           	  
		        	  $sql22 = "UPDATE `".$row['TABLE_NAME']."` SET `".mv($url_key_column)."` = '".mv($url)."' WHERE `id`='".mv($this->tbl_id)."' AND `".$users_id_c."`='".mv($this->owner_id)."'";
 					  $res22 = mysql_query($sql22) or die(mysql_error());
		        	}
		         }
		        
 			    //$this->s3_content_id = mysql_insert_id();
    			
    			
    		}
    		
    		
    	}
    	
       if($this->unlink_original_file && $this->tmp_file_path != ""){
    		unlink($this->tmp_file_path);
    	}
    	
    	return array('type' => $this->type, 's3_content_ids' => $aData);
      }
      
    
    public function save_tmp_file($aObj){
    	
    	
     if(is_array($aObj) && count($aObj) && $aObj['tmp_name'] != ""){
    	 	
           $ext = get_file_ext($aObj['name']);
		   $ext = strtolower($ext);
		   
		   if($ext == '')$ext = 'tmp';//$this->msg("407|Can't fild file extension!");
            
           $rnd = rand(1000, 999999);
		   $targetPath = $this->working_directory;//$_SERVER['DOCUMENT_ROOT'] . $targetFolder;
		   $targetFileName = $this->table_name.'_'.substr(time(), 3).'_'.$rnd.'.'.$ext;
		   $targetFileThumb = "thumb_".$this->table_name.'_'.substr(time(), 3).'_'.$rnd.'.jpg';//.$ext;
		   
		   $targetFile = rtrim($this->working_directory,'/').'/'.$targetFileName;
		   //$targetThumb = rtrim($this->working_directory,'/').'/'.$targetFileThumb;
	
		   if (file_exists($targetFile))unlink($targetFile);
		   //if (file_exists($targetThumb))unlink($targetThumb);
	        
	
		      if(!copy($aObj['tmp_name'], $targetFile)){
		      	 $this->msg('408|Internal copy error! '.$aObj['tmp_name'].' to '.$targetFile);
		       }
		       
            $this->tmp_file_path = $targetFile;
     	    return $this->tmp_file_path;
     	
       }else{
    	   $this->msg("404|file is empty!");
    	 }
    	
    }
    
    
   public function full_file_check(){
   	
   	    if($this->tmp_file_path == "")$this->msg('404|tmp_file_path is empty');
   	    	
   		   $ext = get_file_ext($this->tmp_file_path);
		   $ext = strtolower($ext);
   	
           if($this->type == ''){
           	 if(count($this->SupportedFileFormats)){
           	   foreach($this->SupportedFileFormats as $key => $val){
           	      if (in_array($ext, $val)) {
                     $this->type = $key;
                     break;
                   }
           	    }
           	  }else{
           	  	$this->msg("100|nothing supported");
           	  }
            }
            
             $aSupport_str[] = array();
            foreach($this->SupportedFileFormats as $key => $val){
           	      $support_str[] = $key .'('.implode(", ", $val).') ';
           	    }
            
            /*
           if($this->type == '' || !isset($this->SupportedFileFormats[$this->type])){
           	 $this->msg("406|".$this->type." type is empty or wrong! Supported: ".(implode(", ", $support_str)));
            }*/
/*
           if (!in_array($ext, $this->SupportedFileFormats[$this->type])) {
           	 $this->msg("405|Invalid file type: ".$ext."! Supported: ".(implode(", ", $support_str)));
            }*/
            
    	
   		if($this->type == 'image'){
   			$resp = is_the_picture_is_good($this->tmp_file_path);
   			if($resp != "")$this->msg('xxx|'.$resp);
		 }
		       
		if($this->type == 'video'){
		  $length = get_video_length($this->tmp_file_path);
		  if($length == "")$this->msg('410|video is corrupted');
		 }
		 
   		if($this->type == 'audio'){
		  $length = get_video_length($this->tmp_file_path);
		  if($length == "")$this->msg('410|audio is corrupted');
		 }
		
		
    	return true;
    }
     
    private function msg($txt, $type = "error"){
    	
    	if($type == "error" && $this->unlink_original_file && $this->tmp_file_path != ""){
    		unlink($this->tmp_file_path);
    	}
    	
    	if($this->feedback_type == "return"){
    		//return self::kill($txt, $type);//array($type => $txt);;
    		if($type == "error"){
    		  throw new Exception(json_encode( array($type => $txt)));
    		 }else{
    		 	return array($type => $txt);
    		 }
    	 }
    	 
    	done_json($txt, $type);
     }

    public function __get($param) {
        if (isset($this->data[$param])) {
            return $this->data[$param];
        } else {
            return null;
        }
      }

    public function __isset($param) {
        return isset($this->data[$param]);
      }

    public function __set($param, $value) {
        $this->data[$param] = $value;
      }
 }


?>