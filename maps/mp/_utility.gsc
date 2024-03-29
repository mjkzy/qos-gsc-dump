#include maps\mp\gametypes\_hud_util;

flag_wait (msg)
{
	while (!level.flag[msg])
		level waittill (msg);
}

flag_wait_either( flag1, flag2 )
{
	for ( ;; )
	{
		if ( flag( flag1 ) )
			return;
		if ( flag( flag2 ) )
			return;
		
		level waittill_either( flag1, flag2 );
	}
}

flag_waitopen (msg)
{
	while (level.flag[msg])
		level waittill (msg);
}


flag_trigger_init( message, trigger, continuous )
{
	flag_init( message );

	if ( !isDefined( continuous ) )
		continuous = false;
	
	assert( isSubStr( trigger.classname, "trigger" ) );
	trigger thread _flag_wait_trigger( message, continuous );
	
	return trigger;
}


flag_triggers_init( message, triggers, all )
{
	flag_init( message );

	if ( !isDefined( all ) )
		all = false;
	
	for ( index = 0; index < triggers.size; index++ )
	{
		assert( isSubStr( triggers[index].classname, "trigger" ) );
		triggers[index] thread _flag_wait_trigger( message, false );
	}
	
	return triggers;
}


flag_init( message, trigger )
{
	if ( !isDefined( level.flag ) )
	{
		level.flag = [];
		level.flags_lock = [];
	}
	assertEx( !isDefined( level.flag[message] ), "Attempt to reinitialize existing message: " + message );
	level.flag[message] = false;
/#
	level.flags_lock[message] = false;
#/
}

flag_set_delayed( message, delay )
{
	wait( delay );
	flag_set( message );
}

flag_set( message )
{
/#
	assertEx( isDefined( level.flag[message] ), "Attempt to set a flag before calling flag_init: " + message );
	assert( level.flag[message] == level.flags_lock[message] );
	level.flags_lock[message] = true;
#/	
	level.flag[message] = true;
	level notify ( message );
}

flag_clear( message )
{
/#
	assertEx( isDefined( level.flag[message] ), "Attempt to set a flag before calling flag_init: " + message );
	assert( level.flag[message] == level.flags_lock[message] );
	level.flags_lock[message] = false;
#/	
	level.flag[message] = false;
	level notify ( message );
}

flag( message )
{
	assertEx( isdefined( message ), "Tried to check flag but the flag was not defined." );
	if ( !level.flag[message] )
		return false;

	return true;
}

_flag_wait_trigger( message, continuous )
{
	self endon ( "death" );
	
	for ( ;; )
	{
		self waittill( "trigger", other );
		flag_set( message );

		if ( !continuous )
			return;

		while ( other isTouching( self ) )
			wait ( 0.05 );
		
		flag_clear( messagE );
	}
}

triggerOff()
{
	if (!isdefined (self.realOrigin))
		self.realOrigin = self.origin;

	if (self.origin == self.realorigin)
		self.origin += (0, 0, -10000);
}

triggerOn()
{
	if (isDefined (self.realOrigin) )
		self.origin = self.realOrigin;
}

error(msg)
{
	println("^c*ERROR* ", msg);
	wait .05;	// waitframe
/#
	if (getdvar("debug") != "1")
		assertmsg("This is a forced error - attach the log file");
#/
}

error2(msg)
{
	println("^c*ERROR* ", msg);
	wait .05;	// waitframe
/#
	if (getdvar("debug") != "1")
		assertmsg(msg);
#/
}

vector_scale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

vector_multiply( vec, vec2 )
{
	vec = (vec[0] * vec2[0], vec[1] * vec2[1], vec[2] * vec2[2]);
	
	return vec;
}


add_to_array(array, ent)
{
	if(!isdefined(ent))
		return array;
		
	if(!isdefined(array))
		array[0] = ent;
	else
		array[array.size] = ent;
	
	return array;	
}

exploder(num)
{
	num = int(num);
	ents = level._script_exploders;

	for(i = 0; i < ents.size; i++)
	{
		if(!isdefined(ents[i]))
			continue;

		if (ents[i].script_exploder != num)
			continue;

		if (isdefined(ents[i].script_fxid))
			level thread cannon_effect(ents[i]);

		if (isdefined (ents[i].script_sound))
			ents[i] thread exploder_sound();

		if (isdefined(ents[i].targetname))
		{
			if(ents[i].targetname == "exploder")
				ents[i] thread brush_show();
			else
			if((ents[i].targetname == "exploderchunk") || (ents[i].targetname == "exploderchunk visible"))
				ents[i] thread brush_throw();
			else
			if(!isdefined(ents[i].script_fxid))
				ents[i] thread brush_delete();
		}
		else
		if (!isdefined(ents[i].script_fxid))
			ents[i] thread brush_delete();
	}
}

exploder_sound()
{
	if(isdefined(self.script_delay))
		wait self.script_delay;
		
	self playSound(level.scr_sound[self.script_sound]);
}

cannon_effect(source)
{
	if(!isdefined(source.script_delay))
		source.script_delay = 0;

	if((isdefined(source.script_delay_min)) && (isdefined(source.script_delay_max)))
		source.script_delay = source.script_delay_min + randomfloat (source.script_delay_max - source.script_delay_min);

	org = undefined;
	if(isdefined(source.target))
		org = (getent(source.target, "targetname")).origin;

	level thread maps\mp\_fx::OneShotfx(source.script_fxid, source.origin, source.script_delay, org);
}

brush_delete()
{
	if(isdefined(self.script_delay))
		wait(self.script_delay);

	self delete();
}

brush_show()
{
	if(isdefined(self.script_delay))
		wait(self.script_delay);

	self show();
	self solid();
}

brush_throw()
{
	if(isdefined(self.script_delay))
		wait(self.script_delay);

	ent = undefined;
	if(isdefined(self.target))
		ent = getent(self.target, "targetname");

	if(!isdefined(ent))
	{
		self delete();
		return;
	}

	self show();

	org = ent.origin;

	temp_vec = (org - self.origin);

//	println("start ", self.origin , " end ", org, " vector ", temp_vec, " player origin ", level.player getorigin());

	x = temp_vec[0];
	y = temp_vec[1];
	z = temp_vec[2];

	self rotateVelocity((x,y,z), 12);
	self moveGravity((x, y, z), 12);

	wait(6);
	self delete();
}
/*
saveModel()
{
	info["model"] = self.model;
	info["viewmodel"] = self getViewModel();
	attachSize = self getAttachSize();
	info["attach"] = [];
	
	assert(info["viewmodel"] != ""); // No viewmodel was associated with the player's model
	
	for(i = 0; i < attachSize; i++)
	{
		info["attach"][i]["model"] = self getAttachModelName(i);
		info["attach"][i]["tag"] = self getAttachTagName(i);
		info["attach"][i]["ignoreCollision"] = self getAttachIgnoreCollision(i);
	}
	
	return info;
}

loadModel(info)
{
	self detachAll();
	self setModel(info["model"]);
	self setViewModel(info["viewmodel"]);

	attachInfo = info["attach"];
	attachSize = attachInfo.size;
    
	for(i = 0; i < attachSize; i++)
		self attach(attachInfo[i]["model"], attachInfo[i]["tag"], attachInfo[i]["ignoreCollision"]);
}
*/
getPlant()
{
	start = self.origin + (0, 0, 10);

	range = 11;
	forward = anglesToForward(self.angles);
	forward = vector_scale(forward, range);

	traceorigins[0] = start + forward;
	traceorigins[1] = start;

	trace = bulletTrace(traceorigins[0], (traceorigins[0] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[0], tracefraction is", trace["fraction"]);
		
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	trace = bulletTrace(traceorigins[1], (traceorigins[1] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[1], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	traceorigins[2] = start + (16, 16, 0);
	traceorigins[3] = start + (16, -16, 0);
	traceorigins[4] = start + (-16, -16, 0);
	traceorigins[5] = start + (-16, 16, 0);

	besttracefraction = undefined;
	besttraceposition = undefined;
	for(i = 0; i < traceorigins.size; i++)
	{
		trace = bulletTrace(traceorigins[i], (traceorigins[i] + (0, 0, -1000)), false, undefined);

		//ent[i] = spawn("script_model",(traceorigins[i]+(0, 0, -2)));
		//ent[i].angles = (0, 180, 180);
		//ent[i] setmodel("105");

		//println("^6trace ", i ," fraction is ", trace["fraction"]);

		if(!isdefined(besttracefraction) || (trace["fraction"] < besttracefraction))
		{
			besttracefraction = trace["fraction"];
			besttraceposition = trace["position"];

			//println("^6besttracefraction set to ", besttracefraction, " which is traceorigin[", i, "]");
		}
	}
	
	if(besttracefraction == 1)
		besttraceposition = self.origin;
	
	temp = spawnstruct();
	temp.origin = besttraceposition;
	temp.angles = orientToNormal(trace["normal"]);
	return temp;
}

orientToNormal(normal)
{
	hor_normal = (normal[0], normal[1], 0);
	hor_length = length(hor_normal);

	if(!hor_length)
		return (0, 0, 0);
	
	hor_dir = vectornormalize(hor_normal);
	neg_height = normal[2] * -1;
	tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
	plant_angle = vectortoangles(tangent);

	//println("^6hor_normal is ", hor_normal);
	//println("^6hor_length is ", hor_length);
	//println("^6hor_dir is ", hor_dir);
	//println("^6neg_height is ", neg_height);
	//println("^6tangent is ", tangent);
	//println("^6plant_angle is ", plant_angle);

	return plant_angle;
}

array_levelthread (ents, process, var, excluders)
{
	exclude = [];
	for (i=0;i<ents.size;i++)
		exclude[i] = false;

	if (isdefined (excluders))
	{
		for (i=0;i<ents.size;i++)
		for (p=0;p<excluders.size;p++)
		if (ents[i] == excluders[p])
			exclude[i] = true;
	}

	for (i=0;i<ents.size;i++)
	{
		if (!exclude[i])
		{
			if (isdefined (var))
				level thread [[process]](ents[i], var);
			else
				level thread [[process]](ents[i]);
		}
	}
}

deletePlacedEntity(entity)
{
	entities = getentarray(entity, "classname");
	for(i = 0; i < entities.size; i++)
	{
		//println("DELETED: ", entities[i].classname);
		entities[i] delete();
	}
}

playSoundOnPlayers( sound, team )
{
	players = getentarray("player", "classname");

	if(level.splitscreen)
	{	
		if(isdefined(players[0]))
			players[0] playLocalSound(sound);
	}
	else
	{
		if(isdefined(team))
		{
			for(i = 0; i < players.size; i++)
			{
				if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
					players[i] playLocalSound(sound);
			}
		}
		else
		{
			for(i = 0; i < players.size; i++)
				players[i] playLocalSound(sound);
		}
	}
}

printJoinedTeam(team)
{
	level.gametype = toLower( getDvar( "g_gametype" ) );
	
	if(!level.splitscreen)
	{

		if(level.gametype != "dm" || level.gametype != "os" )
		{
		if(team == "allies")
			iprintln(&"MP_JOINED_ALLIES", self);
		else if(team == "axis")
			iprintln(&"MP_JOINED_OPFOR", self);
	}
		else 
		{
			iprintln(&"MP_JOINED_THE_GAME", self);
		}
}
}

waittill_either( msg1, msg2 )
{
	self endon( msg1 );
	self waittill( msg2 );
}

waittill_any_mp( string1, string2, string3, string4, string5 )
{
	if ((!isdefined (string1) || string1 != "death") &&
	    (!isdefined (string2) || string2 != "death") &&
	    (!isdefined (string3) || string3 != "death") &&
	    (!isdefined (string4) || string4 != "death") &&
	    (!isdefined (string5) || string5 != "death"))
		self endon ("death");
		
	ent = spawnstruct();

	if (isdefined (string1))
		self thread waittill_string_mp (string1, ent);

	if (isdefined (string2))
		self thread waittill_string_mp (string2, ent);

	if (isdefined (string3))
		self thread waittill_string_mp (string3, ent);

	if (isdefined (string4))
		self thread waittill_string_mp (string4, ent);

	if (isdefined (string5))
		self thread waittill_string_mp (string5, ent);

	ent waittill ( "returned", msg );
	ent notify ( "die" );
	return msg;
}



waittill_string_mp( msg, ent )
{
	if ( msg != "death" )
		self endon ("death");
		
	ent endon ( "die" );
	self waittill ( msg );
	ent notify ( "returned", msg );
}


waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");

	while(self useButtonPressed() != true)
		wait .05;
}


setLowerMessage( text, time )
{
	if ( !isDefined( self.lowerMessage ) )
		return;
		
	self.lowerMessage setText( text );
	
	if ( isDefined( time ) && time > 0 )
		self.lowerTimer setTimer( time );
	else
		self.lowerTimer setText( "" );
}


printOnTeam(text, team)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
}


printOnTeamArg(text, team, arg)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text, arg);
	}
}


printOnPlayers( text, team )
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if ( isDefined( team ) )
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i] iprintln(text);
		}
		else
		{
			players[i] iprintln(text);
		}
	}
}


dvarIntValue( dVar, defVal, minVal, maxVal )
{
	dVar = "scr_" + level.gameType + "_" + dVar;
	if ( getDvar( dVar ) == "" )
	{
		setDvar( dVar, defVal );
		return defVal;
	}
	
	value = getDvarInt( dVar );

	if ( IsDefined( maxVal ) && value > maxVal )
		value = maxVal;
	else if ( IsDefined( minVal ) && value < minVal )
		value = minVal;
	else
		return value;
		
	setDvar( dVar, value );
	return value;
}


dvarFloatValue( dVar, defVal, minVal, maxVal )
{
	dVar = "scr_" + level.gameType + "_" + dVar;
	if ( getDvar( dVar ) == "" )
	{
		setDvar( dVar, defVal );
		return defVal;
	}
	
	value = getDvarFloat( dVar );

	if ( value > maxVal )
		value = maxVal;
	else if ( value < minVal )
		value = minVal;
	else
		return value;
		
	setDvar( dVar, value );
	return value;
}


play_sound_on_tag( alias, tag )
{
	org = spawn( "script_origin", (0,0,0) );

	if ( isdefined( tag) )
	{
		org linkto( self, tag, (0,0,0), (0,0,0) );
	}
	else
	{
		org.origin = self.origin;
		org.angles = self.angles;
		org linkto( self );
	}

	org playsound (alias, "sounddone");
	org waittill ("sounddone");
	org delete();
}


createLoopEffect( fxid )
{
	ent = maps\mp\_createfx::createEffect( "loopfx", fxid );
	ent.v["delay"] = 0.5;
	return ent;
}

createOneshotEffect( fxid )
{
	ent = maps\mp\_createfx::createEffect( "oneshotfx", fxid );
	ent.v["delay"] = -15;
	return ent;
}

loop_fx_sound ( alias, origin, ender, timeout )
{
	org = spawn ("script_origin",(0,0,0));
	if ( isdefined( ender ) )
	{
		thread loop_sound_delete (ender, org);
		self endon( ender );
	}
	org.origin = origin;
	org playloopsound (alias);
	if (!isdefined (timeout))
		return;
		
	wait (timeout);
//	org delete();
}

exploder_damage ()
{
	if (isdefined(self.v["delay"]))
		delay = self.v["delay"];
	else
		delay = 0;
		
	if (isdefined (self.v["damage_radius"]))
		radius = self.v["damage_radius"];
	else
		radius = 128;

	damage = self.v["damage"];
	origin = self.v["origin"];
	
	wait (delay);
	// Range, max damage, min damage
	radiusDamage (origin, radius, damage, damage);
}


exploder_before_load( num )
{
	// gotta wait twice because the createfx_init function waits once then inits all exploders. This guarentees
	// that if an exploder is run on the first frame, it happens after the fx are init.
	waittillframeend;
	waittillframeend;
	activate_exploder( num );
}

exploder_after_load( num )
{
	activate_exploder( num );
}

activate_exploder (num)
{
	num = int(num);
	for (i=0;i<level.createFXent.size;i++)
	{
		ent = level.createFXent[i];
		if (!isdefined (ent))
			continue;
	
		if (ent.v["type"] != "exploder")
			continue;	
	
		// make the exploder actually removed the array instead?
		if (!isdefined(ent.v["exploder"]))
			continue;

		if (ent.v["exploder"] != num)
			continue;

		if (isdefined (ent.v["firefx"]))
			ent thread fire_effect();

		if ( isdefined ( ent.v["fxid"] ) && ent.v["fxid"] != "No FX" )
			ent thread cannon_effect();
		else
		if (isdefined (ent.v["soundalias"]))
			ent thread sound_effect();

		if (isdefined (ent.v["damage"]))
			ent thread exploder_damage();

		if (isdefined (ent.v["earthquake"]))
		{
			eq = ent.v["earthquake"];
			earthquake(level.earthquake[eq]["magnitude"],
						level.earthquake[eq]["duration"],
						ent.v["origin"],
						level.earthquake[eq]["radius"]);
		}

		if (ent.v["exploder_type"] == "exploder")
			ent thread brush_show();
		else
		if ((ent.v["exploder_type"] == "exploderchunk") || (ent.v["exploder_type"] == "exploderchunk visible"))
			ent thread brush_throw();
		else
			ent thread brush_delete();
	}

/*
	for (i=0;i<level.createFXent.size;i++)
	{
		ent = level.createFXent[i];
		if (!isdefined (ent))
			continue;
		if (ent.v["exploder"] != num)
			continue;
		ent thread brush_delete();
	}
*/
}

sound_effect ()
{
	self effect_soundalias();
}

effect_soundalias ( )
{
	if (!isdefined (self.v["delay"]))
		self.v["delay"] = 0;
	
	// save off this info in case we delete the effect
	origin = self.v["origin"];
	alias = self.v["soundalias"];
	wait (self.v["delay"]);
	play_sound_in_space ( alias, origin );
}

play_sound_in_space (alias, origin, master)
{
	org = spawn ("script_origin",(0,0,1));
	if (!isdefined (origin))
		origin = self.origin;
	org.origin = origin;
	if (isdefined(master) && master)
		org playsoundasmaster (alias, "sounddone");
	else
		org playsound (alias, "sounddone");
	org waittill ("sounddone");
	org delete();
}

fire_effect ( )
{
	if (!isdefined (self.v["delay"]))
		self.v["delay"] = 0;

	delay = self.v["delay"];
	if ((isdefined (self.v["delay_min"])) && (isdefined (self.v["delay_max"])))
		delay = self.v["delay_min"] + randomfloat (self.v["delay_max"] - self.v["delay_min"]);

	forward = self.v["forward"];
	up = self.v["up"];

	org = undefined;

	firefxSound = self.v["firefxsound"];
	origin = self.v["origin"];
	firefx = self.v["firefx"];
	ender = self.v["ender"];
	if (!isdefined (ender))
		ender = "createfx_effectStopper";
	timeout = self.v["firefxtimeout"];

	fireFxDelay = 0.5;
	if (isdefined (self.v["firefxdelay"]))
		fireFxDelay = self.v["firefxdelay"];

	wait (delay);

	if (isdefined (firefxSound))	
		level thread loop_fx_sound ( firefxSound, origin, ender, timeout );

	playfx ( level._effect[firefx], self.v["origin"], forward, up );

//	loopfx(				fxId,	fxPos, 	waittime,	fxPos2,	fxStart,	fxStop,	timeout)
//	maps\_fx::loopfx(	firefx,	origin,	delay,		org,	undefined,	ender,	timeout);
}

loop_sound_delete ( ender, ent )
{
	ent endon ("death");
	self waittill (ender);
	ent delete();
}

createExploder( fxid )
{
	ent = maps\mp\_createfx::createEffect( "exploder", fxid );
	ent.v["delay"] = 0;
	ent.v["exploder_type"] = "normal";
	return ent;
}

getOtherTeam( team )
{
	if ( team == "allies" )
		return "axis";
	else if ( team == "axis" )
		return "allies";
		
	assertMsg( "getOtherTeam: invalid team " + team );
}