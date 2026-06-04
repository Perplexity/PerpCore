PerpCore.Ninja = PerpCore.Ninja or {}
Ninja = PerpCore.Ninja

Ninja.Abilities = {
	Dokumori = 2248,
	TCJ = 7403,
	KunaisBane = 36958,
	Kassatsu = 2264,
	DreamWithiADream = 3566,
	Ten = 2259,
	Chi = 2261,
	Jin = 2263
}

local Abilities = Ninja.Abilities;

function Ninja.GetMudraStacks()
	local ten = ActionList:Get(1, Abilities.Ten);
	local stacks = math.floor((ten.cd == 0 and 40 or ten.cd) / 20);
	return stacks;
end

function Ninja.GetDoubleRaitonWaitTime()
	local mudraCooldown = ActionList:Get(1, Abilities.Ten).cd;
	if (mudraCooldown == 0) then return 0; end
	return math.max(0, 25 - mudraCooldown);
end

function Ninja.GetSecondsUntilDokumori()
	local dokumori = ActionList:Get(1, Abilities.Dokumori);
	return dokumori.cdmax - dokumori.cd;
end
