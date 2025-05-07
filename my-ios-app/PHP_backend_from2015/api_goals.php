<?php

/* api function begin
 $aTmpObj['goals_id'] = '1';
 $aTmpObj['seconds_from_gmt'] = '10800';
*/
function api_goal_details($aObj, $LUser){
	//if($LUser['id'] == '')done_json("Login error!");
	if($aObj['goals_id'] == "")done_json("goals_id required!");
	 
	 
	$sql = "SELECT * FROM `goals` WHERE `id` = '".mv($aObj['goals_id'])."'";
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
		$aGoal=mysql_fetch_assoc($res);
	}else{
		done_json("the goal doesn't exist");
	}
	 
	 
	$aGoal = manage_goal_row($aGoal, $LUser['id'], $aObj['seconds_from_gmt']);
	$aGoal['aFiles'] = get_s3_files("3", $aGoal['id']);
	 
	done_json($aGoal, "result");
	 
}
/* api function end */
  




/* api function begin
 $aTmpObj['users_id'] = '';//team + leader + owner
 $aTmpObj['creator_id'] = '';
$aTmpObj['invited_user_id'] = '';//optional
$aTmpObj['portals_id'] = '';
$aTmpObj['manage_permission'] = '';//1, 0
$aTmpObj['goal_types_id'] = '';
$aTmpObj['goal_metrics_id'] = '';
$aTmpObj['limit'] = '50';//optional
$aTmpObj['offset'] = '0';//optional
$aTmpObj['seconds_from_gmt'] = '10800';
*/

function api_get_goals($aObj, $LUser){
		
	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($limit == 0)$limit = 50;

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be <= 4096");
		
	$aConds = array();

	if($aObj['manage_permission'] != ""){
		if($LUser['id'] == '')done_json("Login error!");
		$equal = ($aObj['manage_permission'] == "1")?"=":"<>";
		$aConds[] = " (`users_id` ".$equal." '".mv($LUser['id'])."' OR `lead_id` ".$equal." '".mv($LUser['id'])."') ";
		if($aObj['invited_user_id'] != ''){
			$aConds[] = " `id` NOT IN (SELECT `goals_id` FROM `goals_team` WHERE `users_id2` = '".mv($aObj['invited_user_id'])."') ";
		}
	}

	if($aObj['creator_id'] != ""){
		$aConds[] = " (`users_id`  = '".mv($aObj['creator_id'])."') ";
	}
	

	if($aObj['users_id'] != ""){
		$aConds[] = " (`users_id`  = '".mv($aObj['users_id'])."' OR `lead_id`  = '".mv($aObj['users_id'])."' OR `id` IN (SELECT `goals_id` FROM `goals_team` WHERE `users_id2` = '".mv($aObj['users_id'])."' AND `confirmed` = 1)) ";
	}
		
	if($aObj['portals_id'] != ""){
		$aConds[] = " `portals_id`  = '".mv($aObj['portals_id'])."' ";
	}

	if($aObj['goal_types_id'] != ""){
		$aConds[] = " `goal_types_id`  = '".mv($aObj['goal_types_id'])."' ";
	}

	if($aObj['goal_metrics_id'] != ""){
		$aConds[] = " `goal_metrics_id`  = '".mv($aObj['goal_metrics_id'])."' ";
	}

	/*
	 if($aObj['keyword'] != ""){
	$aConds[] = " LOWER(`title`) LIKE '%".strtolower(mvs($aObj['keyword']))."%' ";
	}*/

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$sql = "SELECT * FROM `goals` ".$sql_cond." ORDER BY `id` DESC LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	$aPortalsIDs = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){

			$sql22 = "SELECT * FROM `goals_team` WHERE `users_id1` = '".mv($LUser['id'])."' AND `goals_id` = '".$row['id']."'";
			$res22 = mysql_query($sql22) or die(mysql_error());
			$aInvitedUsers = array();
			if(mysql_num_rows($res22)){
				while($row22=mysql_fetch_assoc($res22)){
					$aInvitedUsers[] = $row22;
				}
			}
			$aPortalsIDs[$row['portals_id']] = $row['portals_id'];
			$row['aInvitedUsers'] = $aInvitedUsers;
			$aData[] = manage_goal_row($row, $LUser['id'], $aObj['seconds_from_gmt']);
		}
	}
	
	$aPortals = array();
	if(count($aPortalsIDs)){
		
		$sql = "SELECT * FROM `portals` WHERE `id` IN (".implode(", ", $aPortalsIDs).")";
		$res = mysql_custom_query($sql);
 		if(mysql_num_rows($res)){
   		 while($row=mysql_fetch_assoc($res)){
     		$aPortals[] = manage_portal_row($row);
    	   }
  		 }
	}
		
	$aRet = array();
	$aRet['aPortals'] = $aPortals;
	$aRet['aGoals'] = $aData;
	done_json($aRet, "result");
		
}
/* api function end */



function manage_goal_row($row, $users_id, $seconds_from_gmt = ""){

	$row['_c_file_max_640x640_url'] = "";

	$sql = "SELECT `url` FROM `s3_content` WHERE `key`='file_max_640x640' AND `tbl_index` = 3 AND `tbl_id` = '".mv($row['id'])."' ";
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
		$row['_c_file_max_640x640_url'] = mysql_result($res, 0, 0);
	}

	$row['manage_permission'] = (check_manage_goal_permission("", $row, $users_id))?'1':'0';


	$sql = "SELECT COUNT(*) FROM `goals_team` WHERE `goals_id`='".mv($row['id'])."' AND `confirmed` = 1";
	$res = mysql_query($sql) or die(mysql_error());
	$row['count_of_members'] = mysql_result($res, 0, 0);
	
	$row['team_member'] = 0;
	if(!empty($users_id)){
	  $sql = "SELECT COUNT(*) FROM `goals_team` WHERE `goals_id`='".mv($row['id'])."' AND `users_id2` = '".mv($users_id)."' AND `confirmed` = 1";
	  $res = mysql_query($sql) or die(mysql_error());
	  $row['team_member'] = mysql_result($res, 0, 0);
	 }
	$row['progress'] = round($row['filled_quota']/$row['quota'], 2);

	$aObj2 = array();
	$aObj2['goals_id'] = $row['id'];
	$aObj2['limit'] = '4';
	$aObj2['offset'] = '0';
	$aObj2['seconds_from_gmt'] = $seconds_from_gmt;
	$aObj2['__return_result'] = '1';
	$row['aLatestProgress'] = api_get_goals_progress_log($aObj2, array('id' => $users_id));

	return $row;

}



/* api function begin
 $aTmpObj['goals_id'] = '1';
*/
 
function api_delete_goal($aObj, $LUser){
	 
	if($LUser['id'] == '')done_json("Login error!");
	if($aObj['goals_id'] == '')done_json("goals_id required!");
	 
	$sql = "SELECT `portals_id`, `lead_id` FROM `goals` WHERE `id`='".mv($aObj['goals_id'])."'";
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
		$portals_id = mysql_result($res, 0, 0);
		$lead_id = mysql_result($res, 0, 1);
	}else{
		done_json("the parent portal doesn't exist!");
	}

	 
	if($lead_id){
		if($lead_id != $LUser['id'])done_json("Only the Lead of the Goal has Edit Goal Button and can Edit Goal.");
	}else{
		$owner_id = check_portal_editor_permission($LUser['id'], $portals_id);
	}


	$res_log_txt = delete_db_row_and_related_data("goals", $aObj['goals_id']);

	$aLog = array();
	$aLog['log'] = $res_log_txt;
	done_json("ok", "result");

}
/* api function end */
  
  
/* api function begin
 $aTmpObj['portals_id'] = '2';
$aTmpObj['goal_types_id'] = '2';
$aTmpObj['goal_metrics_id'] = '';//optional
$aTmpObj['quota'] = '64';//optional
$aTmpObj['rep_commission'] = '50';//%
$aTmpObj['lead_id'] = '';
$aTmpObj['description'] = 'Dolor sit #amet, consectetuer adipiscing elit, sed diam #nonummy nibh euismod tincidunt ut laoreet #dolore magna aliquam erat volutpat.';
$aTmpObj['reporting_increments_id'] = '2';//
$aTmpObj['aSources'][0] = '0';//aMultipleFiles[0]
$aTmpObj['aSources'][1] = '1';//aMultipleFiles[1]; or url here
$aTmpObj['aSourcesNotes'][0] = 'portal_file';
$aTmpObj['aSourcesNotes'][1] = 'portal_file';
$input_file[] = "aMultipleFiles[]";
$input_file[] = "aMultipleFiles[]";
*/
 
function api_create_goal($aObj, $LUser){
	global $RootDir, $RootDomain, $foursquare_client_key, $foursquare_client_secret;
	 
	if($LUser['id'] == '')done_json("Login error!");
	if($aObj['description'] == '')done_json("description required!");
	if($aObj['portals_id'] == '')done_json("portals_id required!");
	 

	if($aObj['lead_id'] != ''){
		$sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['lead_id'])."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_result($res, 0, 0) == 0)done_json("Wrong lead_id");
	}


	if($aObj['quota'] == ''){
		$aObj['quota'] = 100;
	}else{
		$aObj['quota'] = (int)$aObj['quota'];
	}


	if($aObj['quota'] < 1)done_json("quota < 1");
	 
	 
	$owner_id = check_portal_editor_permission($LUser['id'], $aObj['portals_id']);

	if($aObj['goal_types_id'] == "")done_json("goal_types_id is empty");
	//if($aObj['goal_metrics_id'] == "")done_json("goal_metrics_id is empty");
	if($aObj['reporting_increments_id'] == "")done_json("reporting_increments_id is empty");

	if($aObj['goal_metrics_id'] == ""){
		$sql = "SELECT `id` FROM `goal_metrics` WHERE `goal_types_id`='".mv($aObj['goal_types_id'])."' LIMIT 0, 1";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_num_rows($res)){
			$aObj['goal_metrics_id'] = mysql_result($res, 0, 0);
		}
	}
	 
	check_existance_by_id("reporting_increments", $aObj['reporting_increments_id']);
	check_existance_by_id("goal_metrics", $aObj['goal_metrics_id']);
	check_existance_by_id("goal_types", $aObj['goal_types_id']);

	$aInsert = array();
	$aInsert["`users_id`"] = "'".mv($LUser['id'])."'";
	$aInsert["`description`"] = "'".mvs($aObj['description'])."'";
	$aInsert["`portals_id`"] = "'".mv($aObj['portals_id'])."'";
	$aInsert["`quota`"] = "'".mv($aObj['quota'])."'";
	$aInsert["`goal_types_id`"] = "'".mv($aObj['goal_types_id'])."'";
	$aInsert["`goal_metrics_id`"] = "'".mv($aObj['goal_metrics_id'])."'";
	$aInsert["`rep_commission`"] = "'".mv($aObj['rep_commission'])."'";
	$aInsert["`reporting_increments_id`"] = "'".mv($aObj['reporting_increments_id'])."'";
	 
	$sql = "INSERT INTO `goals` (".implode(", ", array_keys($aInsert)).")VALUES (".implode(", ", $aInsert).");";
	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
	$goals_id = mysql_insert_id();
	 
	$sql = "INSERT INTO `goals_team` (`users_id1`, `users_id2`, `goals_id`, `confirmed`) VALUES ('".mv($LUser['id'])."', '".mv($LUser['id'])."', '".$goals_id."', 1)";
	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
	
	$aObj2 = array();
	$aObj2['goals_id'] = $goals_id;
	$aObj2['added_value'] = 1;
	$goals_progress_log_id = log_goal_progress($LUser['id'], $aObj2, "recruiting");


	$aObj2 = array();
	$aObj2['goals_id'] = $goals_id;
	$aObj2["lead_id"] = $aObj['lead_id'];
	$aObj2['aSources'] = $aObj['aSources'];
	$aObj2['aSourcesNotes'] = $aObj['aSourcesNotes'];
	api_edit_goal($aObj2, $LUser);
	 
	done_json($aLog, "result");
	 
}
/* api function end */
  


function log_goal_progress($users_id, $aObj, $type = ""){

	$goals_id = $aObj['goals_id'];
	$added_value = $aObj['added_value'];
	$note = $aObj['note'];
	$aSources = $aObj['aSources'];
	$aSourcesNotes = $aObj['aSourcesNotes'];
	/*
	- Recruiting    (counts # of reps on goal. No manual Goal Form needed)
			- Marketing     (counts # of “Share” actions by User on Portal page.  No manual Goal Form needed)
					- Sales    (sums # of “buy” actions by User on Offerings of Portal page.  Metric is Sales Dollars = sum total offering purchases as metric)
	
							1, 2, 5*/
	
	$sql = "SELECT `goal_types_id` FROM `goals` WHERE `id`='".mv($goals_id)."'";
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
	  $goal_types_id = mysql_result($res, 0, 0);
	}else{
		return -404;
	 }
	
	if($type == "recruiting"){
		if($goal_types_id != 5)return -503;
		$sql = "SELECT COUNT(*) FROM `goals_progress_log` WHERE `users_id`='".mv($users_id)."' AND `goals_id` = '".mv($goals_id)."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_result($res, 0, 0) > 0)return -11;
	}
	
	if($type == "marketing"){
		if($goal_types_id != 2)return -503;
		$sql = "SELECT COUNT(*) FROM `goals_progress_log` WHERE `users_id`='".mv($users_id)."' AND `goals_id` = '".mv($goals_id)."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_result($res, 0, 0) > 0)return -11;
	 }
	 
	 if($type == "sales"){
	 	if($goal_types_id != 1)return -503;
	  }

	$sql = "INSERT INTO `goals_progress_log` (`users_id`, `goals_id`, `added_value`, `note`) VALUES
   	  		('".mv($users_id)."', '".mv($goals_id)."', '".mv($added_value)."', '".mvs($note)."')";
	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
	$goals_progress_log_id = mysql_insert_id();

	$aQRALog = check_and_add_quota_is_reached_activity($goals_id, $users_id);

	//print_r($aQRALog);exit;
	$sql = "UPDATE `goals_progress_log` SET `value` = '".mv($aQRALog['new_filled_quota'])."' WHERE `id`='".mv($goals_progress_log_id)."'";
	$res = mysql_query($sql) or die(mysql_error());

	$new_files_count = count($aSources);
	if($new_files_count){
		$current_count = get_s3_files_count($goals_progress_log_id, 5);
		if($current_count + $new_files_count > 10){
			$aLog['aFiles'] = "Main Graphics (up to 10 16x9 images from phone or cloud storage service); current count: ".($current_count + $new_files_count);
		}else{
			$aLog['aFiles'] = add_s3_files_to_a_table($goals_progress_log_id, 5, $aSources, $aSourcesNotes, $users_id);
		}
	}

	return $goals_progress_log_id;

}



function delete_goal_progress_log($users_id, $goals_id, $type = ""){


	$sql = "SELECT `goal_types_id` FROM `goals` WHERE `id`='".mv($goals_id)."'";
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
		$goal_types_id = mysql_result($res, 0, 0);
	}else{
		return -404;
	}

	if(($type == "recruiting" && $goal_types_id == 5) || ($type == "marketing" && $goal_types_id == 2)){
		$sql = "DELETE FROM `goals_progress_log` WHERE `users_id` = '".mv($users_id)."' AND `goals_id` = '".mv($goals_id)."'";
		$res = mysql_query($sql) or die(mysql_error().' '.$sql);
	 }
	 

	$aQRALog = check_and_add_quota_is_reached_activity($goals_id, $users_id);

	$sql = "UPDATE `goals_progress_log` SET `value` = '".mv($aQRALog['new_filled_quota'])."' WHERE `id`='".mv($goals_progress_log_id)."'";
	$res = mysql_query($sql) or die(mysql_error());


	return 1;

}


/* api function begin
 $aTmpObj['goals_id'] = '2';
$aTmpObj['added_value'] = '2';//
$aTmpObj['note'] = 'Lorem ipsum...';
$aTmpObj['aSources'][0] = '0';//aMultipleFiles[0]
$aTmpObj['aSources'][1] = '1';//aMultipleFiles[1]; or url here
$aTmpObj['aSourcesNotes'][0] = 'goal_progress_file';
$aTmpObj['aSourcesNotes'][1] = 'goal_progress_file';
$input_file[] = "aMultipleFiles[]";
$input_file[] = "aMultipleFiles[]";
*/
function api_update_goal_filled_quota($aObj, $LUser){
	 
	if($LUser['id'] == '')done_json("Login error!");
	if($aObj['goals_id'] == "")done_json("goals_id required!");
	if($aObj['added_value'] == "")done_json("added_value required!");
	 
	 
	$sql = "SELECT `goal_types_id`, `users_id` FROM `goals` WHERE `id`='".mv($aObj['goals_id'])."';";///`users_id` = '".mv($LUser['id'])."'
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
		$goal_types_id = mysql_result($res, 0, 0);
		$owner_id = mysql_result($res, 0, 1);
	}else{
		done_json("404");
	}
	 
	if($owner_id != $LUser['id']){
	  $sql = "SELECT COUNT(*) FROM `goals_team` WHERE `goals_id`='".mv($aObj['goals_id'])."' AND `users_id2` = '".mv($LUser['id'])."' and `confirmed` = 1";
	  $res = mysql_query($sql) or die(mysql_error());
	  if(mysql_result($res, 0, 0) == 0)done_json("503");
	 }
	
	
	if($goal_types_id == "1" || $goal_types_id == "2" || $goal_types_id == "5")done_json("INTERNAL GOALS (No Update Goal Form Needed");
	
	
	$goals_progress_log_id = log_goal_progress($LUser['id'], $aObj);
	if($goals_progress_log_id <= 0)done_json($goals_progress_log_id);
	
	api_goal_details($aObj, $LUser);
	 
	done_json("nothing updated");

}
/* api function end */


  
/* api function begin
 $aTmpObj['goals_id'] = '2';
$aTmpObj['goal_types_id'] = '2';
$aTmpObj['goal_metrics_id'] = '2';
$aTmpObj['rep_commission'] = '50';//%
$aTmpObj['quota'] = '64';//optional
$aTmpObj['lead_id'] = '';
$aTmpObj['description'] = 'Dolor sit #amet, consectetuer adipiscing elit, sed diam #nonummy nibh euismod tincidunt ut laoreet #dolore magna aliquam erat volutpat.';
$aTmpObj['reporting_increments_id'] = '2';//
$aTmpObj['aSources'][0] = '0';//aMultipleFiles[0]
$aTmpObj['aSources'][1] = '1';//aMultipleFiles[1]; or url here
$aTmpObj['aSourcesNotes'][0] = 'goal_file';
$aTmpObj['aSourcesNotes'][1] = 'goal_file';
$input_file[] = "aMultipleFiles[]";
$input_file[] = "aMultipleFiles[]";
*/
function api_edit_goal($aObj, $LUser){
	 
	if($LUser['id'] == '')done_json("Login error!");
	if($aObj['goals_id'] == "")done_json("goals_id required!");
	 

	if($aObj['lead_id'] != ''){
		$sql = "SELECT COUNT(*) FROM `users` WHERE `id`='".mv($aObj['lead_id'])."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_result($res, 0, 0) == 0)done_json("Wrong lead_id");
	}


	$sql = "SELECT `portals_id`, `lead_id` FROM `goals` WHERE `id`='".mv($aObj['goals_id'])."'";
	$res = mysql_query($sql) or die(mysql_error());
	if(mysql_num_rows($res)){
		$portals_id = mysql_result($res, 0, 0);
		$lead_id = mysql_result($res, 0, 1);
	}else{
		done_json("the parent portal doesn't exist!");
	}

	 
	if($lead_id){
		if($aObj['lead_id'] != $LUser['id'])done_json("Only the Lead of the Goal has Edit Goal Button and can Edit Goal.");
	}else{
		$owner_id = check_portal_editor_permission($LUser['id'], $portals_id);
	}
	 
	if($aObj['reporting_increments_id'] != "")check_existance_by_id("reporting_increments", $aObj['reporting_increments_id']);
	if($aObj['goal_metrics_id'] != "")check_existance_by_id("goal_metrics", $aObj['goal_metrics_id']);
	if($aObj['goal_types_id'] != "")check_existance_by_id("goal_types", $aObj['goal_types_id']);
	 
	$aLog = array();
	 
	$aUpdateFields = array();
	$aAuoUpdateColumns = array('goal_types_id', 'goal_metrics_id', 'rep_commission', 'lead_id', 'description', 'reporting_increments_id', 'quota');
	 
	if(count($aAuoUpdateColumns)){
		foreach($aAuoUpdateColumns as $key => $val){
			if($aObj[$val] != "")$aUpdateFields[] = " `".$val."`='".mvs($aObj[$val])."' ";
		}
	}
	 
	if(count($aUpdateFields)){
		$sql = "UPDATE `goals` SET ".implode(", ", $aUpdateFields)." WHERE `id`='".mv($aObj['goals_id'])."';";
		$res = mysql_query($sql) or die(mysql_error().' '.$sql);
		$aLog['goals_fields'] = mysql_affected_rows();
	}
	 
	 
	$new_files_count = count($aObj['aSources']);
	if($new_files_count){
		$current_count = get_s3_files_count($aObj['goals_id'], 3);
		if($current_count + $new_files_count > 10){
			$aLog['aFiles'] = "Main Graphics (up to 10 16x9 images from phone or cloud storage service); current count: ".($current_count + $new_files_count);
		}else{
			$aLog['aFiles'] = add_s3_files_to_a_table($aObj['goals_id'], 3, $aObj['aSources'], $aSourcesNotes, $LUser['id']);
		}
	}
	 

	api_goal_details($aObj, $LUser);
	 
	done_json($aLog, "result");
}
 
/* api function end */
 
 
function check_manage_goal_permission($goals_id, $aGoal = array(), $users_id = 0){
	 
	//api_get_goals - check permissions in the sql
	if(count($aGoal) == 0){
		$sql = "SELECT * FROM `goals` WHERE `id`='".mv($goals_id)."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_num_rows($res)){
			$aGoal = mysql_fetch_assoc($res);
		}else{
			return false;
		}
	}
		
	
	if($users_id == "" || $users_id == "0")return false;
	if($aGoal['users_id'] != $users_id && $aGoal['lead_id'] != $users_id)return false;

	return true;

}
 
 


/* api function begin
 $aTmpObj['aGoalsIDs'][0] = '1';
$aTmpObj['aGoalsIDs'][1] = '2';
$aTmpObj['todo'] = 'join';//leave
*/
function api_join_goal($aObj, $LUser){
	 
	if($LUser['id'] == '')done_json("Login error!");
	if(!is_array($aObj['aGoalsIDs']) || count($aObj['aGoalsIDs']) == 0)done_json("aGoalsIDs is empty or wrong!");
	if($aObj['todo'] == "")done_json("todo required! join/leave");

	$aLog = array();
	 
	$aToDB = check_existance_by_ids("goals", $aObj['aGoalsIDs']);
	 
	if(count($aToDB) == 0)done_json("empty array, error #777");
	 
	foreach ($aToDB as $goals_id => $val){

		$sql = "SELECT COUNT(*) FROM `goals` WHERE `id` = '".mv($goals_id)."'";
		$res = mysql_query($sql) or die(mysql_error());
		if(mysql_result($res, 0, 0) == 0){
			$aLog[$goals_id] = "the goal doesn't exist!";
			continue;
		}
		 
		 
		$sql = "SELECT COUNT(*) FROM `goals_team` WHERE `goals_id` = '".mv($goals_id)."' AND `users_id2` = '".mv($LUser['id'])."'";
		$res = mysql_query($sql) or die(mysql_error());
		$team_member = mysql_result($res, 0, 0);
		 
		 
		if($aObj['todo'] == 'join'){
			if($team_member > 0){
				$aLog[$goals_id] = "You are already a member of the team!";
				continue;
			}
			

			$sql = "INSERT INTO `goals_team` (`goals_id`, `users_id1` , `users_id2`, `confirmed`) VALUES ('".mv($goals_id)."', '".mv($LUser['id'])."', '".mv($LUser['id'])."', 1);";
			$res = mysql_query($sql) or die(mysql_error());
			
			$aObj2 = array();
			$aObj2['goals_id'] = $goals_id;
			$aObj2['added_value'] = 1;
			$goals_progress_log_id = log_goal_progress($LUser['id'], $aObj2, "recruiting");

		}
		 

		if($aObj['todo'] == 'leave'){
			if($team_member == 0){
				$aLog[$goals_id] = "You are not a member of the team!";
				continue;
			}
			$sql = "DELETE FROM `goals_team` WHERE `goals_id` = '".mv($goals_id)."' AND `users_id2` = '".mv($LUser['id'])."'";
			$res = mysql_query($sql) or die(mysql_error());

			delete_goal_progress_log($LUser['id'], $goals_id, "recruiting");
			
		}
			
			
		$aLog[$goals_id] = "ok";
		 
	}
	 

	done_json($aLog, "result");
	 
}
/* api function end */


/* api function begin
 $aTmpObj['aGoalsIDs'][0] = '1';
 $aTmpObj['aGoalsIDs'][1] = '2';
 $aTmpObj['todo'] = 'join';//leave
 $aTmpObj['aUsers'][0] = '1';
 $aTmpObj['aUsers'][1] = '2';
 $aTmpObj['__return_result'] = '';
*/
 
function api_manage_goal_team($aObj, $LUser){

	if($LUser['id'] == '')done_json("login required!");
	if((!is_array($aObj['aGoalsIDs']) || count($aObj['aGoalsIDs']) == 0))done_json("aGoalsIDs is empty or wrong!");
	if((!is_array($aObj['aUsers']) || count($aObj['aUsers']) == 0))done_json("aUsers is empty or wrong!");
	if($aObj['todo'] == '' || ($aObj['todo'] != 'join' && $aObj['todo'] != 'leave'))done_json("todo is empty or wrong! Supported: join, leave");


	$aLog = array();
	foreach($aObj['aGoalsIDs'] as $agoals_key => $agoals_id){

		$aLog[$agoals_id] = array();
		/* ALL TEAM MEMBERS need to be able to Join, Update, and Invite to the Goal for this to really start working correctly.  
		if(!check_manage_goal_permission($agoals_id, array(), $LUser['id'])){
			$aLog[$agoals_id] = "404 or 503";
			continue;
		}*/


		$aObj['aUsers'] = array_unique($aObj['aUsers']);
		 
		 
		$aToDB = array();
		foreach($aObj['aUsers'] as $key => $val){
			$val = trim($val);
			if($val == '')continue;
			$aToDB[$val] = "'".mvs($val)."'";
			$aLog[$agoals_id][$val] = 'ok';
		}
		 
		 
		$sql = "SELECT COUNT(*) FROM `users` WHERE `id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$xs  = mysql_result($res, 0, 0);
		if($xs != count($aObj['aUsers']))done_json("not all ids are users!");
		 
		 
		if($aObj['todo'] == 'leave'){
			$sql = "DELETE FROM `goals_team` WHERE `goals_id`='".mv($agoals_id)."' AND `users_id2` IN (".implode(", ", $aToDB).")";
			$res = mysql_query($sql) or die(mysql_error());
			$aLog[$agoals_id]['leave_affected_rows'] = mysql_affected_rows();
			$sql = "DELETE FROM `activities` WHERE `type` = 'new_goal_invite' AND `data_type1`='goals' AND `data_id1` = '".mv($agoals_id)."' AND `users_id2` IN (".implode(", ", $aToDB).")";
			$res = mysql_query($sql) or die(mysql_error());
		}
		 
		 
		if($aObj['todo'] == 'join'){

			$aObj2 = array();
			$aObj2['goals_id'] = $agoals_id;
			$aObj2['__return_result'] = '1';
			$aUsers = api_get_goal_team($aObj2, $LUser);
			 
			$aSQL = array();
			$aPushUsers = array();
			foreach($aObj['aUsers'] as $key => $val){
				if(!isset($aUsers[$val])){
					$aSQL[] = "('".mv($LUser['id'])."', '".mv($val)."', '".mv($agoals_id)."')";
					$aLog[$agoals_id][$val] = 'sent';
					$aPushUsers[$val] = $val;
				}else{
					$aLog[$agoals_id][$val] = ($aUsers[$val]['confirmed'] == 1)?'already in the team':'invite for the user already exists in DB';
				}
			}
			 
			if(count($aSQL)){
					
				$sql = "INSERT INTO `goals_team` (`users_id1`, `users_id2`, `goals_id`) VALUES ".implode(", ", $aSQL);
				$res = mysql_query($sql) or die(mysql_error());
					
				foreach($aPushUsers as $key => $val){
					register_new_activity($LUser['id'], $val, "new_goal_invite", 1, $agoals_id, "goals");
				}

			}
			 
		}
		 

	}





	 
	if($aObj['__return_result'] == '1')return $aLog;
	done_json($aLog, "result");
}
/* api function end */
  
  

/* api function begin
 $aTmpObj['goals_id'] = '';
$aTmpObj['confirmed'] = '';//1, 0, -1
$aTmpObj['limit'] = '50';
$aTmpObj['offset'] = '0';
$aTmpObj['__return_result'] = '0';

*/

function api_get_goal_team($aObj, $LUser){
	//if($LUser['id'] == '')done_json("login required!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be < 4096");

	if($limit == 0)$limit = 1024;

	$aConds = array();

	$aConds[] = "`goals_id` = '".mv($aObj['goals_id'])."'";

	if($aObj['confirmed'] != ''){
		$aConds[] = "`confirmed` = '".mv($aObj['confirmed'])."'";
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";


	$sql = "SELECT * FROM `goals_team` ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aData[$row['users_id2']] = $row;

		}
	}

	if($aObj['__return_result'] == '1'){
		return $aData;
	}

	$aData = array_values($aData);
	done_json($aData, "result");


}
/* api function end */





/* api function begin
 $aTmpObj['goals_id'] = '';
$aTmpObj['folder'] = '';//inbox, sent, current; empty = current
$aTmpObj['confirmed'] = '-1,0,1';
$aTmpObj['read1'] = '';//1, 0 (read by sender)
$aTmpObj['read2'] = '';//1, 0 (read by receiver)
$aTmpObj['limit'] = '50';
$aTmpObj['offset'] = '0';
$aTmpObj['seconds_from_gmt'] = '10800';
$aTmpObj['__return_result'] = '0';

*/

function api_get_goals_team_invites($aObj, $LUser){
	if($LUser['id'] == '')done_json("login required!");

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be < 4096");

	if($limit == 0)$limit = 1024;

	$folder = "current";
	if($aObj['folder'] != ""){
		if($aObj['folder'] != "inbox" && $aObj['folder'] != "sent" && $aObj['folder'] != "current")done_json("wrong folder! Supported: inbox, sent, current");
		$folder = $aObj['folder'];
	}

	$aConds = array();

	if($folder == "current"){
			
		$sub_sql1 = " (gt.`users_id2` = '".mv($LUser['id'])."' AND gt.`confirmed` = 0) ";
		$sub_sql2 = " (gt.`users_id1` = '".mv($LUser['id'])."' AND gt.`confirmed` <> 0 AND gt.`read1` = 0) ";
			
		$aConds[] = " (".$sub_sql1." OR ".$sub_sql2.") ";
			
	}elseif($folder == "current"){
		$aConds[] = " (gt.`users_id2` = '".mv($LUser['id'])."') ";
	}else{//sent
		$aConds[] = " (gt.`users_id1` = '".mv($LUser['id'])."') ";
	}


	if($aObj['read1'] != ''){
		$aConds[] = " gt.`read1` = '".mv($aObj['read1'])."' ";
	}

	if($aObj['read2'] != ''){
		$aConds[] = " gt.`read2` = '".mv($aObj['read2'])."' ";
	}

	if($aObj['goals_id'] != ''){
		$aConds[] = " gt.`goals_id` = '".mv($aObj['goals_id'])."' ";
	}

	if($aObj['confirmed'] != ''){
		$aTmpSt = explode(",", $aObj['confirmed']);
		$aSts = array();
		foreach($aTmpSt as $key => $val)$aSts[] = "'".mv($val)."'";
		if(count($aSts)){
			$aConds[] = " gt.`confirmed` IN (".implode(",", $aSts).") ";
		}
	}

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";

	$aUsers = array();
	$aGoals = array();
	$aPortals = array();
	//$sql = "SELECT g.*, gt.`confirmed`, gt.`users_id1`, gt.`users_id2`, gt.`read1`, gt.`read2`, gt.`timestamp` as invited_on FROM `goals_team` as gt, `goals` as g ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
	$sql = "SELECT gt.* FROM `goals_team` as gt ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
	$res = mysql_query($sql) or die(mysql_error().' '.$sql);
	$aInvites = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$row['inbox'] = ($row['users_id2'] == $LUser['id'])?'1':'0';
			$aUsers[$row['users_id1']] = $row['users_id1'];
			$aUsers[$row['users_id2']] = $row['users_id2'];
			$aGoals[$row['goals_id']] = $row['goals_id'];
			$aInvites[] = $row;

		}
	}


	if(count($aGoals)){
			
		$sql = "SELECT * FROM `goals` WHERE `id` IN (".implode(", ", $aGoals).")";
		$res = mysql_query($sql) or die(mysql_error());
		$aGoals = array();
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				$row = manage_goal_row($row, $LUser['id'], $aObj['seconds_from_gmt']);
				$aGoals[] = $row;
				$aPortals[$row['portals_id']] = $row['portals_id'];
			}
		}
	}


	if(count($aUsers)){
		$sql = "SELECT * FROM `users` WHERE `id` IN (".implode(", ", $aUsers).")";
		$aUsers = get_users_from_sql($sql);
	}
		
	if(count($aPortals)){
		$sql = "SELECT * FROM `portals` WHERE `id` IN (".implode(", ", $aPortals).")";
		$res = mysql_query($sql) or die(mysql_error());
		$aPortals = array();
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				$aPortals[] = manage_portal_row($row);
			}
		}
	}

	if($aObj['__return_result'] == '1'){
		return $aData;
	}

	$aRet = array();
	$aRet['aInvites'] = $aInvites;
	$aRet['aGoals'] = $aGoals;
	$aRet['aUsers'] = $aUsers;
	$aRet['aPortals'] = $aPortals;
	done_json($aRet, "result");


}
/* api function end */




/* api function begin
 $aTmpObj['aGoalsIDs'][0] = '1';
$aTmpObj['aGoalsIDs'][1] = '2';
$aTmpObj['aGoalsIDs'][2] = '4';
$aTmpObj['todo'] = 'accept';//decline, delete, mark_as_read
*/

function api_manage_goals_invites($aObj, $LUser){

	if($LUser['id'] == '')done_json("Login error!");

	if(!is_array($aObj['aGoalsIDs']) || count($aObj['aGoalsIDs']) == 0)done_json("aGoalsIDs is empty!");
	if($aObj['todo'] == '' || ($aObj['todo'] != 'accept' && $aObj['todo'] != 'decline' && $aObj['todo'] != 'delete' && $aObj['todo'] != 'mark_as_read'))done_json("todo is empty or wrong! Supported: accept, decline, delete, mark_as_read");


	$aToDB = array();
	foreach($aObj['aGoalsIDs'] as $key => $val){
		$val = trim($val);
		if($val == '')continue;
		$aToDB[$val] = "'".mv($val)."'";
	}

	if(count($aToDB) == 0)done_json("aToDB is empty!");

	if ($aObj['todo'] == 'mark_as_read'){

		$sql = "UPDATE `goals_team` SET `read1` = 1 WHERE `users_id1`='".mv($LUser['id'])."' AND `goals_id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$c1 = mysql_affected_rows();
			
		$sql = "UPDATE `goals_team` SET `read2` = 1 WHERE `users_id2`='".mv($LUser['id'])."' AND `goals_id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$c2 = mysql_affected_rows();
			
		$c = $c1+$c2;
		if($c){
			done_json($c, "result");
		}

		done_json("0 marked");
	}

	if ($aObj['todo'] == 'delete'){

		$sql = "DELETE FROM `goals_team` WHERE (`users_id1`='".mv($LUser['id'])."' OR `users_id2`='".mv($LUser['id'])."') AND `goals_id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$c = mysql_affected_rows();
		if($c){
			done_json($c, "result");
		}

		done_json("0 deleted");
	}

	if ($aObj['todo'] == 'decline'){

		$sql = "UPDATE `goals_team` SET `confirmed` = -1, `read2` = 1 WHERE `users_id2`='".mv($LUser['id'])."' AND `goals_id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$c = mysql_affected_rows();
		if($c){

			$sql33 = "SELECT `users_id1`, `goals_id` FROM `goals_team` WHERE `users_id2`='".mv($LUser['id'])."' AND `goals_id` IN (".implode(", ", $aToDB).")";
			$res33 = mysql_query($sql33) or die(mysql_error());
			if(mysql_num_rows($res33)){
				while($row33=mysql_fetch_assoc($res33)){
					register_new_activity($LUser['id'], $row33['users_id1'], "goal_invite_declined", 1, $LUser['id'], "users", $row33['goals_id'], "goals");
				}
			}

			done_json($c, "result");
		}

		done_json("0 declined");
	}
		
		
	if ($aObj['todo'] == 'accept'){


		$sql = "SELECT * FROM `goals_team` WHERE `users_id2`='".mv($LUser['id'])."' AND `goals_id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$aData = array();
		$aLog = array();
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){

				if($row['confirmed'] != 1){
					$aLog[$row['goals_id']] = 'ok';
					register_new_activity($LUser['id'], $row['users_id1'], "goal_invite_accepted", 1, $LUser['id'], "users", $row['goals_id'], "goals");
					$aObj2 = array();
					$aObj2['goals_id'] = $row['goals_id'];
					$aObj2['added_value'] = '1';
					$aObj2['note'] = "";
					$goals_progress_log_id = log_goal_progress($LUser['id'], $aObj2, "recruiting");
				}else{
					$aLog[$row['goals_id']] = 'already a member';
				}

			}
		}



		$sql = "UPDATE `goals_team` SET `confirmed` = 1, `read2` = 1 WHERE `users_id2`='".mv($LUser['id'])."' AND `goals_id` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$aLog['c'] = mysql_affected_rows();


		done_json($aLog, "result");
	}

	done_json("something wrong");
}
/* api function end */



/* api function begin
 $aTmpObj['goals_id'] = '';
$aTmpObj['group_by'] = 'none';//week, month, day
$aTmpObj['limit'] = '50';
$aTmpObj['offset'] = '0';
$aTmpObj['seconds_from_gmt'] = '10800';
$aTmpObj['__return_result'] = '0';

*/

function api_get_goals_progress_log($aObj, $LUser){
	//if($LUser['id'] == '')done_json("login required!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be < 4096");

	if($limit == 0)$limit = 1024;


	$sql = "SELECT * FROM `goals` WHERE `id` = '".mv($aObj['goals_id'])."'";
	$res = mysql_query($sql) or die(mysql_error());
	$aGoal = array();
	if(mysql_num_rows($res)){
		$aGoal=mysql_fetch_assoc($res);
	}else{
		done_json("404 or 503");
	}



	if($aObj['group_by'] == ''){
		if($aGoal['reporting_increments_id'] == '2')$aObj['group_by'] = 'week';
		if($aGoal['reporting_increments_id'] == '3')$aObj['group_by'] = 'month';
	}else{
		if($aObj['group_by'] != 'day' && $aObj['group_by'] != 'week' && $aObj['group_by'] != 'month' && $aObj['group_by'] != 'none')done_json("group_by is wrong! Supported: day, week, month, none");
	}


	$aConds = array();

	$aConds[] = "`goals_id` = '".mv($aObj['goals_id'])."'";

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
	
	$time_stamp_column = "`timestamp`";
	
	if($aObj['seconds_from_gmt'] != ""){
	   $seconds_from_gmt = (int)$aObj['seconds_from_gmt'];
	   if(!empty($seconds_from_gmt))$time_stamp_column = "(`timestamp` + INTERVAL ".$seconds_from_gmt." SECOND)";
	 }
	 
	 //echo $time_stamp_column;exit;

	$date_column_sql = ", DATE(".$time_stamp_column.") as date, DATE_FORMAT(".$time_stamp_column.",'%b-%d') as date_str";
	$group_by_sql = "";
	$max_value_sql = "";
	if($aObj['group_by'] == 'day' || $aObj['group_by'] == ''){
		$date_column_sql = ", DATE(".$time_stamp_column.") as date, DATE_FORMAT(".$time_stamp_column.",'%b-%d') as date_str";
		$group_by_sql = "GROUP BY DATE(".$time_stamp_column.")";
		$max_value_sql = ", MAX(`value`) as value";
	}elseif($aObj['group_by'] == 'week'){
		$date_column_sql = ", CONCAT(YEAR(".$time_stamp_column."), '/', WEEK(`timestamp`)) as date, DATE_FORMAT(".$time_stamp_column.",'%b-%d') as date_str";
		$group_by_sql = "GROUP BY CONCAT(YEAR(".$time_stamp_column."), '/', WEEK(`timestamp`))";
		$max_value_sql = ", MAX(`value`) as value";
	}elseif($aObj['group_by'] == 'month'){
		$date_column_sql = ", DATE_FORMAT(".$time_stamp_column.", '%Y/%m') as date, DATE_FORMAT(".$time_stamp_column.",'%b-%d') as date_str";
		$group_by_sql = "GROUP BY DATE_FORMAT(".$time_stamp_column.", '%Y/%m')";
		$max_value_sql = ", MAX(`value`) as value";
	}
		
	 
	 
	//$sql = "SELECT * FROM `goals_progress_log` ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
	$sql = "SELECT *, ".$time_stamp_column." as timestamp  ".$max_value_sql.' '.$date_column_sql." FROM `goals_progress_log` ".$sql_cond." ".$group_by_sql." ORDER BY `id` ASC LIMIT ".$offset.", ".$limit;
	//echo $sql;exit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		$sum = 0;
		$previous = 0;
		while($row=mysql_fetch_assoc($res)){
			//$sum += $row['progress'];
			//$row['progress_sector_percent'] = ($sum/$aGoal['quota'])*100;

			$percent = round(($row['value']/$aGoal['quota']), 2);
			if($percent > 1)$percent = 1;
			if($percent < 0)$percent = 0;
			$row['progress_total_percent'] = $percent;

			if($row['value'] - $previous > 0){
				$row['progress_sector_percent'] = round((($row['value'] - $previous)/$aGoal['quota']), 2);
			}else{
				$row['progress_sector_percent'] = $row['progress_total_percent'];
			}

			$previous = $row['value'];
			$row['c'] = count($aData);
			if($aObj['group_by'] == 'none')$row['aFiles'] = get_s3_files("5", $row['id']);
			$aData[] = $row;
		}
	}
	
	//print_r($aData);exit;
	
	//$aTmpObj['seconds_from_gmt']

	if($aObj['__return_result'] == '1'){
		return $aData;
	}

	//$aData = array_values($aData);
	done_json($aData, "result");


}
/* api function end */




/* api function begin
 $aTmpObj['goals_id'] = '';
$aTmpObj['limit'] = '50';
$aTmpObj['offset'] = '0';
$aTmpObj['__return_result'] = '0';
*/

function api_get_goals_progress_feed($aObj, $LUser){
	//if($LUser['id'] == '')done_json("login required!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");

	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];

	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be < 4096");

	if($limit == 0)$limit = 1024;


	$sql = "SELECT * FROM `goals` WHERE `id` = '".mv($aObj['goals_id'])."'";
	$res = mysql_query($sql) or die(mysql_error());
	$aGoal = array();
	if(mysql_num_rows($res)){
		$aGoal=mysql_fetch_assoc($res);
	}else{
		done_json("404 or 503");
	}


	$aConds = array();
	$aUsers = array();

	$aConds[] = "`goals_id` = '".mv($aObj['goals_id'])."'";

	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
		
		
	//$sql = "SELECT * FROM `goals_progress_log` ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
	$sql = "SELECT * FROM `goals_progress_log` ".$sql_cond." LIMIT ".$offset.", ".$limit;
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		$sum = 0;
		$previous = 0;
		while($row=mysql_fetch_assoc($res)){
			//$sum += $row['progress'];
			//$row['progress_sector_percent'] = ($sum/$aGoal['quota'])*100;

			$aUsers[$row['users_id']] = $row['users_id'];

			$percent = round(($row['value']/$aGoal['quota']), 2);
			if($percent > 1)$percent = 1;
			if($percent < 0)$percent = 0;
			$row['progress_total_percent'] = $percent;

			if($row['value'] - $previous > 0){
				$row['progress_sector_percent'] = round((($row['value'] - $previous)/$aGoal['quota']), 2);
			}else{
				$row['progress_sector_percent'] = $row['progress_total_percent'];
			}
				
			$row['added_value'] = $row['value'] - $previous;

			$previous = $row['value'];

			$row['c'] = count($aData);
			$row['aAttachments'] = get_s3_files("5", $row['id']);
			$aData[] = $row;
		}
	}

	if(count($aUsers)){
		$sql = "SELECT * FROM `users` WHERE `id` IN (".implode(", ", $aUsers).")";
		$aUsers = get_users_from_sql($sql);
	}

	$aRet = array();
	//$aRet['aGoal'] = $aGoal;
	$aRet['aData'] = $aData;
	$aRet['aUsers'] = $aUsers;


	if($aObj['__return_result'] == '1'){
		return $aRet;
	}

	//$aData = array_values($aData);
	done_json($aRet, "result");


}
/* api function end */





function check_and_add_quota_is_reached_activity($goals_id, $users_id){

	$LUser['id'] = $users_id;
	 
	$aRet = array();

	$sql = "SELECT * FROM `goals` WHERE `id` = '".mv($goals_id)."'";
	$res = mysql_query($sql) or die(mysql_error());
	$aGoal = array();
	if(mysql_num_rows($res)){
		$aGoal=mysql_fetch_assoc($res);
		if($aGoal['quota'] == 0){
			//echo 'ddd';
			return false;
		}
	}else{
		//echo 'sss';exit;
		return false;
	}
	 
	 
	$sql = "SELECT SUM(`added_value`) FROM `goals_progress_log` WHERE `goals_id`='".mv($goals_id)."'";
	$res = mysql_query($sql) or die(mysql_error());
	$new_filled_quota = mysql_result($res, 0, 0);
	 
	if($new_filled_quota != $aGoal['filled_quota']){
		$sql23 = "UPDATE `goals` SET `filled_quota` = '".$new_filled_quota."' WHERE `id`='".mv($goals_id)."'";
		$res23 = mysql_query($sql23) or die(mysql_error());
		$aGoal['filled_quota'] = $new_filled_quota;
	}

	 
	$quota_is_now_reached = false;
	if($aGoal['filled_quota'] >= $aGoal['quota'] && $aGoal['quota_is_reached_note'] != "1"){

		$aObj2 = array();
		$aObj2['goals_id'] = $goals_id;
		$aObj2['__return_result'] = '1';
		$aUsers = api_get_goal_team($aObj2, $LUser);

		$aPushUsersIDs = array();
		if(count($aUsers)){
			foreach($aUsers as $key => $val){

				$aPushUsersIDs[$val['users_id1']] = $val['users_id1'];
				$aPushUsersIDs[$val['users_id2']] = $val['users_id2'];

			}
		}

		unset($aPushUsersIDs[$LUser['id']]);


		$sql23 = "UPDATE `goals` SET `quota_is_reached_note` = 1 WHERE `id`='".mv($goals_id)."'";
		$res23 = mysql_query($sql23) or die(mysql_error());

		if(count($aPushUsersIDs)){
			foreach($aPushUsersIDs as $key => $val){
				register_new_activity($LUser['id'], $val, "quota_is_reached", 1, $goals_id, "goals");
			}
		}

		$quota_is_now_reached = true;
	}
	 
	 
	$aRet = array();
	$aRet['quota_is_now_reached'] = $quota_is_now_reached;
	$aRet['new_filled_quota'] = $new_filled_quota;
	 
	return $aRet;
}


/* api function begin
 $aTmpObj['goals_id'] = '';
$aTmpObj['confirmed'] = '';//1, 0, -1
$aTmpObj['limit'] = '50';
$aTmpObj['offset'] = '0';
$aTmpObj['__return_result'] = '0';
 
*/
 
function api_get_goal_users($aObj, $LUser){
	//if($LUser['id'] == '')done_json("login required!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");
	 
	$offset = (int)$aObj['offset'];
	$limit = (int)$aObj['limit'];
	 
	if($offset < 0) done_json("offset is wrong!");
	if($limit > 4096) done_json("limit should be < 4096");
	 
	if($limit == 0)$limit = 1024;
	 
	$aConds = array();
	 
	$aConds[] = "gt.`users_id2` = u.`id`";
	$aConds[] = "gt.`goals_id` = '".mv($aObj['goals_id'])."'";
	 
	if($aObj['confirmed'] != ''){
		$aConds[] = "gt.`confirmed` = '".mv($aObj['confirmed'])."'";
	}
	 
	$sql_cond = (count($aConds))?" WHERE ".implode(" AND ", $aConds):"";
	 
	 
	$sql = "SELECT u.* FROM `goals_team` as gt, `users` as u ".$sql_cond." LIMIT ".mv($offset).", ".mv($limit);
	$res = mysql_query($sql) or die(mysql_error());
	$aUsers = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aUsers[$row['id']] = manage_user_row($row);
			 
		}
	}
	 
	if($aObj['__return_result'] == '1'){
		return $aUsers;
	}
	 
	$aUsers = array_values($aUsers);
	done_json($aUsers, "result");
	 
	 
}
/* api function end */





/* api function begin
  $aTmpObj['goals_id'] = '1';
  $aTmpObj['todo'] = 'add';//delete
  $aTmpObj['aEmails'][0] = 'halcyon.user@gmail.com';
  $aTmpObj['aEmails'][1] = 'halcyon.test@gmail.com';
  $aTmpObj['aEmails'][2] = 'xwsrfsds';
  $aTmpObj['aFBIDs'][0] = '1';
  $aTmpObj['aFBIDs'][1] = '2';
  $aTmpObj['aFBIDs'][2] = '3';
  $aTmpObj['aPhones'][0] = '5555648583';
  $aTmpObj['aPhones'][1] = '4155553695';
  $aTmpObj['aPhones'][2] = '380000000000';
  $aTmpObj['do_not_send_sms'] = '1';//for testing
*/

function api_invite_to_goal($aObj, $LUser){

	$aObj['__return_result'] = '1';
	$aRet = array();
	if(is_array($aObj['aEmails']) && count($aObj['aEmails'])){
		$aRet['aEmails'] = api_invite_phone_friends_to_a_goal($aObj, $LUser);
	}
	if(is_array($aObj['aFBIDs']) && count($aObj['aFBIDs'])){
		$aRet['aFBIDs'] = api_invite_fb_friends_to_a_goal($aObj, $LUser);
	}
	if(is_array($aObj['aPhones']) && count($aObj['aPhones'])){
		$aRet['aPhones'] = api_invite_phone_friends_to_a_goal($aObj, $LUser);
	}

	done_json($aRet, "result");
}
/* api function end */




/* api function begin
 $aTmpObj['goals_id'] = '1';
$aTmpObj['todo'] = 'add';//delete
$aTmpObj['do_not_send_sms'] = '1';//for testing
$aTmpObj['aPhones'][0] = '5555648583';
$aTmpObj['aPhones'][1] = '4155553695';
$aTmpObj['aPhones'][2] = '380000000000';
*/

function api_invite_phone_friends_to_a_goal($aObj, $LUser){
	global $RootDomain, $PassSalt, $ProjectName;
	if($LUser['id'] == '')done_json("login required!");

	$aLog = array();
	$aUsers = array();
	$aToDB = array();

	if(!is_array($aObj['aPhones']) || count($aObj['aPhones']) == 0)done_json("aPhones is empty or wrong!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");
	if($aObj['todo'] == '' || ($aObj['todo'] != 'add' && $aObj['todo'] != 'delete'))done_json("todo is empty or wrong! Supported: add, delete");

	
	 $sql = "SELECT * FROM `goals` WHERE `id`='".mv($aObj['goals_id'])."'";
 	 $res = mysql_custom_query($sql);
 	 $aGoal = array();
 	 if(mysql_num_rows($res)){
   		$aGoal=mysql_fetch_assoc($res);
      }else{
      	done_json("goal: 404");
      }
      
      
      $sql = "SELECT `name` FROM `portals` WHERE `id`='".mv($aGoal['portals_id'])."'";
      $res = mysql_custom_query($sql);
      if(mysql_num_rows($res)){
      	$portal_name = mysql_result($res, 0, 0);
       }else{
      	 done_json("parent portal: 404");
        }
      

	foreach($aObj['aPhones'] as $key => $val){
		if($val == '')continue;
		$phone = fix_phone($val);

		if(strlen($phone) > 10 && strlen($phone) < 13){
			$aToDB[$phone] = "'".mvs($phone)."'";
		}else{
			$aLog[$val] = 'wrong phone! '.strlen($phone);
		}
	}

	if(count($aToDB) == 0){
		$aFLog = array();
		$aFLog['message'] = "aToDB/aPhones is empty or wrong!";
		$aFLog['aLog'] = $aLog;
		done_json($aFLog);
	}
		
		
	if($aObj['todo'] == 'delete'){

		$sql = "DELETE FROM `goals_pre_invites` WHERE `users_id` = '".mv($LUser['id'])."' AND `goals_id` = '".mv($aObj['goals_id'])."' AND `type` = 'phone' AND `identifier` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$c = mysql_affected_rows();
		if($aObj['__return_result'] == '1')return $c;
		done_json($c, "result");
	}
		

	$sql = "SELECT `id`, `phone` FROM `users` WHERE `phone` IN (".implode(", ", $aToDB).")";
	$res = mysql_query($sql) or die(mysql_error());
	$aData = array();
	if(mysql_num_rows($res)){
		while($row=mysql_fetch_assoc($res)){
			$aUsers[] = $row['id'];
			unset($aObj['aPhones'][$row['phone']]);
			unset($aToDB[$row['phone']]);
			$aLog[$row['phone']] = 'already registered: '.$row['id'];
		}
	}

	if(count($aToDB)){
		$sql = "SELECT * FROM `goals_pre_invites` WHERE `goals_id` = '".mv($aObj['goals_id'])."' AND `type` = 'phone' AND `identifier` IN (".implode(", ", $aToDB).")";
		$res = mysql_query($sql) or die(mysql_error());
		$aPUsers = array();
		if(mysql_num_rows($res)){
			while($row=mysql_fetch_assoc($res)){
				$aPUsers[] = $row['id'];
				unset($aObj['aPhones'][$row['identifier']]);
				unset($aToDB[$row['identifier']]);
				$aLog[$row['identifier']] = 'already in invited by '.$row['users_id'];
			}
		}
	}

	if(count($aUsers)){
		$aObj2 = array();
		$aObj2['aGoalsIDs'][0] = $aObj['goals_id'];
		$aObj2['todo'] = 'join';
		$aObj2['aUsers'] = $aUsers;
		$aObj2['__return_result'] = '1';
		$aLog['aRegisteredInvites'] = api_manage_goal_team($aObj2, $LUser);
	}

		
	if(count($aToDB)){

		$aSQLs = array();
		foreach($aToDB as $key => $val){
			$aSQLs[] = "('".mv($LUser['id'])."', '".mv($aObj['goals_id'])."', 'phone', ".$val.")";

			/*
			$hash = md5($aObj['goals_id'].$PassSalt.$key);
			$hash = substr($hash, 0, 8);
			$join_link = $RootDomain.'/registration/'.$key.'/'.$aObj['goals_id'].'/'.$hash.'/';
			*/

			$text="".$LUser['fname'].' '.$LUser['lname']." has invited you to ".$portal_name.' '.sstring($aGoal['description'], 24)."  http://google.com/ ";

			//my_mail($key, $ProjectName, $text);
			if($aObj['do_not_send_sms'] == '1'){
				tmp_log($key.': '.$text, "sms.log");
				$aLog[$key] = $text;
			}else{
				//$aLog[$key] = send_click_sms($key, $text);
				$aLog[$key] = "sms provider is empty";
			}

		}

		if(count($aSQLs)){
			$sql = "INSERT INTO `goals_pre_invites` (`users_id` ,`goals_id` ,`type` ,`identifier`) VALUES ".implode(", ", $aSQLs).";";
			$res = mysql_query($sql) or die(mysql_error());
			$aLog['result'] = count($aSQLs);
		}

	}else{
		$aLog['result'] = '-';
	}

	if($aObj['__return_result'] == '1')return $aLog;
	done_json($aLog, "result");

}
/* api function end */





/* api function begin
 $aTmpObj['goals_id'] = '1';
$aTmpObj['todo'] = 'add';//delete
$aTmpObj['aEmails'][0] = 'halcyon.user@gmail.com';
$aTmpObj['aEmails'][1] = 'halcyon.test@gmail.com';
$aTmpObj['aEmails'][2] = 'xwsrfsds';

*/

function api_invite_email_friends_to_a_goal($aObj, $LUser){
	global $ProjectName;
if($LUser['id'] == '')done_json("login required!");

	$aLog = array();
	$aUsers = array();
	$aToDB = array();

	if(!is_array($aObj['aEmails']) || count($aObj['aEmails']) == 0)done_json("aEmails is empty or wrong!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");
	if($aObj['todo'] == '' || ($aObj['todo'] != 'add' && $aObj['todo'] != 'delete'))done_json("todo is empty or wrong! Supported: add, delete");

	
	 $sql = "SELECT * FROM `goals` WHERE `id`='".mv($aObj['goals_id'])."'";
 	 $res = mysql_custom_query($sql);
 	 $aGoal = array();
 	 if(mysql_num_rows($res)){
   		$aGoal=mysql_fetch_assoc($res);
      }else{
      	done_json("goal: 404");
      }
      
      
      $sql = "SELECT `name` FROM `portals` WHERE `id`='".mv($aGoal['portals_id'])."'";
      $res = mysql_custom_query($sql);
      if(mysql_num_rows($res)){
      	$portal_name = mysql_result($res, 0, 0);
       }else{
      	 done_json("parent portal: 404");
        }

	foreach($aObj['aEmails'] as $key => $val){
	$val = trim($val);
	if($val == '')continue;
	if(preg_match("/^[a-zA-Z0-9][a-zA-Z0-9\.\-\_]+\@([a-zA-Z0-9_-]+\.)+[a-zA-Z]+$/", $val)){
		  $aToDB[$val] = "'".mvs($val)."'";
	}else{
	$aLog[$val] = 'wrong email!';
	}
	}

		if(count($aToDB) == 0)done_json("aToDB/aEmails is empty or wrong!");
		 
		 
	  if($aObj['todo'] == 'delete'){

		$sql = "DELETE FROM `goals_pre_invites` WHERE `users_id` = '".mv($LUser['id'])."' AND `goals_id` = '".mv($aObj['goals_id'])."' AND `type` = 'email' AND `identifier` IN (".implode(", ", $aToDB).")";
 		 $res = mysql_query($sql) or die(mysql_error());
		$c = mysql_affected_rows();
		if($aObj['__return_result'] == '1')return $c;
		done_json($c, "result");
	  }
				 

				$sql = "SELECT `id`, `email` FROM `users` WHERE `email` IN (".implode(", ", $aToDB).")";
 		$res = mysql_query($sql) or die(mysql_error());
 		$aData = array();
 		if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 		$aUsers[] = $row['id'];
 		unset($aObj['aEmails'][$row['email']]);
 		unset($aToDB[$row['email']]);
 		$aLog[$row['email']] = 'already registered: '.$row['id'];
 		}
 		}

 		if(count($aToDB)){
 		$sql = "SELECT * FROM `goals_pre_invites` WHERE `goals_id` = '".mv($aObj['goals_id'])."' AND `type` = 'email' AND `identifier` IN (".implode(", ", $aToDB).")";
 				$res = mysql_query($sql) or die(mysql_error());
 				$aPUsers = array();
 		if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 		$aPUsers[] = $row['id'];
 		unset($aObj['aEmails'][$row['identifier']]);
 			unset($aToDB[$row['identifier']]);
 			$aLog[$row['identifier']] = 'already in invited by '.$row['users_id'];
 		}
 		}
 	 }

	if(count($aUsers)){
		$aObj2 = array();
		$aObj2['aGoalsIDs'][0] = $aObj['goals_id'];
		$aObj2['todo'] = 'join';
		$aObj2['aUsers'] = $aUsers;
		$aObj2['__return_result'] = '1';
		$aLog['aRegisteredInvites'] = api_manage_goal_team($aObj2, $LUser);
	}

   	  			
   	  		if(count($aToDB)){
   	  		 
   	  		$aSQLs = array();
   	  		foreach($aToDB as $key => $val){
   	  			$aSQLs[] = "('".mv($LUser['id'])."', '".mv($aObj['goals_id'])."', 'email', ".$val.")";

   	  			$html="".$LUser['fname'].' '.$LUser['lname']." has invited you to ".$portal_name."  http://google.com/ ";

 	  			my_mail($key, $ProjectName, $html);

   	  			$aLog[$key] = 'ok';
   	  			}

   	  			if(count($aSQLs)){
   	  			$sql = "INSERT INTO `goals_pre_invites` (`users_id` ,`goals_id` ,`type` ,`identifier`) VALUES ".implode(", ", $aSQLs).";";
   	  			$res = mysql_query($sql) or die(mysql_error());
   	  			$aLog['result'] = count($aSQLs);
   	  			}
   	  					 
   	  		}else{
   	  		$aLog['result'] = '-';
}

if($aObj['__return_result'] == '1')return $aLog;
done_json($aLog, "result");

}
/* api function end */

/* api function begin
$aTmpObj['goals_id'] = '1';
$aTmpObj['todo'] = 'add';//delete
$aTmpObj['aFBIDs'][0] = '1';
$aTmpObj['aFBIDs'][1] = '2';
$aTmpObj['aFBIDs'][2] = '3';
*/

function api_invite_fb_friends_to_a_goal($aObj, $LUser){
	global $ProjectName;
if($LUser['id'] == '')done_json("login required!");

	$aLog = array();
	$aUsers = array();
	$aToDB = array();

	if(!is_array($aObj['aFBIDs']) || count($aObj['aFBIDs']) == 0)done_json("aFBIDs is empty or wrong!");
	if($aObj['goals_id'] == '')done_json("goals_id is empty!");
	if($aObj['todo'] == '' || ($aObj['todo'] != 'add' && $aObj['todo'] != 'delete'))done_json("todo is empty or wrong! Supported: add, delete");

	
	 $sql = "SELECT * FROM `goals` WHERE `id`='".mv($aObj['goals_id'])."'";
 	 $res = mysql_custom_query($sql);
 	 $aGoal = array();
 	 if(mysql_num_rows($res)){
   		$aGoal=mysql_fetch_assoc($res);
      }else{
      	done_json("goal: 404");
      }
      
      
      $sql = "SELECT `name` FROM `portals` WHERE `id`='".mv($aGoal['portals_id'])."'";
      $res = mysql_custom_query($sql);
      if(mysql_num_rows($res)){
      	$portal_name = mysql_result($res, 0, 0);
       }else{
      	 done_json("parent portal: 404");
        }

	foreach($aObj['aFBIDs'] as $key => $val){
		$val = trim($val);
		if($val == '')continue;
		$aToDB[$val] = "'".mvs($val)."'";
	}

	if(count($aToDB) == 0)done_json("aToDB/aFBIDs is empty or wrong!");
	 
	 
	if($aObj['todo'] == 'delete'){

	  	 $sql = "DELETE FROM `goals_pre_invites` WHERE `users_id` = '".mv($LUser['id'])."' AND `goals_id` = '".mv($aObj['goals_id'])."' AND `type` = 'fb' AND `identifier` IN (".implode(", ", $aToDB).")";
	  	 		$res = mysql_query($sql) or die(mysql_error());
	  	 		$c = mysql_affected_rows();
	  	 		if($aObj['__return_result'] == '1')return $c;
	  	 		done_json($c, "result");
	  }
	 

	  $sql = "SELECT `id`, `facebook_id` FROM `users` WHERE `facebook_id` IN (".implode(", ", $aToDB).")";
 		$res = mysql_query($sql) or die(mysql_error());
 		$aData = array();
 		if(mysql_num_rows($res)){
 		while($row=mysql_fetch_assoc($res)){
 		$aUsers[] = $row['id'];
	unset($aObj['aFBUsers'][$row['facebook_id']]);
	unset($aToDB[$row['facebook_id']]);
	$aLog[$row['facebook_id']] = 'already registered: '.$row['id'];
   			  }
	}

	if(count($aToDB)){
 		$sql = "SELECT * FROM `goals_pre_invites` WHERE `goals_id` = '".mv($aObj['goals_id'])."' AND `type` = 'fb' AND `identifier` IN (".implode(", ", $aToDB).")";
 		$res = mysql_query($sql) or die(mysql_error());
 		$aPUsers = array();
 				if(mysql_num_rows($res)){
  			while($row=mysql_fetch_assoc($res)){
  			$aPUsers[] = $row['id'];
  			unset($aObj['aFBUsers'][$row['identifier']]);
  			unset($aToDB[$row['identifier']]);
  			$aLog[$row['identifier']] = 'already in invited by '.$row['users_id'];
  			}
 		  }
  			}
  				

	if(count($aUsers)){
		$aObj2 = array();
		$aObj2['aGoalsIDs'][0] = $aObj['goals_id'];
		$aObj2['todo'] = 'join';
		$aObj2['aUsers'] = $aUsers;
		$aObj2['__return_result'] = '1';
		$aLog['aRegisteredInvites'] = api_manage_goal_team($aObj2, $LUser);
	}

      	
      if(count($aToDB)){
 	 
      		$aSQLs = array();
      		foreach($aToDB as $key => $val){
 	  		$aSQLs[] = "('".mv($LUser['id'])."', '".mv($aObj['goals_id'])."', 'fb', ".$val.")";
 	  	 }

      if(count($aSQLs)){
      	$sql = "INSERT INTO `goals_pre_invites` (`users_id` ,`goals_id` ,`type` ,`identifier`) VALUES ".implode(", ", $aSQLs).";";
 		  $res = mysql_query($sql) or die(mysql_error());
 		  $aLog['result'] = count($aSQLs);
      	}
      	 
      	}else{
      	$aLog['result'] = '-';
 	  }

 	  if($aObj['__return_result'] == '1')return $aLog;
 	  done_json($aLog, "result");

 	  		}
 	  		/* api function end */
 	  		
 	 ?>