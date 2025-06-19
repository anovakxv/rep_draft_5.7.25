<?php


/* api function begin
 $aTmpObj['type'] = 'activity';//activity - following; my_news - logged in user
$aTmpObj['keyword'] = 'a';//for my_news only
$aTmpObj['limit'] = '50';
$aTmpObj['offset'] = '0';
*/

function api_get_activities($aObj, $LUser){
	global $aGActivitiesTables;
	if($LUser['id'] == '')done_json("Login error!");
	$delete_older_then = 0;

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be < 4096");
	$aData = array();


	$sql = "SELECT COUNT(*) FROM `activities` WHERE `read` = '0' AND (`users_id1` <> '".mv($LUser['id'])."' AND `users_id2` = '".mv($LUser['id'])."')";
	$res = mysql_query($sql) or die(mysql_error().': '.$sql);
	$new_activities = mysql_result($res, 0, 0);


	if($aObj['type'] == 'activity'){
		$aFriendsIDs = get_users_ff_ids($LUser['id'], true);
		if(count($aFriendsIDs) == 0){
			$sql = "";
		}else{
			$sql = "SELECT * FROM `activities` WHERE `users_id1` IN (".implode(", ", $aFriendsIDs).") OR `users_id2` IN (".implode(", ", $aFriendsIDs).") ORDER BY `id` DESC LIMIT ".$offset.", ".$limit;
		}

	}else{

		$aSQLs = array();
		$aSQLs[] = "(a.`users_id1` <> '".mv($LUser['id'])."' AND a.`users_id2` = '".mv($LUser['id'])."')";
		$aSQLs[] = " a.`users_id2` = u.`id` ";
		if($aObj['keyword'] != ""){
			$aSQLs[] = "LOWER(CONCAT_WS(' ', u.`fname`, u.`lname`)) LIKE '%".mv(strtolower($aObj['keyword']))."%'";
		}

		$sql = "SELECT a.* FROM `activities` as a, `users` as u WHERE ".implode(" AND ", $aSQLs)." ORDER BY a.`id` DESC LIMIT ".$offset.", ".$limit;
	}


	$aData = array();
	$aUsers = array();
	$aImportData = array();

	if($sql != ""){
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				if($delete_older_then == 0)$delete_older_then = $row['id'];
				$the_other = ($row['users_id1'] == $LUser['id'])?$row['users_id2']:$row['users_id1'];
				$aUsers[$the_other] = $the_other;

				if($row['data_type1'] != "" && $row['data_id1'] != ""){
					if(!isset($aImportData[$row['data_type1']]))$aImportData[$row['data_type1']] = array();
					$aImportData[$row['data_type1']][$row['data_id1']] = $row['data_id1'];
				}

				if($row['data_type2'] != "" && $row['data_id2'] != ""){
					if(!isset($aImportData[$row['data_type2']]))$aImportData[$row['data_type2']] = array();
					$aImportData[$row['data_type2']][$row['data_id2']] = $row['data_id2'];
				}

				$aData[] = $row;
			}
		}
	}

		
	if(count($aUsers)){
		$sql = "SELECT * FROM `users` WHERE `id` IN (".implode(", ", $aUsers).")";
		$aUsers = get_users_from_sql($sql, $LUser);
	}
		
		
	$aOther = array();
		
	if(count($aImportData)){

		foreach($aImportData as $key => $val){
			if(!$aGActivitiesTables[$key] || !is_array($val) || count($val) == 0)continue;
			if(!isset($aOther[$key]))$aOther[$key] = array();
				
			$sql22 = "SELECT * FROM `".$key."` WHERE `id` IN (".implode(", ", $val).")";
			$res22 = mysql_query($sql22) or die(mysql_error());
			if(mysql_num_rows($res22)){
				while($row22=mysql_fetch_assoc($res22)){
					$aOther[$key][] = $row22;
				}
			}
		}

	}
		
		
	if($delete_older_then){
		$sql = "UPDATE `activities` SET `read` = '1' WHERE `read` = 0 AND (`users_id1` <> '".mv($LUser['id'])."' AND `users_id2` = '".mv($LUser['id'])."') AND `id` <= '".$delete_older_then."'";
		$res = mysql_query($sql) or die(mysql_error());
	}
		
	$aRet = array();
	$aRet['aUsers'] = $aUsers;
	$aRet['aData'] = $aData;
	$aRet['aOther'] = $aOther;
	$aRet['new_activities_count'] = $new_activities;

	done_json($aRet, "result");
}
/* api function end */


/* api function begin
 */

function api_mark_all_activities_as_read($aObj, $LUser){
	if($LUser['id'] == '')done_json("Login error!");
	
	mark_all_activities_as_read($LUser['id']);
	
   done_json("ok", "result");
}
/* api function end */



function mark_all_activities_as_read($users_id){

	$sql = "UPDATE `activities` SET `read` = '1' WHERE `read` = 0 AND `users_id2` = '".mv($users_id)."'";
	$res = mysql_query($sql) or die(mysql_error());
}


/* api function begin
 $aTmpObj['keyword'] = '';
$aTmpObj['limit'] = '50';//optional
$aTmpObj['offset'] = '0';//optional
 $aTmpObj['__return_result'] = '';
*/

function api_get_users_types($aObj, $LUser){
		
	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");
		
	$aConds = array();

	$aConds[] = " `visible`  = '1' ";

	if($aObj['keyword'] != ""){
		$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `user_types` ".$sql_cond." ORDER BY `title` ASC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[] = $row;
		}
	}
	
	if ($aObj['__return_result'] == '1'){
		return $aData;
	}
		
	done_json($aData, "result");
		
}
/* api function end */

/* api function begin
 $aTmpObj['keyword'] = '';
 $aTmpObj['limit'] = '50';//optional
 $aTmpObj['offset'] = '0';//optional
 $aTmpObj['__return_result'] = '';
*/

function api_get_cities($aObj, $LUser){
		
	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");
		
	$aConds = array();

	$aConds[] = " `visible`  = '1' ";

	if($aObj['keyword'] != ""){
		$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `cities` ".$sql_cond." ORDER BY `title` ASC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[] = $row;
		}
	}
		
	if ($aObj['__return_result'] == '1'){
		return $aData;
	 }
	
	done_json($aData, "result");
		
}
/* api function end */

/* api function begin
 $aTmpObj['keyword'] = '';
$aTmpObj['limit'] = '50';//optional
$aTmpObj['offset'] = '0';//optional
 $aTmpObj['__return_result'] = '';
*/

function api_get_categories($aObj, $LUser){

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");

	$aConds = array();

	$aConds[] = " `visible`  = '1' ";

	if($aObj['keyword'] != ""){
		$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `categories` ".$sql_cond." ORDER BY `title` ASC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[] = $row;
		}
	}

	if ($aObj['__return_result'] == '1'){
		return $aData;
	}
	
	
	done_json($aData, "result");

}
/* api function end */


/* api function begin
 $aTmpObj['keyword'] = '';
 $aTmpObj['goal_types_id'] = '1';
 $aTmpObj['limit'] = '50';//optional
 $aTmpObj['offset'] = '0';//optional
  $aTmpObj['__return_result'] = '';
*/

function api_get_goal_metrics($aObj, $LUser){

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");

	$aConds = array();

	$aConds[] = " `visible`  = '1' ";

	if($aObj['keyword'] != ""){
		$aConds[] = " `visible`  = '1' ";
	 }
	
	if($aObj['goal_types_id'] != ""){
		$aConds[] = " `goal_types_id` = '".mv($aObj['goal_types_id'])."' ";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `goal_metrics` ".$sql_cond." ORDER BY `title` ASC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[] = $row;
		}
	}
	
	if ($aObj['__return_result'] == '1'){
		return $aData;
	}
	

	done_json($aData, "result");

}
/* api function end */


/* api function begin
 $aTmpObj['keyword'] = '';
$aTmpObj['limit'] = '50';//optional
$aTmpObj['offset'] = '0';//optional
 $aTmpObj['__return_result'] = '';
*/

function api_get_goal_types($aObj, $LUser){

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");

	$aConds = array();

	$aConds[] = " `visible`  = '1' ";

	if($aObj['keyword'] != ""){
		$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `goal_types` ".$sql_cond." ORDER BY `title` ASC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[] = $row;
		}
	}

	if ($aObj['__return_result'] == '1'){
		return $aData;
	}
	
	
	done_json($aData, "result");

}
/* api function end */


/* api function begin
 $aTmpObj['keyword'] = '';
 $aTmpObj['limit'] = '50';//optional
 $aTmpObj['offset'] = '0';//optional
  $aTmpObj['__return_result'] = '';
*/

function api_get_reporting_increments($aObj, $LUser){

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");

	$aConds = array();

	$aConds[] = " `visible`  = '1' ";

	if($aObj['keyword'] != ""){
		$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `reporting_increments` ".$sql_cond." ORDER BY `title` ASC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[] = $row;
		}
	}
	
	if ($aObj['__return_result'] == '1'){
		return $aData;
	}
	

	done_json($aData, "result");

}
/* api function end */


/* api function begin
   $aTmpObj['keyword'] = '';
   $aTmpObj['limit'] = '100';//optional
   $aTmpObj['offset'] = '0';//optional
 */

function api_get_all_static_data($aObj, $LUser){
	
	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];
	
	if($limit == 0)$limit = 50;
	
	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");
	
	$aObj['__return_result'] = '1';
	$aObj['offset'] = $offset;
	$aObj['limit'] = $limit;
	
	
	
	$aRet = array();
	$aRet['aCities'] = api_get_cities($aObj, $LUser);
	$aRet['aUserTypes'] = api_get_users_types($aObj, $LUser);
	$aRet['aCategories'] = api_get_categories($aObj, $LUser);
	$aRet['aGoalMetrics'] = api_get_goal_metrics($aObj, $LUser);
	$aRet['aGoalTypes'] = api_get_goal_types($aObj, $LUser);
	$aRet['aReportingIncrements'] = api_get_reporting_increments($aObj, $LUser);
	$aRet['aSkills'] = api_get_skills($aObj, $LUser);
	
	done_json($aRet, "result");
	
}
/* api function end */

?>