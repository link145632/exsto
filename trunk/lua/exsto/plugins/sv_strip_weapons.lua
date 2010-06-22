-- Prefan Access Controller
-- Goto and Bring

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Weapon Stripping Functions",
	ID = "weapon-strip",
	Desc = "A plugin that contains weapon related functions!",
	Owner = "Prefanatic",
} )

function PLUGIN:Return( self, victim )
	
	if !victim.OldWeapons then
		return {
			self, COLOR.NAME, victim, COLOR.NORM, " does not have any weapons to return!"
		}
	end
	
	for k,v in pairs( victim.OldWeapons ) do
		victim:Give( v )
	end
	
	victim.OldWeapons = nil

	return {
		Activator = self,
		Player = victim,
		Wording = " has gived back ",
		Secondary = " his weapons"
	}
end
PLUGIN:AddCommand( "returnweps", {
	Call = PLUGIN.Return,
	Desc = "Returns weapons to a player.",
	FlagDesc = "Allows users to return players their weapons.",
	Console = { "returnweapons" },
	Chat = { "!returnweps" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Optional = { }
})

function PLUGIN:Give( self, victim, weapon )
	victim:Give( weapon )
	
	return { COLOR.NAME, self, COLOR.NORM, " has gave ", COLOR.NAME, victim, COLOR.NORM, " a " .. weapon }
end
PLUGIN:AddCommand( "give", {
	Call = PLUGIN.Give,
	Desc = "Gives a weapon to a player.",
	FlagDesc = "Allows users to give weapons.",
	Console = { "give" },
	Chat = { "!give" },
	ReturnOrder = "Victim-Weapon",
	Args = { Victim = "PLAYER", Weapon = "STRING" },
	Optional = { }
})

function PLUGIN:Strip( self, victim )
	victim.OldWeapons = {}
	
	for k,v in pairs( victim:GetWeapons() ) do
		table.insert( victim.OldWeapons, v:GetClass() )
	end
	
	victim:StripWeapons()
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has stripped ",
		Secondary = " of his weapons"
	}
end
PLUGIN:AddCommand( "stripweps", {
	Call = PLUGIN.Strip,
	Desc = "Strips weapons from a player.",
	FlagDesc = "Allows users to strip players of weapons.",
	Console = { "stripweapons", "strip" },
	Chat = { "!stripweps", "!strip" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Optional = { }
})

PLUGIN:Register()