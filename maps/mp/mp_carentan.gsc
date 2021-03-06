main()
{
	openwarfare\maps\mp_carentan_fx::main();
	maps\createart\mp_carentan_art::main();
	maps\mp\_load::main();
	maps\mp\_compass::setupMiniMap("compass_map_mp_carentan");
	
	// raise up planes to avoid them flying through buildings
	level.airstrikeHeightScale = 1.4;
	
	setExpFog(500, 3500, .5, 0.5, 0.45, 0);
	
	game["allies"] = "sas";
	game["axis"] = "russian";
	game["attackers"] = "axis";
	game["defenders"] = "allies";
	game["allies_soldiertype"] = "urban";
	game["axis_soldiertype"] = "urban";

}


