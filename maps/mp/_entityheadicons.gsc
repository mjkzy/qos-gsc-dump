init()
{
	if (!level.teamBased)
		return;
	
	if (isdefined(level.initedEntityHeadIcons))
		return;
	level.initedEntityHeadIcons = true;
	
	entityHeadIconHandler =
		maps\mp\gametypes\_perplayer::init("entityheadiconhandler", ::showAllEntityHeadIcons, ::hideAllEntityHeadIcons);
	maps\mp\gametypes\_perplayer::enable(entityHeadIconHandler);
	level.entitiesWithHeadIcons = [];
	level.playersViewingHeadIcons = [];

	switch(game["allies"])
	{
	case "mi6":
		game["entity_headicon_allies"] = "headicon_mi6";
		precacheShader(game["entity_headicon_allies"]);
		break;
	case "marines":
		game["entity_headicon_allies"] = "headicon_mi6";
		precacheShader(game["entity_headicon_allies"]);
		break;
	}
	game["entity_headicon_axis"] = "headicon_enemy_a";
	precacheShader(game["entity_headicon_axis"]);
}

setEntityHeadIcon(team, offset) // "allies", "axis", "all", "none"
{
	if (!level.teamBased)
		return;
	
	if (!isdefined(self.entityHeadIconTeam)) {
		self.entityHeadIconTeam = "none";
		self.entityHeadIcons = [];
	}
	if (team == self.entityHeadIconTeam)
		return;
	
	self.entityHeadIconTeam = team;
	
	if (isdefined(offset))
		self.entityHeadIconOffset = offset;
	else
		self.entityHeadIconOffset = (0,0,0);

	// destroy existing head icons for this entity
	for (i = 0; i < self.entityHeadIcons.size; i++)
		if (isdefined(self.entityHeadIcons[i]))
			self.entityHeadIcons[i] destroy();
	self.entityHeadIcons = [];
	
	self notify("kill_entity_headicon_thread");
	
	
	if (team != "none") {
		// create new head icons
		for (i = 0; i < level.playersViewingHeadIcons.size; i++)
			level.playersViewingHeadIcons[i] updateEntityHeadIcon(self);
	}
	
	// add to level.entitiesWithHeadIcons
	newarray = [];
	for (i = 0; i < level.entitiesWithHeadIcons.size; i++) {
		if (level.entitiesWithHeadIcons[i] != self)
			newarray[newarray.size] = level.entitiesWithHeadIcons[i];
	}
	if (team != "none")
		newarray[newarray.size] = self;
	level.entitiesWithHeadIcons = newarray;
	
	self thread keepEntityHeadIconsPositioned();
}

showAllEntityHeadIcons()
{
	if (!isdefined(self.entityHeadIcons))
		self.entityHeadIcons = [];
	
	for (i = 0; i < level.entitiesWithHeadIcons.size; i++) {
		if (isdefined(level.entitiesWithHeadIcons[i]))
			self updateEntityHeadIcon(level.entitiesWithHeadIcons[i]);
	}
	
	// add to level.playersViewingHeadIcons
	newarray = [];
	for (i = 0; i < level.playersViewingHeadIcons.size; i++) {
		if (level.playersViewingHeadIcons[i] != self)
			newarray[newarray.size] = level.playersViewingHeadIcons[i];
	}
	newarray[newarray.size] = self;
	level.playersViewingHeadIcons = newarray;
}
hideAllEntityHeadIcons(disconnected)
{
	if (!disconnected)
	{
		for (i = 0; i < self.entityHeadIcons.size; i++) {
			if (isdefined(self.entityHeadIcons[i]))
				self.entityHeadIcons[i] destroy();
		}
		self.entityHeadIcons = [];
	}
	
	// remove from level.playersViewingHeadIcons
	newarray = [];
	for (i = 0; i < level.playersViewingHeadIcons.size; i++) {
		if (level.playersViewingHeadIcons[i] != self)
			newarray[newarray.size] = level.playersViewingHeadIcons[i];
	}
	level.playersViewingHeadIcons = newarray;
}

updateEntityHeadIcon(entity)
{
	if (entity.entityHeadIconTeam != "all" && (!isdefined(self.pers["team"]) || self.pers["team"] != entity.entityHeadIconTeam))
		return;
	
	headicon = newClientHudElem(self);
	headicon.archived = true;
	headicon.x = entity.origin[0] + entity.entityHeadIconOffset[0];
	headicon.y = entity.origin[1] + entity.entityHeadIconOffset[1];
	headicon.z = entity.origin[2] + entity.entityHeadIconOffset[2];
	headicon.alpha = .8;
	headicon setShader(game["entity_headicon_" + self.pers["team"]], 10, 10);
	headicon setwaypoint(false); // false = uniform size in 3D instead of uniform size in 2D
	
	// update entityHeadIcons arrays so we can delete this later when either the entity or the player don't want it
	self.entityHeadIcons[self.entityHeadIcons.size] = headicon;
	entity.entityHeadIcons[entity.entityHeadIcons.size] = headicon;
}

keepEntityHeadIconsPositioned()
{
	self endon("kill_entity_headicon_thread");
	self endon("death");
	
	pos = self.origin;
	while(1)
	{
		if (pos != self.origin) {
			for (i = 0; i < self.entityHeadIcons.size; i++) {
				if (isdefined(self.entityHeadIcons[i]))
					self updateEntityHeadIconPos(self.entityHeadIcons[i]);
			}
			pos = self.origin;
		}
		wait .05;
	}
}
updateEntityHeadIconPos(headicon)
{
	headicon.x = self.origin[0] + self.entityHeadIconOffset[0];
	headicon.y = self.origin[1] + self.entityHeadIconOffset[1];
	headicon.z = self.origin[2] + self.entityHeadIconOffset[2];
}
