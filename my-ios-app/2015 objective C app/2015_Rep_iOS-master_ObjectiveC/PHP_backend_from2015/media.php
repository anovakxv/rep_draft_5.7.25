<?php 


function image_fix_orientation($image, $filename) {
	$exif = exif_read_data($filename);

	if (!empty($exif['Orientation'])) {
		switch ($exif['Orientation']) {
			case 3:
				$image = imagerotate($image, 180, 0);
				break;

			case 6:
				$image = imagerotate($image, -90, 0);
				break;

			case 8:
				$image = imagerotate($image, 90, 0);
				break;
		}
	}

	return $image;
}

function ManualImageResize($inputFile, $outputFile, $x_size, $y_size)
{
	
	  $aExt = array('', 'gif', 'jpeg', 'png');
      $ext_index= exif_imagetype($inputFile);
      if($aExt[$ext_index] == '')return 'Unsupported file format!';
	  $oldFormat = $aExt[$ext_index];
		  
		$openFunction = "imagecreatefrom" . $oldFormat;
		if (function_exists($openFunction))
		{
			$image = $openFunction($inputFile);
			$image = image_fix_orientation($image, $inputFile);
			
			$width = imagesx($image);
			$height = imagesy($image);

			 if ($width < $height){
		       $newWidth=$x_size;
			   $newHeight=($height*$newWidth)/$width;
			  }else{
		       $newHeight=$y_size;
			   $newWidth=($width*$y_size)/$height;
			  }
			  
			 if($newWidth < $x_size){
		       $newWidth=$x_size;
			   $newHeight=($height*$newWidth)/$width;
			  }elseif($newHeight < $y_size){
		       $newHeight=$y_size;
			   $newWidth=($width*$y_size)/$height;
			  }
				  	  
			$newImage = imagecreatetruecolor($newWidth, $newHeight);
			imagecopyresampled($newImage, $image, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
			$image = $newImage;
			
			 if ($newWidth == $x_size){
			   $source_x = 0;
			   $source_y = $newHeight/2 - $y_size/2;
			   $newHeight = $y_size;
			  }else{
			   $source_y = 0;
			   $source_x = $newWidth/2 - $x_size/2;
			   $newWidth = $x_size;
			  }

			$newImage = imagecreatetruecolor($x_size, $y_size);
			imagecopyresampled($newImage, $image, 0, 0, $source_x, $source_y, $newWidth, $newHeight, $x_size, $y_size);
			
			//$saveFunction = "image".$oldFormat;
			$saveFunction = "imagejpeg";
			if (function_exists($saveFunction)){
				$saveFunction($newImage, $outputFile) or die("Error while saving image");
			}else die("Unsupported destination format");
		}
		else die("Unsupported file extension! ");

}

function is_the_picture_is_good($inputFile){

	  $aExt = array('', 'gif', 'jpeg', 'png');
	  
      $ext_index= exif_imagetype($inputFile);
      
      if($aExt[$ext_index] == '')return 'Unsupported file format! ('.$ext_index.')';
      
	  $oldFormat = $aExt[$ext_index];
	  
		$openFunction = "imagecreatefrom" . $oldFormat;
		if (function_exists($openFunction))
		{
			  $image = $openFunction($inputFile);

			  if ($image == ''){echo 'i++';
			  	return "Something wrong with ".$oldFormat." file";
			  }
			  
			  $width = imagesx($image);
			  $height = imagesy($image);

			if ($width < 32 || $width > 20000 || $height < 32 || $height > 20000){
			  return "Wrong image size or format";
			}
		}else return "Unsupported file extension! ";

  return "";
}

function ProportionalImageResize($inputFile, $outputFile, $x_size, $y_size, $ifbiggerthan = 0)
{

	  $aExt = array('', 'gif', 'jpeg', 'png');
      $ext_index= exif_imagetype($inputFile);
      if($aExt[$ext_index] == '')return 'Unsupported file format!';
	  $oldFormat = $aExt[$ext_index];
	  
		$openFunction = "imagecreatefrom" . $oldFormat;
		if (function_exists($openFunction))
		{
			$image = $openFunction($inputFile);
			$image = image_fix_orientation($image, $inputFile);
			$width = imagesx($image);
			$height = imagesy($image);
			
			//remove for both x and y re-resize
			$y_size = round(($x_size * $height) / $width);
			
			if ($width < $ifbiggerthan){
				copy($inputFile, $outputFile);
				return;
			}
			
				  if($height < $width){
				  	  $newHeight=$y_size;
				  	  $newWidth=($y_size*$width)/$height;
				  	  if ($newWidth > $x_size){
				  	   $newWidth=$x_size;
				  	   $newHeight=($x_size*$height)/$width;
				  	  }
				  	  
				   }else{
				  	  $newWidth=$x_size;
				  	  $newHeight=($x_size*$height)/$width;
				  	  if ($newHeight > $y_size){
				  	   $newHeight=$y_size;
				  	   $newWidth=($y_size*$width)/$height;
				  	  }
				  	}

			$newImage = imagecreatetruecolor($newWidth, $newHeight);
			imagecopyresampled($newImage, $image, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
			
			$saveFunction = "image".$oldFormat;
			if (function_exists($saveFunction)){
				$saveFunction($newImage, $outputFile) or die("Error while saving image");
			}else return "Unsupported destination format";
		}
		else return "Unsupported file extension! ";

}


function ffmpeg_image_convertor($image, $new_image){
 	$s = "/usr/local/bin/ffmpeg -i ".$image." -vf scale=800:-1 ".$new_image." 2>&1";
 	$convertation_log = shell_exec($s);
 	return $convertation_log;
 }

function do_we_need_resize($video, $size = 640){
	
	$s = "ffmpeg -i ".$video." 2>&1";
	$video_info = shell_exec($s);
    preg_match_all("|Video\:(.*)tbc|U", $video_info, $out, PREG_PATTERN_ORDER);
    if($out != ""){
    	$val = trim($out[2][0]);
       $tmsp = explode(',', $val);	
   $resolution = trim($tmsp['2']);
   $resolution = explode(' ', $resolution);
   $resolution = $resolution[0];
   $resolution = explode('x', $resolution);
   if (count($resolution) == 2){
   	  //echo '*d'.$resolution[0].'x'.$resolution[1].'d*';
   	  return ($resolution[0] > $size)?1:-1;
     }
    }
    return 0;
 }

function make_video_thumb($video, $thumbnail){
	 
	//$s = "ffmpeg -i $video -deinterlace -an -ss 1 -t 00:00:01 -r 1 -y -vcodec mjpeg -f mjpeg $thumbnail 2>&1";
	$s = "ffmpeg -i ".$video." -ss 00:00:00.800 -f image2 -vframes 1 ".$thumbnail."  2>&1";
	
	//bslog($s);
    $log = shell_exec($s);
    //echo $log;
	$s = "ffmpeg -i ".$video." 2>&1";
	//bslog($s);
    $video_info = shell_exec($s);
    $video_info = str_replace("\r\n", "\n", $video_info);

    preg_match_all("|rotate( *)\:(.*)\n|U", $video_info, $out, PREG_PATTERN_ORDER);
    $degrees = trim($out[2][0]);
    
    if(is_numeric($degrees)){
     $degrees = 0 - $degrees;
     rotate_image($thumbnail, $thumbnail, $degrees);
    }
    
 }
 
 function get_video_length($video){
	
	$s = "ffmpeg -i ".$video." 2>&1";
	$video_info = shell_exec($s);

    preg_match_all("|Duration\:(.*),|U", $video_info, $out, PREG_PATTERN_ORDER);
    if(is_array($out) && count($out)){
    	$tmsp = $out[1][0];
        $tmsp = explode('.', $tmsp);	
       return $tmsp[0];
    }
    return 0;
 }
 
   function get_audio_length($audio){
     return get_video_length($audio);
   }
 
  function rotate_image($infile, $outfile, $degrees){
	$source = imagecreatefromjpeg($infile);
    $rotate = imagerotate($source, $degrees, 0);
    if(file_exists($outfile)){
      unlink($outfile);
    }
    imagejpeg($rotate, $outfile);
 }
?>