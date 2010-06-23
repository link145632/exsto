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

function PLUGIN:SetArmor( self, victim, armor )

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

function PLUGIN:SetHealth( self, victim, health )

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

function PLUGIN:PlayerSpawn( ply )
	if ply.God and ply.ForceGod then
		ply:GodEnable()
	end
end

function PLUGIN:God( self, victim, force )

	if victim.God then
		victim:GodDisable()
		victim.God = false
		victim.ForceGod = false
		
		return {
			Activator = self,
			Player = victim,
			Wording = " has de-godded ",
		}
	else
		victim:GodEnable()
		victim.God = true
		victim.ForceGod = force
			
		return {
			Activator = self,
			Player = victim,
			Wording = force and " has perm-godded " or " has godded ",
		}
		
	end
	
end
PLUGIN:AddCommand( "godmode", {
	Call = PLUGIN.God,
	Desc = "Sets godmode on a player",
	FlagDesc = "Allows users to set godmode on players.",
	Console = { "god", "ungod" },
	Chat = { "!god", "!ungod" },
	ReturnOrder = "Victim-Force",
	Args = { Victim = "PLAYER", Force = "BOOLEAN" },
	Optional = { Force = false, }
})

PLUGIN:Register()