#include openwarfare\_utils;

init()
{
	// Load the names of the custom maps
	customMapNamesList = getdvarlistx( "scr_custom_map_names_", "string", "" );
	
	// Load the maps into an array
	level.customMapNames = [];
	
	for ( i=0; i < customMapNamesList.size; i++ ) {
		// Split the maps
		customMapNames = strtok( customMapNamesList[i], ";" );
		for ( mapix = 0; mapix < customMapNames.size; mapix++ ) {
			// Split the map file name and the desired map name
			thisMap = strtok( customMapNames[ mapix ], "=" );
			// First element is the map file name and second element is the desired map name
			level.customMapNames[ toLower( thisMap[0] ) ] = thisMap[1];
		}
	}
	
	// Get the module's variables (see beginning of init() function in _globallogic.gsc for level.sv_mapRotationLoadBased)
	level.sv_mapRotationScramble = getdvard( "sv_mapRotationScramble", "int", 0, 0, 1  );
	
	// Make sure this is not a listen server
	// Why? Shouldn't a listen server use this features?
	//if ( getDvar("dedicated") == "listen server" )
	//return;
	
	// Clean the map rotation
	cleanMapRotation( false );
	
	// Set the rotation
	setRotationCurrent( true );
	getNextMapInRotation();
	
	level thread onServerLoadSet();
}


onServerLoadSet()
{
	oldServerLoad = level.serverLoad;
	
	// Wait until the game ends and the new server load is set
	level waittill( "server_load", newServerLoad );
	
	// Check if we need to change the map rotation based on the new server load
	if ( !game["amvs_skip_voting"] && level.sv_mapRotationLoadBased == 1 && oldServerLoad != newServerLoad ) {
		// Save the current rotation
		setDvar( "_mrcs_sv_mapRotationCurrent_" + oldServerLoad, getDvar( "sv_mapRotationCurrent" ) );
		setDvar( "sv_mapRotationCurrent", "" );
		setRotationCurrent( false );
		getNextMapInRotation();
	}
}


setRotationCurrent( initCheck )
{
	mrcs_svMRC = getdvarl( "_mrcs_sv_mapRotationCurrent", "string", "", undefined, undefined, level.sv_mapRotationLoadBased );
	// If this is a change of server load check if we have a saved current rotation
	if ( !initCheck && mrcs_svMRC != "" ) {
		setDvar( "sv_mapRotationCurrent", mrcs_svMRC );
	}
	else {
		// Check if we need to set a new rotation line
		if ( initCheck && getDvar( "sv_mapRotationCurrent" ) != "" )
			return;
			
		// Check if this is the first time
		advanceOneMap = false;
		mrcs_Line = getdvarl( "_mrcs_line", "int", -1, -1, 99, level.sv_mapRotationLoadBased );
		// if server is starting up (booting)
		if ( mrcs_Line == -1 ) {
			cleanMapRotation( false );
			currentLine = 0;
			//restartRotation = initCheck;
			advanceOneMap = initCheck;
		}
		else {
			currentLine = mrcs_Line;
			if ( initCheck ) {
				currentLine++;
			}
		}
		
		// Get the map rotations
		mapRotations = getMapRotations();
		
		// Check if we should start from the first one again
		if ( currentLine == mapRotations.size ) {
			// Check if we should scramble or re-generate again the map rotation
			if ( level.sv_mapRotationScramble == 1 || level.scr_mrcs_auto_generate == 1 ) {
				cleanMapRotation( true );
				mapRotations = getMapRotations();
			}
			currentLine = 0;
		}
		
		// Set the current rotation
		setDvar( "sv_mapRotationCurrent", mapRotations[currentLine] );
		setDvarL( "_mrcs_line", currentLine, false );
		
		// Check if we need to advance one map/gametype in the rotation
		// This is needed at server startup since in the first position of sv_mapRotationCurrent
		// is the map that is already running
		if ( advanceOneMap && level.sv_mapRotationScramble == 0 && level.scr_mrcs_auto_generate == 0 )
			advanceOneMapInCurrRot();
	}
}


cleanMapRotation( forceClean )
{
	// Check if we already cleaned the map rotation
	// We clean it at server startup because the dvar is unset
	if ( getdvarl( "_mrcs_cleaned", "int", 0, 0, 1, level.sv_mapRotationLoadBased ) == 1 && !forceClean )
		return;
		
	// Get the combinations
	mgCombinations = getMapGametypeCombinations(false);
	
	// Check if we need to scramble the rotation
	if ( level.sv_mapRotationScramble == 1 || level.scr_mrcs_auto_generate == 1 ) {
		mgCombinations = scrambleMapRotation( mgCombinations );
	}
	
	// Initialize an array to keep the new rotations
	newMapRotations = [];
	newMapRotationsLine = 0;
	newMapRotations[newMapRotationsLine] = "";
	
	for ( mgc=0; mgc < mgCombinations.size; mgc++ ) {
		// Make sure we have space on the current line
		if ( newMapRotations[newMapRotationsLine].size > 900 ) {
			newMapRotationsLine++;
			newMapRotations[newMapRotationsLine] = "";
		}
		
		// Add a space only if this is not the first thing we add to this line
		if ( newMapRotations[newMapRotationsLine] != "" ) {
			newMapRotations[newMapRotationsLine] += " ";
		}
		// Add the gametype change
		newMapRotations[newMapRotationsLine] += "gametype " + mgCombinations[mgc]["gametype"];
		newMapRotations[newMapRotationsLine] += " map " + mgCombinations[mgc]["mapname"];
	}
	
	// Set the next map rotation empty
	newMapRotationsLine++;
	newMapRotations[newMapRotationsLine] = "";
	
	setDvarL( "sv_mapRotation", newMapRotations[0], false );
	for ( mr=1; mr < newMapRotations.size; mr++ ) {
		setDvarL( "sv_mapRotation_" + mr, newMapRotations[mr], false );
	}
	
	// Map rotation cleaned, reset rotation string and restart the first map
	setDvar( "sv_mapRotationCurrent", "" );
	setDvarL( "_mrcs_cleaned", "1", false );
}


scrambleMapRotation( mgCombinations )
{
	// Get how many iterations will be doing
	maxIterations = mgCombinations.size;
	currentIteration = 0;
	newCombinations = [];
	
	while ( currentIteration < maxIterations ) {
		// Get the position
		elementPosition = randomIntRange( 0, maxIterations );
		
		// Search for the element
		while ( !isDefined( mgCombinations[ elementPosition ] ) && elementPosition < maxIterations )
			elementPosition++;
			
		// If we reach end of array we'll search from the beginning
		if ( elementPosition == maxIterations ) {
			elementPosition = 0;
			// Search for the element
			while ( !isDefined( mgCombinations[ elementPosition ] ) && elementPosition < maxIterations )
				elementPosition++;
		}
		
		// Add the new element
		if ( isDefined( mgCombinations[ elementPosition ] ) ) {
			newCombinations[ newCombinations.size ] = mgCombinations[ elementPosition ];
			mgCombinations[ elementPosition ] = undefined;
		}
		else {
			// Why the hell are we here?
			break;
		}
		
		currentIteration++;
	}
	
	return newCombinations;
}


getMapRotations()
{
	mapRotations = [];
	
	// Get the first mandatory map rotation
	thisMapRotation = tolower( getdvarl( "sv_mapRotation", "string", "", undefined, undefined, level.sv_mapRotationLoadBased ) );
	
	// Get the rest of the map rotations
	mr = 0;
	while ( thisMapRotation != "" ) {
		mapRotations[mr] = thisMapRotation;
		
		// Get the next line
		mr++;
		thisMapRotation = tolower( getdvarl( "sv_mapRotation_" + mr, "string", "", undefined, undefined, level.sv_mapRotationLoadBased ) );
	}
	
	return mapRotations;
}


getMapGametypeCombinations(fromCurrentRotation)
{
	mgCombinations = [];
	
	// Get the map rotations
	if ( level.scr_mrcs_auto_generate == 1 && !fromCurrentRotation ) {
		// Get the default gametype list
		defaultGametypes = strtok( tolower( getdvarl( "scr_mrcs_auto_gametypes", "string", level.defaultGametypeList, undefined, undefined, level.sv_mapRotationLoadBased ) ), ";" );
		
		// Get the first map list
		mapLine = 1;
		mapsToProcess = tolower( getdvarl( "scr_mrcs_auto_maps_1", "string", level.defaultMapList, undefined, undefined, level.sv_mapRotationLoadBased ) );
		
		// Process all the lines
		while ( mapsToProcess != "" ) {
			// Split the line by maps first
			mapsToProcess = strtok( mapsToProcess, ";" );
			
			for ( m=0; m < mapsToProcess.size; m++ ) {
				// Split the element into map and gametypes
				mapGametypes = strtok( mapsToProcess[m], ":" );
				
				// Check if we have gametypes defined for this map, if not we'll use the default ones
				if ( !isDefined( mapGametypes[1] ) ) {
					mapGametypes[1] = defaultGametypes;
				}
				else {
					// Convert them into array
					mapGametypes[1] = strtok( mapGametypes[1], "," );
				}
				
				// Process this map
				for ( g=0; g < mapGametypes[1].size; g++ ) {
					// Make sure this gametype is good (we add semicolons to the string to make sure we have a full gametype name)
					if ( isSubstr( ";"+level.defaultGametypeList+";", ";"+mapGametypes[1][g]+";" ) ) {
						newElement = mgCombinations.size;
						mgCombinations[newElement]["gametype"] = mapGametypes[1][g];
						mgCombinations[newElement]["mapname"] = mapGametypes[0];
					}
				}
			}
			
			// Get the next line
			mapLine++;
			mapsToProcess = tolower( getdvarl( "scr_mrcs_auto_maps_" + mapLine, "string", "", undefined, undefined, level.sv_mapRotationLoadBased ) );
		}
		
	}
	else {
		if(fromCurrentRotation && getdvar( "sv_mapRotationCurrent" ) != "")
			mapRotations[0] = tolower( getdvar( "sv_mapRotationCurrent" ) );
		else
			mapRotations = getMapRotations();
			
		// Convert map rotations into array with all the map/gametype combinations
		currentGametype = tolower( getdvard( "g_gametype", "string", "war" ) );
		
		for ( mr=0; mr < mapRotations.size; mr++ ) {
			// Split the line into each element
			thisMapRotation = strtok( mapRotations[mr], " " );
			
			// Analyze the elements and start adding them to the list
			for ( e=0; e < thisMapRotation.size; e++ ) {
				// Discard "gametype" and "map" keywords
				if ( thisMapRotation[e] == "gametype" || thisMapRotation[e] == "map" ) {
					continue;
				}
				// Check for valid gametype (we add semicolons to the string to make sure we have a full gametype name)
				else if ( isSubstr( ";"+level.defaultGametypeList+";", ";"+thisMapRotation[e]+";" ) ) {
					currentGametype = thisMapRotation[e];
					continue;
				}
				// Check for map and add it to the new list
				else if ( getSubStr( thisMapRotation[e], 0, 3 ) == "mp_" ) {
					newElement = mgCombinations.size;
					mgCombinations[newElement]["gametype"] = currentGametype;
					mgCombinations[newElement]["mapname"] = thisMapRotation[e];
				}
			}
		}
	}
	
	return mgCombinations;
}


getNextMapInRotation()
{
	// Get the current map rotation
	mapRotation = getdvar( "sv_mapRotationCurrent" );
	// If mapRotation is empty it means we are running the last map in the rotation
	// so we need to get the map from the actual rotation
	if ( mapRotation == "" ) {
		mapRotation = getdvarl( "sv_mapRotation", "string", "", undefined, undefined, level.sv_mapRotationLoadBased );
	}
	
	// Split the map rotation
	mapRotation = strtok( mapRotation, " " );
	mapIdx = 0;
	// Search for the first map keyword
	while ( mapIdx < mapRotation.size && mapRotation[ mapIdx ] != "map" ) {
		mapIdx++;
	}
	// The next element is the map name
	mapName = mapRotation[ mapIdx + 1 ];
	
	// Now go back and search for the prior gametype keyword
	mapIdx--;
	while ( mapIdx >= 0 && mapRotation[ mapIdx ] != "gametype" ) {
		mapIdx--;
	}
	if ( mapIdx >= 0 ) {
		gameType = mapRotation[ mapIdx + 1 ];
	}
	else {
		gameType = getdvar( "g_gametype" );
	}
	
	// Update the variabels containing the next map in the rotation
	nextMapInfor = [];
	nextMapInfor["mapname"] = mapName;
	nextMapInfor["gametype"] = gameType;
	
	level.nextMapInfo = nextMapInfor;
	
	return;
}


setDvarL( varName, varValue, printLog )
{
	// Check if we need to use the server load or not
	if ( level.sv_mapRotationLoadBased == 1 ) {
		varName = varName + "_" + level.serverLoad;
	}
	
	// Comment the following line on public release
	//if ( printLog ) {
	//	logPrint( "MRCS;" + varName + ": \"" + varValue + "\"\n" );
	//}
	setDvar( varName, varValue );
}

calculateMapRotationCurrentIndex()
{
	for(i=level.mgCombinations.size-1; i>=0; i--) {
		for(j=level.mgCombinationsCurr.size-1; j>=0; j--) {
			outerIndex = i-(level.mgCombinationsCurr.size-1-j);
			if( !isDefined( level.mgCombinationsCurr[j] ) || !isDefined( level.mgCombinations[outerIndex] ) )
				break;
			if( level.mgCombinationsCurr[j]["gametype"] != level.mgCombinations[outerIndex]["gametype"] || level.mgCombinationsCurr[j]["mapname"] != level.mgCombinations[outerIndex]["mapname"] )
				break;
			if( j == 0 )
				return outerIndex-1;
		}
	}
	// strange, there was no match between the rotations, return index -1 then
	return -1;
}

advanceOneMapInCurrRot()
{
	currentRot = getDvar( "sv_mapRotationCurrent" );
	
	upperBound = 64;
	if( currentRot.size < 64 )
		upperBound = currentRot.size;
	
	firstMGEndingIndex = 0;
	// starting at 16 because its the minimum number of letters with: 'gametype X map Y'
	for( i=16; i < upperBound; i++ ) {
		firstMG = GetSubStr(currentRot, 0, i);
		if( numberOfSpaces(firstMG) == 4 ) {
			firstMGEndingIndex = i-1;
			break;
		}
	}
	
	if( firstMGEndingIndex != 0 )
		setDvar( "sv_mapRotationCurrent", GetSubStr(currentRot, firstMGEndingIndex) );
	
}

numberOfSpaces(string) {
	temp = strtok(string, " ");
	return temp.size-1;
}