#include openwarfare\_utils;


setRuleset()
{
	setDvar( "scr_league_ruleset", "OW Softcore All Weapons" );

	rulesets\openwarfare\common\common::init();
	rulesets\openwarfare\match\match::init();
}