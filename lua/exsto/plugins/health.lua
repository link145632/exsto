-- Prefan Access Controller
-- Goto and Bring

-- FURST PLUGIN TO USE NEW COMMAND SYSTEM

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Health Related Commands",
	ID = "health-items",
	Desc = "A plugin that contains a bunch of health related commands!",
	Owner = "Prefanatic",
} )

if CLIENT then return end

function PLUGIN.SetArmor( self, victim, armor )

	victim:SetArmor( math.Clamp( armor, 1, 99998 ) )
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has set the armor of ",
		Secondary = " to " .. armor,
	}
	
end
PLUGIN:AddCommand( "setarmor", {
	Call = PLUGIN.SetArmor,
	Desc = "Sets the armor of a player.",
	FlagDesc = "Allows users to set the armor of players.",
	Console = { "setarmor" },
	Chat = { "!armor" },
	ReturnOrder = "Victim-Armor",
	Args = { Victim = "PLAYER", Armor = "NUMBER" },
	Optional = { Armor = 100 }
})

function PLUGIN.SetHealth( self, victim, health )

	victim:SetHealth( math.Clamp( health, 1, 99998 ) )
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has set the health of ",
		Secondary = " to " .. health,
	}
	
end
PLUGIN:AddCommand( "sethealth", {
	Call = PLUGIN.SetHealth,
	Desc = "Sets the health of a player.",
	FlagDesc = "Allows users to set the health of players.",
	Console = { "sethealth" },
	Chat = { "!health" },
	ReturnOrder = "Victim-Health",
	Args = { Victim = "PLAYER", Health = "NUMBER" },
	Optional = { Health = 100 }
})

function PLUGIN:OnEntityTakeDamage( ent, inflictor, attacker, amount )
	if type( ent ) == "Player" then
		if ent.God then return true end
	end
end

function PLUGIN.God( self, victim )

	if victim.God then
		victim.God = false
		
		return {
			Activator = self,
			Player = victim,
			Wording = " has de-godded ",
		}
	else
		victim.God = true
			
		return {
			Activator = self,
			Player = victim,
			Wording = " has godded ",
		}
		
	end
	
end
PLUGIN:AddCommand( "godmode", {
	Call = PLUGIN.God,
	Desc = "Sets godmode on a player",
	FlagDesc = "Allows users to set godmode on players.",
	Console = { "god" },
	Chat = { "!god" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Optional = { }
})

PLUGIN:Register()