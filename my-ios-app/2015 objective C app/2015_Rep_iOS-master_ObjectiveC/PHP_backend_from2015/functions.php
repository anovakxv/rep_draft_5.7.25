<?php
function stripslashes_array($array) {
  return is_array($array) ?
    array_map('stripslashes_array', $array) : stripslashes($array);
}

function mvs($data){
	return htmlspecialchars(mysql_real_escape_string($data));
}

function mv($data){
	return mysql_real_escape_string($data);
}

function e404(){
	global $RootDomain;
	go($RootDomain.'/e404');
}

 function start_site(){
 	global $SkipSlashes;
 	 
 	$t_array = explode("/", $_SERVER['REQUEST_URI']);

  	if (is_array($t_array) && count($t_array) > 0){
  	  for ($c = 0; $c < $SkipSlashes; $c++){
  	  	unset($t_array[$c]);
  	  }
 	 }
 	  
 	 $n_array = array();
 	 $first = true;
  	if (is_array($t_array) && count($t_array) > 0){
 	  foreach ($t_array as $key => $val){
 	  	if($val == "?" && $first){
 	  	    $first = false;
 	  		continue;
 	  	 }
 	  	$first = false;
        $n_array[] = $val;
 	  }
 	 }
 	 
  	 if (is_array($t_array) && count($t_array) && $t_array[0] == '?'){// FOR IIS
 	 	unset($t_array[0]);
 	  }

 	 if (!isset($n_array[0])){
 	   $n_array[0] = 'home';
 	  }elseif($n_array[0] == ''){
 	   $n_array[0] = 'home';
 	  }
 	  
 	  //print_r($n_array);exit;
 	 return $n_array;
 }
 
 
 function tmp_log($txt, $logfile = "log.log"){
   	 global $RootDir, $StopLogging;
   	 
   	 if($StopLogging == true)return false;
   	 
   	 $log_file = $RootDir."/_tmp/".$logfile;
   	 if(file_exists($log_file) && filesize($log_file) > 1*1024*1024)unlink($log_file);
   	 
     file_put_contents($log_file, date("F j, Y, g:i a").": ".$txt."\r\n", FILE_APPEND);
     return true;	
   }
 
 
function gate($logged = true, $show_login_error=false){
 global $RootDomain;
 
 $login = ($logged)?'login':'profile';
 
 $login_error_txt = ($show_login_error)?'login_error_txt':$login;
 
 if($_SESSION['user']->id == '' && $logged){
    header("Location: ".$RootDomain.'/'.$login_error_txt);
    exit;
 }elseif($_SESSION['user']->id != '' && $logged == false){
   header("Location: ".$RootDomain.'/'.$login_error_txt);
   exit;
 }
}

function home(){
	global $RootDomain;
    header("Location: ".$RootDomain);
    exit;
}

function go($url){
    header("Location: ".$url);
    exit;
}

function go_back($url){
    header("Location: ".((!empty($_SERVER['HTTP_REFERER']))?$_SERVER['HTTP_REFERER']:$url));
    exit;
}

function is($variable){
  	return ($variable != '');
  }
  
function limit_words($string, $word_limit)
{
    $words = explode(" ",$string);
    return implode(" ",array_splice($words,0,$word_limit));
}
  

function get_listing($total_count, $limit, $url, $offset, $aClass = array()){
   	
   	 $listing = "";
   	 $prev="";$next="";
   	 $page = round($offset/$limit);
   	  
   	 if ($total_count > $limit)
   	  {
   	   for($c = 0; $c < $total_count; $c = $c+$limit){

   	   	
   	   	
   	    if ($c == $offset)
   	     {
   	    	if(empty($aClass['1a'])){
    	      $listing .=  ' '.(($c/$limit)+1);
   	    	 }else{
   	    	  $listing .=  '<a class="'.$aClass['1a'].'">'.(($c/$limit)+1).'</a>';
   	    	 }
   	     }else{
   	   	   $style = (!empty($aClass['1b']))?'class="'.$aClass['1b'].'"':'style="color:black;margin:0px 2px;"';
   	       $listing .=  ' <a href="'.str_replace('$digit;', ($c/$limit), $url).'"  '.$style.'>'.($c/$limit+1).'</a> ';
   	      }
   	    }
   	    
   	    /*
      if ($offset > 0){
      	$style = (!empty($aClass[0]))?'class="'.$aClass[0].'"':'style="color:black;margin-right:20px;font-weight:bold;"';
      	$l_cptn = (!empty($aClass['noText']))?'':'Previous';
      	$prev = '<a href="'.str_replace('$digit;', ($page-1), $url).'"  '.$style.'>'.$l_cptn.'</a>';
       }
      
   	  if (($offset/$limit)+1 < ($total_count/$limit)){
   	  	 $style = (!empty($aClass[2]))?'class="'.$aClass[2].'"':'style="color:black;margin-left:20px;font-weight:bold;"';
   	  	 $l_cptn = (!empty($aClass['noText']))?'':'Next';
      	 $next = '<a href="'.str_replace('$digit;', ($page+1), $url).'" '.$style.'>'.$l_cptn.'</a>';
        }*/
   	  }

   	 return $prev.$listing.$next;
  }

function sql_to_time($sql_str){
	
 $adate = explode(" ", $sql_str);
 $adate1 = explode("-", $adate[0]);
 $adate2 = explode(":", $adate[1]);
 if(count($adate2) != 3){
 	$adate2[0] = "00";
 	$adate2[1] = "00";
 	$adate2[2] = "00";
 }
 
 return mktime($adate2[0], $adate2[1], $adate2[2], $adate1[1], $adate1[2], $adate1[0]);
	
}

function time_to_sql($timestamp){
 return date('Y-m-d H:i:s', $timestamp);
}

function sstring($str, $nums){
	$str = htmlspecialchars_decode($str);
	$str = (strlen($str) > $nums)?(substr($str, 0, ($nums-3)).'...'):$str;
	$str = htmlspecialchars($str);
	
	return $str;
}

 function get_youtube_video_id($url){

 	$aurl = explode('/', $url);
    $ret = "";
 	if (is_array($aurl) && count($aurl)){
 		
 	  $next = false;
 	  foreach ($aurl as $key => $val){
 			
 	  	  if ($next){
 	  	  	$ret = $val;
 	  	  	break;
 	  	   }
 	  	  $regular = explode("=", $val);
 	  	  if (isset($regular[0]) && isset($regular[1]) && $regular[0] == 'watch?v'){
 	  	  	$ret = $regular[1];
 	  	  	break;
 	  	  }
 	  	  
 	  	  if ($val == 'v')$next = true;
 	  	  
 		}
 		
 	  if ($ret != ""){
 	  	
 	  	$tret = explode("&", $ret);
 	  	if (is_array($tret) && count($tret)>1){
 	  		$ret = $tret[0];
 	  	 }
 	  	 
 	    $tret = explode("?", $ret);
 	  	if (is_array($tret) && count($tret)>1){
 	  		$ret = $tret[0];
 	  	 }
 	  	
 	   }
 		
 	}
 	return $ret;
 }
 
 
 function get_coordinates($address){
	
  $row = array();
  $address = trim($address);
  
  if (strlen($address) < 3)return $row;
  
  $sql = "SELECT * FROM `coordinates` WHERE lower(`address`) = lower('".mv($address)."')";
  $res = mysql_query($sql) or die(mysql_error());
  if (mysql_num_rows($res)){
     $row = mysql_fetch_assoc($res);
     return $row;
  }else{
    $row = array();
  	$row['country'] = '';
  	$row['state'] = '';
  	$row['city'] = '';
  	$row['zip'] = '';
  	$row['street'] = '';
  	$row['lat'] = '';
  	$row['long'] = '';
  	
  	 //@$data = file_get_contents ("http://maps.google.com/maps/geo?q=urlencode(".$address.")&output=csv&key=ABQIAAAALzxZxZULX9-oXnRMvB1RvxS-ppMTo74UK5LP65eOUWuzYEClfBQGLwC_uVDcU5xIveNkvCVKbhGwCA");
  	 @$data = file_get_contents("http://maps.googleapis.com/maps/api/geocode/json?address=".urlencode($address)."&sensor=true");
     //$data = file_get_contents($RootDir."/pages/json3.json");
     $data = json_decode($data);
     if ($data->status == "OK" )
      {
       for ($c = 0; isset($data->results[$c]); $c++){
         if (!empty($data->results[$c]->address_components))
          {
 	        foreach ($data->results[$c]->address_components as $key => $val){
 		       //echo $val->types[0].' = '.$val->short_name.'<br>';
 		       if ($val->types[0] == 'country')
 		        $row['country'] = $val->short_name;
 		       
 		       if ($val->types[0] == 'administrative_area_level_1')
 		         	$row['state'] = $val->short_name;
 		         	
 		       if ($val->types[0] == 'administrative_area_level_2' && $row['city'] == "")
 		         	$row['city'] = $val->short_name;
 		         	
 		       if ($val->types[0] == 'locality')
 		         	$row['city'] = $val->short_name;
 		         	
 		       if ($val->types[0] == 'postal_code')
 		         	$row['zip'] = $val->short_name;
 		         	
 	          }
 	          
 	          
 	          if ($row['zip'] == ''){
 	          	$row['zip'] = $address;
 	          }
 	          
 	          
 	          if (!empty($data->results[$c]->geometry->location)){
  	           $row['lat'] = $data->results[$c]->geometry->location->lat;
  	           $row['long'] = $data->results[$c]->geometry->location->lng;
 	          }
 	          
 	          
          }
         if ($row['country'] == 'US'){
          break;	
         }
    
        }
     }
     
     $sql = "INSERT INTO `coordinates` 
        (`address`, `country`, `state`, `city`, `zip`, `street`,  `lat` , `long`)
 VALUES ('".mv($address)."', '".mvs($row['country'])."', '".mvs($row['state'])."', '".mvs($row['city'])."', '".mvs($row['zip'])."', '".mvs($row['street'])."', '".mvs($row['lat'])."', '".mvs($row['long'])."');";
     $res = mysql_query($sql) or die(mysql_error());
    
   }
	
	return $row;
}
 
 function prepare_message($txt){
 	
  global $RootDomain;
  $symbols='[\, \!\?\.\:\%\^\;]';

  $txt = ' '.$txt.' ';

//  $txt = preg_replace("|http://[a-zA-Z0-9\.\-\_](.*)[ ,]|U", '<a href="\\0">\\0</a>', $txt);

   preg_match_all("|http(s?)://[a-zA-Z0-9\.\-\_](.*)[ ,]|U", $txt, $found);
   if (is($found[1]) && is_array($found[1]))
    { //	print_r($found);//exit;
 	  foreach ($found[0] as $key => $val){
              if (strlen($val) > 32){
                 $bitly = new bitly('halcyonthird', 'R_53789d8c6dfa7e320b95d96d93b84e2a');
                 $data = $bitly->shorten(trim($val), true);
                 $the_lnk = $data['shortUrl'];
               }else{
                 $the_lnk = trim($val);
                }
 		$replace_in_single_area = str_replace($val, '<a href="'.$the_lnk.'" target="_blank">'.$the_lnk.'</a> ', $found[0][$key]);
 		$txt = str_replace($found[0][$key], $replace_in_single_area, $txt);
 	   }
    }
 /*
   preg_match_all("|".$symbols."#(.*)".$symbols."|U", $txt, $found);
   if (is($found[1]) && is_array($found[1]))
    { 	
 	  foreach ($found[1] as $key => $val){
 		$replace_in_single_area = str_replace($val, '<a href="'.$RootDomain.'/home/?trend='.urlencode(trim($val)).'">'.$val.'</a>', $found[0][$key]);
 		$txt = str_replace($found[0][$key], $replace_in_single_area, $txt);
 	   }
    }*/

    $txt_new = $txt;

  return trim($txt_new);

 }
 
 function makeSeo($string, $size = 0) {
   	if ($size > 0){
   	  $string=sstring($string, $size);
   	 }
    //Unwanted:  {UPPERCASE} ; / ? : @ & = + $ , . ! ~ * ' ( )
    $string = strtolower($string);
    //Strip any unwanted characters
    $string = preg_replace("/[^a-z0-9_\s-]/", "", $string);
    //Clean multiple dashes or whitespaces
    $string = preg_replace("/[\s-]+/", " ", $string);
    //Convert whitespaces and underscore to dash
    $string = preg_replace("/[\s_]/", "-", $string);
    return $string;
}

function get_file_ext($name){
	
	$extension = "";
	
 	if (preg_match("/^(.*)\.(.*)$/", $name, $aFilename)){
		$extension = $aFilename[2];
	  }
	  
	if(strlen($extension) > 5)$extension = substr($extension, 0, 5);
	  
	return $extension;
 }
 
 function done_json($txt, $type = "error"){
 	$json = array();
 	$json[$type] = $txt;
 	if($_REQUEST['__debug_mode'] != ""){
 		$data = print_r($json, true);
 		$data = str_replace("\n", "<br>", $data);
 		$data = str_replace(" ", "&nbsp;", $data);
 		echo '<font style="font-size:12px, font:arial,sans-serif;">'.$data.'</font>';
 	}else{
 	 echo json_encode($json);
 	}
 	exit;
 }
 
 
 function return_json($txt, $type = "error"){
 	$json = array();
 	$json[$type] = $txt;
 	return json_encode($json);
 }
 
 
 function deleteDir($dirPath) {
    if (! is_dir($dirPath)) {
        //throw new InvalidArgumentException('$dirPath must be a directory');
        return;
    }
    if (substr($dirPath, strlen($dirPath) - 1, 1) != '/') {
        $dirPath .= '/';
    }
    $files = glob($dirPath . '*', GLOB_MARK);
    foreach ($files as $file) {
        if (is_dir($file)) {
            deleteDir($file);
        } else {
            unlink($file);
        }
    }
    rmdir($dirPath);
}

function get_zip_by_ip($ip = "", $ignore_session = false){
 	global $Logged;
 	
  	if($ignore_session == false && $Logged && !empty($_SESSION['user']->zip)){
 		return $_SESSION['user']->zip;
 	 }
 	
 	if(!empty($_SESSION['got_zip_by_ip'])){
 		return $_SESSION['got_zip_by_ip'];
 	 }
 	
 	if($ip == ''){
 		$ip = $_SERVER['REMOTE_ADDR'];
 	  }
 	  
  $ip = sprintf("%u", ip2long($ip));
  $sql = "SELECT `zip` FROM `ip_by_zip` WHERE `c1` < (".mv($ip)."+1) AND `c2` > (".mv($ip)."-1)";
  $res = mysql_query($sql) or die(mysql_error());
  if(mysql_num_rows($res)){
    $zip=mysql_result($res,0,0);
    $_SESSION['got_zip_by_ip'] = $zip;
  	return $zip;
   }
  return "";
 }
 
   function get_age($date){
    $year   = gmdate('Y');
    $month  = gmdate('m');
    $day    = gmdate('d');
    $days_in_between = (mktime(0,0,0,$month,$day,$year) - strtotime($date))/86400;
    $age_float = $days_in_between / 365.242199; 
    $age = (int)($age_float);
    return $age;
  }
  
 
function execute_curl_request($url, $random_ips = false){
   	global $RandomIPs;
$header=array(
  'User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12',
  'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language: en-us,en;q=0.5',
  'Accept-Encoding: gzip,deflate',
  'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7',
  'Keep-Alive: 115',
  'Connection: keep-alive',
);
  
	  $ch = curl_init();
	  curl_setopt($ch, CURLOPT_URL, $url);
  	  curl_setopt($ch, CURLOPT_HEADER, 0);
	  curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	  curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
	  curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
  	  curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true );
	  curl_setopt($ch, CURLOPT_COOKIEFILE,'cookies.txt');
	  curl_setopt($ch, CURLOPT_COOKIEJAR,'cookies.txt');
  	  curl_setopt($ch, CURLOPT_USERAGENT, "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12" );
	  curl_setopt($ch, CURLOPT_REFERER, '');
	  curl_setopt($ch, CURLOPT_ENCODING, '');
	  curl_setopt($ch, CURLOPT_HTTPHEADER,$header);
	  
   	  if($random_ips && $RandomIPs > 0){
 		 $server = rand(0, $RandomIPs);
    	 curl_setopt($ch, CURLOPT_INTERFACE, "eth".$server);
  	   }
  
	  $data = curl_exec($ch);
	  curl_close($ch);
	  return $data;
   }
   
   function gps_distance($lat1, $lon1, $lat2, $lon2, $unit = "M") {
	 
      $theta = $lon1 - $lon2;
	  $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
	  $dist = acos($dist);
	  $dist = rad2deg($dist);
      $miles = $dist * 60 * 1.1515;
	  $unit = strtoupper($unit);
	 
	  if ($unit == "K") {
	    return ($miles * 1.609344);
	  } else if ($unit == "N") {
	      return ($miles * 0.8684);
	    } else {
	        return $miles;
	    }
   }
   
   function htmlspecialchars_array($aData){
   	  
  	  $new_array = array();
  	  foreach($aData as $key =>$val){
  	  	 if(is_array($val)){
  	  	 	$new_array[$key] = htmlspecialchars_array($val);
  	  	 }else{
  	  	 	$new_array[$key] = htmlspecialchars($val);
  	  	  }
  	   }
  	 return $new_array;
   }
   
   
   function get_include_contents($filename) {
    if (is_file($filename)) {
        ob_start();
        include $filename;
        return ob_get_clean();
    }
    return false;
   }
   
   
    function get__form_token($ret="val"){
   	
  	  if(!isset($_SESSION['__form_token']['the_key'])){
   	    $the_key = md5($_SESSION['user']->id.'_'.time().$_SESSION['user']->password.'87');
   	    $_SESSION['__form_token']['the_key'] = $the_key;
  	   }else{
  	   	$the_key = $_SESSION['__form_token']['the_key'];
  	   }

   	   if ($ret == 'get') return '__form_token='.$the_key;
   	   if ($ret == 'post') return '<input type="hidden" name="__form_token" value="'.$the_key.'">';
   	   
   	   return $the_key;
    }
    
  function check__form_token($done_json_on_false = true, $text = "__form_token"){
  	
  	 if($_REQUEST['__form_token'] != "" && isset($_SESSION['__form_token']['the_key']) && $_SESSION['__form_token']['the_key'] == $_REQUEST['__form_token']){
  	   //unset($_SESSION['__form_token'][$_REQUEST['__form_token']]);
  	   return true;	
  	 }
  	 
  	if($done_json_on_false)done_json($text);
  	return false;
   }
   
   function get_random_string($length = 10){
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, strlen($characters) - 1)];
    }
    return $randomString;
    
   }
   
   function generate_uid($table, $length = 10, $loop = 128){

   	  for($c = 0; $c < $loop; $c++){
   	  	 $uid = get_random_string($length);
   	  	 $sql = "SELECT COUNT(*) FROM `".mv($table)."` WHERE `uid`='".mv($uid)."'";
 		 $res = mysql_query($sql) or die(mysql_error());
 		 $xs = mysql_result($res, 0, 0);
 		 if($xs == 0)return $uid;
   	   }
   	  return "";
    }
    
 
 
 function timestamp_relative_string($timestamp, $rounding=900) {
 	
    //Round to (default) 15 mins
    $timestamp = floor($timestamp/$rounding)*$rounding;

    //Today
    if($timestamp<mktime(0, 0, 0, date("m"), date("d")-1, date("y")))
      return date("D jS M", $timestamp);
    elseif($timestamp<mktime(23, 59, 59, date("m"), date("d")-1, date("y")))
      return "Today @ ".date("G:i", $timestamp);
    elseif($timestamp<time())
      return "Today @ ".date("G:i", $timestamp);//earlier today
    elseif($timestamp<mktime(23, 59, 59, date("m"), date("d"), date("y")))
      return "Today @ ".date("G:i", $timestamp);
    elseif($timestamp<mktime(23, 59, 59, date("m"), date("d")+1, date("y"))) //Tomorrow
      return "Tomorrow @ ".date("G:i", $timestamp);
    elseif($timestamp<mktime(23, 59, 59, date("m"), date("d")+7, date("y"))) //Next Week
      return "On ".date("l", $timestamp)." at ".date("G:i", $timestamp);
    else 
      return date("D jS M", $timestamp);
  }
  
  
function time_elapsed_string($ptime)
  {
    $etime = time() - $ptime;

    if ($etime < 1)
    {
        return '0 seconds';
    }

    $a = array( 12 * 30 * 24 * 60 * 60  =>  'year',
                30 * 24 * 60 * 60       =>  'month',
                24 * 60 * 60            =>  'day',
                60 * 60                 =>  'hour',
                60                      =>  'minute',
                1                       =>  'second'
                );

    foreach ($a as $secs => $str)
    {
        $d = $etime / $secs;
        if ($d >= 1)
        {
            $r = round($d);
            return $r . ' ' . $str . ($r > 1 ? 's' : '') . ' ago';
        }
    }
}
 


 function delete_activity($user_id1, $user_id2, $type, $data_id1 = "0", $data_type1 = "", $data_id2 = "0", $data_type2 = "", $swap = false){
  	
  if($user_id1 == "")$user_id1 = "0";
  if($user_id2 == "")$user_id2 = "0";
  if($data_id1 == "")$data_id1 = "0";
  if($data_id2 == "")$data_id2 = "0";
  
 	 $users_sql = ($swap)?" (`users_id1`='".mv($user_id2)."' AND `users_id2`='".mv($user_id1)."') OR (`users_id1`='".mv($user_id1)."' AND `users_id2`='".mv($user_id2)."') ":"`users_id1`='".mv($user_id1)."' AND `users_id2`='".mv($user_id2)."'";
 	
 	 $next = ($data_type2 != "")?" AND `data_id2`='".mvs($data_id2)."' AND `data_type2`='".mvs($data_type2)."' ":"";
 	 
     $sql = "DELETE FROM `activities` WHERE (".$users_sql.") AND 
  	`type`='".mvs($type)."' AND `data_id1`='".mv($data_id1)."' AND `data_type1`='".mvs($data_type1)."'".$next;
    $res = mysql_query($sql) or die(mysql_error());
    
    }
	
function register_new_activity($user_id1, $user_id2, $type, $push, $data_id1 = "0", $data_type1 = "", $data_id2 = "0", $data_type2 = ""){
 	
	
  if($user_id1 == "")done_json("user_id1 is empty!");
  if($user_id2 == "")$user_id2 = "0";
  if($data_id1 == "")$data_id1 = "0";
  if($data_id2 == "")$data_id2 = "0";
  
  if($type == "")done_json("type is empty or wrong!");
  
  if(($data_id1 != "0" && $data_type1 == "") || ($data_id1 == "0" && $data_type1 != ""))done_json("data_type AND data_id should be together (".$data_id1.", ".$data_type1.")!");
  if(($data_id2 != "0" && $data_type2 == "") || ($data_id2 == "0" && $data_type2 != ""))done_json("data_type AND data_id should be together (".$data_id1.", ".$data_type1.")!");
  
  if($data_type1 != "" && $data_id1 != "0"){
  	 $sql = "SELECT COUNT(*) FROM `".mv($data_type1)."` WHERE `id`='".mv($data_id1)."'";
 	 $res = mysql_query($sql) or die(mysql_error());
 	 $xs = mysql_result($res, 0, 0);
 	 if($xs == 0)done_json("that data_id1 doesn't exist!");
   }
   
  if($data_type2 != "" && $data_id2 != "0"){
  	 $sql = "SELECT COUNT(*) FROM `".mv($data_type2)."` WHERE `id`='".mv($data_id2)."'";
 	 $res = mysql_query($sql) or die(mysql_error());
 	 $xs = mysql_result($res, 0, 0);
 	 if($xs == 0)done_json("that data_id2 doesn't exist!");
   }
  
   //if($type == 'new_friend' || $type == 'new_friend_request')register_new_push_alert($user_id2, $type, $user_id1);
   
  /*
  $sql = "SELECT COUNT(*) FROM `users_notification_settings` WHERE `user_id`='".mv($user_id)."' AND `".$aAlertTypes[$type]."`='1'";
  $res = mysql_query($sql) or die(mysql_error());
  $xs = mysql_result($res, 0, 0);

  if($xs > 0){*/
  	
  	$sql = "SELECT COUNT(*) FROM `activities` WHERE `users_id1`='".mv($user_id1)."' AND `users_id2`='".mv($user_id2)."' AND 
  	`type`='".mvs($type)."' AND `data_id1`='".mv($data_id1)."' AND `data_type1`='".mvs($data_type1)."' AND 
  	`data_id2`='".mvs($data_id2)."' AND `data_type2`='".mvs($data_type2)."'";
  	//echo $sql;//exit;
    $res = mysql_query($sql) or die(mysql_error());
    if (mysql_result($res, 0, 0) == 0){
     $sql = "INSERT INTO `activities` (`users_id1`, `users_id2`, `type`, `push`, `data_id1`, `data_type1`, `data_id2`, `data_type2`) VALUES (
     '".mv($user_id1)."', '".mv($user_id2)."', '".mvs($type)."', '".mv($push)."', '".mvs($data_id1)."', '".mvs($data_type1)."', '".mvs($data_id2)."', '".mvs($data_type2)."');";
     $res = mysql_query($sql) or die(mysql_error());
    }
   /*}*/
 
  
 }
    
 
 
 function fix_phone($phone){
 	 
 	$phone = trim($phone);
 	if($phone == "")return "";
 	$phone = (int)$phone;
 	if($phone == 0)return "";
 	if(strlen($phone) == 10)$val = '1'.$phone;
 
 	return $phone;
 	 
 }
 
 

 function check_existance_by_id($table, $id){
 
 	if($table == "" || $id == "")done_json("empty table/id data");
 
 	$sql = "SELECT COUNT(*) FROM `".mv($table)."` WHERE `id`='".mv($id)."'";
 	$res = mysql_query($sql) or die(mysql_error());
 	if(mysql_result($res, 0, 0) == 0)done_json("the ".$table.'_'.$id." doesn't exist!");
 
 	return true;
 }
 
 

 function delete_db_row_and_related_data($table, $id, $res_log_txt = "", $aRecLog = array()){
 	global $dbBase, $aS3FilesTables;
 	
 	//echo 'ONSTARRT:**'.count($aRecLog).'***';
 	//Array ( [TABLE_NAME] => activities [COLUMN_NAME] => users_id1 )
 	$aTablesToClear = array();

 	if (in_array($table."_".$id, $aRecLog)){
 		$res_log_txt .= "duplicate 1";
 		return "duplicate 1";
 	}
 	$aRecLog[] = $table."_".$id;
 
 	$aKeys = array();
 	$aKeys[$table."_id"] = "'".$table."_id'";
 	$aKeys[$table."_id1"] = "'".$table."_id1'";
 	$aKeys[$table."_id2"] = "'".$table."_id2'";

 
 	if(!isset($aTablesToClear[$table]))$aTablesToClear[$table] = array();
 	if(isset($aTablesToClear[$table]['id']))return 'duplicate 2';
 	$aTablesToClear[$table]['id'] = "`id` = '".mv($id)."'";
 	
	$s3_files_table_key = array_search($table, $aS3FilesTables);
	if($s3_files_table_key != ""){
		
		$sql = "SELECT `id`, `users_id` FROM `s3_content` WHERE `tbl_index` = '".mv($s3_files_table_key)."' and `tbl_id` = '".mv($id)."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				
 				$S3Obj = new S3Content($row['users_id']);
 				$S3Obj->load($row['id']);
 				$S3Obj->delete(); 
 				$res_log_txt .= '<br>S3 deleted: '.$row['id'].'<br>';
			 }
		 }
		
	 }
	 
	 
	 
	 $sql = "DELETE FROM `activities` WHERE (`data_type1`='".mv($table)."' AND `data_id1` = '".mv($id)."') OR (`data_type2`='".mv($table)."' AND `data_id2` = '".mv($id)."')";
	 $res = mysql_query($sql) or die(mysql_error());
	 $res_log_txt .= '<br>activities deleted: '.mysql_affected_rows().'<br>';
	 

	$sql = "SELECT DISTINCT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME IN (".implode(",", $aKeys).") AND TABLE_SCHEMA='".mv($dbBase)."'";
	$res = mysql_query($sql) or die(mysql_error());
 	if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 			if(!isset($aTablesToClear[$row['TABLE_NAME']]))$aTablesToClear[$row['TABLE_NAME']] = array();
 			$aTablesToClear[$row['TABLE_NAME']][$row['COLUMN_NAME']] = "`".$row['COLUMN_NAME']."` = '".mv($id)."'";
 		}
 	}
 
 	
 	
 	if(count($aTablesToClear)){
 		foreach($aTablesToClear as $key => $val){


 			if($key == 's3_content'){
 			
 				$sql22 = "SELECT `id`, `users_id` FROM `s3_content` WHERE ".implode(" OR ", $val)."";
 				$res22 = mysql_query($sql22) or die(mysql_error());
 				if(mysql_num_rows($res22)){
 					while($row22=mysql_fetch_assoc($$res22)){
 						$S3Obj = new S3Content($row22['users_id']);
 						$S3Obj->load($row22['id']);
	 					$S3Obj->delete();
 						$res_log_txt .= '<br>S3 deleted: '.$row22['id'].'<br>';
 					}
 				}else{
 					$res_log_txt .= '<br>S3 not deleted: '.$row22['id'].'; not found<br>';
 				}
 				continue;
 			}
 			
 
 			$sql22 = "SELECT `id` FROM `".$key."` WHERE ".implode(" OR ", $val)."";
 			
 		 	if (in_array($sql22, $aRecLog)){
 				//echo $sql22.' -  found!<br>';
 				$res_log_txt .= '<br>in array: '.$sql22.'<br>';
 				continue;
 			}else{
 				//echo $sql22.' - <b>not found!</b><br>';
 			 }
 			$aRecLog[] = $sql22;
 			
 			$res22 = mysql_query($sql22) or die(mysql_error());
 			if(mysql_num_rows($res22)){
 				while($row22=mysql_fetch_assoc($res22)){
 					if (!in_array($key."_".$row22['id'], $aRecLog)){
 						$res_log_txt = delete_db_row_and_related_data($key, $row22['id'], $res_log_txt, $aRecLog);
 					}
 				}

 				
 				$sql22 = "DELETE FROM `".$key."` WHERE ".implode(" OR ", $val)."";
 				$res22 = mysql_query($sql22) or die(mysql_error());
 				$res_log_txt .= '<br>'.$sql22.': '.mysql_affected_rows().'<br>';
 			}else{
 				$res_log_txt .= '<br>nothing found: '.$sql22.'<br>';
 			}
 
 		}
 	}
  return $res_log_txt;
 }
 
 
 function mysql_custom_query($sql){
 	global $gShowDBQueryOnError, $gSaveDBLog, $Logged;
 /*
 	if(rand(0, 256) == 32){
 		$sql22 = "DELETE FROM `mysql_queries_log` WHERE `timestamp` < NOW() - INTERVAL 30 DAY";
 		$res22 = mysql_query($sql22) or die(mysql_error());
 	}*/
 
 
 	$plus = ($gShowDBQueryOnError)?$sql:"";
 	$user_id = (isset($_SESSION['user']) && $_SESSION['user']->id != "")?$_SESSION['user']->id:"0";
 
 	$aInsert = array();
 	$aInsert["`users_id`"] = "'".mv($user_id)."'";
 	$aInsert["`sql`"] = "'".mvs($sql)."'";
 
 	$starttime = microtime(true);
 	$res = mysql_query($sql)/* or die(mysql_error().': '.$plus)*/;
 	$duration = microtime(true) - $starttime;
 
 	if(!$res){
 		$aInsert["`error_num`"] = "'".mysql_errno()."'";
 		$aInsert["`error_txt`"] = "'".mvs(mysql_error())."'";
 	}
 
 	$aInsert["`duration`"] = "'".$duration."'";
 
 /*
 	if(!$res || ($gSaveDBLog <= $duration && $gSaveDBLog != -1)){
 		$sql22 = "INSERT INTO `mysql_queries_log` (".implode(", ", array_keys($aInsert)).")VALUES (".implode(", ", $aInsert).");";
 		$res22 = mysql_query($sql22) or die(mysql_error());
 		$mysql_queries_log_id = mysql_insert_id();
 	}*/
 
 
 	if(!$res){
 		if($gShowDBQueryOnError)done_json($aInsert, "error", true);
 		done_json("mysql_queries_log_id: ".$mysql_queries_log_id, "error", true);
 	}
 	return $res;
 }
 
 
 function cron_log_start($cron_filename, $timeout = 3600){
 	global $RootDomain;
 
 	$sql = "SELECT * FROM `cron_log` WHERE `name`='".mv($cron_filename)."'";
 	$res = mysql_custom_query($sql);
 	if(mysql_num_rows($res)){
 		$row=mysql_fetch_assoc($res);
 		if(time() - $row['lastnote'] > $timeout || $_GET['todo'] == 'run_anyway'){
 			$sql = "DELETE FROM `cron_log` WHERE `name` = '".mv($cron_filename)."';";
 			$res = mysql_custom_query($sql);
 		}else{
 			$func_file = str_replace(".php", "", $cron_filename);
 			echo 'CRON IS ALREADY EXECUTING...  <a href="'.$RootDomain.'/func/'.$func_file.'/?todo=run_anyway">run anyway</a>';
 			exit;
 		}
 	}
 
 	$sql = "INSERT INTO `cron_log` (`name`, `lastnote`) VALUES ('".mv($cron_filename)."', '".time()."');";
 	$res = mysql_custom_query($sql);
 
 
 }
  
 function cron_log_end($cron_filename){
 
 	$sql = "DELETE FROM `cron_log` WHERE `name` = '".mv($cron_filename)."';";
 	$res = mysql_custom_query($sql);
 
 }
 
 function cron_log_last_note($cron_filename){
 
 	$sql22 = "UPDATE `cron_log` SET `lastnote` = '".time()."' WHERE `name`='".mv($cron_filename)."'";
 	$res22 = mysql_query($sql22) or die(mysql_error());
 }
 
?>