-- Exsto
-- Slap Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Slap",
	ID = "slap",
	Desc = "Bitch Slap Dat Foo",
	Owner = "Prefanatic and Schuyler",
} )

function PLUGIN.Slap( owner, ply, damage, duration, delay )

	local function Slap()
		if !ply:Alive() then timer.Create( "exsto_WhipDelay"..ply:Nick(), 0.1, 1, function() end ) return end
		local xspeed = math.random( -500, 500 )
		local yspeed = math.random( -500, 500 ) 
		local zspeed = math.random( -500, 500 )
		ply:SetVelocity( Vector( xspeed, yspeed, zspeed ) )
		ply:SetHealth( ply:Health() - damage )

		if ply:InVehicle() then ply:ExitVehicle() end 
		if ply:Health() <= 0 then ply:Kill() end
		ply:EmitSound( "player/pl_fallpain3.wav", 100, 100 )
	end
	
	if duration == 1 then
		Slap()
		return {
			Activator = owner,
			Player = ply,
			Wording = " has slapped ",
		}
	elseif duration > 1 then	
		timer.Create( "exsto_WhipDelay"..ply:Nick(), delay, duration, Slap )
		return {
			Activator = owner,
			Player = ply,
			Wording = " is whipping ",
			Secondary = " " .. duration .. " times",
		}
	end
	
end
PLUGIN:AddCommand( "slap", {
	Call = PLUGIN.Slap,
	Desc = "Slaps a player",
	FlagDesc = "Allows users to slap other players.",
	Console = { "slap" },
	Chat = { "!slap", "!whip" },
	ReturnOrder = "Victim-Damage-Duration-Delay",
	Args = {Victim = "PLAYER", Damage = "NUMBER", Duration = "NUMBER", Delay = "NUMBER"},
	Optional = {Damage = 10, Duration = 1, Delay = 0.7}
})

PLUGIN:Register()
