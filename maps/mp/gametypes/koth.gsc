#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include openwarfare\_utils;


main()
{
	if ( getdvar("mapname") == "mp_background" )
		return;

	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;		

	level.scr_koth_flash_on_capture = getdvarx( "scr_koth_flash_on_capture", "int", 1, 0, 2 );
	level.scr_koth_flash_on_destroy = getdvarx( "scr_koth_flash_on_destroy", "int", 1, 0, 2 );
	
	level.scr_koth_teamdeadspectate_tp = getdvarx( "scr_koth_teamdeadspectate_tp", "int", 0, 0, 1 );

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 0, 0, 10 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 2, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 500 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 5000 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 25, 0, 1440 );


	level.teamBased = true;
	level.doPrematch = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onRoundSwitch = ::onRoundSwitch;

	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );

	precacheShader( "waypoint_targetneutral" );
	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );

	precacheString( &"MP_WAITING_FOR_HQ" );

	// Auxiliary variables
	level.hqAutoDestroyTime = getdvarx( "scr_koth_autodestroytime", "int", 60, 0, 300 );
	level.hqSpawnTime = getdvarx( "scr_koth_spawntime", "int", 40, 0, 300 );
	level.kothMode = getdvarx( "scr_koth_kothmode", "int", 0, 0, 1 );
	level.captureTime = getdvarx( "scr_koth_captureTime", "int", 35, 0, 300 );
	level.destroyTime = getdvarx( "scr_koth_destroyTime", "int", 15, 0, 300 );
	level.delayPlayer = getdvarx( "scr_koth_delayPlayer", "int", 1, 0, 1 );
	level.spawnDelay = getdvarx( "scr_koth_spawnDelay", "int", 60, 0, 300);

	level.iconoffset = (0,0,32);

	level.onRespawnDelay = ::getRespawnDelay;

	game["dialog"]["gametype"] = gameTypeDialog( "headquarters" );
}


updateObjectiveHintMessages( alliesObjective, axisObjective )
{
	game["strings"]["objective_hint_allies"] = alliesObjective;
	game["strings"]["objective_hint_axis"  ] = axisObjective;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isDefined( player.pers["team"] ) && player.pers["team"] != "spectator" )
		{
			hintText = maps\mp\gametypes\_globallogic::getObjectiveHintText( player.pers["team"] );
			player thread maps\mp\gametypes\_hud_message::hintMessage( hintText );
		}
	}
}


getRespawnDelay()
{
	self.lowerMessageOverride = undefined;

	if ( !isDefined( level.radioObject ) )
		return undefined;

	hqOwningTeam = level.radioObject maps\mp\gametypes\_gameobjects::getOwnerTeam();
	if ( self.pers["team"] == hqOwningTeam )
	{
		if ( !isDefined( level.hqDestroyTime ) )
			return undefined;

		timeRemaining = (level.hqDestroyTime - gettime()) / 1000;

		if (!level.spawnDelay )
			return undefined;

		if ( level.spawnDelay >= level.hqAutoDestroyTime )
			self.lowerMessageOverride = &"MP_WAITING_FOR_HQ";

		if ( level.delayPlayer )
		{
			return min( level.spawnDelay, timeRemaining );
		}
		else
		{
			return (int(timeRemaining) % level.spawnDelay);
		}
	}
}


onStartGameType()
{
	// TODO: HQ objective text
	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"OBJECTIVES_KOTH" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"OBJECTIVES_KOTH" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OBJECTIVES_KOTH" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OBJECTIVES_KOTH" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OBJECTIVES_KOTH_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OBJECTIVES_KOTH_SCORE" );
	}

	level.objectiveHintPrepareHQ = &"MP_CONTROL_HQ";
	level.objectiveHintCaptureHQ = &"MP_CAPTURE_HQ";
	level.objectiveHintDestroyHQ = &"MP_DESTROY_HQ";
	level.objectiveHintDefendHQ = &"MP_DEFEND_HQ";
	precacheString( level.objectiveHintPrepareHQ );
	precacheString( level.objectiveHintCaptureHQ );
	precacheString( level.objectiveHintDestroyHQ );
	precacheString( level.objectiveHintDefendHQ );

	if ( level.kothmode )
		level.objectiveHintDestroyHQ = level.objectiveHintCaptureHQ;

	if ( level.hqSpawnTime )
		updateObjectiveHintMessages( level.objectiveHintPrepareHQ, level.objectiveHintPrepareHQ );
	else
		updateObjectiveHintMessages( level.objectiveHintCaptureHQ, level.objectiveHintCaptureHQ );

	setClientNameMode("auto_change");

	// TODO: HQ spawnpoints
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );

	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	level.spawn_all = getentarray( "mp_tdm_spawn", "classname" );

	// Check if we should switch spawn points
	if ( game["switchedsides"] ) {
		level.spawn_axis_start = getentarray("mp_tdm_spawn_allies_start", "classname" );
		level.spawn_allies_start = getentarray("mp_tdm_spawn_axis_start", "classname" );		
	} else {
		level.spawn_axis_start = getentarray("mp_tdm_spawn_axis_start", "classname" );
		level.spawn_allies_start = getentarray("mp_tdm_spawn_allies_start", "classname" );
	}

	level.displayRoundEndText = true;

	allowed[0] = "hq";
	maps\mp\gametypes\_gameobjects::main(allowed);

	thread SetupRadios();

	thread HQMainLoop();
}


HQMainLoop()
{
	level endon("game_ended");

	level.hqRevealTime = -100000;

	hqSpawningInStr = &"MP_HQ_AVAILABLE_IN";
	if ( level.kothmode )
	{
		hqDestroyedInFriendlyStr = &"MP_HQ_DESPAWN_IN";
		hqDestroyedInEnemyStr = &"MP_HQ_DESPAWN_IN";
	}
	else
	{
		hqDestroyedInFriendlyStr = &"MP_HQ_REINFORCEMENTS_IN";
		hqDestroyedInEnemyStr = &"MP_HQ_DESPAWN_IN";
	}

	precacheString( hqSpawningInStr );
	precacheString( hqDestroyedInFriendlyStr );
	precacheString( hqDestroyedInEnemyStr );
	precacheString( &"MP_CAPTURING_HQ" );
	precacheString( &"MP_DESTROYING_HQ" );

	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	xWait( 5.0 );

	timerDisplay = [];
	timerDisplay["allies"] = createServerTimer( "objective", 1.4, "allies" );
	timerDisplay["allies"] setPoint( "TOPRIGHT", "TOPRIGHT", 0, 0 );
	timerDisplay["allies"].label = hqSpawningInStr;
	timerDisplay["allies"].alpha = 0;
	timerDisplay["allies"].archived = false;
	timerDisplay["allies"].hideWhenInMenu = true;

	timerDisplay["axis"  ] = createServerTimer( "objective", 1.4, "axis" );
	timerDisplay["axis"  ] setPoint( "TOPRIGHT", "TOPRIGHT", 0, 0 );
	timerDisplay["axis"  ].label = hqSpawningInStr;
	timerDisplay["axis"  ].alpha = 0;
	timerDisplay["axis"  ].archived = false;
	timerDisplay["axis"  ].hideWhenInMenu = true;

	thread hideTimerDisplayOnGameEnd( timerDisplay["allies"] );
	thread hideTimerDisplayOnGameEnd( timerDisplay["axis"  ] );

	locationObjID = maps\mp\gametypes\_gameobjects::getNextObjID();

	objective_add( locationObjID, "invisible", (0,0,0) );

	while( 1 )
	{
		radio = PickRadioToSpawn();

		iPrintLn( &"MP_HQ_REVEALED" );
		playSoundOnPlayers( "mp_suitcase_pickup" );
		maps\mp\gametypes\_globallogic::leaderDialog( "hq_located" );
//		maps\mp\gametypes\_globallogic::leaderDialog( "move_to_new" );

		radioObject = radio.gameobject;
		level.radioObject = radioObject;
		logString( "radio spawned: " + radio.trigOrigin[0] + " " + radio.trigOrigin[1] + " " + radio.trigOrigin[2] );

		radioObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );

		level.hqRevealTime = gettime();

		if ( level.hqSpawnTime )
		{
			nextObjPoint = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", radio.origin + level.iconoffset, "all", "waypoint_targetneutral" );
			nextObjPoint setWayPoint( true, "waypoint_targetneutral" );
			objective_position( locationObjID, radio.trigorigin );
			objective_icon( locationObjID, "compass_waypoint_captureneutral" );
			objective_state( locationObjID, "active" );

			updateObjectiveHintMessages( level.objectiveHintPrepareHQ, level.objectiveHintPrepareHQ );

			timerDisplay["allies"].label = hqSpawningInStr;
			timerDisplay["allies"] setTimer( level.hqSpawnTime );
			if ( !level.splitscreen )
				timerDisplay["allies"].alpha = 1;
			timerDisplay["axis"  ].label = hqSpawningInStr;
			timerDisplay["axis"  ] setTimer( level.hqSpawnTime );
			if ( !level.splitscreen )
				timerDisplay["axis"  ].alpha = 1;

			finishWait = openwarfare\_timer::getTimePassed() + level.hqSpawnTime * 1000;
			while ( finishWait > openwarfare\_timer::getTimePassed() ) {
				wait (0.05);
				if ( level.inTimeoutPeriod ) {
					timerDisplay["allies"].alpha = 0;
					timerDisplay["axis"  ].alpha = 0;
					xWait( 0.1 );
					timerDisplay["allies"] setTimer( ( finishWait - openwarfare\_timer::getTimePassed() ) / 1000 );
					timerDisplay["axis"  ] setTimer( ( finishWait - openwarfare\_timer::getTimePassed() ) / 1000 );
					timerDisplay["allies"].alpha = 1;
					timerDisplay["axis"  ].alpha = 1;
				}
			}

			maps\mp\gametypes\_objpoints::deleteObjPoint( nextObjPoint );
			objective_state( locationObjID, "invisible" );
			maps\mp\gametypes\_globallogic::leaderDialog( "hq_online" );
		}

		timerDisplay["allies"].alpha = 0;
		timerDisplay["axis"  ].alpha = 0;

		waittillframeend;

		maps\mp\gametypes\_globallogic::leaderDialog( "obj_capture" );
		updateObjectiveHintMessages( level.objectiveHintCaptureHQ, level.objectiveHintCaptureHQ );
		playSoundOnPlayers( "mp_killstreak_radar" );

		radioObject maps\mp\gametypes\_gameobjects::enableObject();

		radioObject maps\mp\gametypes\_gameobjects::allowUse( "any" );
		radioObject maps\mp\gametypes\_gameobjects::setUseTime( level.captureTime );
		radioObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_HQ" );

		radioObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_captureneutral" );
		radioObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" );
		radioObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		radioObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );

		radioObject.onUse = ::onRadioCapture;
		radioObject.onBeginUse = ::onBeginUse;
		radioObject.onEndUse = ::onEndUse;

		level.radioObject = radioObject;

		level waittill( "hq_captured" );

		ownerTeam = radioObject maps\mp\gametypes\_gameobjects::getOwnerTeam();
		otherTeam = getOtherTeam( ownerTeam );

		if ( level.hqAutoDestroyTime )
		{
			thread DestroyHQAfterTime( level.hqAutoDestroyTime, timerDisplay );
			timerDisplay[ownerTeam] setTimer( level.hqAutoDestroyTime );
			timerDisplay[otherTeam] setTimer( level.hqAutoDestroyTime );
		}
		else
		{
			level.hqDestroyedByTimer = false;
		}

		/#
		thread scriptDestroyHQ();
		#/

		while( 1 )
		{
			ownerTeam = radioObject maps\mp\gametypes\_gameobjects::getOwnerTeam();
			otherTeam = getOtherTeam( ownerTeam );

			if ( ownerTeam == "allies" )
			{
				updateObjectiveHintMessages( level.objectiveHintDefendHQ, level.objectiveHintDestroyHQ );
			}
			else
			{
				updateObjectiveHintMessages( level.objectiveHintDestroyHQ, level.objectiveHintDefendHQ );
			}

			radioObject maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			radioObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
			radioObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
			radioObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
			radioObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );

			if ( !level.kothMode )
				radioObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DESTROYING_HQ" );

			radioObject.onUse = ::onRadioDestroy;

			if ( level.hqAutoDestroyTime )
			{
				timerDisplay[ownerTeam].label = hqDestroyedInFriendlyStr;
				if ( !level.splitscreen )
					timerDisplay[ownerTeam].alpha = 1;
				timerDisplay[otherTeam].label = hqDestroyedInEnemyStr;
				if ( !level.splitscreen )
					timerDisplay[otherTeam].alpha = 1;
			}

			level waittill( "hq_destroyed" );

			if ( !level.kothmode || level.hqDestroyedByTimer )
				break;

			thread forceSpawnTeam( ownerTeam );

			radioObject maps\mp\gametypes\_gameobjects::setOwnerTeam( getOtherTeam( ownerTeam ) );
		}

		level notify("hq_reset");

		radioObject maps\mp\gametypes\_gameobjects::disableObject();
		radioObject maps\mp\gametypes\_gameobjects::allowUse( "none" );
		radioObject maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
		radioObject maps\mp\gametypes\_gameobjects::setModelVisibility( false );

		timerDisplay["allies"].alpha = 0;
		timerDisplay["axis"  ].alpha = 0;

		level.radioObject = undefined;

		wait .05;

		thread forceSpawnTeam( ownerTeam );

		wait 3.0;
	}
}


hideTimerDisplayOnGameEnd( timerDisplay )
{
	level waittill("game_ended");
	timerDisplay.alpha = 0;
}


forceSpawnTeam( team )
{
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !isdefined( player ) )
			continue;

		if ( player.pers["team"] == team )
		{
			player.lowerMessageOverride = undefined;
			player notify( "force_spawn" );
			wait .1;
		}
	}
}


onBeginUse( player )
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();

	if ( ownerTeam == "neutral" )
	{
		// [0.0.1] See what kind of flashing we should do according to the dvar
		switch ( level.scr_koth_flash_on_capture ) {
			case 1:
				self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
				break;
			case 2:
				self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
				self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
				break;
		}
		// [0.0.1]

	}
	else
	{
		// [0.0.1] See what kind of flashing we should do according to the dvar
		switch ( level.scr_koth_flash_on_destroy ) {
			case 1:
				self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
				break;
			case 2:
				self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
				self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
				break;
		}
		// [0.0.1]
	}
}


onEndUse( team, player, success )
{
	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}


onRadioCapture( player )
{
	team = player.pers["team"];

	player logString( "radio captured" );
	player thread [[level.onXPEvent]]( "capture" );
	maps\mp\gametypes\_globallogic::givePlayerScore( "capture", player );

	lpselfnum = player getEntityNumber();
	lpGuid = player getGuid();
	logPrint("RC;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");

	oldTeam = maps\mp\gametypes\_gameobjects::getOwnerTeam();
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	if ( !level.kothMode )
		self maps\mp\gametypes\_gameobjects::setUseTime( level.destroyTime );

	otherTeam = "axis";
	if ( team == "axis" )
		otherTeam = "allies";

	thread printOnTeamArg( &"MP_HQ_CAPTURED_BY", team, player );
	thread printOnTeam( &"MP_HQ_CAPTURED_BY_ENEMY", otherTeam );
	maps\mp\gametypes\_globallogic::leaderDialog( "hq_secured", team );
	maps\mp\gametypes\_globallogic::leaderDialog( "hq_enemy_captured", oldTeam );
	thread playSoundOnPlayers( "mp_war_objective_taken", team );
	thread playSoundOnPlayers( "mp_war_objective_lost", otherTeam );

	level thread awardHQPoints( team );

	level notify( "hq_captured" );
}

/#
scriptDestroyHQ()
{
	level endon("hq_destroyed");
	while(1)
	{
		if ( getdvar("scr_destroyhq") != "1" )
		{
			wait .1;
			continue;
		}
		setdvar("scr_destroyhq","0");

		hqOwningTeam = level.radioObject maps\mp\gametypes\_gameobjects::getOwnerTeam();
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( level.players[i].team != hqOwningTeam )
			{
				onRadioDestroy( level.players[i] );
				break;
			}
		}
	}
}
#/

onRadioDestroy( player )
{
	team = player.pers["team"];
	otherTeam = "axis";
	if ( team == "axis" )
		otherTeam = "allies";

	player logString( "radio destroyed" );
	player thread [[level.onXPEvent]]( "capture" );
	maps\mp\gametypes\_globallogic::givePlayerScore( "capture", player );

	lpselfnum = player getEntityNumber();
	lpGuid = player getGuid();
	logPrint("RD;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");
	
	if ( level.kothmode )
	{
		thread printOnTeamArg( &"MP_HQ_CAPTURED_BY", team, player );
		thread printOnTeam( &"MP_HQ_CAPTURED_BY_ENEMY", otherTeam );
		maps\mp\gametypes\_globallogic::leaderDialog( "hq_secured", team );
		maps\mp\gametypes\_globallogic::leaderDialog( "hq_enemy_captured", otherTeam );
	}
	else
	{
		thread printOnTeamArg( &"MP_HQ_DESTROYED_BY", team, player );
		thread printOnTeam( &"MP_HQ_DESTROYED_BY_ENEMY", otherTeam );
		maps\mp\gametypes\_globallogic::leaderDialog( "hq_secured", team );
		maps\mp\gametypes\_globallogic::leaderDialog( "hq_enemy_destroyed", otherTeam );
	}
	thread playSoundOnPlayers( "mp_war_objective_taken", team );
	thread playSoundOnPlayers( "mp_war_objective_lost", otherTeam );

	level notify( "hq_destroyed" );

	if ( level.kothmode )
		level thread awardHQPoints( team );
}


DestroyHQAfterTime( time, timerDisplay )
{
	level endon( "game_ended" );
	level endon( "hq_reset" );

	level.hqDestroyTime = gettime() + time * 1000;
	level.hqDestroyedByTimer = false;

	finishWait = openwarfare\_timer::getTimePassed() + time * 1000;
	while ( finishWait > openwarfare\_timer::getTimePassed() ) {
		wait (0.05);
		if ( level.inTimeoutPeriod ) {
			timerDisplay["allies"].alpha = 0;
			timerDisplay["axis"  ].alpha = 0;
			xWait( 0.1 );
			timerDisplay["allies"] setTimer( ( finishWait - openwarfare\_timer::getTimePassed() ) / 1000 );
			timerDisplay["axis"  ] setTimer( ( finishWait - openwarfare\_timer::getTimePassed() ) / 1000 );
			timerDisplay["allies"].alpha = 1;
			timerDisplay["axis"  ].alpha = 1;
		}
	}

	level.hqDestroyedByTimer = true;
	level notify( "hq_destroyed" );
}


awardHQPoints( team )
{
	level endon( "game_ended" );
	level endon( "hq_destroyed" );

	level notify("awardHQPointsRunning");
	level endon("awardHQPointsRunning");

	seconds = 5;

	while ( !level.gameEnded )
	{
		[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + seconds );
		for ( index = 0; index < level.players.size; index++ )
		{
			player = level.players[index];

			if ( player.pers["team"] == team )
			{
				player thread [[level.onXPEvent]]( "defend" );
				maps\mp\gametypes\_globallogic::givePlayerScore( "defend", player );
			}
		}

		xWait( seconds );
	}
}


onSpawnPlayer()
{
	spawnpoint = undefined;
	
	if ( level.inGracePeriod ) {
		if ( self.pers["team"] == "allies" ) {
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_allies_start );
		} else {
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_axis_start );
		}		
	} else {
		if ( isdefined( level.radioObject ) )
		{
			hqOwningTeam = level.radioObject maps\mp\gametypes\_gameobjects::getOwnerTeam();
			if ( self.pers["team"] == hqOwningTeam )
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, level.radioObject.nearSpawns );
			else if ( level.spawnDelay >= level.hqAutoDestroyTime && gettime() > level.hqRevealTime + 10000 )
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all );
			else
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, level.radioObject.outerSpawns );
		}
	}

	if ( !isDefined( spawnpoint ) ) {
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all );
	}

	assert( isDefined(spawnpoint) );

	self.lowerMessageOverride = undefined;

	self spawn( spawnpoint.origin, spawnpoint.angles );
}


SetupRadios()
{
	maperrors = [];

	radios = getentarray( "hq_hardpoint", "targetname" );

	if ( radios.size < 2 )
	{
		maperrors[maperrors.size] = "There are not at least 2 entities with targetname \"radio\"";
	}

	level.radios = [];
	
	trigs = getentarray("radiotrigger", "targetname");
	for ( i = 0; i < radios.size; i++ )
	{
		if ( i > 6 ) {
			radios[i] delete();
			continue;
		}
		
		level.radios[ level.radios.size ] = radios[i];
		
		errored = false;

		radio = radios[i];
		radio.trig = undefined;
		for ( j = 0; j < trigs.size; j++ )
		{
			if ( radio istouching( trigs[j] ) )
			{
				if ( isdefined( radio.trig ) )
				{
					maperrors[maperrors.size] = "Radio at " + radio.origin + " is touching more than one \"radiotrigger\" trigger";
					errored = true;
					break;
				}
				radio.trig = trigs[j];
				break;
			}
		}

		if ( !isdefined( radio.trig ) )
		{
			if ( !errored )
			{
				maperrors[maperrors.size] = "Radio at " + radio.origin + " is not inside any \"radiotrigger\" trigger";
				continue;
			}

			// possible fallback (has been tested)
			//radio.trig = spawn( "trigger_radius", radio.origin, 0, 128, 128 );
			//errored = false;
		}

		assert( !errored );

		radio.trigorigin = radio.trig.origin;

		visuals = [];
		visuals[0] = radio;

		otherVisuals = getEntArray( radio.target, "targetname" );
		for ( j = 0; j < otherVisuals.size; j++ )
		{
			visuals[visuals.size] = otherVisuals[j];
		}

		radio.gameObject = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", radio.trig, visuals, (radio.origin - radio.trigorigin) + level.iconoffset );
		radio.gameObject maps\mp\gametypes\_gameobjects::disableObject();
		radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( false );
		radio.trig.useObj = radio.gameObject;

		radio setUpNearbySpawns();
	}

	if (maperrors.size > 0)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		maps\mp\_utility::error("Map errors. See above");
		maps\mp\gametypes\_callbacksetup::AbortLevel();

		return;
	}

	level.prevradio = undefined;
	level.prevradio2 = undefined;

	return true;
}

setUpNearbySpawns()
{
	spawns = level.spawn_all;

	for ( i = 0; i < spawns.size; i++ )
	{
		spawns[i].distsq = distanceSquared( spawns[i].origin, self.origin );
	}

	// sort by distsq
	for ( i = 1; i < spawns.size; i++ )
	{
		thespawn = spawns[i];
		for ( j = i - 1; j >= 0 && thespawn.distsq < spawns[j].distsq; j-- )
			spawns[j + 1] = spawns[j];
		spawns[j + 1] = thespawn;
	}

	first = [];
	second = [];
	third = [];
	outer = [];

	thirdSize = spawns.size / 3;
	for ( i = 0; i <= thirdSize; i++ )
	{
		first[ first.size ] = spawns[i];
	}
	for ( ; i < spawns.size; i++ )
	{
		outer[ outer.size ] = spawns[i];
		if ( i <= (thirdSize*2) )
			second[ second.size ] = spawns[i];
		else
			third[ third.size ] = spawns[i];
	}

	self.gameObject.nearSpawns = first;
	self.gameObject.midSpawns = second;
	self.gameObject.farSpawns = third;
	self.gameObject.outerSpawns = outer;
}

PickRadioToSpawn()
{
	// find average of positions of each team
	// (medians would be better, to get rid of outliers...)
	// and find the radio which has the least difference in distance from those two averages

	avgpos["allies"] = (0,0,0);
	avgpos["axis"] = (0,0,0);
	num["allies"] = 0;
	num["axis"] = 0;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isalive( player ) )
		{
			avgpos[ player.pers["team"] ] += player.origin;
			num[ player.pers["team"] ]++;
		}
	}

	if ( num["allies"] == 0 || num["axis"] == 0 )
	{
		radio = level.radios[ randomint( level.radios.size) ];
		while ( isDefined( level.prevradio ) && radio == level.prevradio ) // so lazy
			radio = level.radios[ randomint( level.radios.size) ];

		level.prevradio2 = level.prevradio;
		level.prevradio = radio;

		return radio;
	}

	avgpos["allies"] = avgpos["allies"] / num["allies"];
	avgpos["axis"  ] = avgpos["axis"  ] / num["axis"  ];

	bestradio = undefined;
	lowestcost = undefined;
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];

		// (purposefully using distance instead of distanceSquared)
		cost = abs( distance( radio.origin, avgpos["allies"] ) - distance( radio.origin, avgpos["axis"] ) );

		if ( isdefined( level.prevradio ) && radio == level.prevradio )
		{
			continue;
		}
		if ( isdefined( level.prevradio2 ) && radio == level.prevradio2 )
		{
			if ( level.radios.size > 2 )
				continue;
			else
				cost += 512;
		}

		if ( !isdefined( lowestcost ) || cost < lowestcost )
		{
			lowestcost = cost;
			bestradio = radio;
		}
	}
	assert( isdefined( bestradio ) );

	level.prevradio2 = level.prevradio;
	level.prevradio = bestradio;

	return bestradio;
}



onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	thread checkAllowSpectating();
	
	if ( !isPlayer( attacker ) || (!self.touchTriggers.size && !attacker.touchTriggers.size) || attacker.pers["team"] == self.pers["team"] )
		return;

	if ( self.touchTriggers.size )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;

		if ( ownerTeam != "neutral" )
		{
			team = self.pers["team"];
			if ( team == ownerTeam )
			{
				attacker thread [[level.onXPEvent]]( "assault" );
				maps\mp\gametypes\_globallogic::givePlayerScore( "assault", attacker );
			}
			else
			{
				attacker thread [[level.onXPEvent]]( "defend" );
				maps\mp\gametypes\_globallogic::givePlayerScore( "defend", attacker );
			}
		}
	}

	if ( attacker.touchTriggers.size )
	{
		triggerIds = getArrayKeys( attacker.touchTriggers );
		ownerTeam = attacker.touchTriggers[triggerIds[0]].useObj.ownerTeam;

		if ( ownerTeam != "neutral" )
		{
			team = attacker.pers["team"];
			if ( team == ownerTeam )
			{
				attacker thread [[level.onXPEvent]]( "defend" );
				maps\mp\gametypes\_globallogic::givePlayerScore( "defend", attacker );
			}
			else
			{
				attacker thread [[level.onXPEvent]]( "assault" );
				maps\mp\gametypes\_globallogic::givePlayerScore( "assault", attacker );
			}
		}
	}
}


onRoundSwitch()
{
	// Just change the value for the variable controlling which map assets will be assigned to each team
	level.halftimeType = "halftime";
	game["switchedsides"] = !game["switchedsides"];
}

checkAllowSpectating()
{
	wait ( 0.05 );

	if ( !level.aliveCount[ "axis" ] )
	{
		level.spectateOverride["axis"].allowEnemySpectate = 1;
		if( level.scr_koth_teamdeadspectate_tp )
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				team = player.pers["team"];
				if ( team == "axis" )
					player setClientDvar( "cg_thirdPerson", "1" );
			}
	}
	else
		level.spectateOverride["axis"].allowEnemySpectate = 0;
	if ( !level.aliveCount[ "allies" ] )
	{
		level.spectateOverride["allies"].allowEnemySpectate = 1;
		if( level.scr_koth_teamdeadspectate_tp )
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				team = player.pers["team"];
				if ( team == "allies" )
					player setClientDvar( "cg_thirdPerson", "1" );
			}
	}
	else
		level.spectateOverride["axis"].allowEnemySpectate = 0;

	maps\mp\gametypes\_spectating::updateSpectateSettings();
}