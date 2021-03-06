#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include openwarfare\_utils;

/*
	War
	Objective: 	Score points for your team by eliminating players on the opposing team
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	No wait / Near teammates

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_tdm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of teammates and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "marines";
			game["axis"] = "opfor";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

		If using minefields or exploders:
			maps\mp\_load::main();

	Optional level script settings
	------------------------------
		Soldier Type and Variation:
			game["american_soldiertype"] = "normandy";
			game["german_soldiertype"] = "normandy";
			This sets what character models are used for each nationality on a particular map.

			Valid settings:
				american_soldiertype	normandy
				british_soldiertype		normandy, africa
				russian_soldiertype		coats, padded
				german_soldiertype		normandy, africa, winterlight, winterdark
*/

/*QUAKED mp_tdm_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

/*QUAKED mp_tdm_spawn_axis_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Axis players spawn away from enemies and near their team at one of these positions at the start of a round.*/

/*QUAKED mp_tdm_spawn_allies_start (0.0 0.5 1.0) (-16 -16 0) (16 16 72)
Allied players spawn away from enemies and near their team at one of these positions at the start of a round.*/

main()
{
	aux_mapname = getdvar("mapname");
	if(aux_mapname == "mp_background")
		return;
		
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	level.scr_war_forcestartspawns = getdvarx( "scr_war_forcestartspawns", "int", 0, 0, 1 );
	if(aux_mapname == "mp_sps_muelles" || aux_mapname == "mp_usl_sws_d" || aux_mapname == "mp_old_town" )
		level.scr_war_forcestartspawns = 1;
	
	level.scr_war_lts_enable = getdvarx( "scr_war_lts_enable", "int", 0, 0, 1 );
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	if( !level.scr_war_lts_enable ) {
		maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 0, 0, 10 );
		maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 1, 0, 500 );
		maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 500 );
		maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 750, 0, 5000 );
		maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 12, 0, 1440 );
	}
	else {
		maps\mp\gametypes\_globallogic::registerNumLivesDvar( "war_lts", 1, 1, 10 );
		maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "war_lts", 5, 0, 500 );
		maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "war_lts", 2, 0, 500 );
		maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "war_lts", 3, 0, 5000 );
		maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "war_lts", 5, 0, 1440 );
	}
	
	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onRoundSwitch = ::onRoundSwitch;
	
	if( !level.scr_war_lts_enable )
		game["dialog"]["gametype"] = gameTypeDialog( "team_deathmtch" );
	else
		game["dialog"]["gametype"] = gameTypeDialog( "lastteam" );
}


onStartGameType()
{
	setClientNameMode("auto_change");
	
	if( !level.scr_war_lts_enable ) {
		maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"OBJECTIVES_WAR" );
		maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"OBJECTIVES_WAR" );
	}
	else {
		maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"OW_OBJECTIVES_LTS" );
		maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"OW_OBJECTIVES_LTS" );
	}
	
	if ( level.splitscreen ) {
		if( !level.scr_war_lts_enable ) {
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OBJECTIVES_WAR" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OBJECTIVES_WAR" );
		}
		else {
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OW_OBJECTIVES_LTS" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OW_OBJECTIVES_LTS" );
		}
	}
	else {
		if( !level.scr_war_lts_enable ) {
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OBJECTIVES_WAR_SCORE" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OBJECTIVES_WAR_SCORE" );
		}
		else {
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OW_OBJECTIVES_LTS_SCORE" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OW_OBJECTIVES_LTS_SCORE" );
		}
	}
	if( !level.scr_war_lts_enable ) {
		maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"OBJECTIVES_WAR_HINT" );
		maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"OBJECTIVES_WAR_HINT" );
	}
	else {
		maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"OW_OBJECTIVES_LTS_HINT" );
		maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"OW_OBJECTIVES_LTS_HINT" );
	}
	
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	//level.spawn_axis_start = getentarray( "mp_tdm_spawn_axis_start", "classname" );
	//level.spawn_allies_start = getentarray( "mp_tdm_spawn_allies_start", "classname" );
	//logPrint( "MI;" + level.script + ";spawn_allies_start;" + level.spawn_allies_start.size + ";spawn_axis_start;" + level.spawn_axis_start.size + "\n" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	allowed[0] = "war";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
		
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// elimination style
	if ( level.scr_war_lts_enable || (level.roundLimit != 1 && level.numLives) ) {
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onDeadEvent = ::onDeadEvent;
	}
}

onSpawnPlayer()
{
	// Check which spawn points should be used
	if ( game["switchedsides"] ) {
		spawnTeam = level.otherTeam[ self.pers["team"] ];
	}
	else {
		spawnTeam =  self.pers["team"];
	}
	
	self.usingObj = undefined;
	
	if ( level.inGracePeriod || level.scr_war_forcestartspawns ) {
		spawnPoints = getentarray("mp_tdm_spawn_" + spawnTeam + "_start", "classname");
		
		if ( !spawnPoints.size )
			spawnPoints = getentarray("mp_sab_spawn_" + spawnTeam + "_start", "classname");
			
		if ( !spawnPoints.size ) {
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnTeam );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
		}
		else {
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
		}
	}
	else {
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnTeam );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	self spawn( spawnPoint.origin, spawnPoint.angles );
}


onDeadEvent( team )
{
	// Make sure players on both teams were not eliminated
	if ( team != "all" ) {
		[[level._setTeamScore]]( getOtherTeam(team), [[level._getTeamScore]]( getOtherTeam(team) ) + 1 );
		thread maps\mp\gametypes\_globallogic::endGame( getOtherTeam(team), game["strings"][team + "_eliminated"] );
	}
	else {
		// We can't determine a winner if everyone died like in S&D so we declare a tie
		thread maps\mp\gametypes\_globallogic::endGame( "tie", game["strings"]["round_draw"] );
	}
}


onRoundSwitch()
{
	// Just change the value for the variable controlling which map assets will be assigned to each team
	level.halftimeType = "halftime";
	game["switchedsides"] = !game["switchedsides"];
}